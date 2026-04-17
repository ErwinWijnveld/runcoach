import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/widgets/swooshing_star.dart';

/// Coach loading card — shown while the agent is working before it emits
/// its first streamed text.
class ThinkingCard extends StatefulWidget {
  final String label;

  const ThinkingCard({super.key, this.label = 'Thinking'});

  @override
  State<ThinkingCard> createState() => _ThinkingCardState();
}

class _ThinkingCardState extends State<ThinkingCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.zero,
      topRight: Radius.circular(24),
      bottomLeft: Radius.circular(24),
      bottomRight: Radius.circular(24),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 296),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 16,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: radius,
            gradient: RadialGradient(
              center: Alignment.centerRight,
              radius: 3.5,
              colors: [
                AppColors.secondary.withValues(alpha: 0.15),
                AppColors.secondary.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: FadeTransition(
            opacity: _pulse,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SwooshingStar(),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 20 / 16,
                      color: AppColors.primaryInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

