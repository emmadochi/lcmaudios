class SermonSeries {
  final String id;
  final String title;
  final String description;
  final String ministerName;
  final String ministerId;
  final String bannerArtUrl;
  final int totalParts;
  int get partsCount => totalParts;
  final List<String> trackIds;
  final String year;
  final String intentCategory;

  const SermonSeries({
    required this.id,
    required this.title,
    required this.description,
    required this.ministerName,
    this.ministerId = 'min_martins_omonua',
    required this.bannerArtUrl,
    required this.totalParts,
    required this.trackIds,
    this.year = '2024',
    this.intentCategory = 'deepWorship',
  });

  factory SermonSeries.fromJson(Map<String, dynamic> json) {
    return SermonSeries(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ministerName: json['ministerName'] as String? ?? 'Pastor Martins Omonua',
      ministerId: json['ministerId'] as String? ?? 'min_martins_omonua',
      bannerArtUrl: json['bannerArtUrl'] as String? ?? '',
      totalParts: (json['totalParts'] as num?)?.toInt() ?? 1,
      trackIds: (json['trackIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      year: json['year'] as String? ?? '2024',
      intentCategory: json['intentCategory'] as String? ?? 'all',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ministerName': ministerName,
      'ministerId': ministerId,
      'bannerArtUrl': bannerArtUrl,
      'totalParts': totalParts,
      'trackIds': trackIds,
      'year': year,
      'intentCategory': intentCategory,
    };
  }
}
