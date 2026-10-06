import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../theme/app_theme.dart';
import 'uni_icons.dart';
import 'motion.dart';
import 'auth_tone.dart';

export 'auth_tone.dart';

/// Habillage commun des écrans d'authentification (connexion, inscription) :
/// fond « mesh », carte blanche, panneau visuel à gauche et formulaire à
/// droite, ou empilés sur une fenêtre étroite.
///
/// Extrait de l'écran de connexion pour que l'inscription ait exactement le
/// même cadre : deux écrans d'entrée qui ne se ressemblent pas donnent
/// l'impression de deux produits.

/// Rouge plus sombre que `AppColors.danger`, réservé au **texte** posé sur un
/// fond rouge très clair : le rouge d'alerte manque de contraste en lecture.
const Color kDangerInk = Color(0xFFB91C1C);

/// Au-dessous de cette largeur, une seule colonne : bandeau de marque compact
/// en haut, formulaire dessous. Au-dessus, deux colonnes plein écran comme le
/// web (`lg:` de Tailwind ≈ 1024 ; 900 ici parce qu'une fenêtre desktop
/// « moitié d'écran » fait souvent 960).
const double kAuthTwoColumnBreakpoint = 900;

/// Paliers d'échelle des écrans d'authentification.
///
/// Sur une fenêtre 1024×576, la connexion était une carte figée de ~570×320
/// au milieu d'un grand vide, avec des textes de taille « téléphone » ; en
/// plein écran 4K, la même carte. Les marges, titres, champs et boutons
/// suivent désormais la largeur de la fenêtre par paliers.
class AuthScale {
  /// Marge autour du formulaire.
  final double padding;

  /// Taille du titre principal (« Se connecter »).
  final double title;

  /// Taille du texte courant.
  final double body;

  /// Hauteur des champs et du bouton principal.
  final double field;

  /// Facteur appliqué au texte du formulaire (via `MediaQuery.textScaler`).
  final double textFactor;

  const AuthScale._({
    required this.padding,
    required this.title,
    required this.body,
    required this.field,
    required this.textFactor,
  });

  static const compact =
      AuthScale._(padding: 24, title: 24, body: 14, field: 48, textFactor: 1.0);
  static const regular = AuthScale._(
      padding: 40, title: 30, body: 15, field: 50, textFactor: 1.06);
  static const large = AuthScale._(
      padding: 52, title: 34, body: 16, field: 52, textFactor: 1.14);
  static const huge = AuthScale._(
      padding: 64, title: 40, body: 17, field: 56, textFactor: 1.26);

  /// Palier pour une largeur de fenêtre : < 900, 900–1400, 1400–1900, ≥ 1900
  /// (écrans 4K).
  static AuthScale forWidth(double width) {
    if (width < kAuthTwoColumnBreakpoint) return compact;
    if (width < 1400) return regular;
    if (width < 1900) return large;
    return huge;
  }

  /// Largeur du formulaire : ~40 % de la fenêtre, bornée [360, 560], sans
  /// dépasser 90 % de la colonne qui l'accueille.
  static double formWidth(double windowWidth, double columnWidth) {
    final target = (windowWidth * 0.4).clamp(360.0, 560.0);
    return target.clamp(0.0, columnWidth * 0.9).clamp(0.0, 560.0);
  }

  static AuthScale of(BuildContext context) =>
      _AuthScaleScope.of(context)?.scale ??
      forWidth(MediaQuery.sizeOf(context).width);
}

class _AuthScaleScope extends InheritedWidget {
  final AuthScale scale;
  const _AuthScaleScope({required this.scale, required super.child});

  static _AuthScaleScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AuthScaleScope>();

  @override
  bool updateShouldNotify(_AuthScaleScope oldWidget) =>
      oldWidget.scale != scale;
}

