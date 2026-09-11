import 'spiritual_intent.dart';

class LyricLine {
  final double timestampSeconds;
  final String text;

  const LyricLine({
    required this.timestampSeconds,
    required this.text,
  });

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      timestampSeconds: (json['timestampSeconds'] as num?)?.toDouble() ?? 0.0,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestampSeconds': timestampSeconds,
      'text': text,
    };
  }
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

  String get formattedTimestamp {
    final minutes = (timestampSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (timestampSeconds % 60).floor().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  factory SermonNote.fromJson(Map<String, dynamic> json) {
    return SermonNote(
      id: json['id'] as String? ?? '',
      timestampSeconds: (json['timestampSeconds'] as num?)?.toDouble() ?? 0.0,
      noteText: json['noteText'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestampSeconds': timestampSeconds,
      'noteText': noteText,
      'createdAt': createdAt.toIso8601String(),
    };
  }
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
  final String categoryKey;
  final MediaType mediaType;
  final bool isDownloaded;
  final bool isFavorite;
  final bool isPremium;
  final List<LyricLine> lyrics;
  final List<SermonNote> notes;
  final String? seriesId;
  final String? seriesTitle;
  final int? seriesPart;
  final String? scriptureReference;
  final String? scriptureBook;
  final int? scriptureChapter;
  final String? ministerId;

  AudioTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.audioUrl,
    required this.duration,
    required this.subgenre,
    required this.intentCategory,
    this.categoryKey = '',
    required this.mediaType,
    this.isDownloaded = false,
    this.isFavorite = false,
    this.isPremium = false,
    this.lyrics = const [],
    this.notes = const [],
    this.seriesId,
    this.seriesTitle,
    this.seriesPart,
    this.scriptureReference,
    this.scriptureBook,
    this.scriptureChapter,
    this.ministerId,
  });

  String get formattedDuration {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool matchesCategoryKey(String targetKey) {
    if (targetKey.toLowerCase() == 'all') return true;
    final cleanTarget = targetKey.toLowerCase().replaceAll(' ', '');
    final cleanCatKey = categoryKey.toLowerCase().replaceAll(' ', '');
    final cleanEnum = intentCategory.name.toLowerCase();

    return cleanCatKey == cleanTarget || cleanEnum == cleanTarget;
  }

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    final rawKey = (json['intentCategory'] as String? ?? '').trim();

    IntentCategory parseIntent(String? val) {
      if (val == null) return IntentCategory.all;
      final clean = val.toLowerCase().replaceAll(' ', '');
      return IntentCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == clean,
        orElse: () => IntentCategory.custom,
      );
    }

    MediaType parseMediaType(String? val) {
      if (val == null) return MediaType.song;
      return MediaType.values.firstWhere(
        (e) => e.name.toLowerCase() == val.toLowerCase(),
        orElse: () => MediaType.song,
      );
    }

    return AudioTrack(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      albumArtUrl: json['albumArtUrl'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      duration: Duration(seconds: (json['durationSeconds'] as num?)?.toInt() ?? json['duration'] as int? ?? 180),
      subgenre: json['subgenre'] as String? ?? 'Worship',
      intentCategory: parseIntent(rawKey),
      categoryKey: rawKey,
      mediaType: parseMediaType(json['mediaType'] as String?),
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isPremium: json['isPremium'] == true ||
          json['is_premium'] == true ||
          json['isPremium'] == 'true' ||
          json['is_premium'] == 'true' ||
          json['isPremium'] == 1 ||
          json['is_premium'] == 1,
      lyrics: (json['lyrics'] as List?)?.map((e) => LyricLine.fromJson(e)).toList() ?? [],
      notes: (json['notes'] as List?)?.map((e) => SermonNote.fromJson(e)).toList() ?? [],
      seriesId: json['seriesId'] as String? ?? json['series_id'] as String?,
      seriesTitle: json['seriesTitle'] as String? ?? json['series_title'] as String?,
      seriesPart: (json['seriesPart'] as num?)?.toInt() ?? (json['series_part'] as num?)?.toInt(),
      scriptureReference: json['scriptureReference'] as String? ?? json['scripture_reference'] as String?,
      scriptureBook: json['scriptureBook'] as String? ?? json['scripture_book'] as String?,
      scriptureChapter: (json['scriptureChapter'] as num?)?.toInt() ?? (json['scripture_chapter'] as num?)?.toInt(),
      ministerId: json['ministerId'] as String? ?? json['minister_id'] as String?,
    );
  }

  AudioTrack copyWith({
    bool? isDownloaded,
    bool? isFavorite,
    bool? isPremium,
    List<SermonNote>? notes,
    String? seriesId,
    String? seriesTitle,
    int? seriesPart,
    String? scriptureReference,
    String? scriptureBook,
    int? scriptureChapter,
    String? ministerId,
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
      categoryKey: categoryKey,
      mediaType: mediaType,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isFavorite: isFavorite ?? this.isFavorite,
      isPremium: isPremium ?? this.isPremium,
      lyrics: lyrics,
      notes: notes ?? this.notes,
      seriesId: seriesId ?? this.seriesId,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      seriesPart: seriesPart ?? this.seriesPart,
      scriptureReference: scriptureReference ?? this.scriptureReference,
      scriptureBook: scriptureBook ?? this.scriptureBook,
      scriptureChapter: scriptureChapter ?? this.scriptureChapter,
      ministerId: ministerId ?? this.ministerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'albumArtUrl': albumArtUrl,
      'audioUrl': audioUrl,
      'durationSeconds': duration.inSeconds,
      'subgenre': subgenre,
      'intentCategory': intentCategory.name,
      'categoryKey': categoryKey,
      'mediaType': mediaType.name,
      'isDownloaded': isDownloaded,
      'isFavorite': isFavorite,
      'isPremium': isPremium,
      'lyrics': lyrics.map((l) => l.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
      if (seriesId != null) 'seriesId': seriesId,
      if (seriesTitle != null) 'seriesTitle': seriesTitle,
      if (seriesPart != null) 'seriesPart': seriesPart,
      if (scriptureReference != null) 'scriptureReference': scriptureReference,
      if (scriptureBook != null) 'scriptureBook': scriptureBook,
      if (scriptureChapter != null) 'scriptureChapter': scriptureChapter,
      if (ministerId != null) 'ministerId': ministerId,
    };
  }
}
