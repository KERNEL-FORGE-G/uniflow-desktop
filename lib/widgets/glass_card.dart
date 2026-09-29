import 'dart:ui';

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

    if (!isDark) {
      return Container(
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: colors.border),
        ),
        child: child,
      );
    }

    final accent = accentColor ?? colors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            // Fond très sombre légèrement bleuté, semi-transparent
            color: Color.alphaBlend(
              accent.withAlpha(25),
              colors.surface,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: accent.withAlpha(60),
              width: 1,
            ),
            // Légère lueur sur le bord supérieur
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withAlpha(30),
                Colors.transparent,
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
