import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexOf(GoRouterState.of(context).matchedLocation),
        onTap: (index) {
          switch (index) {
            case 0: context.go('/dashboard');
            case 1: context.go('/schedule');
            case 2: context.go('/coach');
            case 3: context.go('/races');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'AI Coach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'Races',
          ),
        ],
      ),
    );
  }
}
