import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app/app.dart';
import 'package:app/core/utils/date_formatter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // intl's date-formatting needs locale symbols loaded before use. On
  // Flutter Web this is strictly required even for 'en'. Load the app's
  // current locale (see `appDateLocale`) before runApp.
  await initializeDateFormatting(appDateLocale);

  runApp(
    const ProviderScope(
      child: RunCoachApp(),
    ),
  );
}
