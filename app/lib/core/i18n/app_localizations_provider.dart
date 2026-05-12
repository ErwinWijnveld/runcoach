import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:app/core/i18n/locale_provider.dart';
import 'package:app/l10n/app_localizations.dart';

part 'app_localizations_provider.g.dart';

/// Exposes [AppLocalizations] outside of widget trees.
///
/// Use cases: services that compose user-visible strings (e.g. error
/// formatters, notification body assemblers), Riverpod providers that
/// need localized copy in their state, etc.
///
/// In widget code prefer `context.l10n.foo` (cheaper, synchronous).
///
/// Rebuilds whenever [appLocaleProvider] emits a new locale.
@Riverpod(keepAlive: true)
Future<AppLocalizations> appLocalizations(Ref ref) async {
  final locale = await ref.watch(appLocaleProvider.future);
  return AppLocalizations.delegate.load(locale);
}
