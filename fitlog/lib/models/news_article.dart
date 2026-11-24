class NewsArticle {
  final int id;
  final String title;
  final String description;
  final String category;
  final String image;
  final String source;
  final String url;
  final String publishedAt;

  NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.image,
    required this.source,
    required this.url,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      publishedAt: json['publishedAt']?.toString() ?? '',
    );
  }
}
