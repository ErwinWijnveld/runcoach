import 'package:flutter/cupertino.dart';

/// Thin wrapper around `CupertinoPageScaffold` for screens that want the
/// app's cream → gold gradient background. The gradient itself is now
/// applied globally in `RunCoachApp.builder` (app.dart) — this widget just
/// keeps the scaffold transparent so the gradient shows through, and
/// exists as a stable callsite for the dozens of screens that already
/// use it.
///
/// New screens can use `CupertinoPageScaffold` directly (its transparent
/// theme background means the global gradient already shows through);
/// `GradientScaffold` is kept around for backwards compatibility.
class GradientScaffold extends StatelessWidget {
  final Widget child;

  const GradientScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: child,
    );
  }
}
