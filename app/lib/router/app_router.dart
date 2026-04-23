import 'dart:ui';

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart' show Icons, IconData;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/auth/screens/welcome_screen.dart';
import 'package:app/features/auth/screens/strava_auth_screen.dart';
import 'package:app/features/dashboard/screens/dashboard_screen.dart';
import 'package:app/features/schedule/screens/weekly_plan_screen.dart';
import 'package:app/features/schedule/screens/training_day_detail_screen.dart';
import 'package:app/features/schedule/screens/training_result_screen.dart';
import 'package:app/features/coach/screens/coach_chat_list_screen.dart';
import 'package:app/features/coach/screens/coach_chat_screen.dart';
import 'package:app/features/goals/screens/goal_list_screen.dart';
import 'package:app/features/goals/screens/goal_detail_screen.dart';
import 'package:app/features/onboarding/screens/onboarding_overview_screen.dart';
import 'package:app/features/onboarding/screens/onboarding_form_screen.dart';
import 'package:app/features/onboarding/screens/onboarding_generating_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/welcome';
      if (isLoggedIn && isAuthRoute) return '/dashboard';

      final user = authState.value;
      if (isLoggedIn &&
          user?.hasCompletedOnboarding == false &&
          !state.matchedLocation.startsWith('/onboarding') &&
          !state.matchedLocation.startsWith('/coach/chat/')) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth/strava',
        builder: (context, state) => const StravaAuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        redirect: (context, state) =>
            state.matchedLocation == '/onboarding' ? '/onboarding/overview' : null,
      ),
      GoRoute(
        path: '/onboarding/overview',
        builder: (context, state) => const OnboardingOverviewScreen(),
      ),
      GoRoute(
        path: '/onboarding/form',
        builder: (context, state) => const OnboardingFormScreen(),
      ),
      GoRoute(
        path: '/onboarding/generating',
        builder: (context, state) => const OnboardingGeneratingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WeeklyPlanScreen(),
            ),
            routes: [
              GoRoute(
                path: 'day/:dayId',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => HidesBottomNav(
                  child: TrainingDayDetailScreen(
                    dayId: int.parse(state.pathParameters['dayId']!),
                  ),
                ),
              ),
              GoRoute(
                path: 'day/:dayId/result',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => HidesBottomNav(
                  child: TrainingResultScreen(
                    dayId: int.parse(state.pathParameters['dayId']!),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/coach',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CoachChatListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'chat/:conversationId',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => HidesBottomNav(
                  child: CoachChatScreen(
                    conversationId: state.pathParameters['conversationId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/goals',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GoalListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':goalId',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => HidesBottomNav(
                  child: GoalDetailScreen(
                    goalId: int.parse(state.pathParameters['goalId']!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Height of the bar content (excludes bottom safe-area inset).
const double kBottomNavContentHeight = 58;

/// Approximate total height including a typical home-indicator safe area.
/// Scrollable tab screens pad their bottom by this so the last row doesn't
/// sit permanently under the translucent bar.
const double kBottomNavReservedHeight = 92;

/// Approximate visual height of the floating CoachPromptBar including its
/// top/bottom padding wrapper. Used alongside kBottomNavReservedHeight to
/// reserve bottom space on screens that stack the prompt bar ABOVE the nav.
const double kFloatingPromptBarHeight = 68;

/// Scroll-content bottom padding for any tab screen that renders BOTH the
/// floating CoachPromptBar AND the bottom nav above it. Using this constant
/// keeps every tab screen consistent and guarantees the last item of content
/// isn't hidden under either floating bar.
///
/// If you add a new tab screen with a fixed prompt bar, use this value for
/// its scroll view / list bottom padding.
const double kBottomStackedReservedHeight =
    kBottomNavReservedHeight + kFloatingPromptBarHeight;

/// The `Positioned.bottom` offset for a floating CoachPromptBar so it sits
/// just above the tab bar. Platform-aware because the native UITabBar on
/// iOS is thinner than our Flutter fallback nav.
///
/// Use on every screen that stacks a `CoachPromptBar` above the shell's
/// bottom nav: `bottom: floatingPromptBarBottomOffset(context)`.
double floatingPromptBarBottomOffset(BuildContext context) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    // Native UITabBar is ~49pt tall and manages its own home-indicator
    // safe inset. The prompt bar's own `SafeArea(top: false)` wrapper
    // still adds the bottom safe inset + Padding(bottom:12), which together
    // push the visible pill up by ~46pt. 41 places its visible bottom
    // right above the tab bar on iPhones with a home-indicator (38-41 on
    // SE-class devices).
    return 48;
  }
  return kBottomNavContentHeight;
}

/// Scroll-content bottom padding for DETAIL screens that render on the root
/// navigator (no tab bar, just a floating prompt bar). Reserves enough
/// bottom space so the last content item clears the prompt bar + home
/// indicator safe area.
double detailScreenBottomReservedHeight(BuildContext context) =>
    kFloatingPromptBarHeight + MediaQuery.paddingOf(context).bottom + 16;

/// Global toggle any screen can flip to force-hide the shell's bottom nav.
/// The path-based check ([MainShell._isTabRoot]) already hides the nav for
/// known detail paths, but go_router's `currentConfiguration.uri.path` is
/// not reliable across every platform/navigator combo — this notifier is the
/// belt-and-suspenders guarantee. Use [HidesBottomNav] instead of touching
/// this directly.
final ValueNotifier<bool> _bottomNavHidden = ValueNotifier(false);

/// Wrap a detail screen (any screen that pushes on `_rootNavigatorKey`) with
/// this widget to hide the shell's bottom tab bar while it's on top of the
/// stack. Without it, the native iOS `CNTabBar`'s UiKitView shadow can bleed
/// through during the push transition and, on some nav paths, the tab bar
/// stays visible under the detail screen entirely.
///
/// Pattern:
/// ```dart
/// GoRoute(
///   path: 'day/:dayId',
///   parentNavigatorKey: _rootNavigatorKey,
///   builder: (context, state) => HidesBottomNav(
///     child: TrainingDayDetailScreen(...),
///   ),
/// )
/// ```
class HidesBottomNav extends StatefulWidget {
  final Widget child;
  const HidesBottomNav({super.key, required this.child});

  @override
  State<HidesBottomNav> createState() => _HidesBottomNavState();
}

class _HidesBottomNavState extends State<HidesBottomNav> {
  @override
  void initState() {
    super.initState();
    // Schedule for the next frame so the notifier update doesn't collide with
    // the build that pushed this route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bottomNavHidden.value = true;
    });
  }

  @override
  void dispose() {
    // Defer to post-frame: dispose() fires during widget-tree teardown, and
    // touching the ValueNotifier synchronously would rebuild the shell's
    // ValueListenableBuilder while the tree is locked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bottomNavHidden.value = false;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  /// True only when the router's top-of-stack is one of the four tab roots.
  /// Secondary defense behind [HidesBottomNav] — catches legacy detail routes
  /// that forget to wrap themselves.
  static bool _isTabRoot(String location) {
    return location == '/dashboard' ||
        location == '/schedule' ||
        location == '/coach' ||
        location == '/goals';
  }

  static int _indexOf(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/coach')) return 2;
    if (location.startsWith('/goals')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);

    // Keep `child` (the routed shell navigator) OUTSIDE the rebuilding
    // subtree. Rebuilding its parent reparents the Navigator's pages, which
    // collides with go_router's internal GlobalObjectKeys and throws a
    // "Duplicate GlobalKey detected" assertion. Only the bottom-nav slot
    // listens to route + visibility changes.
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                router.routerDelegate,
                _bottomNavHidden,
              ]),
              builder: (context, _) {
                final location =
                    router.routerDelegate.currentConfiguration.uri.path;
                final forceHidden = _bottomNavHidden.value;
                final showNav = !forceHidden && _isTabRoot(location);
                if (!showNav) return const SizedBox.shrink();
                return _RunCoreBottomNav(currentIndex: _indexOf(location));
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Native-backed tab bar on iOS (real UITabBar with the iOS 26 Liquid Glass
/// material via `cupertino_native`'s UiKitView bridge). On Android and Web
/// the native bridge isn't available, so we fall back to a Flutter
/// `BackdropFilter`-based approximation.
///
/// Route-to-index mapping is defined once in [MainShell._indexOf] and
/// mirrored here in [_tabRoutes] so both widgets stay in sync.
const _tabRoutes = ['/dashboard', '/schedule', '/coach', '/goals'];

class _RunCoreBottomNav extends StatelessWidget {
  static const _activeColor = Color(0xFF785600);
  static const _inactiveColor = Color(0xFFBBAA80);
  static const _topBorder = Color(0x1F000000);

  final int currentIndex;
  const _RunCoreBottomNav({required this.currentIndex});

  void _goTo(BuildContext context, int index) {
    context.go(_tabRoutes[index]);
  }

  bool get _useNativeIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    if (_useNativeIos) {
      return _NativeIosTabBar(
        currentIndex: currentIndex,
        onTap: (i) => _goTo(context, i),
      );
    }
    return _buildFlutterFallback(context);
  }

  Widget _buildFlutterFallback(BuildContext context) {
    // `ClipRect` bounds the blur to the bar so it doesn't leak upward.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            // Warm cream at ~60% opacity; the gradient + any content below
            // the blur shows through while keeping the bar legible.
            // color: Color(0x99FAF1D9),
            border: Border(top: BorderSide(color: _topBorder, width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: kBottomNavContentHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: Icons.dashboard,
                        label: 'Dashboard',
                        active: currentIndex == 0,
                        onTap: () => _goTo(context, 0),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.calendar_today,
                        label: 'Schedule',
                        active: currentIndex == 1,
                        onTap: () => _goTo(context, 1),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        svgAsset: 'assets/icons/ai_coach_tab.svg',
                        label: 'AI Coach',
                        active: currentIndex == 2,
                        onTap: () => _goTo(context, 2),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.emoji_events,
                        label: 'Goals',
                        active: currentIndex == 3,
                        onTap: () => _goTo(context, 3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData? icon;
  final String? svgAsset;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    this.icon,
    this.svgAsset,
    required this.label,
    required this.active,
    required this.onTap,
  }) : assert(icon != null || svgAsset != null);

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? _RunCoreBottomNav._activeColor
        : _RunCoreBottomNav._inactiveColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.55 : 1,
        duration: const Duration(milliseconds: 120),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                child: widget.icon != null
                    ? Icon(widget.icon, color: color, size: 24)
                    : SvgPicture.asset(
                        widget.svgAsset!,
                        width: 20,
                        height: 24,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: RunCoreText.tabLabel(color: color, active: widget.active),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS-native tab bar backed by a real `UITabBar` via `cupertino_native`.
///
/// On iOS 26 this renders with the system Liquid Glass material (translucent
/// pill, specular highlights, lensing). On iOS 14–25 it degrades to the
/// pre-26 translucent tab bar appearance, which is still system-native.
///
/// SF Symbol names chosen to match Apple's iOS 26 guidance — prefer filled
/// glyphs on the selected state where Apple's own apps do.
class _NativeIosTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _NativeIosTabBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // No outer SafeArea: the native UITabBar manages its own home-indicator
    // inset, so wrapping it in SafeArea would double-pad the bottom and
    // float the bar above the home indicator.
    return CNTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      tint: _RunCoreBottomNav._activeColor,
      items: const [
        CNTabBarItem(
          label: 'Dashboard',
          icon: CNSymbol('square.grid.2x2.fill'),
        ),
        CNTabBarItem(
          label: 'Schedule',
          icon: CNSymbol('calendar'),
        ),
        CNTabBarItem(
          label: 'AI Coach',
          icon: CNSymbol('sparkles'),
        ),
        CNTabBarItem(
          label: 'Goals',
          icon: CNSymbol('trophy.fill'),
        ),
      ],
    );
  }
}
