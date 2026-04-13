import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/auth/providers/auth_provider.dart';

class StravaAuthScreen extends ConsumerStatefulWidget {
  const StravaAuthScreen({super.key});

  @override
  ConsumerState<StravaAuthScreen> createState() => _StravaAuthScreenState();
}

class _StravaAuthScreenState extends ConsumerState<StravaAuthScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.parse(request.url);

          // Check if this is the callback URL with a code
          if (uri.path.contains('/auth/strava/callback') &&
              uri.queryParameters.containsKey('code')) {
            final code = uri.queryParameters['code']!;
            _handleAuthCode(code);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageFinished: (_) => setState(() => _loading = false),
      ));

    // Get the Strava authorize URL from our API
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/auth/strava/redirect');
      final stravaUrl = response.data['url'] as String;
      _controller.loadRequest(Uri.parse(stravaUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to server: $e')),
        );
        context.go('/auth/welcome');
      }
    }
  }

  Future<void> _handleAuthCode(String code) async {
    setState(() => _loading = true);

    await ref.read(authProvider.notifier).loginWithStrava(code);

    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Strava'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/auth/welcome'),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
