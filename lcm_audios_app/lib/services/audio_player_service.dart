import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/audio_track.dart';
import '../core/models/spiritual_intent.dart';
import '../core/models/custom_playlist.dart';
import 'api_service.dart';
import 'mock_data_service.dart';
import 'offline_storage_service.dart';
import 'audio_handler.dart';

enum RepeatMode {
  off,
  all,
  one,
}

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  LcmAudioHandler? _audioHandler;
  LcmAudioHandler? get audioHandler => _audioHandler;

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

  // ─── Custom Playlists & Active Queue State ────────────────────────────────
  List<CustomPlaylist> _customPlaylists = [];
  List<CustomPlaylist> get customPlaylists => _customPlaylists;

  List<AudioTrack> _queue = [];
  List<AudioTrack> get queue => _queue;
  int _currentQueueIndex = 0;
  int get currentQueueIndex => _currentQueueIndex;

  bool _isShuffle = false;
  bool get isShuffle => _isShuffle;

  RepeatMode _repeatMode = RepeatMode.off;
  RepeatMode get repeatMode => _repeatMode;

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
  String? _userEmail;
  String? _userId;
  String? _jwtToken;
  int _listenCount = 3;

  String? get userEmail => _userEmail;
  String? get userId => _userId;
  String? get jwtToken => _jwtToken;
  bool get isAuthenticated => _jwtToken != null && _jwtToken!.isNotEmpty;

  // ─── Mini Player Visibility State ─────────────────────────────────────────
  bool _isMiniPlayerDismissed = false;
  bool get isMiniPlayerDismissed => _isMiniPlayerDismissed;

  void dismissMiniPlayer() {
    _isMiniPlayerDismissed = true;
    notifyListeners();
  }

  void showMiniPlayer() {
    _isMiniPlayerDismissed = false;
    notifyListeners();
  }

  // ─── Covenant Partner (Premium Tier) State & Access Control ───────────────
  bool _isCovenantPartner = false;
  bool get isCovenantPartner => _isCovenantPartner;

  String? _partnerPlanType;
  String? get partnerPlanType => _partnerPlanType;

  String? _partnerPaymentRef;
  String? get partnerPaymentRef => _partnerPaymentRef;

  String? _partnerReceiptNo;
  String? get partnerReceiptNo => _partnerReceiptNo;

  String? _partnerExpiryDate;
  String? get partnerExpiryDate => _partnerExpiryDate;

  bool _previewLimitReached = false;
  bool get previewLimitReached => _previewLimitReached;

  void resetPreviewLimit() {
    _previewLimitReached = false;
    notifyListeners();
  }

  int get maxFreeDownloads => 3;
  int get currentDownloadCount => _allTracks.where((t) => t.isDownloaded).length;
  bool get hasReachedDownloadLimit => !_isCovenantPartner && currentDownloadCount >= maxFreeDownloads;

  bool isTrackAccessible(AudioTrack track) => _isCovenantPartner || !track.isPremium;

  Future<void> activatePartnerTier(
    bool active, {
    String? planType,
    String? reference,
    String? receiptNumber,
    String? expiryDate,
  }) async {
    _isCovenantPartner = active;
    _previewLimitReached = false;
    if (active) {
      _partnerPlanType   = planType ?? _partnerPlanType ?? 'monthly';
      _partnerPaymentRef = reference ?? _partnerPaymentRef;
      _partnerReceiptNo  = receiptNumber ?? _partnerReceiptNo;
      _partnerExpiryDate = expiryDate ?? _partnerExpiryDate;
    } else {
      _partnerPlanType   = null;
      _partnerPaymentRef = null;
      _partnerReceiptNo  = null;
      _partnerExpiryDate = null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_covenant_partner', active);
      if (active) {
        if (_partnerPlanType != null) await prefs.setString('partner_plan_type', _partnerPlanType!);
        if (_partnerPaymentRef != null) await prefs.setString('partner_payment_ref', _partnerPaymentRef!);
        if (_partnerReceiptNo != null) await prefs.setString('partner_receipt_no', _partnerReceiptNo!);
        if (_partnerExpiryDate != null) await prefs.setString('partner_expiry_date', _partnerExpiryDate!);
      } else {
        await prefs.remove('partner_plan_type');
        await prefs.remove('partner_payment_ref');
        await prefs.remove('partner_receipt_no');
        await prefs.remove('partner_expiry_date');
      }
    } catch (e) {
      debugPrint('[Partner] Save error: $e');
    }
    notifyListeners();
  }

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

  // ─── Offline Mode Only Filter ─────────────────────────────────────────────
  bool _isOfflineModeOnly = false;
  bool get isOfflineModeOnly => _isOfflineModeOnly;

  void toggleOfflineModeOnly() {
    _isOfflineModeOnly = !_isOfflineModeOnly;
    notifyListeners();
  }

  int get userProgressPercentage => (userProgress * 100).round();

  List<AudioTrack> get filteredTracks {
    List<AudioTrack> base = _allTracks;
    if (_isOfflineModeOnly) {
      base = base.where((t) => t.isDownloaded).toList();
    }
    if (_selectedCategoryKey == 'all' && _selectedIntent == IntentCategory.all) {
      return base;
    }
    return base.where((t) {
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
    _currentTrack = null;
    _initAudioHandler();
    _initPlayerListeners();
    _initConnectivityListener();
    _loadTracksAndStorage();
  }

  // ─── System AudioService Lock Screen / Media Session ──────────────────────
  Future<void> _initAudioHandler() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => LcmAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.lcmaudios.playback',
          androidNotificationChannelName: 'LCM Audios Playback',
          androidNotificationChannelDescription: 'Live playback controls & lock screen media metadata',
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: true,
        ),
      );

      _audioHandler!.onPlay = () => togglePlayPause();
      _audioHandler!.onPause = () => togglePlayPause();
      _audioHandler!.onSeek = (pos) => seekTo(pos);
      _audioHandler!.onSkipNext = () => skipNext(userInitiated: true);
      _audioHandler!.onSkipPrevious = () => skipPrevious();
      _audioHandler!.onStop = () => _audioPlayer.stop();

      if (_currentTrack != null) {
        _audioHandler!.updateMediaItemFromTrack(_currentTrack!, _duration);
        _syncAudioHandler();
      }
    } catch (e) {
      debugPrint('[AudioHandler] Init error: $e');
    }
  }

  void _syncAudioHandler() {
    if (_audioHandler == null) return;
    _audioHandler!.updatePlayerState(
      isPlaying: _isPlaying,
      position: _position,
      duration: _duration,
      speed: _playbackSpeed,
      isBuffering: _isBuffering,
    );
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

      _syncAudioHandler();
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) async {
      if (_sleepTimerEndAtTrack) {
        _sleepTimerEndAtTrack = false;
        await _audioPlayer.pause();
        _syncAudioHandler();
        notifyListeners();
      } else if (_repeatMode == RepeatMode.one) {
        // Repeat the exact same track from the start seamlessly
        if (_currentTrack != null) {
          await playTrack(_currentTrack!, updateQueue: false);
        }
      } else {
        await skipNext();
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      if (_currentTrack != null) {
        _audioHandler?.updateMediaItemFromTrack(_currentTrack!, d);
      }
      _syncAudioHandler();
      notifyListeners();
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
      _position = p;

      // 45-Second Anointed Preview Lock for Free Tier
      if (_currentTrack != null && _currentTrack!.isPremium && !_isCovenantPartner) {
        if (_position.inSeconds >= 45) {
          _previewLimitReached = true;
          _position = const Duration(seconds: 45);
          _audioPlayer.pause();
          _syncAudioHandler();
          notifyListeners();
          return;
        } else {
          _previewLimitReached = false;
        }
      }

      // Periodically persist position every 5 seconds
      final now = DateTime.now();
      if (_lastPositionSaveTime == null || now.difference(_lastPositionSaveTime!).inSeconds >= 5) {
        _lastPositionSaveTime = now;
        _persistCurrentPosition();
      }
      _syncAudioHandler();
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
    _isMiniPlayerDismissed = false;
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

  Future<void> playTrack(AudioTrack track, {bool updateQueue = true}) async {
    _isMiniPlayerDismissed = false;
    _currentTrack = track;
    _resetTelemetry();

    if (updateQueue) {
      final existingIdx = _queue.indexWhere((t) => t.id == track.id);
      if (existingIdx != -1) {
        _currentQueueIndex = existingIdx;
      } else {
        if (_queue.isEmpty) {
          _queue = List.from(filteredTracks.isNotEmpty ? filteredTracks : [track]);
          _currentQueueIndex = _queue.indexWhere((t) => t.id == track.id);
          if (_currentQueueIndex == -1) {
            _queue.insert(0, track);
            _currentQueueIndex = 0;
          }
        } else {
          _queue.insert(_currentQueueIndex + 1, track);
          _currentQueueIndex++;
        }
      }
    }

    notifyListeners();

    try {
      await _audioPlayer.stop();

      // Configure native looping for repeat-one
      await _audioPlayer.setReleaseMode(_repeatMode == RepeatMode.one ? ReleaseMode.loop : ReleaseMode.stop);

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
          _audioHandler?.updateMediaItemFromTrack(track, track.duration);
          await _audioPlayer.play(BytesSource(decryptedBytes));
          _startTelemetryTimer();
          _syncAudioHandler();
          return;
        }
      }

      // Fallback: stream from network
      _isBuffering = true;
      notifyListeners();
      _audioHandler?.updateMediaItemFromTrack(track, track.duration);
      await _audioPlayer.play(UrlSource(track.audioUrl));
      _isBuffering = false;
      _startTelemetryTimer();
      _syncAudioHandler();
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
      // If free user on premium track already reached or exceeded 45s limit, refuse resume
      if (_currentTrack!.isPremium && !_isCovenantPartner && _position.inSeconds >= 45) {
        _previewLimitReached = true;
        _position = const Duration(seconds: 45);
        await _audioPlayer.pause();
        notifyListeners();
        return;
      }
      _isMiniPlayerDismissed = false;
      if (_position > Duration.zero) {
        await _audioPlayer.resume();
      } else {
        await playTrack(_currentTrack!);
      }
    }
  }

  Future<void> seekTo(Duration newPosition) async {
    Duration target = newPosition;
    if (_currentTrack != null && _currentTrack!.isPremium && !_isCovenantPartner) {
      if (target.inSeconds >= 45) {
        target = const Duration(seconds: 45);
        _previewLimitReached = true;
        await _audioPlayer.seek(target);
        await _audioPlayer.pause();
        _position = target;
        _lastTelemetryPosition = target;
        _syncAudioHandler();
        notifyListeners();
        return;
      } else {
        _previewLimitReached = false;
      }
    }
    await _audioPlayer.seek(target);
    _lastTelemetryPosition = target;
  }

  Future<void> skipNext({bool userInitiated = false}) async {
    if (!userInitiated && _repeatMode == RepeatMode.one && _currentTrack != null) {
      await playTrack(_currentTrack!, updateQueue: false);
      return;
    }

    if (_queue.isNotEmpty) {
      if (_isShuffle && _queue.length > 1) {
        int nextRandomIdx;
        do {
          nextRandomIdx = Random().nextInt(_queue.length);
        } while (nextRandomIdx == _currentQueueIndex && _queue.length > 1);
        _currentQueueIndex = nextRandomIdx;
        await playTrack(_queue[_currentQueueIndex], updateQueue: false);
        return;
      }

      if (_currentQueueIndex + 1 < _queue.length) {
        _currentQueueIndex++;
        await playTrack(_queue[_currentQueueIndex], updateQueue: false);
      } else if (_repeatMode == RepeatMode.all) {
        _currentQueueIndex = 0;
        await playTrack(_queue[0], updateQueue: false);
      } else {
        // Reached end of queue without repeat all
        await _audioPlayer.pause();
        await seekTo(Duration.zero);
      }
    } else {
      final list = filteredTracks;
      if (list.isEmpty) return;
      final currentIdx = list.indexWhere((t) => t.id == _currentTrack?.id);
      if (currentIdx == -1) {
        await playTrack(list.first);
        return;
      }
      if (currentIdx + 1 < list.length) {
        await playTrack(list[currentIdx + 1]);
      } else if (_repeatMode == RepeatMode.all) {
        await playTrack(list.first);
      } else {
        // Reached end of stream list without repeat all
        await _audioPlayer.pause();
        await seekTo(Duration.zero);
      }
    }
  }

  Future<void> skipPrevious() async {
    if (_position.inSeconds > 4) {
      await seekTo(Duration.zero);
      return;
    }

    if (_queue.isNotEmpty) {
      if (_currentQueueIndex > 0) {
        _currentQueueIndex--;
        await playTrack(_queue[_currentQueueIndex], updateQueue: false);
      } else if (_repeatMode == RepeatMode.all) {
        _currentQueueIndex = _queue.length - 1;
        await playTrack(_queue[_currentQueueIndex], updateQueue: false);
      } else {
        await seekTo(Duration.zero);
      }
    } else {
      final list = filteredTracks;
      if (list.isEmpty) return;
      final prevIdx =
          (list.indexWhere((t) => t.id == _currentTrack?.id) - 1 + list.length) % list.length;
      await playTrack(list[prevIdx]);
    }
  }

  // ─── Queue Management ─────────────────────────────────────────────────────
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  Future<void> cycleRepeatMode() async {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    await _audioPlayer.setReleaseMode(_repeatMode == RepeatMode.one ? ReleaseMode.loop : ReleaseMode.stop);
    notifyListeners();
  }

  void setQueue(List<AudioTrack> newQueue, {int startIndex = 0}) {
    _queue = List.from(newQueue);
    _currentQueueIndex = startIndex.clamp(0, _queue.isNotEmpty ? _queue.length - 1 : 0);
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex > _queue.length) newIndex = _queue.length;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    if (_currentTrack != null) {
      _currentQueueIndex = _queue.indexWhere((t) => t.id == _currentTrack!.id);
    }
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (_currentTrack != null) {
      _currentQueueIndex = _queue.indexWhere((t) => t.id == _currentTrack!.id);
      if (_currentQueueIndex == -1 && _queue.isNotEmpty) {
        _currentQueueIndex = 0;
      }
    }
    notifyListeners();
  }

  void addToQueueNext(AudioTrack track) {
    if (_queue.isEmpty) {
      _queue = [track];
      _currentQueueIndex = 0;
    } else {
      final insertIndex = (_currentQueueIndex + 1).clamp(0, _queue.length);
      _queue.insert(insertIndex, track);
    }
    notifyListeners();
  }

  void addToQueueEnd(AudioTrack track) {
    _queue.add(track);
    notifyListeners();
  }

  void clearQueue() {
    if (_currentTrack != null) {
      _queue = [_currentTrack!];
      _currentQueueIndex = 0;
    } else {
      _queue.clear();
      _currentQueueIndex = 0;
    }
    notifyListeners();
  }

  Future<void> playFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentQueueIndex = index;
    await playTrack(_queue[index], updateQueue: false);
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
  Future<bool> toggleDownload(String trackId) async {
    final idx = _allTracks.indexWhere((t) => t.id == trackId);
    if (idx == -1) return false;

    final track = _allTracks[idx];

    if (track.isDownloaded) {
      // Delete immediately
      final deleted = await OfflineStorageService.deleteDownloadedTrack(trackId);
      if (deleted) {
        _allTracks[idx] = track.copyWith(isDownloaded: false);
        if (_currentTrack?.id == trackId) _currentTrack = _allTracks[idx];
        _downloadProgress.remove(trackId);
        notifyListeners();
        return true;
      }
      return false;
    } else {
      // Check free download tier limit (3 downloads max for free users)
      if (hasReachedDownloadLimit) {
        return false;
      }

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
      return success;
    }
  }

  Future<void> clearAllDownloads() async {
    await OfflineStorageService.clearAllCache();
    for (int i = 0; i < _allTracks.length; i++) {
      if (_allTracks[i].isDownloaded) {
        _allTracks[i] = _allTracks[i].copyWith(isDownloaded: false);
      }
    }
    if (_currentTrack != null && _currentTrack!.isDownloaded) {
      _currentTrack = _currentTrack!.copyWith(isDownloaded: false);
    }
    _downloadProgress.clear();
    notifyListeners();
  }

  /// Returns [0.0 – 1.0] if a download is in progress, or null otherwise.
  double? getDownloadProgressFor(String trackId) => _downloadProgress[trackId];

  /// Download multiple tracks sequentially with real-time progress.
  Future<int> batchDownloadTracks(List<AudioTrack> tracks) async {
    final toDownload = tracks.where((t) => !t.isDownloaded).toList();
    if (toDownload.isEmpty) return 0;

    int successCount = 0;
    for (final track in toDownload) {
      _downloadProgress[track.id] = 0.0;
      notifyListeners();

      final success = await OfflineStorageService.downloadEncryptedTrack(
        track.id,
        track.audioUrl,
        onProgress: (p) {
          _downloadProgress[track.id] = p;
          notifyListeners();
        },
      );

      if (success) {
        successCount++;
        final idx = _allTracks.indexWhere((t) => t.id == track.id);
        if (idx != -1) {
          _allTracks[idx] = _allTracks[idx].copyWith(isDownloaded: true);
          if (_currentTrack?.id == track.id) _currentTrack = _allTracks[idx];
        }
      }
      _downloadProgress.remove(track.id);
      notifyListeners();
    }
    return successCount;
  }

  /// Purge all offline DRM downloads from local storage.
  Future<void> clearAllOfflineCache() async {
    await OfflineStorageService.clearAllCache();
    for (int i = 0; i < _allTracks.length; i++) {
      _allTracks[i] = _allTracks[i].copyWith(isDownloaded: false);
    }
    if (_currentTrack != null) {
      _currentTrack = _currentTrack!.copyWith(isDownloaded: false);
    }
    _downloadProgress.clear();
    notifyListeners();
  }

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

  // ─── Custom User Playlists ────────────────────────────────────────────────
  static const String _customPlaylistsKey = 'lcm_user_custom_playlists';

  Future<void> _loadCustomPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_customPlaylistsKey) ?? [];
      if (rawList.isEmpty) {
        // Seed initial default playlists if none exist
        _customPlaylists = [
          CustomPlaylist(
            id: 'pl_default_1',
            title: 'Midnight Prayers & Warfare',
            description: 'Intense declarations, midnight chants & deliverance sermons',
            trackIds: _allTracks.take(3).map((t) => t.id).toList(),
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          CustomPlaylist(
            id: 'pl_default_2',
            title: 'Atmosphere for Healing & Faith',
            description: 'Calm instrumental worship and faith-building teachings',
            trackIds: _allTracks.skip(1).take(2).map((t) => t.id).toList(),
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
        await _saveCustomPlaylists();
      } else {
        _customPlaylists = rawList
            .map((str) => CustomPlaylist.fromJson(json.decode(str) as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[Playlists] Load error: $e');
    }
  }

  Future<void> _saveCustomPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = _customPlaylists.map((pl) => json.encode(pl.toJson())).toList();
      await prefs.setStringList(_customPlaylistsKey, rawList);
    } catch (e) {
      debugPrint('[Playlists] Save error: $e');
    }
  }

  Future<CustomPlaylist> createPlaylist(String title, String description) async {
    final newPl = CustomPlaylist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      trackIds: [],
      createdAt: DateTime.now(),
    );
    _customPlaylists.insert(0, newPl);
    await _saveCustomPlaylists();
    notifyListeners();
    return newPl;
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    final idx = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;

    if (!_customPlaylists[idx].trackIds.contains(trackId)) {
      final updatedTrackIds = List<String>.from(_customPlaylists[idx].trackIds)..add(trackId);
      _customPlaylists[idx] = _customPlaylists[idx].copyWith(trackIds: updatedTrackIds);
      await _saveCustomPlaylists();
      notifyListeners();
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId) async {
    final idx = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;

    final updatedTrackIds = List<String>.from(_customPlaylists[idx].trackIds)..remove(trackId);
    _customPlaylists[idx] = _customPlaylists[idx].copyWith(trackIds: updatedTrackIds);
    await _saveCustomPlaylists();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _customPlaylists.removeWhere((p) => p.id == playlistId);
    await _saveCustomPlaylists();
    notifyListeners();
  }

  Future<void> playCustomPlaylist(CustomPlaylist playlist, {int startIndex = 0}) async {
    final tracks = _allTracks.where((t) => playlist.trackIds.contains(t.id)).toList();
    if (tracks.isEmpty) return;

    setQueue(tracks, startIndex: startIndex);
    final targetTrack = tracks[startIndex.clamp(0, tracks.length - 1)];
    await playTrack(targetTrack, updateQueue: false);
  }

  // ─── Initialisation ───────────────────────────────────────────────────────
  Future<void> _loadTracksAndStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken          = prefs.getString('auth_jwt_token');
    _userEmail         = prefs.getString('auth_user_email');
    _userId            = prefs.getString('auth_user_id');
    _userName          = prefs.getString('user_name') ?? 'Grace Worshipper';
    _listenCount       = prefs.getInt('user_listen_count') ?? 3;
    _isCovenantPartner = prefs.getBool('is_covenant_partner') ?? false;
    if (_userId != null && _userId!.isNotEmpty) {
      OfflineStorageService.setDrmUserId(_userId!);
    }
    if (_isCovenantPartner) {
      _partnerPlanType   = prefs.getString('partner_plan_type') ?? 'monthly';
      _partnerPaymentRef = prefs.getString('partner_payment_ref');
      _partnerReceiptNo  = prefs.getString('partner_receipt_no');
      _partnerExpiryDate = prefs.getString('partner_expiry_date');
    }

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
      }
    }

    // Load custom user playlists
    await _loadCustomPlaylists();

    // Sync downloaded state from local storage
    final downloadedIds = await OfflineStorageService.getDownloadedTrackIds();
    for (int i = 0; i < _allTracks.length; i++) {
      if (downloadedIds.contains(_allTracks[i].id)) {
        _allTracks[i] = _allTracks[i].copyWith(isDownloaded: true);
      }
    }

    // Restore pending track state if available
    if (_lastPlayedTrackId != null) {
      final idx = _allTracks.indexWhere((t) => t.id == _lastPlayedTrackId);
      if (idx != -1) {
        _currentTrack = _allTracks[idx];
        _position = _lastPlayedPosition;
        if (_currentTrack!.duration > Duration.zero) {
          _duration = _currentTrack!.duration;
        }
      }
    } else if (_currentTrack != null) {
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

  // ─── Authentication Session Management ─────────────────────────────────────
  Future<void> saveAuthSession({
    required String token,
    required String userId,
    required String email,
    required String fullName,
  }) async {
    _jwtToken = token;
    _userId = userId;
    _userEmail = email;
    _userName = fullName;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_jwt_token', token);
      await prefs.setString('auth_user_id', userId);
      await prefs.setString('auth_user_email', email);
      await prefs.setString('user_name', fullName);
      await OfflineStorageService.setDrmUserId(userId);
    } catch (e) {
      debugPrint('[Auth] Session save error: $e');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _jwtToken = null;
    _userId = null;
    _userEmail = null;
    _userName = 'Grace Worshipper';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_jwt_token');
      await prefs.remove('auth_user_id');
      await prefs.remove('auth_user_email');
      await prefs.setString('user_name', 'Grace Worshipper');
    } catch (e) {
      debugPrint('[Auth] Logout error: $e');
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
