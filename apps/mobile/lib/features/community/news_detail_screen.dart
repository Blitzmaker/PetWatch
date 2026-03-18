import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.categoryTitle,
    required this.publishedAt,
  });

  static const _directusBaseUrl = String.fromEnvironment(
    'DIRECTUS_BASE_URL',
    defaultValue: 'http://10.0.2.2:8055',
  );

  final String title;
  final String content;
  final String excerpt;
  final String categoryTitle;
  final DateTime? publishedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedContent = _normalizeHtml(content).trim();
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
            if (normalizedContent.isNotEmpty)
              Html(
                data: normalizedContent,
                style: {
                  'body': Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    fontSize: FontSize(theme.textTheme.bodyLarge?.fontSize ?? 16),
                    lineHeight: const LineHeight(1.5),
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  'p': Style(margin: Margins.only(bottom: 16)),
                  'img': Style(margin: Margins.only(bottom: 16)),
                  'figure': Style(margin: Margins.only(bottom: 16)),
                  'h1': Style(fontSize: FontSize(28), fontWeight: FontWeight.w700),
                  'h2': Style(fontSize: FontSize(24), fontWeight: FontWeight.w700),
                  'h3': Style(fontSize: FontSize(20), fontWeight: FontWeight.w700),
                  'a': Style(color: const Color(0xFF2CB89D), textDecoration: TextDecoration.underline),
                  'blockquote': Style(
                    padding: HtmlPaddings.only(left: 12),
                    border: Border(left: BorderSide(color: Colors.grey.shade400, width: 3)),
                    fontStyle: FontStyle.italic,
                  ),
                },
              )
            else
              Text(
                fallbackText,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
          ],
        ),
      ),
    );
  }

  String _normalizeHtml(String value) {
    return value
        .replaceAllMapped(RegExp(r'''(src|href)=(['"])(/[^'"]*)\2''', caseSensitive: false), (match) {
          final attribute = match.group(1)!;
          final quote = match.group(2)!;
          final path = match.group(3)!;
          return '$attribute=$quote${_directusBaseUrl}$path$quote';
        })
        .trim();
  }
}
