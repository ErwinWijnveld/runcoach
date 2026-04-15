import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, IconData, InkWell, Material;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/auth/screens/welcome_screen.dart';
import 'package:app/features/auth/screens/strava_auth_screen.dart';
import 'package:app/features/auth/screens/onboarding_screen.dart';
import 'package:app/features/dashboard/screens/dashboard_screen.dart';
import 'package:app/features/schedule/screens/weekly_plan_screen.dart';
import 'package:app/features/schedule/screens/training_day_detail_screen.dart';
import 'package:app/features/schedule/screens/training_result_screen.dart';
import 'package:app/features/coach/screens/coach_chat_list_screen.dart';
import 'package:app/features/coach/screens/coach_chat_screen.dart';
import 'package:app/features/races/screens/race_list_screen.dart';
import 'package:app/features/races/screens/race_create_screen.dart';
import 'package:app/features/races/screens/race_detail_screen.dart';

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
      if (isLoggedIn && user?.coachStyle == null && state.matchedLocation != '/auth/onboarding') {
        return '/auth/onboarding';
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
        path: '/auth/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
                builder: (context, state) => TrainingDayDetailScreen(
                  dayId: int.parse(state.pathParameters['dayId']!),
                ),
              ),
              GoRoute(
                path: 'day/:dayId/result',
                builder: (context, state) => TrainingResultScreen(
                  dayId: int.parse(state.pathParameters['dayId']!),
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
                builder: (context, state) => CoachChatScreen(
                  conversationId: state.pathParameters['conversationId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/races',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RaceListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const RaceCreateScreen(),
              ),
              GoRoute(
                path: ':raceId',
                builder: (context, state) => RaceDetailScreen(
                  raceId: int.parse(state.pathParameters['raceId']!),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static int _indexOf(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/coach')) return 2;
    if (location.startsWith('/races')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indexOf(GoRouterState.of(context).matchedLocation);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.neutral,
      child: Column(
        children: [
          Expanded(child: child),
          _RunCoreBottomNav(currentIndex: currentIndex),
        ],
      ),
    );
  }
}

class _RunCoreBottomNav extends StatelessWidget {
  static const _activeColor = Color(0xFF785600);
  static const _inactiveColor = Color(0xFFBBAA80);
  static const _topBorder = Color(0xFFF6F3EF);

  final int currentIndex;
  const _RunCoreBottomNav({required this.currentIndex});

  void _goTo(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
      case 1:
        context.go('/schedule');
      case 2:
        context.go('/coach');
      case 3:
        context.go('/races');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral,
        border: Border(top: BorderSide(color: _topBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  active: currentIndex == 0,
                  onTap: () => _goTo(context, 0),
                ),
                _NavItem(
                  icon: Icons.calendar_today,
                  label: 'Schedule',
                  active: currentIndex == 1,
                  onTap: () => _goTo(context, 1),
                ),
                _NavItem(
                  svgAsset: 'assets/icons/ai_coach_tab.svg',
                  label: 'AI Coach',
                  active: currentIndex == 2,
                  onTap: () => _goTo(context, 2),
                ),
                _NavItem(
                  icon: Icons.emoji_events,
                  label: 'Goals',
                  active: currentIndex == 3,
                  onTap: () => _goTo(context, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final color = active
        ? _RunCoreBottomNav._activeColor
        : _RunCoreBottomNav._inactiveColor;
    return Material(
      color: const Color(0x00000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                child: icon != null
                    ? Icon(icon, color: color, size: 24)
                    : SvgPicture.asset(
                        svgAsset!,
                        width: 20,
                        height: 24,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      ),
              ),
              const SizedBox(height: 2),
              Text(label, style: RunCoreText.tabLabel(color: color, active: active)),
            ],
          ),
        ),
      ),
    );
  }
}
