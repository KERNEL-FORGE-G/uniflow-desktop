import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Carte avec effet glassmorphism en thème sombre, comportement normal (fond
/// blanc + ombre légère) en thème clair.
///
/// En dark : fond bleu semi-transparent + BackdropFilter blur 20 + bordure
/// lumineuse subtile, comme les cartes du design de référence NFT/crypto.
/// En light : fond `surface` + border arrondie, identique à l'existant.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? accentColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = UniFlowColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172033) : colors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? (accentColor?.withValues(alpha: 0.25) ??
                  const Color(0xFF2E3E5D))
              : colors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColors.primaryBlue.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
