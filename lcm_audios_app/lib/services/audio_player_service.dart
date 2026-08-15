import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/audio_track.dart';
import '../core/models/spiritual_intent.dart';
import 'api_service.dart';
import 'mock_data_service.dart';
import 'offline_storage_service.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<AudioTrack> _allTracks = [];
  AudioTrack? _currentTrack;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isOnline = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  IntentCategory _selectedIntent = IntentCategory.all;

  List<SpiritualIntent> _categories = List.from(SpiritualIntent.defaultCategories);
  String _selectedCategoryKey = 'all';

  // ─── Playback Speed & Sleep Timer State ───────────────────────────────────
  double _playbackSpeed = 1.0;
  Duration? _sleepTimerDuration;
  int _sleepTimerSecondsLeft = 0;
  Timer? _sleepTimer;
  bool _sleepTimerEndAtTrack = false;

  // ─── "Continue Listening" Resume Memory ───────────────────────────────────
  String? _lastPlayedTrackId;
  Duration _lastPlayedPosition = Duration.zero;
  DateTime? _lastPositionSaveTime;

  // ─── Telemetry metering state ────────────────────────────────────────────
  /// Position at last telemetry checkpoint for delta calculation.
  Duration _lastTelemetryPosition = Duration.zero;
  /// Timer fires every 30 seconds to queue a telemetry event.
  Timer? _telemetryTimer;

  // ─── Download progress ────────────────────────────────────────────────────
  final Map<String, double> _downloadProgress = {};

  // ─── Connectivity ─────────────────────────────────────────────────────────
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  String _userName = 'Grace Worshipper';
  int _listenCount = 3;

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<AudioTrack> get allTracks => _allTracks;
  AudioTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get isOnline => _isOnline;
  Duration get position => _position;
  Duration get duration => _duration;
  IntentCategory get selectedIntent => _selectedIntent;
  String get selectedCategoryKey => _selectedCategoryKey;
  List<SpiritualIntent> get categories => _categories;
  String get userName => _userName;
  int get listenCount => _listenCount;
  double get playbackSpeed => _playbackSpeed;
  Duration? get sleepTimerDuration => _sleepTimerDuration;
  int get sleepTimerSecondsLeft => _sleepTimerSecondsLeft;
  bool get isSleepTimerActive => _sleepTimerSecondsLeft > 0 || _sleepTimerEndAtTrack;
  bool get sleepTimerEndAtTrack => _sleepTimerEndAtTrack;
  Map<String, double> get downloadProgress => Map.unmodifiable(_downloadProgress);

  String get formattedSleepTimerRemaining {
    if (_sleepTimerEndAtTrack) return 'End of Track';
    if (_sleepTimerSecondsLeft <= 0) return 'Off';
    final m = (_sleepTimerSecondsLeft / 60).floor().toString().padLeft(2, '0');
    final s = (_sleepTimerSecondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  AudioTrack? get lastPlayedTrack {
    if (_lastPlayedTrackId == null) return null;
    try {
      return _allTracks.firstWhere((t) => t.id == _lastPlayedTrackId);
    } catch (_) {
      return null;
    }
  }

  Duration get lastPlayedPosition => _lastPlayedPosition;

  double get userProgress {
    int downloadedCount = _allTracks.where((t) => t.isDownloaded).length;
    int notesCount      = _allTracks.fold(0, (sum, t) => sum + t.notes.length);
    int favoritesCount  = _allTracks.where((t) => t.isFavorite).length;
    int points = (_listenCount * 15) + (downloadedCount * 20) + (notesCount * 25) + (favoritesCount * 10);
    return (points / 100.0).clamp(0.1, 1.0);
  }

  int get userProgressPercentage => (userProgress * 100).round();

  List<AudioTrack> get filteredTracks {
    if (_selectedCategoryKey == 'all' && _selectedIntent == IntentCategory.all) {
      return _allTracks;
    }
    return _allTracks.where((t) {
      if (_selectedCategoryKey != 'all') {
        return t.matchesCategoryKey(_selectedCategoryKey);
      }
      return t.intentCategory == _selectedIntent;
    }).toList();
  }

  // ─── Constructor ──────────────────────────────────────────────────────────
  AudioPlayerService() {
    _initAudioContext();
    _allTracks    = List.from(MockDataService.sampleTracks);
    _currentTrack = _allTracks.isNotEmpty ? _allTracks[0] : null;
    _initPlayerListeners();
    _initConnectivityListener();
    _loadTracksAndStorage();
  }

  // ─── Background Audio Context ─────────────────────────────────────────────
  void _initAudioContext() {
    try {
      AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.allowAirPlay,
            AVAudioSessionOptions.allowBluetooth,
          },
        ),
      ));
    } catch (e) {
      debugPrint('[Player] AudioContext setup: $e');
    }
  }

  // ─── Player listeners ─────────────────────────────────────────────────────
  void _initPlayerListeners() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying   = (state == PlayerState.playing);
      _isBuffering = false;

      if (wasPlaying && !_isPlaying) {
        // Paused or stopped — flush partial session telemetry immediately & persist position
        _flushSessionTelemetry();
        _telemetryTimer?.cancel();
        _persistCurrentPosition();
      } else if (!wasPlaying && _isPlaying) {
        // Resumed — restart 30-second metering timer
        _startTelemetryTimer();
      }

      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (_sleepTimerEndAtTrack) {
        _sleepTimerEndAtTrack = false;
        _audioPlayer.pause();
        notifyListeners();
      } else {
        skipNext();
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
      _position = p;
      // Periodically persist position every 5 seconds
      final now = DateTime.now();
      if (_lastPositionSaveTime == null || now.difference(_lastPositionSaveTime!).inSeconds >= 5) {
        _lastPositionSaveTime = now;
        _persistCurrentPosition();
      }
      notifyListeners();
    });
  }

  // ─── Position Persistence ("Continue Listening") ──────────────────────────
  Future<void> _persistCurrentPosition() async {
    if (_currentTrack == null) return;
    if (_position.inSeconds < 5) return; // Don't save first 5 seconds
    _lastPlayedTrackId = _currentTrack!.id;
    _lastPlayedPosition = _position;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_played_track_id', _lastPlayedTrackId!);
      await prefs.setInt('last_played_position_sec_${_currentTrack!.id}', _position.inSeconds);
      await prefs.setInt('last_played_position_sec', _position.inSeconds);
    } catch (e) {
      debugPrint('[Player] Position persist error: $e');
    }
  }

  // ─── Connectivity ─────────────────────────────────────────────────────────
  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((results) async {
      final wasOffline = !_isOnline;
      _isOnline = results.any(
        (r) => r != ConnectivityResult.none,
      );

      debugPrint('[Connectivity] Status: $_isOnline');

      if (wasOffline && _isOnline) {
        // Came back online — flush queued telemetry
        final flushed = await OfflineStorageService.flushPendingTelemetry();
        if (flushed > 0) debugPrint('[Telemetry] 🔄 Back-online flush: $flushed events sent.');
      }
      notifyListeners();
    });
  }

  // ─── Telemetry metering ───────────────────────────────────────────────────

  /// Start 30-second recurring telemetry checkpoint timer.
  void _startTelemetryTimer() {
    _telemetryTimer?.cancel();
    _lastTelemetryPosition = _position;
    _telemetryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _flushSessionTelemetry();
    });
  }

  /// Calculate delta seconds since last checkpoint and queue event.
  void _flushSessionTelemetry() {
    if (_currentTrack == null) return;
    final delta = (_position - _lastTelemetryPosition).inSeconds.toDouble();
    if (delta < 3) return; // ignore sub-3-second deltas
    _lastTelemetryPosition = _position;

    OfflineStorageService.queueTelemetryEvent(
      trackId: _currentTrack!.id,
      durationPlayedSeconds: delta,
    );

    // If online, flush immediately; otherwise the connectivity listener will do it
    if (_isOnline) {
      OfflineStorageService.flushPendingTelemetry();
    }
  }

  /// Reset telemetry state when a new track starts.
  void _resetTelemetry() {
    _telemetryTimer?.cancel();
    _lastTelemetryPosition = Duration.zero;
  }

  // ─── Playback Speed Controls ──────────────────────────────────────────────
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioPlayer.setPlaybackRate(speed);
    notifyListeners();
  }

  // ─── Sleep Timer Controls ─────────────────────────────────────────────────
  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimerEndAtTrack = false;
    _sleepTimerDuration = duration;

    if (duration == null) {
      _sleepTimerSecondsLeft = 0;
      notifyListeners();
      return;
    }

    _sleepTimerSecondsLeft = duration.inSeconds;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimerSecondsLeft > 1) {
        _sleepTimerSecondsLeft--;
        notifyListeners();
      } else {
        _sleepTimerSecondsLeft = 0;
        _sleepTimerDuration = null;
        timer.cancel();
        _audioPlayer.pause();
        notifyListeners();
      }
    });
  }

  void setSleepTimerEndAtTrack() {
    _sleepTimer?.cancel();
    _sleepTimerDuration = null;
    _sleepTimerSecondsLeft = 0;
    _sleepTimerEndAtTrack = true;
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerDuration = null;
    _sleepTimerSecondsLeft = 0;
    _sleepTimerEndAtTrack = false;
    notifyListeners();
  }

  // ─── Relative Seek Helper (Rewind / Fast-Forward) ─────────────────────────
  Future<void> seekRelative(int secondsDelta) async {
    final target = _position + Duration(seconds: secondsDelta);
    if (target < Duration.zero) {
      await seekTo(Duration.zero);
    } else if (target > _duration) {
      await seekTo(_duration);
    } else {
      await seekTo(target);
    }
  }

  // ─── Playback & Filtering ────────────────────────────────────────────────
  void setIntentFilter(IntentCategory category) {
    _selectedIntent = category;
    _selectedCategoryKey = category.name;
    notifyListeners();
  }

  void setCategoryFilter(String categoryKey) {
    _selectedCategoryKey = categoryKey;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    await _loadTracksAndStorage();
  }

  Future<void> resumeTrack(AudioTrack track, {Duration? startAt}) async {
    await playTrack(track);
    if (startAt != null && startAt > Duration.zero) {
      await Future.delayed(const Duration(milliseconds: 300));
      await seekTo(startAt);
    } else {
      // Check saved position for this track
      final prefs = await SharedPreferences.getInstance();
      final savedSec = prefs.getInt('last_played_position_sec_${track.id}') ?? 0;
      if (savedSec > 5) {
        await Future.delayed(const Duration(milliseconds: 300));
        await seekTo(Duration(seconds: savedSec));
      }
    }
  }

  Future<void> playTrack(AudioTrack track) async {
    _currentTrack = track;
    _resetTelemetry();
    notifyListeners();

    try {
      await _audioPlayer.stop();

      // Set playback speed rate
      if (_playbackSpeed != 1.0) {
        await _audioPlayer.setPlaybackRate(_playbackSpeed);
      }

      // Attempt encrypted offline playback first
      if (track.isDownloaded) {
        _isBuffering = true;
        notifyListeners();
        final decryptedBytes = await OfflineStorageService.getDecryptedAudioBytes(track.id);
        _isBuffering = false;
        if (decryptedBytes != null && decryptedBytes.isNotEmpty) {
          debugPrint('[Player] 🔐 Offline DRM playback: ${track.id} (${decryptedBytes.length} bytes)');
          await _audioPlayer.play(BytesSource(decryptedBytes));
          _startTelemetryTimer();
          return;
        }
      }

      // Fallback: stream from network
      _isBuffering = true;
      notifyListeners();
      await _audioPlayer.play(UrlSource(track.audioUrl));
      _isBuffering = false;
      _startTelemetryTimer();
    } catch (e) {
      _isBuffering = false;
      debugPrint('[Player] Error: $e');
      notifyListeners();
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
    // Reset telemetry checkpoint to avoid counting seek-skipped time
    _lastTelemetryPosition = newPosition;
  }

  Future<void> skipNext() async {
    final list = filteredTracks;
    if (list.isEmpty) return;
    final nextIdx = (list.indexWhere((t) => t.id == _currentTrack?.id) + 1) % list.length;
    await playTrack(list[nextIdx]);
  }

  Future<void> skipPrevious() async {
    final list = filteredTracks;
    if (list.isEmpty) return;
    final prevIdx =
        (list.indexWhere((t) => t.id == _currentTrack?.id) - 1 + list.length) % list.length;
    await playTrack(list[prevIdx]);
  }

  // ─── Favorites ────────────────────────────────────────────────────────────
  void toggleFavorite(String trackId) {
    final idx = _allTracks.indexWhere((t) => t.id == trackId);
    if (idx != -1) {
      _allTracks[idx] = _allTracks[idx].copyWith(isFavorite: !_allTracks[idx].isFavorite);
      if (_currentTrack?.id == trackId) _currentTrack = _allTracks[idx];
      notifyListeners();
    }
  }

  // ─── Downloads ────────────────────────────────────────────────────────────
  Future<void> toggleDownload(String trackId) async {
    final idx = _allTracks.indexWhere((t) => t.id == trackId);
    if (idx == -1) return;

    final track = _allTracks[idx];

    if (track.isDownloaded) {
      // Delete immediately
      final deleted = await OfflineStorageService.deleteDownloadedTrack(trackId);
      if (deleted) {
        _allTracks[idx] = track.copyWith(isDownloaded: false);
        if (_currentTrack?.id == trackId) _currentTrack = _allTracks[idx];
        _downloadProgress.remove(trackId);
        notifyListeners();
      }
    } else {
      // Stream download with progress
      _downloadProgress[trackId] = 0.0;
      notifyListeners();

      final success = await OfflineStorageService.downloadEncryptedTrack(
        trackId,
        track.audioUrl,
        onProgress: (p) {
          _downloadProgress[trackId] = p;
          notifyListeners();
        },
      );

      if (success) {
        _allTracks[idx] = track.copyWith(isDownloaded: true);
        if (_currentTrack?.id == trackId) _currentTrack = _allTracks[idx];
      }
      _downloadProgress.remove(trackId);
      notifyListeners();
    }
  }

  /// Returns [0.0 – 1.0] if a download is in progress, or null otherwise.
  double? getDownloadProgressFor(String trackId) => _downloadProgress[trackId];

  // ─── Profile / User ───────────────────────────────────────────────────────
  Future<void> setUserName(String name) async {
    if (name.trim().isEmpty) return;
    _userName = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userName);
    notifyListeners();
  }

  // ─── Sermon Notes ─────────────────────────────────────────────────────────
  Future<void> addSermonNote(String trackId, String noteText) async {
    final idx = _allTracks.indexWhere((t) => t.id == trackId);
    if (idx == -1) return;

    final timestamp = _position.inSeconds.toDouble();
    final newNote = SermonNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestampSeconds: timestamp,
      noteText: noteText,
      createdAt: DateTime.now(),
    );

    final updatedNotes = List<SermonNote>.from(_allTracks[idx].notes)..add(newNote);
    _allTracks[idx] = _allTracks[idx].copyWith(notes: updatedNotes);
    if (_currentTrack?.id == trackId) _currentTrack = _allTracks[idx];
    notifyListeners();

    // Persist to backend
    await ApiService.saveSermonNote(
      trackId: trackId,
      timestampSeconds: timestamp,
      noteText: noteText,
    );
  }

  // ─── Initialisation ───────────────────────────────────────────────────────
  Future<void> _loadTracksAndStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _userName    = prefs.getString('user_name') ?? 'Grace Worshipper';
    _listenCount = prefs.getInt('user_listen_count') ?? 3;

    // Restore last played track and position
    _lastPlayedTrackId = prefs.getString('last_played_track_id');
    final savedPosSec  = prefs.getInt('last_played_position_sec') ?? 0;
    _lastPlayedPosition = Duration(seconds: savedPosSec);

    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult.any((r) => r != ConnectivityResult.none);

    // Fetch live tracks and categories or fall back to seed data
    if (_isOnline) {
      final fetchedCats = await ApiService.fetchCategories();
      if (fetchedCats.isNotEmpty) {
        _categories = fetchedCats;
      }

      final apiTracks = await ApiService.fetchTracks();
      if (apiTracks.isNotEmpty) {
        _allTracks = apiTracks;
        if (_currentTrack == null || _allTracks.every((t) => t.id != _currentTrack!.id)) {
          _currentTrack = _allTracks.first;
        }
      }
    }

    // Sync downloaded state from local storage
    final downloadedIds = await OfflineStorageService.getDownloadedTrackIds();
    for (int i = 0; i < _allTracks.length; i++) {
      if (downloadedIds.contains(_allTracks[i].id)) {
        _allTracks[i] = _allTracks[i].copyWith(isDownloaded: true);
      }
    }

    if (_currentTrack != null) {
      final idx = _allTracks.indexWhere((t) => t.id == _currentTrack!.id);
      if (idx != -1) _currentTrack = _allTracks[idx];
    }

    // Flush any pending offline telemetry if online
    if (_isOnline) {
      final flushed = await OfflineStorageService.flushPendingTelemetry();
      if (flushed > 0) debugPrint('[Telemetry] Startup flush: $flushed events.');
    }

    notifyListeners();
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _flushSessionTelemetry(); // Capture final partial session
    _telemetryTimer?.cancel();
    _sleepTimer?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
