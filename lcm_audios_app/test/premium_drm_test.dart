import 'package:flutter_test/flutter_test.dart';
import 'package:lcm_audios_app/core/models/audio_track.dart';
import 'package:lcm_audios_app/core/models/spiritual_intent.dart';
import 'package:lcm_audios_app/services/audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Covenant Partner DRM & Access Tier Ingestion Tests', () {
    test('AudioTrack.fromJson accurately parses boolean and string isPremium representations', () {
      final jsonBoolTrue = {
        'id': 't1',
        'title': 'Anointing 1',
        'artist': 'Pastor Martins',
        'audioUrl': 'https://example.com/audio1.mp3',
        'isPremium': true,
      };
      final track1 = AudioTrack.fromJson(jsonBoolTrue);
      expect(track1.isPremium, isTrue);

      final jsonStringTrue = {
        'id': 't2',
        'title': 'Anointing 2',
        'artist': 'Pastor Martins',
        'audioUrl': 'https://example.com/audio2.mp3',
        'isPremium': 'true',
      };
      final track2 = AudioTrack.fromJson(jsonStringTrue);
      expect(track2.isPremium, isTrue);

      final jsonBoolFalse = {
        'id': 't3',
        'title': 'Free Sermon',
        'artist': 'Pastor Martins',
        'audioUrl': 'https://example.com/audio3.mp3',
        'isPremium': false,
      };
      final track3 = AudioTrack.fromJson(jsonBoolFalse);
      expect(track3.isPremium, isFalse);
    });

    test('AudioPlayerService DRM enforces lock on premium tracks for non-partners', () {
      final playerService = AudioPlayerService();
      expect(playerService.isCovenantPartner, isFalse);

      final premiumTrack = AudioTrack(
        id: 'premium_test_1',
        title: 'Secret Place Mysteries',
        artist: 'Pastor Martins',
        albumArtUrl: 'https://example.com/art.jpg',
        audioUrl: 'https://example.com/audio.mp3',
        duration: const Duration(minutes: 10),
        subgenre: 'Prophetic',
        intentCategory: IntentCategory.deepWorship,
        mediaType: MediaType.sermon,
        isPremium: true,
      );

      final freeTrack = AudioTrack(
        id: 'free_test_1',
        title: 'Morning Prayer',
        artist: 'Pastor Martins',
        albumArtUrl: 'https://example.com/art.jpg',
        audioUrl: 'https://example.com/audio.mp3',
        duration: const Duration(minutes: 5),
        subgenre: 'Devotion',
        intentCategory: IntentCategory.morningDevotion,
        mediaType: MediaType.song,
        isPremium: false,
      );

      // Verify DRM access validation
      expect(playerService.isTrackAccessible(freeTrack), isTrue);
      expect(playerService.isTrackAccessible(premiumTrack), isFalse);
    });
  });
}
