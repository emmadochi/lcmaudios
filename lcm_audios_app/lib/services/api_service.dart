import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/models/audio_track.dart';
import '../core/models/spiritual_intent.dart';
import '../core/models/sermon_series.dart';

class PaginatedTracksResult {
  final List<AudioTrack> tracks;
  final int total;
  final int page;
  final int totalPages;
  final bool hasMore;

  const PaginatedTracksResult({
    required this.tracks,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasMore,
  });
}

class ApiService {
  // Live Cloud Production URL on AWS (audios.lifechangerstouch.org)
  static const String _liveCloudUrl = 'https://audios.lifechangerstouch.org/api/v1';
  static const String _localUrl = 'http://localhost:5000/api/v1';

  // Always use the live cloud URL if configured, enabling emulator & device to stream live tracks
  static String get baseUrl {
    if (_liveCloudUrl.startsWith('https://') || _liveCloudUrl.startsWith('http://')) {
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

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email.trim().toLowerCase()}),
      ).timeout(const Duration(seconds: 25));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'], 'otp': data['otp']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to request password reset.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Unable to connect to server. Please check your connection.'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 25));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to reset password.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Unable to connect to server. Please check your connection.'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? email,
    String? token,
    int? streamCount,
    int? downloadCount,
    int? totalListeningMinutes,
    int? notesCount,
  }) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.patch(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
        body: json.encode({
          'fullName': fullName.trim(),
          if (email != null) 'email': email.trim().toLowerCase(),
          if (streamCount != null) 'streamCount': streamCount,
          if (downloadCount != null) 'downloadCount': downloadCount,
          if (totalListeningMinutes != null) 'totalListeningMinutes': totalListeningMinutes,
          if (notesCount != null) 'notesCount': notesCount,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to update profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
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
      ).timeout(const Duration(seconds: 7));

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

  // Fetch featured sermon series dynamically from cloud
  static Future<List<SermonSeries>> fetchSeries() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/series'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['series'] ?? [];
        if (list.isNotEmpty) {
          final fetched = list.map((json) => SermonSeries.fromJson(json)).toList();
          return fetched;
        }
      }
    } catch (e) {
      debugPrint('[ApiService] Series fetch error: $e');
    }
    return [];
  }

  // Fetch windowed page of audio tracks for progressive infinite scroll at 5,000+ scale
  static Future<PaginatedTracksResult> fetchTracksPaginated({
    int page = 1,
    int limit = 50,
    IntentCategory? intent,
    String? categoryKey,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (categoryKey != null && categoryKey != 'all') {
        queryParams['intentCategory'] = categoryKey;
      } else if (intent != null && intent != IntentCategory.all) {
        queryParams['intentCategory'] = intent.name;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$baseUrl/tracks').replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['tracks'] ?? [];
        final tracks = list.map((json) => AudioTrack.fromJson(json)).toList();
        final total = data['total'] is int ? data['total'] as int : tracks.length;
        final resPage = data['page'] is int ? data['page'] as int : page;
        final totalPages = data['totalPages'] is int ? data['totalPages'] as int : 1;
        final hasMore = data['hasMore'] is bool ? data['hasMore'] as bool : (page < totalPages);

        return PaginatedTracksResult(
          tracks: tracks,
          total: total,
          page: resPage,
          totalPages: totalPages,
          hasMore: hasMore,
        );
      }
    } catch (e) {
      debugPrint('[ApiService] Paginated tracks fetch error: $e');
    }

    final fallback = _getFallbackTracks();
    return PaginatedTracksResult(
      tracks: fallback,
      total: fallback.length,
      page: 1,
      totalPages: 1,
      hasMore: false,
    );
  }

  // Fetch catalog of audio tracks with optional intent category filter
  static Future<List<AudioTrack>> fetchTracks({IntentCategory? intent}) async {
    try {
      String endpoint = '$baseUrl/tracks';
      if (intent != null && intent != IntentCategory.all) {
        endpoint += '?intentCategory=${intent.name}';
      }

      final response = await http.get(Uri.parse(endpoint)).timeout(
        const Duration(seconds: 7),
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
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/initialize'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'planType': planType,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
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

  // Fetch dynamic list of ministers from backend
  static Future<List<Map<String, dynamic>>> fetchMinisters() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ministers'),
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['ministers'] ?? [];
        return list.map((m) => Map<String, dynamic>.from(m)).toList();
      }
    } catch (e) {
      debugPrint('[ApiService] Ministers fetch error: $e');
    }
    return _getFallbackMinisters();
  }

  // Fallback seed ministers when offline (empty to prevent resurrected unapproved mock data)
  static List<Map<String, dynamic>> _getFallbackMinisters() {
    return const [];
  }

  // Fallback seed tracks when offline (empty to prevent resurrected deleted mock data)
  static List<AudioTrack> _getFallbackTracks() {
    return const [];
  }
}

