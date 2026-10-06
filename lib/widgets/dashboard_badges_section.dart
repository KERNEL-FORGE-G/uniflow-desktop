import 'package:flutter/material.dart';

import '../models/badges.dart';
import '../theme/app_theme.dart';
import '../widgets/phosphor.dart';
import 'animated_number.dart';

/// Section "Mes badges" pour le tableau de bord desktop.
///
/// Affiche les six badges en grille horizontale scrollable, avec l'effet
/// glassmorphism en dark mode. Réutilise [BadgeProgress] et [computeBadges]
/// du modèle partagé avec le mobile.
///
/// En mode desktop, les badges sont plus grands (80 px), affichés en grille
/// de 3 colonnes max plutôt qu'en liste horizontale, pour occuper la largeur
/// disponible.
class DashboardBadgesSection extends StatelessWidget {
  final List<BadgeProgress> badges;
  final VoidCallback? onSeeAll;

  const DashboardBadgesSection({
    super.key,
    required this.badges,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = badges.where((b) => b.unlocked).length;
    final ordered = [...badges]
      ..sort((a, b) {
        if (a.unlocked != b.unlocked) return a.unlocked ? -1 : 1;
        return b.progress.compareTo(a.progress);
      });

    return _BadgeCard(
      title: unlocked == 0
          ? 'Badges — aucun débloqué'
          : 'Badges — $unlocked / ${badges.length}',
      onSeeAll: onSeeAll,
      child: _BadgeGrid(badges: ordered),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;

  const _BadgeCard({
    required this.title,
    required this.child,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _GlassWrapper(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Voir tout'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Fond glassmorphism en dark, fond surface en light — même logique que
/// [GlassCard] mais intégré directement pour éviter une dépendance circulaire.
class _GlassWrapper extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _GlassWrapper({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.all(20);
    const radius = 16.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172033) : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3E5D) : AppColors.inputBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : AppColors.primaryBlue.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Grille 3×2 des badges, adaptée à la largeur desktop.
class _BadgeGrid extends StatelessWidget {
  final List<BadgeProgress> badges;

  const _BadgeGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 720
            ? 6
            : constraints.maxWidth >= 480
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: badges.length,
          itemBuilder: (context, i) => SlideFadeIn(
            delay: Duration(milliseconds: 60 * i),
            child: _BadgeTile(progress: badges[i]),
          ),
        );
      },
    );
  }
}

/// Tuile d'un badge : médaille + nom + barre de progression.
class _BadgeTile extends StatelessWidget {
  final BadgeProgress progress;

  const _BadgeTile({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DesktopBadgeMedal(progress: progress, size: 72),
        const SizedBox(height: 6),
        Text(
          progress.badge.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: progress.unlocked ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        if (!progress.unlocked)
          Tooltip(
            message: progress.badge.rule,
            child: SizedBox(
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.progress,
                  backgroundColor: AppColors.inputBorder,
                  color: AppColors.teal,
                ),
              ),
            ),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }
}

/// Médaille de badge pour le desktop : burst animation + cadenas + anneau.
/// Allégée par rapport à la version mobile (pas de `SingleTickerProviderStateMixin`
/// si pas d'animation demandée).
class _DesktopBadgeMedal extends StatefulWidget {
  final BadgeProgress progress;
  final double size;

  const _DesktopBadgeMedal({required this.progress, required this.size});

  @override
  State<_DesktopBadgeMedal> createState() => _DesktopBadgeMedalState();
}

class _DesktopBadgeMedalState extends State<_DesktopBadgeMedal>
    with SingleTickerProviderStateMixin {
  late AnimationController _burst;
  late Animation<double> _burstRadius;
  late Animation<double> _burstOpacity;

  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.2126 * 0.75, 0.7152 * 0.75, 0.0722 * 0.75, 0, 70,
    0.2126 * 0.75, 0.7152 * 0.75, 0.0722 * 0.75, 0, 70,
    0.2126 * 0.75, 0.7152 * 0.75, 0.0722 * 0.75, 0, 70,
    0, 0, 0, 1, 0,
  ]);

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _burstRadius = Tween<double>(begin: 0.3, end: 1.2).animate(
        CurvedAnimation(parent: _burst, curve: Curves.easeOut));
    _burstOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
        CurvedAnimation(parent: _burst, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_DesktopBadgeMedal old) {
    super.didUpdateWidget(old);
    if (!old.progress.unlocked && widget.progress.unlocked) {
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = widget.progress.unlocked;
    final size = widget.size;

    final image = Image.asset(
      widget.progress.badge.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => PhosphorIcon(
        PhosphorIconsFill.medal,
        size: size * 0.7,
        color: unlocked ? AppColors.warning : AppColors.textMuted,
      ),
    );

    final medal = unlocked
        ? DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: image,
          )
        : Opacity(
            opacity: 0.55,
            child: ColorFiltered(colorFilter: _greyscale, child: image),
          );

    return Semantics(
      label: unlocked
          ? 'Badge ${widget.progress.badge.title}, gagné'
          : 'Badge ${widget.progress.badge.title}, ${widget.progress.percent} %',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _burst,
              builder: (context, _) {
                if (_burst.value == 0) return const SizedBox.shrink();
                return Opacity(
                  opacity: _burstOpacity.value,
                  child: Container(
                    width: size * _burstRadius.value,
                    height: size * _burstRadius.value,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                );
              },
            ),
            if (!unlocked)
              SizedBox(
                width: size * 0.98,
                height: size * 0.98,
                child: CircularProgressIndicator(
                  value: widget.progress.progress.clamp(0.0, 1.0),
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.inputBorder,
                  color: AppColors.teal,
                ),
              ),
            Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: medal,
            ),
            if (!unlocked)
              Positioned(
                right: size * 0.04,
                bottom: size * 0.04,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      PhosphorIconsFill.lock,
                      size: size * 0.16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
