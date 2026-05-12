import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/auth/providers/auth_provider.dart';

/// Native Apple Sign-In flow. Triggers the iOS dialog on mount, exchanges
/// the returned identity token with the backend for a Sanctum bearer.
/// Routes to `/onboarding/connect-health` (new user) or `/dashboard`
/// (returning user — router will handle further redirects).
class AppleAuthScreen extends ConsumerStatefulWidget {
  const AppleAuthScreen({super.key});

  @override
  ConsumerState<AppleAuthScreen> createState() => _AppleAuthScreenState();
}

class _AppleAuthScreenState extends ConsumerState<AppleAuthScreen> {
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    // Capture localized strings BEFORE the first await — context may not
    // be safe to use once we resume on error paths.
    final l10n = context.l10n;
    final errNoIdentityToken = l10n.authAppleErrorNoIdentityToken;
    final errBackendRejected = l10n.authAppleErrorBackendRejected;
    final errAuthEmpty = l10n.authAppleErrorAuthEmpty;

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception(errNoIdentityToken);
      }

      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((p) => p != null && p.isNotEmpty).join(' ').trim();

      await ref.read(authProvider.notifier).loginWithApple(
            identityToken: identityToken,
            email: credential.email,
            name: fullName.isEmpty ? null : fullName,
          );

      if (!mounted) return;

      // loginWithApple swallows backend errors into AsyncValue.error — if
      // the POST /auth/apple call failed (bad token verification, network,
      // etc.) we'd otherwise navigate to /dashboard with no logged-in user
      // and the router would silently bounce back to /auth/welcome. Surface
      // the real error here instead.
      final auth = ref.read(authProvider);
      if (auth.hasError) {
        final err = auth.error;
        setState(() => _error = err?.toString() ?? errBackendRejected);
        return;
      }
      if (auth.value == null) {
        setState(() => _error = errAuthEmpty);
        return;
      }

      context.go('/dashboard');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        if (mounted) context.go('/auth/welcome');
        return;
      }
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.cream,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.cream.withValues(alpha: 0.92),
        border: null,
        middle: Text(context.l10n.authAppleScreenTitle),
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
        child: Center(
          child: _busy
              ? const AppSpinner()
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_triangle,
                              size: 36, color: AppColors.warmBrown),
                          const SizedBox(height: 12),
                          Text(context.l10n.authAppleErrorTitle),
                          const SizedBox(height: 8),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          CupertinoButton.filled(
                            onPressed: () {
                              setState(() {
                                _busy = true;
                                _error = null;
                              });
                              _start();
                            },
                            child: Text(context.l10n.authAppleErrorRetry),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