/// Habillage plein écran des écrans d'authentification.
///
/// Deux colonnes dès [kAuthTwoColumnBreakpoint] : panneau de marque à gauche
/// (45 %, dégradé indigo → teal, logo, accroche, trois arguments,
/// illustration), formulaire à droite (55 %) sur fond clair, centré, largeur
/// [AuthScale.formWidth]. En dessous : bandeau compact puis formulaire pleine
/// largeur avec 24 px de marge. Le formulaire défile toujours : jamais de
/// débordement sur une petite fenêtre.
class AuthShell extends StatelessWidget {
  final Widget form;

  /// Illustration du volet blanc (connexion ou inscription).
  final AuthArtwork artwork;

  /// Conservés pour compatibilité des appelants ; la largeur est désormais
  /// calculée depuis la fenêtre ([AuthScale.formWidth]).
  final double formWidth;
  final double formWidthWide;

  const AuthShell({
    super.key,
    required this.form,
    this.artwork = AuthArtwork.login,
    this.formWidth = 380,
    this.formWidthWide = 460,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPortalNight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final scale = AuthScale.forWidth(width);
          final twoColumns = width >= kAuthTwoColumnBreakpoint;
          return _AuthScaleScope(
            scale: scale,
            child: twoColumns
                ? _twoColumns(context, constraints, scale)
                : _oneColumn(context, constraints, scale),
          );
        },
      ),
    );
  }

  /// Maquette « portail universitaire » : une carte flottante aux coins très
  /// arrondis sur un fond bleu nuit parsemé de bulles. Dans la carte, un volet
  /// blanc à bord ondulé (logo, illustration Archlord + Uni, mentions) déborde
  /// sur le panneau bleu qui porte le formulaire en texte clair.
  Widget _twoColumns(
      BuildContext context, BoxConstraints constraints, AuthScale scale) {
    final margin = (constraints.maxWidth * 0.045).clamp(20.0, 72.0);
    final vMargin = (constraints.maxHeight * 0.06).clamp(16.0, 64.0);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1A44), _kPortalNight, Color(0xFF0B3A4A)],
          stops: [0.0, 0.55, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _PortalBubbles()),
          Center(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: margin, vertical: vMargin),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 1360, maxHeight: 880),
                child: CascadeIn(
                  index: 0,
                  offset: const Offset(0, 0.03),
                  child: _PortalCard(
                    form: form,
                    scale: scale,
                    artwork: artwork,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _oneColumn(
      BuildContext context, BoxConstraints constraints, AuthScale scale) {
    // Le bandeau garde une hauteur bornée pour laisser le formulaire respirer
    // même sur 800×600 ; le tout défile d'un bloc.
    final bannerHeight = (constraints.maxHeight * 0.26).clamp(120.0, 180.0);
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: bannerHeight,
            width: double.infinity,
            child: CascadeIn(
              index: 0,
              offset: const Offset(0, -0.05),
              child: AuthHeroPanel(scale: scale, compact: true),
            ),
          ),
          _FormColumn(
            form: form,
            scale: scale,
            columnWidth: constraints.maxWidth,
            windowWidth: constraints.maxWidth,
            minHeight: constraints.maxHeight - bannerHeight,
            scrollable: false,
          ),
        ],
      ),
    );
  }
}

/// Illustration affichée dans le volet blanc des écrans d'authentification.
enum AuthArtwork { login, register }

/// Fond de page des écrans d'authentification (bleu nuit UniFlow).
const Color _kPortalNight = Color(0xFF0F2557);

/// Panneau bleu de la carte, derrière le formulaire.
const LinearGradient _kPortalPanel = LinearGradient(
  colors: [Color(0xFF1E3A8A), Color(0xFF172F72), Color(0xFF123B66)],
  stops: [0.0, 0.6, 1.0],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Bulles translucides du fond de page, placées en fractions de la fenêtre
/// pour suivre le redimensionnement.
class _PortalBubbles extends StatelessWidget {
  const _PortalBubbles();

  static const _bubbles = <(double, double, double, double)>[
    // (x, y, diamètre, opacité)
    (0.04, 0.10, 46, 0.07),
    (0.16, 0.03, 90, 0.05),
    (0.30, 0.90, 70, 0.06),
    (0.62, 0.04, 34, 0.08),
    (0.86, 0.12, 120, 0.04),
    (0.93, 0.78, 84, 0.06),
    (0.72, 0.95, 40, 0.08),
    (0.02, 0.70, 140, 0.04),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      return Stack(
        children: [
          for (final (x, y, d, o) in _bubbles)
            Positioned(
              left: c.maxWidth * x - d / 2,
              top: c.maxHeight * y - d / 2,
              child: Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: o),
                ),
              ),
            ),
        ],
      );
    });
  }
}

