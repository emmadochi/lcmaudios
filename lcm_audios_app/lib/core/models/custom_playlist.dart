class CustomPlaylist {
  final String id;
  final String title;
  final String description;
  final List<String> trackIds;
  final DateTime createdAt;
  final String? coverUrl;

  const CustomPlaylist({
    required this.id,
    required this.title,
    required this.description,
    required this.trackIds,
    required this.createdAt,
    this.coverUrl,
  });

  CustomPlaylist copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? trackIds,
    DateTime? createdAt,
    String? coverUrl,
  }) {
    return CustomPlaylist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      trackIds: trackIds ?? this.trackIds,
      createdAt: createdAt ?? this.createdAt,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'trackIds': trackIds,
      'createdAt': createdAt.toIso8601String(),
      'coverUrl': coverUrl,
    };
  }

  factory CustomPlaylist.fromJson(Map<String, dynamic> json) {
    return CustomPlaylist(
      id: json['id'] as String? ?? 'pl_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'My Playlist',
      description: json['description'] as String? ?? '',
      trackIds: (json['trackIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      coverUrl: json['coverUrl'] as String?,
    );
  }
}
