import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Palette des formulaires d'authentification.
///
/// Les écrans de connexion et d'inscription desktop posent leur formulaire
/// sur le panneau bleu nuit de la carte (maquette « portail universitaire ») ;
/// partout ailleurs les mêmes champs restent sur fond clair. Plutôt que de
/// dupliquer [AppTextField], [AuthDropdown] et compagnie, ces widgets lisent
/// leurs couleurs ici : clair par défaut, sombre sous un [AuthTone] `dark`.
class AuthPalette {
  final bool dark;
  final Color text;
  final Color textSoft;
  final Color muted;
  final Color fill;
  final Color border;
  final Color focus;
  final Color link;
  final Color divider;
  final Color selectedFill;
  final Color selectedBorder;
  final Color selectedText;
  final Color menu;
  final double fieldRadius;

  const AuthPalette._({
    required this.dark,
    required this.text,
    required this.textSoft,
    required this.muted,
    required this.fill,
    required this.border,
    required this.focus,
    required this.link,
    required this.divider,
    required this.selectedFill,
    required this.selectedBorder,
    required this.selectedText,
    required this.menu,
    required this.fieldRadius,
  });

  static const light = AuthPalette._(
    dark: false,
    text: AppColors.textPrimary,
    textSoft: AppColors.textSecondary,
    muted: AppColors.textMuted,
    fill: AppColors.inputFill,
    border: AppColors.inputBorder,
    focus: AppColors.primaryBlue,
    link: AppColors.primaryBlue,
    divider: AppColors.inputBorder,
    selectedFill: AppColors.primary50,
    selectedBorder: AppColors.primaryBlue,
    selectedText: AppColors.primaryBlue,
    menu: Colors.white,
    fieldRadius: 10,
  );

  /// Variante panneau bleu nuit : champs « pilule » plus sombres que le fond,
  /// accent teal clair pour le focus et les liens (contraste AA sur #1E3A8A).
  static const darkPanel = AuthPalette._(
    dark: true,
    text: Colors.white,
    textSoft: Color(0xFFCBD5E1),
    muted: Color(0xFF94A8CC),
    fill: Color(0xFF0D1E4A),
    border: Color(0x1FFFFFFF),
    focus: Color(0xFF2DD4BF),
    link: Color(0xFF5EEAD4),
    divider: Color(0x29FFFFFF),
    selectedFill: Color(0x2614B8A8),
    selectedBorder: Color(0xFF2DD4BF),
    selectedText: Color(0xFF5EEAD4),
    menu: Color(0xFF13295E),
    fieldRadius: 28,
  );

  TextStyle get label => AppTextStyles.label.copyWith(color: text);
  TextStyle get linkStyle => AppTextStyles.link.copyWith(color: link);
}

/// Fournit une [AuthPalette] aux widgets de formulaire descendants.
class AuthTone extends InheritedWidget {
  final AuthPalette palette;

  const AuthTone({super.key, required this.palette, required super.child});

  /// Palette courante ; claire en l'absence de [AuthTone] dans l'arbre.
  static AuthPalette of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthTone>()?.palette ??
      AuthPalette.light;

  @override
  bool updateShouldNotify(AuthTone oldWidget) => oldWidget.palette != palette;
}
