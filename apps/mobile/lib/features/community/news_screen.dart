import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_shell.dart';
import 'news_detail_screen.dart';

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  static const _directusBaseUrl = String.fromEnvironment(
    'DIRECTUS_BASE_URL',
    defaultValue: 'http://10.0.2.2:8055',
  );
  static const _directusToken = String.fromEnvironment('DIRECTUS_STATIC_TOKEN', defaultValue: '');
  late final Dio _dio;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _posts = const [];
  List<NewsCategory> _categories = const [];
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(baseUrl: _directusBaseUrl));
    if (_directusToken.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $_directusToken';
    }
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _loadPosts(),
        _loadCategories(),
      ]);

      final postsResponse = results[0];
      final categoriesResponse = results[1];

      final postsData = (postsResponse.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
      final categoriesData = (categoriesResponse.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];

      final posts = postsData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final categories = categoriesData.map((e) => NewsCategory.fromMap(Map<String, dynamic>.from(e as Map))).toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

      final availableCategoryIds = posts.map(_extractCategoryId).whereType<String>().toSet();
      final selectedCategoryStillExists = _selectedCategoryId == null || availableCategoryIds.contains(_selectedCategoryId);

      setState(() {
        _posts = posts;
        _categories = categories;
        if (!selectedCategoryStillExists) {
          _selectedCategoryId = null;
        }
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = _buildErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<Response<dynamic>> _loadPosts() {
    return _dio.get('/items/cms_posts', queryParameters: {
      'sort': '-published_at,-date_created',
      'filter[status][_eq]': 'published',
      'fields': 'id,title,excerpt,content,published_at,date_created,category,category.id,category.title,category.for_members,cms_category,cms_category.id,cms_category.title,cms_category.for_members',
      'limit': 50,
    });
  }

  Future<Response<dynamic>> _loadCategories() {
    return _dio.get('/items/cms_category', queryParameters: {
      'sort': 'title',
      'fields': 'id,title,for_members',
      'limit': 100,
    });
  }

  bool _isForbiddenOrNotFound(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 403 || statusCode == 404) {
      return true;
    }

    final message = (e.response?.data ?? '').toString().toLowerCase();
    return message.contains('forbidden') || message.contains('does not exist') || message.contains('permission');
  }

  String _buildErrorMessage(DioException e) {
    final details = e.response?.data?.toString();
    final networkIssue = e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout;
    if (networkIssue) {
      return 'News konnten nicht geladen werden. Prüfe DIRECTUS_BASE_URL (auf einem echten Handy nicht 10.0.2.2 verwenden).';
    }

    if (_isForbiddenOrNotFound(e)) {
      return 'Kein Zugriff auf die News-Collection. Prüfe in Directus die Leserechte für "cms_posts" und "cms_category".'
          '${details != null ? '\n\nAntwort: $details' : ''}';
    }

    return details ?? 'News konnten nicht geladen werden. Prüfe DIRECTUS_BASE_URL und Berechtigungen.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final visiblePosts = _selectedCategoryId == null
        ? _posts
        : _posts.where((post) => _extractCategoryId(post) == _selectedCategoryId).toList();

    return AppShell(
      currentIndex: 1,
      title: 'News',
      body: RefreshIndicator(
        onRefresh: _loadContent,
        child: _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red)))),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  _CategorySelector(
                    categories: _categories,
                    selectedCategoryId: _selectedCategoryId,
                    onSelected: (value) => setState(() => _selectedCategoryId = value),
                  ),
                  const SizedBox(height: 16),
                  if (visiblePosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 120),
                      child: Center(child: Text('Für diese Kategorie sind noch keine News-Beiträge vorhanden.')),
                    )
                  else
                    ...visiblePosts.expand(
                      (post) => [
                        _NewsPostCard(
                          post: post,
                          categoryTitle: _extractCategoryTitle(post),
                          excerpt: ((post['excerpt'] as String?)?.trim().isNotEmpty == true)
                              ? (post['excerpt'] as String).trim()
                              : _truncate((post['content'] as String?) ?? '', 170),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewsDetailScreen(
                                postId: post['id'].toString(),
                                title: ((post['title'] as String?)?.trim().isNotEmpty == true) ? post['title'] as String : 'Ohne Titel',
                                content: (post['content'] as String?) ?? '',
                                excerpt: (post['excerpt'] as String?) ?? '',
                                categoryTitle: _extractCategoryTitle(post),
                                publishedAt: _parsePostDate(post),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                ],
              ),
      ),
    );
  }

  DateTime? _parsePostDate(Map<String, dynamic> post) {
    final dateRaw = (post['published_at'] ?? post['date_created'])?.toString();
    return DateTime.tryParse(dateRaw ?? '');
  }

  String? _extractCategoryId(Map<String, dynamic> post) {
    final category = _extractCategoryMap(post);
    if (category != null && category['id'] != null) {
      return category['id'].toString();
    }

    final flatCategory = post['category'] ?? post['cms_category'];
    if (flatCategory == null || flatCategory is Map<String, dynamic>) {
      return null;
    }
    return flatCategory.toString();
  }

  String _extractCategoryTitle(Map<String, dynamic> post) {
    final category = _extractCategoryMap(post);
    final title = category?['title']?.toString().trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }

    final categoryId = _extractCategoryId(post);
    final matchingCategory = _categories.where((item) => item.id == categoryId).cast<NewsCategory?>().firstOrNull;
    return matchingCategory?.title ?? 'Unkategorisiert';
  }

  Map<String, dynamic>? _extractCategoryMap(Map<String, dynamic> post) {
    final directCategory = post['category'];
    if (directCategory is Map) {
      return Map<String, dynamic>.from(directCategory);
    }

    final cmsCategory = post['cms_category'];
    if (cmsCategory is Map) {
      return Map<String, dynamic>.from(cmsCategory);
    }

    return null;
  }

  static String _truncate(String value, int maxChars) {
    final text = value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}...';
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<NewsCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategorien',
          style: TextStyle(fontFamily: 'SourGummy', fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Alle'),
                  selected: selectedCategoryId == null,
                  onSelected: (_) => onSelected(null),
                ),
              ),
              ...categories.map(
                (category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category.title),
                    selected: selectedCategoryId == category.id,
                    onSelected: (_) => onSelected(category.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NewsPostCard extends StatelessWidget {
  const _NewsPostCard({
    required this.post,
    required this.categoryTitle,
    required this.excerpt,
    required this.onTap,
  });

  final Map<String, dynamic> post;
  final String categoryTitle;
  final String excerpt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = (post['title'] as String?)?.trim().isNotEmpty == true ? post['title'] as String : 'Ohne Titel';
    final dateRaw = (post['published_at'] ?? post['date_created'])?.toString();
    final date = DateTime.tryParse(dateRaw ?? '');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'SourGummy', fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (date != null)
                Text(
                  '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                  style: const TextStyle(color: Color(0xFF6F7F8C), fontSize: 12),
                ),
              const SizedBox(height: 6),
              Text(
                'in $categoryTitle',
                style: const TextStyle(color: Color(0xFF6F7F8C), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(excerpt.isEmpty ? 'Kein Vorschautext verfügbar.' : excerpt),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'mehr anzeigen',
                  style: TextStyle(color: Color(0xFF2CB89D), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsCategory {
  const NewsCategory({
    required this.id,
    required this.title,
    required this.forMembers,
  });

  final String id;
  final String title;
  final bool forMembers;

  factory NewsCategory.fromMap(Map<String, dynamic> map) {
    return NewsCategory(
      id: map['id'].toString(),
      title: (map['title'] as String?)?.trim().isNotEmpty == true ? (map['title'] as String).trim() : 'Ohne Titel',
      forMembers: map['for_members'] == true,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
