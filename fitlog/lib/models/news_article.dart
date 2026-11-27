class NewsArticle {
  final String title;
  final String summary;
  final String link;

  const NewsArticle({
    required this.title,
    required this.summary,
    required this.link,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
    );
  }
}
