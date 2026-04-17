import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
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
          if (uri.path.contains('/auth/strava/callback') &&
              uri.queryParameters.containsKey('code')) {
            final code = uri.queryParameters['code']!;
            _handleAuthCode(code);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (_) {
          if (mounted && _loading) setState(() => _loading = false);
        },
        onProgress: (progress) {
          if (mounted && _loading && progress > 30) {
            setState(() => _loading = false);
          }
        },
        onPageFinished: (_) {
          if (mounted && _loading) setState(() => _loading = false);
        },
      ));

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/auth/strava/redirect');
      final stravaUrl = response.data['url'] as String;
      _controller.loadRequest(Uri.parse(stravaUrl));
    } catch (e) {
      if (mounted) {
        await showAppAlert(
          context,
          title: 'Connection Failed',
          message: 'Failed to connect to server: $e',
        );
        if (mounted) context.go('/auth/welcome');
      }
    }
  }

  Future<void> _handleAuthCode(String code) async {
    setState(() => _loading = true);
    await ref.read(authProvider.notifier).loginWithStrava(code);
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.cream.withValues(alpha: 0.92),
        border: null,
        middle: const Text('Connect Strava'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/auth/welcome'),
          child: const Icon(
            CupertinoIcons.xmark,
            color: AppColors.warmBrown,
          ),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading) const AppSpinner(),
          ],
        ),
      ),
    );
  }
}
