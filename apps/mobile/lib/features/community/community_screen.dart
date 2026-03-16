import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_shell.dart';
import '../../core/providers.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  static const _flarumBaseUrl = String.fromEnvironment(
    'FLARUM_BASE_URL',
    defaultValue: 'https://community.example.com',
  );
  static const _flarumSsoPath = String.fromEnvironment('FLARUM_SSO_PATH', defaultValue: '/sso/mobile');

  late final WebViewController _controller;
  bool _loading = true;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final token = await ref.read(tokenStoreProvider).getAccessToken();
    final uri = Uri.parse('$_flarumBaseUrl$_flarumSsoPath').replace(queryParameters: {
      if (token != null && token.isNotEmpty) 'token': token,
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(uri);

    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 2,
      title: 'Community',
      body: _flarumBaseUrl.contains('example.com')
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Flarum ist noch nicht konfiguriert. Setze --dart-define=FLARUM_BASE_URL und optional FLARUM_SSO_PATH, damit Community-Inhalte inkl. SSO geladen werden.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Stack(
              children: [
                if (_loading) const LinearProgressIndicator(minHeight: 2),
                Padding(
                  padding: EdgeInsets.only(top: _loading ? 2 : 0),
                  child: _ready ? WebViewWidget(controller: _controller) : const SizedBox.shrink(),
                ),
              ],
            ),
    );
  }
}
