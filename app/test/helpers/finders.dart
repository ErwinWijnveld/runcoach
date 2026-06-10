import 'package:app/core/widgets/runboost_logo.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds a [RunBoostHeading] by its semantic (pre-uppercase) copy.
///
/// The design system owns the case transform (Anton headings render
/// UPPERCASE — pinned in test/core/widgets/runboost_heading_test.dart), so
/// tests assert the l10n copy fed to the heading, not the rendered casing.
Finder findHeading(String text) => find.byWidgetPredicate(
      (w) => w is RunBoostHeading && w.text == text,
      description: 'RunBoostHeading("$text")',
    );

/// Like [findHeading] but matches on a substring of the heading copy.
Finder findHeadingContaining(String substring) => find.byWidgetPredicate(
      (w) => w is RunBoostHeading && w.text.contains(substring),
      description: 'RunBoostHeading containing "$substring"',
    );
