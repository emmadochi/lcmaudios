import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/models/audio_track.dart';
import '../core/models/spiritual_intent.dart';

class ApiService {
  // Live Cloud Production URL deployed on Render.com
  static const String _liveCloudUrl = 'https://lcmaudios.onrender.com/api/v1';
  static const String _localUrl = 'http://localhost:5000/api/v1';

  // Always use the live cloud URL if configured, enabling emulator & device to stream live tracks
  static String get baseUrl {
    if (_liveCloudUrl.startsWith('https://')) {
      return _liveCloudUrl;
    }
    return _localUrl;
  }

  // ─── User Authentication & Registration ─────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 25));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'token': data['token'], 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed. Please check your credentials.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Unable to connect to streaming cloud. Please check your network connection.'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    List<String>? intentPreferences,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim().toLowerCase(),
          'password': password,
          'fullName': fullName.trim(),
          'intentPreferences': intentPreferences ?? ['morningDevotion', 'deepWorship'],
        }),
      ).timeout(const Duration(seconds: 25));

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'token': data['token'], 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Unable to connect to streaming cloud. Please check your network connection.'};
    }
  }

  static Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    required String fullName,
    String? googleId,
    String? photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim().toLowerCase(),
          'fullName': fullName.trim(),
          'googleId': googleId,
          'photoUrl': photoUrl,
        }),
      ).timeout(const Duration(seconds: 25));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'token': data['token'], 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Google authentication failed.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Unable to connect to streaming cloud for Google sign-in.'};
    }
  }

  static Future<Map<String, dynamic>?> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['user'];
      }
    } catch (_) {}
    return null;
  }

  // Fetch spiritual intent categories dynamically from cloud
  static Future<List<SpiritualIntent>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/categories'),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['categories'] ?? [];
        if (list.isNotEmpty) {
          final fetched = list.map((json) => SpiritualIntent.fromJson(json)).toList();
          return fetched;
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Categories fetch error: $e');
    }
    return SpiritualIntent.defaultCategories;
  }

  // Fetch catalog of audio tracks with optional intent category filter
  static Future<List<AudioTrack>> fetchTracks({IntentCategory? intent}) async {
    try {
      String endpoint = '$baseUrl/tracks';
      if (intent != null && intent != IntentCategory.all) {
        endpoint += '?intentCategory=${intent.name}';
      }

      final response = await http.get(Uri.parse(endpoint)).timeout(
        const Duration(seconds: 20),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['tracks'] ?? [];
        return list.map((json) => AudioTrack.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[ApiService] Connection error: $e');
    }
    return _getFallbackTracks();
  }

  // Fetch line-by-line synchronized lyrics for a track
  static Future<List<LyricLine>> fetchLyrics(String trackId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tracks/$trackId/lyrics'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['lyrics'] ?? [];
        return list.map((json) => LyricLine.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('[ApiService] Lyrics fetch error: $e');
    }
    return [];
  }

  // Check API connectivity status
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(
        const Duration(seconds: 3),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Create a timestamped sermon note
  static Future<bool> saveSermonNote({
    required String trackId,
    required double timestampSeconds,
    required String noteText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'trackId': trackId,
          'timestampSeconds': timestampSeconds,
          'noteText': noteText,
        }),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Send stream telemetry data to backend for creator accounting
  static Future<bool> syncTelemetry(List<Map<String, dynamic>> events) async {
    if (events.isEmpty) return true;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/telemetry'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'events': events}),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] Telemetry sync error: $e');
      return false;
    }
  }

  // ─── Paystack Covenant Partner Payments ──────────────────────────────
  static Future<Map<String, dynamic>?> initializePaystackPayment({
    required String email,
    required String planType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/initialize'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'planType': planType,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Paystack init error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> verifyPaystackPayment(String reference) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/verify/$reference'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Paystack verify error: $e');
    }
    return null;
  }

  // Fallback seed tracks when offline
  static List<AudioTrack> _getFallbackTracks() {
    return [
      AudioTrack(
        id: 'track_1',
        title: 'Atmosphere of Grace & Glory',
        artist: 'Nathaniel Bassey & LCM Worship',
        albumArtUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        duration: const Duration(seconds: 342),
        subgenre: 'Deep Worship',
        intentCategory: IntentCategory.deepWorship,
        mediaType: MediaType.song,
        isFavorite: true,
        lyrics: const [
          LyricLine(timestampSeconds: 0, text: '[Instrumental Prelude]'),
          LyricLine(timestampSeconds: 12, text: 'Let your glory fill this sacred place'),
          LyricLine(timestampSeconds: 24, text: 'We bow in awe before your throne of grace'),
          LyricLine(timestampSeconds: 38, text: 'Holy Holy, Almighty is the Lord'),
          LyricLine(timestampSeconds: 52, text: 'Forever faithful is your holy word'),
        ],
      ),
      AudioTrack(
        id: 'track_2',
        title: 'Morning Mercies & Devotional Declaration',
        artist: 'Pastor Enoch Adeboye',
        albumArtUrl: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?auto=format&fit=crop&w=800&q=80',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        duration: const Duration(seconds: 1110),
        subgenre: 'Spoken Sermon',
        intentCategory: IntentCategory.morningDevotion,
        mediaType: MediaType.sermon,
        lyrics: const [
          LyricLine(timestampSeconds: 0, text: 'Welcome to this morning devotional broadcast.'),
          LyricLine(timestampSeconds: 15, text: 'Lamentations 3:22 tells us His mercies are new every morning.'),
          LyricLine(timestampSeconds: 40, text: 'Speak to your day before the sun rises above the horizon.'),
        ],
      ),
    ];
  }
}
