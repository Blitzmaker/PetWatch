import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_shell.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  static const _directusBaseUrl = String.fromEnvironment(
    'DIRECTUS_BASE_URL',
    defaultValue: 'http://10.0.2.2:8055',
  );
  static const _directusToken = String.fromEnvironment('DIRECTUS_STATIC_TOKEN', defaultValue: '');
  static const _communityCollection = String.fromEnvironment(
    'DIRECTUS_COMMUNITY_COLLECTION',
    defaultValue: 'cms_posts',
  );

  late final Dio _dio;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _posts = const [];

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(baseUrl: _directusBaseUrl));
    if (_directusToken.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $_directusToken';
    }
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _loadPostsWithFallbackCollection();

      final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
      setState(() {
        _posts = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = _buildErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<Response<dynamic>> _loadPostsWithFallbackCollection() async {
    final candidateCollections = _candidateCollections();
    DioException? lastError;

    for (final collection in candidateCollections) {
      try {
        return await _dio.get('/items/$collection', queryParameters: {
          'sort': '-date_created',
          'filter[status][_eq]': 'published',
          'fields': 'id,title,excerpt,content,published_at,date_created',
          'limit': 50,
        });
      } on DioException catch (e) {
        lastError = e;
        if (!_isForbiddenOrNotFound(e)) {
          rethrow;
        }
      }
    }

    throw lastError ?? DioException(requestOptions: RequestOptions(path: '/items/${candidateCollections.first}'));
  }

  List<String> _candidateCollections() {
    final baseCollection = _communityCollection.trim().isEmpty ? 'cms_posts' : _communityCollection.trim();
    if (baseCollection == 'cms_post') {
      return const ['cms_post', 'cms_posts'];
    }
    if (baseCollection == 'cms_posts') {
      return const ['cms_posts', 'cms_post'];
    }
    return [baseCollection];
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
      return 'Community-Beiträge konnten nicht geladen werden. Prüfe DIRECTUS_BASE_URL (auf einem echten Handy nicht 10.0.2.2 verwenden).';
    }

    if (_isForbiddenOrNotFound(e)) {
      return 'Kein Zugriff auf die Community-Collection. Prüfe in Directus die Leserechte für "${_candidateCollections().join(' / ')}" '
          'oder setze --dart-define=DIRECTUS_COMMUNITY_COLLECTION=<name>.${details != null ? '\n\nAntwort: $details' : ''}';
    }

    return details ?? 'Community-Beiträge konnten nicht geladen werden. Prüfe DIRECTUS_BASE_URL und Berechtigungen.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AppShell(
      currentIndex: 3,
      title: 'Community',
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.red)))),
                ],
              )
            : _posts.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Noch keine Community-Beiträge vorhanden.')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: _posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final post = _posts[index];
                      final title = (post['title'] as String?)?.trim().isNotEmpty == true ? post['title'] as String : 'Ohne Titel';
                      final excerpt = (post['excerpt'] as String?) ?? _truncate((post['content'] as String?) ?? '', 170);
                      final dateRaw = (post['published_at'] ?? post['date_created'])?.toString();
                      final date = DateTime.tryParse(dateRaw ?? '');

                      return Card(
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
                              const SizedBox(height: 8),
                              Text(excerpt.isEmpty ? 'Kein Vorschautext verfügbar.' : excerpt),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _truncate(String value, int maxChars) {
    final text = value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}...';
  }
}
