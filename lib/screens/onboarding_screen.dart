import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DONNÉES ONBOARDING PLEIN ÉCRAN (MODÈLE ÉPURÉ 2D SANS DIALOGUE)
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardPage {
  final String tagline;
  final String title;
  final String subtitle;
  final String bgImage;
  final String buttonLabel;

  const _OnboardPage({
    required this.tagline,
    required this.title,
    required this.subtitle,
    required this.bgImage,
    required this.buttonLabel,
  });
}

const _kPages = [
  _OnboardPage(
    tagline: 'BIENVENUE',
    title: 'Bienvenue sur\nUniFlow',
    subtitle:
        'La plateforme universitaire tout-en-un — cours, présences QR code, '
        'notes et communication en un seul endroit fluide et performant.',
    bgImage: 'assets/onboarding/onboarding_1_welcome.jpg',
    buttonLabel: 'Suivant →',
  ),
  _OnboardPage(
    tagline: 'COURS & OUTILS',
    title: 'Tout ce dont vous\navez besoin',
    subtitle: 'Étudiants, délégués et enseignants connectés. '
        'Émargement instantané par QR code, suivi des notes en temps réel et organisation globale.',
    bgImage: 'assets/onboarding/onboarding_2_courses.jpg',
    buttonLabel: 'Continuer →',
  ),
  _OnboardPage(
    tagline: 'COMMUNAUTÉ',
    title: 'Votre campus,\nvotre communauté',
    subtitle:
        'Forum de promo, messages directs et notifications d\'urgence. '
        'UniFlow vous connecte avec toute votre promotion, en temps réel.',
    bgImage: 'assets/onboarding/onboarding_3_community.jpg',
    buttonLabel: 'Continuer →',
  ),
  _OnboardPage(
    tagline: 'KERNEL FORGE · AXORA',
    title: 'Fait par des\nétudiants, pour vous',
    subtitle:
        'UniFlow est né à l\'Université de Yaoundé I. Soutenu technologiquement par Axora, '
        'il fonctionne même hors connexion. Vos données restent sur vos appareils.',
    bgImage: 'assets/onboarding/onboarding_4_forge.jpg',
    buttonLabel: 'Commencer !',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  ÉCRAN ONBOARDING PLEIN ÉCRAN (ADAPTÉ À TOUTE LA FENÊTRE)
// ─────────────────────────────────────────────────────────────────────────────

/// Onboarding desktop pleine fenêtre :
/// S'adapte à toute la taille de l'écran (zéro boîte étriquée au centre).
/// • Gauche : illustration 2D officielle cartoon Archlord & Uni occupant la hauteur
/// • Droite : grand titre épuré (style « Say hello! »), description, bouton pilule et dots
/// • Zéro dialogue ni bulle de texte
class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onFinished;
  const OnboardingScreen({super.key, this.onFinished});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _page = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prefs.onboardingDone', true);
    if (!mounted) return;
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _next() {
    if (_page < _kPages.length - 1) {
      setState(() {
        _page++;
      });
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_page > 0) {
      setState(() {
        _page--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _kPages[_page];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final isNarrow = w < 850;

            return Stack(
              children: [
                // ── Barre supérieure pleine largeur avec logo bien visible ──
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 84,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (w * 0.05).clamp(24.0, 64.0),
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/brand/uniflow_logo_horizontal.png',
                          height: 52,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => const Text(
                            'UniFlow',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_page < _kPages.length - 1)
                          TextButton(
                            onPressed: _finish,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text(
                              'Passer',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Corps principal adapté à toute la fenêtre ─────────────
                Positioned.fill(
                  top: 84,
                  child: isNarrow
                      ? _buildVerticalLayout(page, w, h)
                      : _buildHorizontalLayout(page, w, h),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHorizontalLayout(_OnboardPage page, double w, double h) {
    final titleSize = (w * 0.034).clamp(32.0, 52.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (w * 0.06).clamp(32.0, 80.0),
        vertical: 24,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Moitié gauche : Grande illustration cartoon ───────────────────
          Expanded(
            flex: 5,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Image.asset(
                  page.bgImage,
                  key: ValueKey(page.bgImage),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),

          SizedBox(width: (w * 0.06).clamp(32.0, 72.0)),

          // ── Moitié droite : Titre style « Say hello! », description, CTA ──
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tagline chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    page.tagline,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Grand Titre épuré
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: Text(
                    page.title,
                    key: ValueKey(page.title),
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Sous-titre épuré et lisible
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    child: Text(
                      page.subtitle,
                      key: ValueKey(page.subtitle),
                      style: const TextStyle(
                        fontSize: 16.5,
                        color: Color(0xFF64748B),
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Actions : Boutons de navigation (Précédent / Suivant) + indicateurs
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Bouton Précédent (si on n'est pas sur la première page)
                    if (_page > 0)
                      OutlinedButton(
                        onPressed: _prev,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(
                            color: Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('← Précédent'),
                      ),

                    // Bouton Pilule principal
                    ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black26,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 15,
                        ),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      child: Text(page.buttonLabel),
                    ),

                    const SizedBox(width: 10),

                    // Indicateurs de page (dots cliquables)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_kPages.length, (i) {
                        final active = i == _page;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _page = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(right: 8),
                              width: active ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLayout(_OnboardPage page, double w, double h) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              height: (h * 0.42).clamp(180.0, 320.0),
              child: Image.asset(
                page.bgImage,
                key: ValueKey(page.bgImage),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              page.tagline,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            page.subtitle,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              if (_page > 0) ...[
                OutlinedButton(
                  onPressed: _prev,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('←'),
                ),
                const SizedBox(width: 10),
              ],
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 14,
                  ),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(page.buttonLabel),
              ),
              const Spacer(),
              Row(
                children: List.generate(_kPages.length, (i) {
                  final active = i == _page;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _page = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
