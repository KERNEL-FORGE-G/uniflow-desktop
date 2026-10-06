import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/uni/uni_mascot.dart';
import '../widgets/uni/archlord_mascot.dart';
import '../widgets/uni/mascot_dialogue.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DONNÉES
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardPage {
  final String title;
  final String subtitle;
  final String bgImage;
  final Color accentColor;   // couleur de la sidebar gauche
  final Color buttonColor;   // couleur du bouton Suivant / Commencer
  final UniPose uniPose;
  final ArchlordPose archlordPose;
  final List<DialogueLine> dialogue;
  final String tagline;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.bgImage,
    required this.accentColor,
    required this.buttonColor,
    required this.uniPose,
    required this.archlordPose,
    required this.dialogue,
    required this.tagline,
  });
}

const _kPages = [
  _OnboardPage(
    tagline: 'BIENVENUE',
    title: 'Bienvenue sur\nUniFlow',
    subtitle: 'La plateforme universitaire tout-en-un — cours, présences,\n'
        'notes et communication en un seul endroit.',
    bgImage: 'assets/onboarding/onboarding_desk_1.webp',
    accentColor: Color(0xFF1E3A8A),
    buttonColor: Color(0xFF1E3A8A),
    uniPose: UniPose.wave,
    archlordPose: ArchlordPose.wave,
    dialogue: [
      DialogueLine.archlord(
          'UniFlow est né dans notre propre fac. On a résolu nos propres problèmes.'),
      DialogueLine.uni(
          'Salut ! Moi c\'est Uni. Je suis là pour vous guider tout au long de l\'aventure !'),
      DialogueLine.archlord('On vous prépare un espace de travail sur mesure. Bienvenue !'),
    ],
  ),
  _OnboardPage(
    tagline: 'FONCTIONNALITÉS',
    title: 'Tout ce dont vous\navez besoin',
    subtitle: 'Étudiants, enseignants, programmes et salles.\n'
        'Présences QR code, devoirs, notes et bulletins automatisés.',
    bgImage: 'assets/onboarding/onboarding_desk_2.webp',
    accentColor: Color(0xFF0D9488),
    buttonColor: Color(0xFF0D9488),
    uniPose: UniPose.celebrate,
    archlordPose: ArchlordPose.explain,
    dialogue: [
      DialogueLine.uni('Multi-rôles, offline-first, et toujours synchronisé !'),
      DialogueLine.archlord(
          'Gestion de présences en QR code, notes en temps réel, bulletins auto…'),
      DialogueLine.uni(
          'Et tout fonctionne même sans Internet — on a pensé à tout !'),
    ],
  ),
  _OnboardPage(
    tagline: 'PRÊT ?',
    title: 'Transformez\nvotre campus',
    subtitle: 'Connectez-vous avec votre compte universitaire ou créez un\n'
        'espace indépendant. UniFlow fonctionne même sans Internet.',
    bgImage: 'assets/onboarding/onboarding_desk_3.webp',
    accentColor: Color(0xFF7C3AED),
    buttonColor: Color(0xFF7C3AED),
    uniPose: UniPose.pointing,
    archlordPose: ArchlordPose.thumbs,
    dialogue: [
      DialogueLine.archlord(
          'KERNEL FORGE — UniFlow est notre premier produit, pas le dernier.'),
      DialogueLine.uni(
          'Cliquez sur Commencer — je serai toujours là si vous avez besoin !'),
      DialogueLine.archlord('Vos retours font le produit. On construit ça ensemble.'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  ÉCRAN PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────

/// Onboarding desktop — layout deux colonnes :
/// • Colonne gauche (40%) : card colorée avec tagline, titre, description,
///   dialogue mascotte et bouton Suivant/Commencer.
/// • Colonne droite (60%) : image plein cadre avec fondu doux.
///
/// Thème : card solide colorée — zéro glassmorphism, zéro blur.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Callback appelé quand l'utilisateur termine ou passe l'onboarding.
  /// Si null, on fait un pop() de la navigation.
  final VoidCallback? onFinished;
  const OnboardingScreen({super.key, this.onFinished});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prefs.onboardingDone', true);
    if (!mounted) return;
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _next() {
    if (_page < _kPages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _kPages[_page];
    return Scaffold(
      backgroundColor: page.accentColor,
      body: Row(
        children: [
          // ── Colonne gauche : card solide ──────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: 420,
            color: page.accentColor,
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + bouton Passer
                Row(
                  children: [
                    Image.asset(
                      'assets/brand/uniflow_logo_horizontal.png',
                      height: 28,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                      errorBuilder: (_, __, ___) => const Text(
                        'UniFlow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_page < _kPages.length - 1)
                      TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.20),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Passer',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),

                const Spacer(),

                // Tag pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    page.tagline,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Titre
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    page.title,
                    key: ValueKey(page.title),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sous-titre
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    page.subtitle,
                    key: ValueKey(page.subtitle),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Dialogue mascotte
                if (page.dialogue.isNotEmpty)
                  MascotDialogue(
                    lines: page.dialogue,
                    uniPose: page.uniPose,
                    archlordPose: page.archlordPose,
                    figureHeight: 120,
                    interval: const Duration(milliseconds: 4000),
                  ),

                const Spacer(),

                // Dots + bouton
                Row(
                  children: [
                    // Dots cliquables
                    Row(
                      children: List.generate(_kPages.length, (i) {
                        final active = i == _page;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              _controller.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 380),
                                curve: Curves.easeInOutCubic,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              margin: const EdgeInsets.only(right: 6),
                              width: active ? 24.0 : 7.0,
                              height: 7,
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.40),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    // Bouton blanc arrondi
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _next,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _page < _kPages.length - 1 ? 'Suivant →' : 'Commencer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: page.accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Colonne droite : image ────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _kPages.length,
              physics: const PageScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _ImagePane(page: _kPages[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  VOLET IMAGE
// ─────────────────────────────────────────────────────────────────────────────

class _ImagePane extends StatelessWidget {
  final _OnboardPage page;
  const _ImagePane({required this.page});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image principale
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Image.asset(
            page.bgImage,
            key: ValueKey(page.bgImage),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, error, __) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      page.accentColor,
                      page.accentColor.withValues(alpha: 0.7),
                      const Color(0xFF0F172A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/mascot/archlord_uni_duo_solid.webp',
                    width: 320,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              );
            },
          ),
        ),
        // Fondu gauche pour se fondre avec la card
        Positioned(
          left: 0, top: 0, bottom: 0, width: 80,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  page.accentColor,
                  page.accentColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
