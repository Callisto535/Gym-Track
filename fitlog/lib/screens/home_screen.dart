import 'dart:convert';

import 'package:fitlog/config/api_config.dart';
import 'package:fitlog/models/exercise.dart';
import 'package:fitlog/models/news_article.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final bool isLoading;
  final String errorMessage;
  final Future<void> Function() onRefresh;

  const HomeScreen({
    super.key,
    required this.exercises,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _newsApiUrl = '${ApiConfig.baseUrl}/news';
  final List<NewsArticle> _newsArticles = [];
  bool _isNewsLoading = true;
  String _newsErrorMessage = '';
  String _newsNotice = '';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isNewsLoading = true;
      _newsErrorMessage = '';
      _newsNotice = '';
    });

    try {
      final response = await http.get(Uri.parse(_newsApiUrl));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> &&
            (data['status'] == 'success' || data['status'] == 'fallback') &&
            data['news'] is List) {
          final List<dynamic> newsList = data['news'];
          setState(() {
            _newsArticles
              ..clear()
              ..addAll(
                newsList
                    .whereType<Map>()
                    .map(
                      (item) =>
                          NewsArticle.fromJson(Map<String, dynamic>.from(item)),
                    )
                    .take(10)
                    .toList(),
              );
            _newsNotice = data['status'] == 'fallback'
                ? data['message']?.toString() ??
                      'Live news unavailable. Showing saved articles instead.'
                : '';
            _isNewsLoading = false;
          });
        } else {
          setState(() {
            _newsErrorMessage = 'The news API returned an invalid response.';
            _isNewsLoading = false;
          });
        }
      } else {
        String message = '';
        try {
          final data = json.decode(response.body);
          if (data is Map && data['message'] != null) {
            message = data['message'].toString();
          }
        } catch (_) {}

        setState(() {
          if (message.isEmpty) {
            _newsErrorMessage =
                'Cannot load fitness news. Server status: ${response.statusCode}';
          } else {
            _newsErrorMessage =
                'Cannot load fitness news. $message (Status ${response.statusCode})';
          }
          _isNewsLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _newsErrorMessage =
            'Cannot connect to the news API. Make sure the backend is running.';
        _isNewsLoading = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await widget.onRefresh();
    await _fetchNews();
  }

  Future<void> _openArticle(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This article has no valid link.')),
      );
      return;
    }

    final bool opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open this article.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalSets = 0;
    for (final exercise in widget.exercises) {
      totalSets += exercise.sets;
    }

    final List<Exercise> todayExercises = widget.exercises.where((exercise) {
      return exercise.date == _formatDate(DateTime.now());
    }).toList();

    int todaySets = 0;
    for (final exercise in todayExercises) {
      todaySets += exercise.sets;
    }

    final List<String> todayCategories = [];
    for (final exercise in todayExercises) {
      if (!todayCategories.contains(exercise.category)) {
        todayCategories.add(exercise.category);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FitLog',
          style: TextStyle(
            color: Color(0xFFC7F000),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: widget.isLoading || widget.errorMessage.isNotEmpty
          ? RefreshIndicator(
              onRefresh: _refreshAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (widget.errorMessage.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.errorMessage,
                                style: const TextStyle(
                                  color: Color(0xFFB1B5AA),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: widget.onRefresh,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC7F000),
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Fitness News',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildNewsSection(),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready for today\'s workout?',
                      style: TextStyle(color: Color(0xFFB1B5AA)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Today\'s Workout',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    todayExercises.isEmpty
                                        ? 'No exercises today'
                                        : 'Today\'s Progress',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '${todayExercises.length} exercises',
                                    style: const TextStyle(
                                      color: Color(0xFFB1B5AA),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    todayCategories.isEmpty
                                        ? 'No categories recorded'
                                        : todayCategories.join(', '),
                                    style: const TextStyle(
                                      color: Color(0xFFB1B5AA),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$todaySets total sets',
                                    style: const TextStyle(
                                      color: Color(0xFFB1B5AA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC7F000),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                todayExercises.isEmpty
                                    ? 'Rest Day'
                                    : 'Completed',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Quick Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            value: '${widget.exercises.length}',
                            label: 'Exercises',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            value: '$totalSets',
                            label: 'Sets',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Fitness News',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildNewsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildNewsSection() {
    if (_isNewsLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_newsErrorMessage.isNotEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _newsErrorMessage,
                style: const TextStyle(color: Color(0xFFB1B5AA)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchNews,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC7F000),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_newsArticles.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No fitness news available.',
            style: TextStyle(color: Color(0xFFB1B5AA)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_newsNotice.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _newsNotice,
              style: const TextStyle(color: Color(0xFFB1B5AA)),
            ),
          ),
        for (final article in _newsArticles)
          _NewsArticleCard(
            article: article,
            onTap: () => _openArticle(article.link),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFC7F000),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Color(0xFFB1B5AA))),
          ],
        ),
      ),
    );
  }
}

class _NewsArticleCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback onTap;

  const _NewsArticleCard({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title.isEmpty ? 'Untitled article' : article.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              article.summary.isEmpty
                  ? 'No summary available.'
                  : article.summary,
              style: const TextStyle(color: Color(0xFFB1B5AA)),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.open_in_new),
              label: Text(
                article.link,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
