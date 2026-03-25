import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class NewsDetailScreen extends ConsumerStatefulWidget {
  const NewsDetailScreen({
    super.key,
    required this.postId,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.categoryTitle,
    required this.publishedAt,
  });

  final String postId;
  final String title;
  final String content;
  final String excerpt;
  final String categoryTitle;
  final DateTime? publishedAt;

  @override
  ConsumerState<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends ConsumerState<NewsDetailScreen> {
  static const _directusBaseUrl = String.fromEnvironment(
    'DIRECTUS_BASE_URL',
    defaultValue: 'http://10.0.2.2:8055',
  );

  static const List<_ReactionOption> _reactions = [
    _ReactionOption(type: 'LIKE', emoji: '👍', label: 'Like'),
    _ReactionOption(type: 'LOVE', emoji: '❤️', label: 'Love'),
    _ReactionOption(type: 'LAUGH', emoji: '😂', label: 'Lachen'),
    _ReactionOption(type: 'WOW', emoji: '😮', label: 'Wow'),
    _ReactionOption(type: 'SAD', emoji: '😢', label: 'Traurig'),
  ];

  bool _reactionLoading = true;
  bool _reactionSaving = false;
  String? _ownReaction;
  Map<String, int> _reactionCounts = const {};

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  Future<void> _loadReactions() async {
    setState(() => _reactionLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.get('/news/reactions', queryParameters: {'postIds': widget.postId});
      final data = response.data;
      if (data is! List || data.isEmpty || data.first is! Map) {
        setState(() {
          _ownReaction = null;
          _reactionCounts = const {};
          _reactionLoading = false;
        });
        return;
      }

      final summary = Map<String, dynamic>.from(data.first as Map);
      final countsRaw = Map<String, dynamic>.from((summary['counts'] as Map?) ?? const {});
      setState(() {
        _ownReaction = summary['ownReaction']?.toString();
        _reactionCounts = countsRaw.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
        _reactionLoading = false;
      });
    } on DioException {
      setState(() => _reactionLoading = false);
    }
  }

  Future<void> _selectReaction(String reactionType) async {
    if (_reactionSaving) return;

    setState(() {
      _reactionSaving = true;
      _ownReaction = reactionType;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.put('/news/${widget.postId}/reaction', data: {'reaction': reactionType});
      final summary = Map<String, dynamic>.from((response.data as Map?) ?? const {});
      final countsRaw = Map<String, dynamic>.from((summary['counts'] as Map?) ?? const {});
      setState(() {
        _ownReaction = summary['ownReaction']?.toString() ?? reactionType;
        _reactionCounts = countsRaw.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
      });
    } on DioException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deine Reaktion konnte nicht gespeichert werden.')),
      );
    } finally {
      if (mounted) {
        setState(() => _reactionSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedContent = _normalizeHtml(widget.content).trim();
    final fallbackText = widget.excerpt.trim().isNotEmpty ? widget.excerpt.trim() : 'Für diesen Beitrag ist kein Inhalt hinterlegt.';

    return Scaffold(
      appBar: AppBar(title: const Text('News-Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontFamily: 'SourGummy', fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (widget.publishedAt != null)
              Text(
                '${widget.publishedAt!.day.toString().padLeft(2, '0')}.${widget.publishedAt!.month.toString().padLeft(2, '0')}.${widget.publishedAt!.year}',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6F7F8C)),
              ),
            const SizedBox(height: 6),
            Text(
              'in ${widget.categoryTitle}',
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
            const SizedBox(height: 24),
            const Text(
              'Deine Reaktion',
              style: TextStyle(fontFamily: 'SourGummy', fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (_reactionLoading)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _reactions.map((reaction) {
                  final isSelected = _ownReaction == reaction.type;
                  final count = _reactionCounts[reaction.type] ?? 0;
                  return ChoiceChip(
                    selected: isSelected,
                    onSelected: _reactionSaving ? null : (_) => _selectReaction(reaction.type),
                    avatar: Text(reaction.emoji),
                    label: Text('${reaction.label} ($count)'),
                  );
                }).toList(),
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

class _ReactionOption {
  const _ReactionOption({
    required this.type,
    required this.emoji,
    required this.label,
  });

  final String type;
  final String emoji;
  final String label;
}
