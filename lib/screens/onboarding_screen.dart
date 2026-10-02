import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/uni/uni_mascot.dart';
import '../widgets/uni/archlord_mascot.dart';
import '../widgets/uni/mascot_dialogue.dart';

/// Écran d'onboarding affiché uniquement au premier lancement (desktop).
///
/// 3 pages — chacune avec Archlord + Uni en bas qui échangent des répliques
/// contextuelles. Le dialogue avance automatiquement toutes les 3,5 s et
/// au clic.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  int _page = 0;
  late final AnimationController _anim;

  static const _pages = [
    _OnboardPage(
      title: 'Bienvenue sur UniFlow',
      subtitle:
          'La plateforme universitaire tout-en-un — cours, présences, notes '
          'et communication en un seul endroit.',
      uniPose: UniPose.wave,
      archlordPose: ArchlordPose.wave,
      dialogue: [
        DialogueLine.archlord('UniFlow est né dans notre propre fac. On a résolu nos propres problèmes.'),
        DialogueLine.uni('Salut ! Moi c\'est Uni. Je suis là pour vous guider tout au long de l\'aventure !'),
        DialogueLine.archlord('On vous prépare un espace de travail sur mesure. Bienvenue !'),
      ],
      gradient: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    _OnboardPage(
      title: 'Tout ce dont vous avez besoin',
      subtitle:
          'Étudiants, enseignants, programmes et salles. Présences QR code, '
          'devoirs, notes et bulletins automatisés.',
      uniPose: UniPose.celebrate,
      archlordPose: ArchlordPose.explain,
      dialogue: [
        DialogueLine.uni('Multi-rôles, offline-first, et toujours synchronisé !'),
        DialogueLine.archlord('Gestion de présences en QR code, notes en temps réel, bulletins auto…'),
        DialogueLine.uni('Et tout fonctionne même sans Internet — on a pensé à tout !'),
      ],
      gradient: [Color(0xFF1D4ED8), Color(0xFF0891B2), Color(0xFF0D9488)],
    ),
    _OnboardPage(
      title: 'Prêt à transformer votre campus ?',
      subtitle:
          'Connectez-vous avec votre compte universitaire ou créez un espace '
          'indépendant. UniFlow fonctionne même sans Internet.',
      uniPose: UniPose.pointing,
      archlordPose: ArchlordPose.thumbs,
      dialogue: [
        DialogueLine.archlord('KERNEL FORGE — UniFlow est notre premier produit, pas le dernier.'),
        DialogueLine.uni('Cliquez sur Commencer — je serai toujours là si vous avez besoin !'),
        DialogueLine.archlord('Vos retours font le produit. On construit ça ensemble.'),
      ],
      gradient: [Color(0xFF0D9488), Color(0xFF0F766E), Color(0xFF134E4A)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim.forward();
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
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  @override
  Widget build(BuildContext context) {
    final page = _pages[_page];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.gradient,
          ),
        ),
        child: Stack(
          children: [
            // Cercles décoratifs fond
            Positioned(
              top: -120,
              right: -120,
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Contenu principal
            Column(
              children: [
                // Bouton Skip
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _page < _pages.length - 1
                        ? TextButton(
                            onPressed: _skip,
                            child: Text(
                              'Passer',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : const SizedBox(height: 44),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      final p = _pages[i];
                      return _PageContent(page: p);
                    },
                  ),
                ),

                // Bas : dots + bouton
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: i == _page
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bouton principal
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E3A8A),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _page < _pages.length - 1 ? 'Suivant' : 'Commencer',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
//  PAGE CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});
  final _OnboardPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Titre
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Sous-titre
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),

          // ── Dialogue Archlord + Uni ──────────────────────────────────
          if (page.dialogue.isNotEmpty)
            MascotDialogue(
              lines: page.dialogue,
              uniPose: page.uniPose,
              archlordPose: page.archlordPose,
              figureHeight: 140,
              interval: const Duration(milliseconds: 3500),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MODÈLE
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardPage {
  final String title;
  final String subtitle;
  final UniPose uniPose;
  final ArchlordPose archlordPose;
  final List<DialogueLine> dialogue;
  final List<Color> gradient;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.uniPose,
    required this.archlordPose,
    required this.dialogue,
    required this.gradient,
  });
}
