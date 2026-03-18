import 'package:flutter/material.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.categoryTitle,
    required this.publishedAt,
  });

  final String title;
  final String content;
  final String excerpt;
  final String categoryTitle;
  final DateTime? publishedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleContent = _stripHtml(content).trim();
    final fallbackText = excerpt.trim().isNotEmpty ? excerpt.trim() : 'Für diesen Beitrag ist kein Inhalt hinterlegt.';

    return Scaffold(
      appBar: AppBar(title: const Text('News-Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontFamily: 'SourGummy', fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (publishedAt != null)
              Text(
                '${publishedAt!.day.toString().padLeft(2, '0')}.${publishedAt!.month.toString().padLeft(2, '0')}.${publishedAt!.year}',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6F7F8C)),
              ),
            const SizedBox(height: 6),
            Text(
              'in $categoryTitle',
              style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6F7F8C), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Text(
              visibleContent.isNotEmpty ? visibleContent : fallbackText,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ');
  }
}