/// La carte : panneau bleu (formulaire, à droite) et volet blanc ondulé
/// (illustration, à gauche) qui le chevauche.
class _PortalCard extends StatelessWidget {
  final Widget form;
  final AuthScale scale;
  final AuthArtwork artwork;

  const _PortalCard({
    required this.form,
    required this.scale,
    required this.artwork,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: _kPortalPanel,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final whiteWidth = w * 0.58;
        final formWidth = w * 0.42;
        return Stack(
          children: [
            // Halos discrets sur le panneau bleu.
            Positioned(
              right: -60,
              top: -60,
              child: _Blob(
                  size: 220, color: Colors.white.withValues(alpha: 0.05)),
            ),
            Positioned(
              right: formWidth * 0.55,
              bottom: -40,
              child: _Blob(
                  size: 120, color: AppColors.tealLight.withValues(alpha: 0.10)),
            ),
            // ── Formulaire ────────────────────────────────────────────────
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: formWidth,
              child: _FormColumn(
                form: form,
                scale: scale,
                columnWidth: formWidth,
                windowWidth: w,
                minHeight: h,
                dark: true,
              ),
            ),
            Positioned(
              right: 28,
              bottom: 18,
              child: Text(
                'Besoin d’aide ? Contactez votre établissement.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
            // ── Volet blanc ondulé ────────────────────────────────────────
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: whiteWidth,
              child: ClipPath(
                clipper: const _PortalWaveClipper(),
                child: ColoredBox(
                  color: Colors.white,
                  child: _ArtworkPanel(
                    artwork: artwork,
                    contentWidth: whiteWidth * 0.78,
                    showMascots: h >= 560,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Bord droit ondulé du volet blanc : courbe douce et généreuse
/// qui enveloppe parfaitement les mascottes sans jamais rogner Uni.
class _PortalWaveClipper extends CustomClipper<Path> {
  const _PortalWaveClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.84, 0)
      ..cubicTo(w * 0.95, h * 0.08, w * 0.89, h * 0.28, w * 0.97, h * 0.45)
      ..cubicTo(w * 1.03, h * 0.60, w * 1.01, h * 0.78, w * 0.92, h * 0.90)
      ..cubicTo(w * 0.87, h * 0.96, w * 0.83, h, w * 0.80, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Contenu du volet blanc : logo, illustration sur taches teal, mentions.
class _ArtworkPanel extends StatelessWidget {
  final AuthArtwork artwork;
  final double contentWidth;
  final bool showMascots;

  const _ArtworkPanel({
    required this.artwork,
    required this.contentWidth,
    this.showMascots = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLogin = artwork == AuthArtwork.login;
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 30, 24, 22),
      child: SizedBox(
        width: contentWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/brand/uniflow_logo_horizontal.png',
              height: 34,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/brand/uniflow-wordmark.png',
                height: 34,
                errorBuilder: (_, __, ___) => const Text(
                  'UniFlow',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (showMascots)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _ArtworkScene(isLogin: isLogin),
                  ),
                ),
              )
            else
              const Spacer(),
            Text(
              isLogin
                  ? 'Archlord et Uni vous attendent sur votre campus.'
                  : 'Rejoignez Archlord et Uni sur UniFlow.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '© ${DateTime.now().year} UniFlow · KERNEL FORGE\n'
              'Plateforme universitaire, même hors ligne.',
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scène d'accueil : Archlord et Uni font un fistbump, sur fond de bulles pastel,
/// parfaitement centrés dans l'espace blanc visible.
class _ArtworkScene extends StatelessWidget {
  final bool isLogin;
  const _ArtworkScene({required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Bulles pastel décoratives en arrière-plan harmonisées
        Positioned(
          top: 10,
          right: 48,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 14,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          right: 64,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Illustration officielle exacte : rééquilibrée vers la gauche
        // pour que Archlord et Uni soient harmonieusement centrés dans la zone blanche
        Align(
          alignment: const Alignment(-0.25, 0.0),
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 36),
            child: Image.asset(
              'assets/mascot/archlord_uni_fistbump.webp',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/illustrations/archlord_uni_duo_solid.webp',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/brand/uniflow_marque.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Colonne qui centre le formulaire, le borne en largeur et le fait
/// défiler. Le texte du formulaire est mis à l'échelle du palier courant via
/// `MediaQuery.textScaler`, de sorte que titres, libellés et boutons
/// grandissent ensemble sans toucher chaque widget.
///
/// `dark` : le formulaire est posé sur le panneau bleu de la carte ; les
/// champs passent en palette sombre via [AuthTone].
class _FormColumn extends StatelessWidget {
  final Widget form;
  final AuthScale scale;
  final double columnWidth;
  final double windowWidth;
  final double minHeight;
  final bool scrollable;
  final bool dark;

  const _FormColumn({
    required this.form,
    required this.scale,
    required this.columnWidth,
    required this.windowWidth,
    required this.minHeight,
    this.scrollable = true,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = dark
        ? (columnWidth * 0.78).clamp(280.0, 420.0)
        : AuthScale.formWidth(windowWidth, columnWidth);
    final palette = dark ? AuthPalette.darkPanel : AuthPalette.light;
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dark ? 24 : scale.padding,
            vertical: dark ? 40 : scale.padding,
          ),
          child: SizedBox(
            key: const Key('auth-form'),
            width: width,
            child: CascadeIn(
              index: 1,
              offset: const Offset(0, 0.04),
              child: MediaQuery(
                data: media.copyWith(
                  // Borné : l'agrandissement système reste respecté mais ne
                  // se cumule pas sans limite avec le palier.
                  textScaler: TextScaler.linear(
                    (media.textScaler.scale(1) * scale.textFactor)
                        .clamp(0.9, 1.6),
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    inputDecorationTheme:
                        Theme.of(context).inputDecorationTheme.copyWith(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical:
                                    ((scale.field - 20) / 2).clamp(12.0, 20.0),
                              ),
                            ),
                    checkboxTheme: dark
                        ? CheckboxThemeData(
                            side: BorderSide(color: palette.muted, width: 1.4),
                            fillColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? AppColors.tealLight
                                  : Colors.transparent,
                            ),
                          )
                        : null,
                    dividerColor: palette.divider,
                  ),
                  child: AuthTone(
                    palette: palette,
                    child:
                        Material(type: MaterialType.transparency, child: form),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final body = scrollable ? SingleChildScrollView(child: content) : content;
    if (dark) return body;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Colors.white, Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: body,
    );
  }
}

/// Arguments affichés sur le panneau de marque — les trois du web
/// (`LoginPage.tsx`), pour que les deux clients racontent la même chose.
final List<({IconData icon, String title, String desc, Color color})>
    kAuthFeatures = [
  (
    icon: UniIcons.students(UniIcons.defaultStyle),
    title: 'Gestion académique complète',
    desc:
        'Cours, devoirs, notes et emploi du temps centralisés en un seul endroit.',
    color: const Color(0xFF34D399),
  ),
  (
    icon: UniIcons.online(UniIcons.defaultStyle),
    title: 'Accès résilient',
    desc:
        'Les données consultées restent disponibles ; les opérations sensibles exigent une session active.',
    color: const Color(0xFF60A5FA),
  ),
  (
    icon: UniIcons.security(UniIcons.defaultStyle),
    title: 'Rôles contrôlés',
    desc:
        'La session Appwrite et les permissions par rôle encadrent chaque accès.',
    color: const Color(0xFFC084FC),
  ),
];

/// Panneau de marque — style référence : fond dégradé navy → teal avec blob
/// blanc organique contenant mascotte + logo. Inspiré du design université
/// avec forme blob blanche flottant sur fond sombre.
///
/// Deux variantes :
/// - `compact: false` (défaut) : deux colonnes — blob central plein écran
/// - `compact: true` : bandeau horizontal étroit (vue < 900 px)
class AuthHeroPanel extends StatelessWidget {
  final bool compact;
  final AuthScale scale;
  const AuthHeroPanel(
      {super.key, this.compact = false, this.scale = AuthScale.regular});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.authHeroGradient),
      child: ClipRect(
        child: Stack(
          children: [
            // Halos décoratifs arrière-plan
            Positioned(
                top: -80,
                left: -60,
                child: _Blob(
                    size: compact ? 200 : 360,
                    color: Colors.white.withValues(alpha: 0.07))),
            Positioned(
                bottom: -100,
                right: -80,
                child: _Blob(
                    size: compact ? 220 : 320,
                    color: Colors.white.withValues(alpha: 0.05))),
            // Petits cercles décoratifs
            if (!compact) ...[
              Positioned(
                  top: 60, right: 30,
                  child: _Blob(size: 40, color: Colors.white.withValues(alpha: 0.12))),
              Positioned(
                  bottom: 80, left: 20,
                  child: _Blob(size: 24, color: Colors.white.withValues(alpha: 0.15))),
              Positioned(
                  top: 200, left: 10,
                  child: _Blob(size: 16, color: Colors.white.withValues(alpha: 0.20))),
            ],
            Positioned.fill(
              child: compact
                  ? _compactBanner()
                  : _fullPanel(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactBanner() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Logo sur fond blanc arrondi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Image.asset(
                'assets/brand/uniflow-wordmark.png',
                height: 28,
                filterQuality: FilterQuality.high,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'UniFlow',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue sur UniFlow',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h1
                        .copyWith(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'La plateforme universitaire qui fonctionne partout, même sans Internet.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.88)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _fullPanel(BuildContext context) {
    final pad = scale.padding;
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final showFeatures = h >= 680;
        // Largeur du blob blanc : environ 75% de la colonne, borné
        final blobW = (w * 0.80).clamp(260.0, 440.0);
        final blobH = (h * 0.55).clamp(240.0, 380.0);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad * 0.7),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: h - pad * 1.4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Blob blanc central avec mascotte + logo ────────────────
                Center(
                  child: Container(
                    width: blobW,
                    height: blobH,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 36,
                          offset: const Offset(0, 14),
                        ),
                        BoxShadow(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.16),
                          blurRadius: 20,
                          offset: const Offset(-6, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/auth/login_hero.webp',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/mascot/archlord_uni_duo_solid.webp',
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Logo UniFlow officiel en haut à gauche
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/brand/uniflow_logo_horizontal.png',
                              height: 20,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Text(
                                'UniFlow',
                                style: TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: pad * 0.6),

                // ── Titre + sous-titre sous le blob ───────────────────────
                Text(
                  'Bienvenue sur UniFlow',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontSize: scale.title + 2,
                      height: 1.15),
                ),
                const SizedBox(height: 8),
                Text(
                  'La plateforme universitaire intelligente\nqui fonctionne partout, même sans Internet.',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: scale.body,
                      height: 1.5,
                      color: const Color(0xFFDBEAFE)),
                ),

                // ── Arguments en bas ─────────────────────────────────────
                if (showFeatures) ...[
                  SizedBox(height: pad * 0.7),
                  for (var i = 0; i < kAuthFeatures.length; i++) ...[
                    CascadeIn(
                        index: 2 + i,
                        child: _FeatureCard(
                            feature: kAuthFeatures[i], scale: scale)),
                    if (i < kAuthFeatures.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Carte d'argument translucide (`bg-white/10`, bordure `white/20`), qui se
/// décale de 6 px au survol comme sur le web.
class _FeatureCard extends StatefulWidget {
  final ({IconData icon, String title, String desc, Color color}) feature;
  final AuthScale scale;
  const _FeatureCard({required this.feature, required this.scale});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(_hover ? 6 : 0, 0, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _hover ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PhosphorIcon(f.icon, size: 22, color: f.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: widget.scale.body + 0.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    f.desc,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: widget.scale.body - 1.5,
                        height: 1.4,
                        color: const Color(0xFFDBEAFE)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton principal en dégradé bleu → teal. `ElevatedButton` ne sait pas
/// peindre un dégradé, et c'est ce dégradé qui rattache l'écran à la charte.
class GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    this.isLoading = false,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final dark = AuthTone.of(context).dark;
    // Sur le panneau bleu nuit, le bouton est une pilule teal (maquette) ;
    // sur fond clair, le dégradé bleu → teal de la charte.
    final radius = BorderRadius.circular(dark ? 999 : AppTheme.radiusCard);
    final gradient = dark
        ? const LinearGradient(
            colors: [Color(0xFF14B8A8), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : AppColors.logoGradient;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: disabled ? null : gradient,
        color: disabled
            ? (dark ? const Color(0x33FFFFFF) : AppColors.inputBorder)
            : null,
        borderRadius: radius,
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: (dark ? AppColors.teal : AppColors.primaryBlue)
                      .withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: SizedBox(
            height: AuthScale.of(context).field,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          PhosphorIcon(icon!, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.button,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Encadré rouge d'erreur. Un texte rouge isolé se confond avec le formulaire.
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final dark = AuthTone.of(context).dark;
    return CascadeIn(
      index: 0,
      offset: const Offset(0, -0.1),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: dark ? 0.16 : 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PhosphorIcon(UniIcons.warningCircle(UniIconStyle.bold),
                size: 18, color: AppColors.danger),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: dark ? const Color(0xFFFECACA) : kDangerInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Choix « Compte universitaire / Compte indépendant », deux cartes.
///
/// Le type de compte décide de tout le reste (cursus ou espace personnel),
/// il vient donc en premier, avant même l'email.
class AccountTypeSelector extends StatelessWidget {
  final AccountType value;
  final ValueChanged<AccountType> onChanged;

  const AccountTypeSelector(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Pas de `LayoutBuilder` ici : la colonne du formulaire vit dans un
    // `IntrinsicHeight` (pour égaliser panneau et formulaire), qui ne sait pas
    // mesurer un `LayoutBuilder`. Les deux cartes se partagent la largeur et
    // tronquent leur texte si elle manque.
    return Row(
      children: [
        Expanded(
          child: _TypeCard(
            selected: value == AccountType.university,
            icon: UniIcons.university(UniIconStyle.bold),
            title: 'Universitaire',
            subtitle: 'Rattaché à un établissement',
            onTap: () => onChanged(AccountType.university),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TypeCard(
            selected: value == AccountType.personal,
            icon: UniIcons.person(UniIconStyle.bold),
            title: 'Indépendant',
            subtitle: 'Espace personnel libre',
            onTap: () => onChanged(AccountType.personal),
          ),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AuthTone.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? p.selectedFill : p.fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? p.selectedBorder : p.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            PhosphorIcon(icon,
                size: 22, color: selected ? p.selectedText : p.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? p.selectedText : p.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: p.textSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste déroulante habillée comme les champs `AppTextField`.
class AuthDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String hint;

  const AuthDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Sélectionner',
  });

  @override
  Widget build(BuildContext context) {
    final p = AuthTone.of(context);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(p.fieldRadius),
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: p.label),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          // `initialValue` est l'API des versions récentes de Flutter ; la
          // valeur est resynchronisée par la clé quand elle change de
          // l'extérieur (réinitialisation en cascade).
          key: ValueKey(value),
          initialValue: value,
          isExpanded: true,
          icon: PhosphorIcon(UniIcons.chevronDown(UniIconStyle.bold),
              color: p.muted),
          dropdownColor: p.menu,
          borderRadius: BorderRadius.circular(14),
          style: TextStyle(fontSize: 14, color: p.text),
          hint: Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: p.muted),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: p.fill,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: border(p.border),
            enabledBorder: border(p.border),
            focusedBorder: border(p.focus, 1.5),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(size * 0.4)),
    );
  }
}
