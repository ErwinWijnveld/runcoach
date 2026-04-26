import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/router/app_router.dart';

class RunCoachApp extends ConsumerWidget {
  const RunCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return CupertinoApp.router(
      title: 'RunCoach',
      theme: AppTheme.cupertino,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      // Single source of truth for the cream → gold app background. Wraps
      // every route the router renders so individual screens don't have to
      // re-apply it (the old per-screen `GradientScaffold` + DecoratedBox
      // pattern). Cupertino theme's scaffoldBackgroundColor is transparent
      // so the gradient shows through every CupertinoPageScaffold.
      builder: (context, child) {
        return DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.onboardingGradient),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
