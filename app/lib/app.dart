import 'package:flutter/cupertino.dart';
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
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
    );
  }
}
