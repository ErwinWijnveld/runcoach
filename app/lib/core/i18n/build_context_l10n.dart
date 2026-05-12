import 'package:flutter/widgets.dart';

import 'package:app/l10n/app_localizations.dart';

extension BuildContextL10n on BuildContext {
  /// Strongly-typed access to localized strings.
  ///
  /// Usage:
  /// ```dart
  /// Text(context.l10n.appTitle)
  /// ```
  ///
  /// Non-nullable thanks to `nullable-getter: false` in `l10n.yaml`.
  /// `AppLocalizations.of(this)` will always return a value once
  /// `CupertinoApp.router` registers the delegates (see `lib/app.dart`).
  AppLocalizations get l10n => AppLocalizations.of(this);
}
