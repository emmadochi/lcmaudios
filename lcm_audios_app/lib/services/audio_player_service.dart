import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/models/audio_track.dart';
import '../core/models/spiritual_intent.dart';
import 'mock_data_service.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<AudioTrack> _allTracks = [];
  AudioTrack? _currentTrack;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  IntentCategory _selectedIntent = IntentCategory.all;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  AudioPlayerService() {
    _allTracks = List.from(MockDataService.sampleTracks);
    if (_allTracks.isNotEmpty) {
      _currentTrack = _allTracks[0];
    }
    _initPlayerListeners();
  }

  // Getters
  List<AudioTrack> get allTracks => _allTracks;
  AudioTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  IntentCategory get selectedIntent => _selectedIntent;

  List<AudioTrack> get filteredTracks {
    if (_selectedIntent == IntentCategory.all) {
      return _allTracks;
    }
    return _allTracks
        .where((track) => track.intentCategory == _selectedIntent)
        .toList();
  }

  void _initPlayerListeners() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = (state == PlayerState.playing);
      _isBuffering = false;
      notifyListeners();
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((newDuration) {
      _duration = newDuration;
      notifyListeners();
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      notifyListeners();
    });
  }

  void setIntentFilter(IntentCategory category) {
    _selectedIntent = category;
    notifyListeners();
  }

  Future<void> playTrack(AudioTrack track) async {
    _currentTrack = track;
    notifyListeners();

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(track.audioUrl));
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (_currentTrack == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position > Duration.zero) {
        await _audioPlayer.resume();
      } else {
        await playTrack(_currentTrack!);
      }
    }
  }

  Future<void> seekTo(Duration newPosition) async {
    await _audioPlayer.seek(newPosition);
  }

  Future<void> skipNext() async {
    final list = filteredTracks;
    if (list.isEmpty) return;
    int nextIdx = (list.indexWhere((t) => t.id == _currentTrack?.id) + 1) % list.length;
    await playTrack(list[nextIdx]);
  }

  Future<void> skipPrevious() async {
    final list = filteredTracks;
    if (list.isEmpty) return;
    int prevIdx = (list.indexWhere((t) => t.id == _currentTrack?.id) - 1 + list.length) % list.length;
    await playTrack(list[prevIdx]);
  }

  void toggleFavorite(String trackId) {
    int idx = _allTracks.indexWhere((t) => t.id == trackId);
    if (idx != -1) {
      _allTracks[idx] = _allTracks[idx].copyWith(isFavorite: !_allTracks[idx].isFavorite);
      if (_currentTrack?.id == trackId) {
        _currentTrack = _allTracks[idx];
      }
      notifyListeners();
    }
  }

  void toggleDownload(String trackId) {
    int idx = _allTracks.indexWhere((t) => t.id == trackId);
    if (idx != -1) {
      _allTracks[idx] = _allTracks[idx].copyWith(isDownloaded: !_allTracks[idx].isDownloaded);
      if (_currentTrack?.id == trackId) {
        _currentTrack = _allTracks[idx];
      }
      notifyListeners();
    }
  }

  void addSermonNote(String trackId, String noteText) {
    int idx = _allTracks.indexWhere((t) => t.id == trackId);
    if (idx != -1) {
      final newNote = SermonNote(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestampSeconds: _position.inSeconds.toDouble(),
        noteText: noteText,
        createdAt: DateTime.now(),
      );
      final updatedNotes = List<SermonNote>.from(_allTracks[idx].notes)..add(newNote);
      _allTracks[idx] = _allTracks[idx].copyWith(notes: updatedNotes);
      if (_currentTrack?.id == trackId) {
        _currentTrack = _allTracks[idx];
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
