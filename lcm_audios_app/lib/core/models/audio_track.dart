import 'spiritual_intent.dart';

class LyricLine {
  final double timestampSeconds;
  final String text;

  const LyricLine({
    required this.timestampSeconds,
    required this.text,
  });
}

class SermonNote {
  final String id;
  final double timestampSeconds;
  final String noteText;
  final DateTime createdAt;

  SermonNote({
    required this.id,
    required this.timestampSeconds,
    required this.noteText,
    required this.createdAt,
  });
}

enum MediaType {
  song,
  sermon,
  podcast,
}

class AudioTrack {
  final String id;
  final String title;
  final String artist;
  final String albumArtUrl;
  final String audioUrl;
  final Duration duration;
  final String subgenre;
  final IntentCategory intentCategory;
  final MediaType mediaType;
  final bool isDownloaded;
  final bool isFavorite;
  final List<LyricLine> lyrics;
  final List<SermonNote> notes;

  AudioTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.audioUrl,
    required this.duration,
    required this.subgenre,
    required this.intentCategory,
    required this.mediaType,
    this.isDownloaded = false,
    this.isFavorite = false,
    this.lyrics = const [],
    this.notes = const [],
  });

  AudioTrack copyWith({
    bool? isDownloaded,
    bool? isFavorite,
    List<SermonNote>? notes,
  }) {
    return AudioTrack(
      id: id,
      title: title,
      artist: artist,
      albumArtUrl: albumArtUrl,
      audioUrl: audioUrl,
      duration: duration,
      subgenre: subgenre,
      intentCategory: intentCategory,
      mediaType: mediaType,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isFavorite: isFavorite ?? this.isFavorite,
      lyrics: lyrics,
      notes: notes ?? this.notes,
    );
  }
}
