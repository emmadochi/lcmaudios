import 'dart:async';
import 'package:audio_service/audio_service.dart';
import '../core/models/audio_track.dart';

class LcmAudioHandler extends BaseAudioHandler with SeekHandler, QueueHandler {
  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function(Duration)? onSeek;
  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;
  Future<void> Function()? onStop;

  LcmAudioHandler() {
    _initInitialState();
  }

  void _initInitialState() {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  void updateMediaItemFromTrack(AudioTrack track, Duration duration) {
    mediaItem.add(
      MediaItem(
        id: track.id,
        album: 'LCM Audios — ${track.subgenre}',
        title: track.title,
        artist: track.artist,
        duration: duration > Duration.zero ? duration : track.duration,
        artUri: Uri.tryParse(track.albumArtUrl),
        playable: true,
        displayTitle: track.title,
        displaySubtitle: '${track.artist} • ${track.subgenre}',
        displayDescription: track.notes.isNotEmpty ? '${track.notes.length} Sermon Notes' : null,
      ),
    );
  }

  void updatePlayerState({
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    required double speed,
    bool isBuffering = false,
  }) {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          isPlaying ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: isBuffering
            ? AudioProcessingState.buffering
            : (isPlaying ? AudioProcessingState.ready : AudioProcessingState.idle),
        playing: isPlaying,
        updatePosition: position,
        bufferedPosition: duration,
        speed: speed,
        queueIndex: 0,
      ),
    );
  }

  @override
  Future<void> play() async {
    if (onPlay != null) {
      await onPlay!();
    }
  }

  @override
  Future<void> pause() async {
    if (onPause != null) {
      await onPause!();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (onSeek != null) {
      await onSeek!(position);
    }
  }

  @override
  Future<void> skipToNext() async {
    if (onSkipNext != null) {
      await onSkipNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (onSkipPrevious != null) {
      await onSkipPrevious!();
    }
  }

  @override
  Future<void> stop() async {
    if (onStop != null) {
      await onStop!();
    }
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }
}
