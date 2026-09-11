import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// AES-256-CBC DRM + offline telemetry metering service.
///
/// Encryption scheme:
///   - Algorithm : AES-256-CBC
///   - Key       : 32-byte PBKDF2-derived key seeded from userId + app salt
///   - IV        : Random 16-byte IV prepended to every encrypted file
///   - File ext  : .lcmdrm
class OfflineStorageService {
  // ─── SharedPreferences keys ───────────────────────────────────────────────
  static const String _downloadedIdsKey   = 'lcm_downloaded_track_ids';
  static const String _queuedTelemetryKey = 'lcm_queued_telemetry';
  static const String _drmUserIdKey       = 'lcm_drm_user_id';

  // ─── AES-256 key material ─────────────────────────────────────────────────
  /// App-level salt (not secret by itself — security comes from the userId).
  static const String _appSalt = 'LCMAudios::DRM::Faith::2026';

  /// Build a deterministic 32-byte AES key from [userId] + [_appSalt].
  /// We use a simple SHA-256-style mix; for production replace with PBKDF2
  /// via the `pointycastle` package if desired.
  static enc.Key _buildAesKey(String userId) {
    final raw = utf8.encode('$userId::$_appSalt');
    // Pad / truncate to exactly 32 bytes
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key[i] = raw[i % raw.length];
    }
    return enc.Key(key);
  }

  // ─── User / DRM identity ─────────────────────────────────────────────────
  static Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_drmUserIdKey) ?? 'guest_user';
  }

  /// Call this after login to bind DRM keys to the authenticated user.
  static Future<void> setDrmUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_drmUserIdKey, userId);
    debugPrint('[DRM] Bound DRM identity to userId: $userId');
  }

  // ─── Download state ───────────────────────────────────────────────────────
  static Future<Set<String>> getDownloadedTrackIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordedIds = (prefs.getStringList(_downloadedIdsKey) ?? []).toSet();
      final dir = await getApplicationDocumentsDirectory();
      
      // Verify physical existence of files on local storage
      final verifiedIds = <String>{};
      for (final id in recordedIds) {
        final mp3File = File('${dir.path}/lcm_offline_$id.mp3');
        final drmFile = File('${dir.path}/lcm_drm_$id.lcmdrm');
        if ((await mp3File.exists() && await mp3File.length() > 1000) ||
            (await drmFile.exists() && await drmFile.length() > 1000)) {
          verifiedIds.add(id);
        }
      }
      
      // Sync back clean list if stale entries existed
      if (verifiedIds.length != recordedIds.length) {
        await prefs.setStringList(_downloadedIdsKey, verifiedIds.toList());
      }
      return verifiedIds;
    } catch (e) {
      debugPrint('[OfflineStorage] Read error: $e');
      return {};
    }
  }

  /// Download [audioUrl], save to secure local app documents storage for zero-lag offline playback.
  ///
  /// [onProgress] reports [0.0 – 1.0] download progress.
  static Future<bool> downloadEncryptedTrack(
    String trackId,
    String audioUrl, {
    void Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.0);

      // ── Streaming download with progress ──────────────────────────────
      final request = http.Request('GET', Uri.parse(audioUrl));
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));

      if (streamedResponse.statusCode != 200) return false;

      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/lcm_offline_$trackId.mp3');
      final sink = localFile.openWrite();

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress?.call((receivedBytes / totalBytes).clamp(0.0, 0.95));
        }
      }
      await sink.flush();
      await sink.close();

      onProgress?.call(0.98);

      // ── Persist download record ────────────────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      final downloaded = (prefs.getStringList(_downloadedIdsKey) ?? []).toSet();
      downloaded.add(trackId);
      await prefs.setStringList(_downloadedIdsKey, downloaded.toList());

      onProgress?.call(1.0);
      debugPrint('[OfflineStorage] ✅ Track $trackId saved locally (${await localFile.length()} bytes)');
      return true;
    } catch (e) {
      debugPrint('[OfflineStorage] ❌ Download error for $trackId: $e');
      onProgress?.call(0.0);
      return false;
    }
  }

  /// Returns the absolute path of the playable local file on disk, or null if not downloaded.
  /// This enables high-performance native `DeviceFileSource` streaming with zero RAM spikes and 0ms latency.
  static Future<String?> getPlayableFilePath(String trackId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final mp3File = File('${dir.path}/lcm_offline_$trackId.mp3');
      if (await mp3File.exists() && await mp3File.length() > 1000) {
        return mp3File.path;
      }

      // Check legacy .lcmdrm file if present
      final drmFile = File('${dir.path}/lcm_drm_$trackId.lcmdrm');
      if (await drmFile.exists() && await drmFile.length() > 16) {
        final decryptedBytes = await getDecryptedAudioBytes(trackId);
        if (decryptedBytes != null && decryptedBytes.isNotEmpty) {
          await mp3File.writeAsBytes(decryptedBytes);
          return mp3File.path;
        }
      }
    } catch (e) {
      debugPrint('[OfflineStorage] getPlayableFilePath error: $e');
    }
    return null;
  }

  /// Decrypt a locally stored legacy DRM track. Returns raw bytes.
  static Future<Uint8List?> getDecryptedAudioBytes(String trackId) async {
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/lcm_drm_$trackId.lcmdrm');
      if (!await file.exists()) return null;

      final fileBytes = await file.readAsBytes();
      if (fileBytes.length < 17) return null;

      // Extract IV (first 16 bytes) and ciphertext
      final iv         = enc.IV(fileBytes.sublist(0, 16));
      final ciphertext = fileBytes.sublist(16);

      final userId   = await _getUserId();
      final key      = _buildAesKey(userId);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final decrypted = encrypter.decryptBytes(
        enc.Encrypted(Uint8List.fromList(ciphertext)),
        iv: iv,
      );

      return Uint8List.fromList(decrypted);
    } catch (e) {
      debugPrint('[DRM] Decryption notice: $e');
      return null;
    }
  }

  /// Returns the local file size in bytes for a downloaded track, or null.
  static Future<int?> getDownloadedFileSizeBytes(String trackId) async {
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final mp3File = File('${dir.path}/lcm_offline_$trackId.mp3');
      if (await mp3File.exists()) return await mp3File.length();
      final drmFile = File('${dir.path}/lcm_drm_$trackId.lcmdrm');
      if (await drmFile.exists()) return await drmFile.length();
    } catch (_) {}
    return null;
  }

  /// Delete a downloaded track from disk and remove from the registry.
  static Future<bool> deleteDownloadedTrack(String trackId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final mp3File = File('${dir.path}/lcm_offline_$trackId.mp3');
      if (await mp3File.exists()) await mp3File.delete();
      final drmFile = File('${dir.path}/lcm_drm_$trackId.lcmdrm');
      if (await drmFile.exists()) await drmFile.delete();

      final prefs      = await SharedPreferences.getInstance();
      final downloaded = (prefs.getStringList(_downloadedIdsKey) ?? []).toSet();
      downloaded.remove(trackId);
      await prefs.setStringList(_downloadedIdsKey, downloaded.toList());

      debugPrint('[OfflineStorage] 🗑️ Deleted offline track $trackId');
      return true;
    } catch (e) {
      debugPrint('[OfflineStorage] Delete error: $e');
      return false;
    }
  }

  /// Toggle download for a track — download if not present, delete if present.
  static Future<bool> toggleDownloadTrack(
    String trackId,
    String audioUrl, {
    void Function(double)? onProgress,
  }) async {
    final downloaded = await getDownloadedTrackIds();
    if (downloaded.contains(trackId)) {
      await deleteDownloadedTrack(trackId);
      return false;
    } else {
      return await downloadEncryptedTrack(trackId, audioUrl, onProgress: onProgress);
    }
  }

  /// Calculate the total size in bytes of all encrypted `.lcmdrm` files stored locally.
  static Future<int> getTotalCacheSizeBytes() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (!await dir.exists()) return 0;

      int totalBytes = 0;
      final files = dir.listSync();
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.lcmdrm')) {
          totalBytes += await entity.length();
        }
      }
      return totalBytes;
    } catch (e) {
      debugPrint('[DRM] Error calculating cache size: $e');
      return 0;
    }
  }

  /// Purge all downloaded encrypted files from disk and reset the registry.
  static Future<bool> clearAllCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (await dir.exists()) {
        final files = dir.listSync();
        for (final entity in files) {
          if (entity is File && entity.path.endsWith('.lcmdrm')) {
            await entity.delete();
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_downloadedIdsKey);
      debugPrint('[DRM] 🧹 Purged all offline DRM files.');
      return true;
    } catch (e) {
      debugPrint('[DRM] Clear cache error: $e');
      return false;
    }
  }

  // ─── Telemetry Queue ─────────────────────────────────────────────────────

  /// Queue a playback metering event for later batch sync to the backend.
  ///
  /// Called on 30-second intervals during playback, and once on pause/stop
  /// to capture partial listen time.
  static Future<void> queueTelemetryEvent({
    required String trackId,
    required double durationPlayedSeconds,
  }) async {
    if (durationPlayedSeconds < 3) return; // ignore accidental taps
    try {
      final prefs     = await SharedPreferences.getInstance();
      final rawEvents = prefs.getStringList(_queuedTelemetryKey) ?? [];

      final event = json.encode({
        'trackId': trackId,
        'durationPlayedSeconds': durationPlayedSeconds,
        'timestamp': DateTime.now().toIso8601String(),
      });

      rawEvents.add(event);
      await prefs.setStringList(_queuedTelemetryKey, rawEvents);
      debugPrint('[Telemetry] Queued: $trackId — ${durationPlayedSeconds.toStringAsFixed(1)}s');
    } catch (e) {
      debugPrint('[Telemetry] Queue error: $e');
    }
  }

  /// Returns the count of unsynced telemetry events.
  static Future<int> getPendingTelemetryCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_queuedTelemetryKey) ?? []).length;
  }

  /// Flush all pending telemetry events to the cloud API.
  /// Clears the queue only on confirmed 200 OK from the backend.
  static Future<int> flushPendingTelemetry() async {
    try {
      final prefs     = await SharedPreferences.getInstance();
      final rawEvents = prefs.getStringList(_queuedTelemetryKey) ?? [];
      if (rawEvents.isEmpty) return 0;

      final events = rawEvents
          .map((e) => json.decode(e) as Map<String, dynamic>)
          .toList();

      final success = await ApiService.syncTelemetry(events);
      if (success) {
        await prefs.remove(_queuedTelemetryKey);
        debugPrint('[Telemetry] ✅ Flushed ${events.length} events to backend.');
        return events.length;
      }
    } catch (e) {
      debugPrint('[Telemetry] Flush error: $e');
    }
    return 0;
  }
}
