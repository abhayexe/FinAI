class MarketNews {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String source;
  final DateTime publishedAt;

  MarketNews({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
  });

  factory MarketNews.fromJson(Map<String, dynamic> json) {
    return MarketNews(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      source: json['source'] ?? '',
      publishedAt: json['publishedAt'] != null 
          ? DateTime.parse(json['publishedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'imageUrl': imageUrl,
      'source': source,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }
}
