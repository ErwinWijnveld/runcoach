import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Material, InkWell;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/runcore_logo.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.neutral,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TodayCard(
                      onTap: () => context.go('/schedule'),
                    ),
                    const SizedBox(height: 12),
                    _CoachPromptBar(
                      onTap: () => context.go('/coach'),
                    ),
                    const SizedBox(height: 12),
                    const _GoalProgressionCard(
                      title: 'ASML Marathon Eindhoven',
                      daysToGo: 28,
                      progress: 147 / 297,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ImageCard(
                            asset: 'assets/images/ai_coach_bg.png',
                            title: 'AI Coach',
                            alignment: const Alignment(-0.1, -0.2),
                            onTap: () => context.go('/coach'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ImageCard(
                            asset: 'assets/images/goals_bg.png',
                            title: 'Goals',
                            alignment: const Alignment(0.0, 0.0),
                            onTap: () => context.go('/races'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const RunCoreLogo(starSize: 19, textSize: 20, gap: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.notifications,
                  color: AppColors.secondary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE8DC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/user_avatar.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today card
// ---------------------------------------------------------------------------

class _TodayCard extends StatelessWidget {
  final VoidCallback onTap;
  const _TodayCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _RoundedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _GoldBadge(label: 'TODAY'),
                    const SizedBox(height: 8),
                    Text(
                      'Threshold Intervals',
                      style: RunCoreText.serifTitle(
                        size: 36,
                        height: 40 / 36,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CircleArrowButton(onTap: onTap),
            ],
          ),
          const SizedBox(height: 32),
          const Row(
            children: [
              _Stat(label: 'DISTANCE', value: '8.2 km'),
              SizedBox(width: 48),
              _Stat.withSuffix(
                label: 'TARGET PACE',
                value: '4:45',
                suffix: 'min/km',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoldBadge extends StatelessWidget {
  final String label;
  const _GoldBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: RunCoreText.badge()),
    );
  }
}

class _CircleArrowButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleArrowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryInk,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: Icon(
              Icons.arrow_forward,
              color: AppColors.neutral,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;

  const _Stat({required this.label, required this.value}) : suffix = null;
  const _Stat.withSuffix({
    required this.label,
    required this.value,
    required String this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: RunCoreText.statLabel()),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: RunCoreText.statValue()),
            if (suffix != null) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(suffix!, style: RunCoreText.statSuffix()),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Coach prompt bar
// ---------------------------------------------------------------------------

class _CoachPromptBar extends StatelessWidget {
  final VoidCallback onTap;
  const _CoachPromptBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(24),
            gradient: RadialGradient(
              center: Alignment.centerRight,
              radius: 0.9,
              colors: [
                AppColors.secondary.withValues(alpha: 0.15),
                AppColors.secondary.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/coach_prompt_star.svg',
                width: 18,
                height: 19,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ask your coach...',
                  style: RunCoreText.body(),
                ),
              ),
              const SizedBox(width: 12),
              SvgPicture.asset(
                'assets/icons/coach_send.svg',
                width: 28,
                height: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goal Progression card
// ---------------------------------------------------------------------------

class _GoalProgressionCard extends StatelessWidget {
  final String title;
  final int daysToGo;
  final double progress;
  const _GoalProgressionCard({
    required this.title,
    required this.daysToGo,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return _RoundedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GOAL PROGRESSION', style: RunCoreText.sectionEyebrow()),
          const SizedBox(height: 4),
          Text(
            title,
            style: RunCoreText.serifTitle(size: 36, height: 40 / 36),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$daysToGo days to go',
                style: RunCoreText.italicSmall(),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 12,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Container(color: AppColors.neutralHighlight),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image cards (AI Coach / Goals)
// ---------------------------------------------------------------------------

class _ImageCard extends StatelessWidget {
  final String asset;
  final String title;
  final Alignment alignment;
  final VoidCallback onTap;

  const _ImageCard({
    required this.asset,
    required this.title,
    required this.alignment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(48),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 176,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(48),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  alignment: alignment,
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 109,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00FDF9ED),
                          AppColors.neutral,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: RunCoreText.serifTitle(
                      size: 28,
                      color: AppColors.primary,
                      height: 40 / 28,
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

// ---------------------------------------------------------------------------
// Shared rounded card chrome
// ---------------------------------------------------------------------------

class _RoundedCard extends StatelessWidget {
  final Widget child;
  const _RoundedCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(48),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            spreadRadius: 0,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: child,
    );
  }
}
