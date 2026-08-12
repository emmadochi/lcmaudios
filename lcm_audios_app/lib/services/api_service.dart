import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/models/audio_track.dart';
import '../core/models/spiritual_intent.dart';

class ApiService {
  // Live Cloud Production URL deployed on Render.com
  static const String _liveCloudUrl = 'https://lcmaudios.onrender.com/api/v1';
  static const String _localUrl = 'http://localhost:5000/api/v1';

  static String get baseUrl {
    if (kReleaseMode && _liveCloudUrl.startsWith('https://')) {
      return _liveCloudUrl;
    }
    return _localUrl;
  }

  // Fetch catalog of audio tracks with optional intent category filter
  static Future<List<AudioTrack>> fetchTracks({IntentCategory? intent}) async {
    try {
      String endpoint = '$baseUrl/tracks';
      if (intent != null && intent != IntentCategory.all) {
        endpoint += '?intentCategory=${intent.name}';
      }

      final response = await http.get(Uri.parse(endpoint)).timeout(
        const Duration(seconds: 8),
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
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
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
        duration: 342,
        subgenre: 'Deep Worship',
        intentCategory: IntentCategory.deepWorship,
        mediaType: 'song',
        isFavorite: true,
        lyrics: [
          LyricLine(id: 'l1', trackId: 'track_1', timestampSeconds: 0, text: '[Instrumental Prelude]'),
          LyricLine(id: 'l2', trackId: 'track_1', timestampSeconds: 12, text: 'Let your glory fill this sacred place'),
          LyricLine(id: 'l3', trackId: 'track_1', timestampSeconds: 24, text: 'We bow in awe before your throne of grace'),
          LyricLine(id: 'l4', trackId: 'track_1', timestampSeconds: 38, text: 'Holy Holy, Almighty is the Lord'),
          LyricLine(id: 'l5', trackId: 'track_1', timestampSeconds: 52, text: 'Forever faithful is your holy word'),
        ],
      ),
      AudioTrack(
        id: 'track_2',
        title: 'Morning Mercies & Devotional Declaration',
        artist: 'Pastor Enoch Adeboye',
        albumArtUrl: 'https://images.unsplash.com/photo-1507676184212-d03ab07a01bf?auto=format&fit=crop&w=800&q=80',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        duration: 1110,
        subgenre: 'Spoken Sermon',
        intentCategory: IntentCategory.morningDevotion,
        mediaType: 'sermon',
        lyrics: [
          LyricLine(id: 'l6', trackId: 'track_2', timestampSeconds: 0, text: 'Welcome to this morning devotional broadcast.'),
          LyricLine(id: 'l7', trackId: 'track_2', timestampSeconds: 15, text: 'Lamentations 3:22 tells us His mercies are new every morning.'),
          LyricLine(id: 'l8', trackId: 'track_2', timestampSeconds: 40, text: 'Speak to your day before the sun rises above the horizon.'),
        ],
      ),
    ];
  }
}
