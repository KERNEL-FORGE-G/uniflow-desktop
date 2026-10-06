import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_destination.dart';
import '../models/appwrite_models.dart';
import '../models/dashboard_models.dart';
import '../models/dashboard_overview.dart';
import '../models/user_role.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/badges_provider.dart';
import '../providers/directory_provider.dart';
import '../providers/navigation_provider.dart';
import '../repositories/academic_repository.dart';
import '../router/route_guard.dart';
import '../theme/app_theme.dart';
import '../utils/french_date.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/dashboard_badges_section.dart';
import '../widgets/data_state_view.dart';
import '../widgets/gamification_widgets.dart';
import '../widgets/stat_card.dart';
import '../widgets/uni_icons.dart';

/// Chiffres du tableau de bord d'un apprenant ou d'un enseignant, dans son
/// périmètre. L'administration ne s'en sert pas : elle a ses compteurs
/// globaux ([dashboardStatsProvider]) et ses graphiques.
final dashboardOverviewProvider =
    FutureProvider<DashboardOverview>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return DashboardOverview.empty;
  final repository = ref.watch(academicRepositoryProvider);
  final (courses, assignments, grades, attendance, students) = await (
    ref.watch(scopedCoursesProvider.future),
    repository.getAssignments(),
    repository.getAllGrades(),
    ref.watch(studentAttendanceProvider.future),
    ref.watch(studentsProvider.future),
  ).wait;
  return DashboardOverview.compute(
    role: user.userRole,
    userId: user.id,
    courses: courses,
    assignments: assignments,
    grades: grades,
    attendance: attendance,
    studentCount: students.length,
  );
});

final dashboardStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  // Recalculé à chaque changement de compte : les caches du compte précédent
  // survivaient à la déconnexion.
  ref.watch(currentUserProvider.select((u) => u?.id));
  return ref.read(academicRepositoryProvider).getGlobalStats();
});

/// Inscriptions des 6 derniers mois, comptées depuis `academic_enrollments`.
final dashboardEnrollmentsProvider =
    FutureProvider<List<MonthlyCount>>((ref) async {
  // Recalculé à chaque changement de compte : les caches du compte précédent
  // survivaient à la déconnexion.
  ref.watch(currentUserProvider.select((u) => u?.id));
  return ref.read(academicRepositoryProvider).getEnrollmentsByMonth();
});

/// Répartition des présences. `null` = pas de données exploitables, ce que la
/// carte distingue explicitement d'un taux nul.
final dashboardAttendanceProvider =
    FutureProvider<AttendanceBreakdown?>((ref) async {
  // Recalculé à chaque changement de compte : les caches du compte précédent
  // survivaient à la déconnexion.
  ref.watch(currentUserProvider.select((u) => u?.id));
  return ref.read(academicRepositoryProvider).getAttendanceBreakdown();
});

/// Derniers documents créés, toutes collections confondues.
final dashboardActivityProvider =
    FutureProvider<List<ActivityEntry>>((ref) async {
  // Recalculé à chaque changement de compte : les caches du compte précédent
  // survivaient à la déconnexion.
  ref.watch(currentUserProvider.select((u) => u?.id));
  return ref.read(academicRepositoryProvider).getRecentActivity();
});

/// Tableau de bord, par rôle.
///
/// Même contenu que le web pour le même compte : l'administration voit les
/// compteurs de l'établissement, les inscriptions et les présences
/// (`AdminDashboardPage.tsx`) ; un apprenant ou un enseignant voit **ses**
/// cours, devoirs, notes et présences (`DashboardPage.tsx`). Le desktop
/// affichait auparavant les compteurs d'administration à tout le monde, y
/// compris à un étudiant, qui découvrait ainsi les effectifs de tout
/// l'établissement.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// Raccourcis proposés sous les indicateurs, par rôle. Filtrés ensuite par
  /// la garde de navigation pour qu'un compte personnel ne voie jamais un
  /// écran d'établissement.
  static const Map<UserRole, List<AppDestination>> quickActions = {
    UserRole.student: [
      AppDestination.schedule,
      AppDestination.assignments,
      AppDestination.grades,
      AppDestination.library,
    ],
    UserRole.delegate: [
      AppDestination.schedule,
      AppDestination.attendance,
      AppDestination.assignments,
      AppDestination.students,
    ],
    UserRole.teacher: [
      AppDestination.schedule,
      AppDestination.attendance,
      AppDestination.assignments,
      AppDestination.grades,
    ],
    UserRole.admin: [
      AppDestination.accounts,
      AppDestination.teachers,
      AppDestination.schedule,
      AppDestination.statistics,
    ],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final role = ref.watch(currentRoleProvider);
    final accountType = ref.watch(currentAccountTypeProvider);

    final actions = [
      for (final destination in quickActions[role] ?? const <AppDestination>[])
        if (canAccess(destination, role: role, accountType: accountType))
          destination,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DashboardHeader(user: user, role: role),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl,
                AppSpacing.xxl, AppSpacing.uniClearance),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1020;

                if (!role.isAdmin && isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Colonne principale (gauche, 64%) ───────────────
                      Expanded(
                        flex: 64,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DesktopHeroBanner(user: user, role: role),
                            const SizedBox(height: AppSpacing.lg),
                            _RoleStats(role: role),
                            const SizedBox(height: AppSpacing.lg),
                            const _CoursesSectionModern(),
                            if (actions.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.lg),
                              _QuickActions(destinations: actions),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      // ── Colonne latérale (droite, 36%) ────────────────
                      Expanded(
                        flex: 36,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            QuestSummaryWidget(
                              onViewAll: () => ref.read(currentDestinationProvider.notifier).state = AppDestination.quests,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DailyReminderCard(
                              onViewSchedule: () => ref.read(currentDestinationProvider.notifier).state = AppDestination.schedule,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            BadgeHighlightWidget(
                              onSeeAll: () => ref.read(currentDestinationProvider.notifier).state = AppDestination.badges,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const _BadgesSection(),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DesktopHeroBanner(user: user, role: role),
                    const SizedBox(height: AppSpacing.lg),
                    if (role.isAdmin)
                      const _AdminStats()
                    else
                      _RoleStats(role: role),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _QuickActions(destinations: actions),
                    ],
                    if (!role.isAdmin) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const _CoursesSectionModern(),
                      const SizedBox(height: AppSpacing.lg),
                      QuestSummaryWidget(
                        onViewAll: () => ref.read(currentDestinationProvider.notifier).state = AppDestination.quests,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DailyReminderCard(
                        onViewSchedule: () => ref.read(currentDestinationProvider.notifier).state = AppDestination.schedule,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      BadgeHighlightWidget(
                        onSeeAll: () => ref.read(currentDestinationProvider.notifier).state = AppDestination.badges,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _BadgesSection(),
                    ],
                    if (role.isAdmin) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const _ResponsiveRow(
                        breakpoint: 900,
                        left: _EnrollmentChartCard(),
                        right: _AttendanceDonutCard(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _RecentActivityCard(),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Bannière hero du tableau de bord desktop — style SkillSet.
/// Carte pleine largeur avec dégradé bleu UniFlow, salutation,
/// mascotte Uni à droite.
class _DesktopHeroBanner extends StatelessWidget {
  final UniFlowUser? user;
  final UserRole role;

  const _DesktopHeroBanner({required this.user, required this.role});

  @override
  Widget build(BuildContext context) {
    final firstName = _DashboardHeader.firstNameOf(user?.name);
    final greeting = firstName.isEmpty
        ? 'Bienvenue sur UniFlow'
        : 'Bonjour, $firstName';
    final subtitle = switch (role) {
      UserRole.student => 'Prêt pour vos cours du jour ?',
      UserRole.delegate => 'Votre journée et celle de la classe',
      UserRole.teacher => 'Vos séances et ce qu\'il reste à corriger',
      UserRole.admin => 'Vue d\'ensemble de l\'établissement',
    };

    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2D4FA8), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Cercles décoratifs
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 110,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Texte à gauche
          Positioned(
            left: AppSpacing.xxl,
            top: 0,
            bottom: 0,
            right: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill)),
                    textStyle: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Explorer →'),
                ),
              ],
            ),
          ),
          // Mascotte cartoon Archlord & Uni à droite
          Positioned(
            right: 10,
            bottom: 0,
            child: Image.asset(
              'assets/mascot/archlord_uni_duo_solid.webp',
              height: 155,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/mascot/uni_graduate.webp',
                height: 155,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(width: 155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête : salut, rôle et date du jour, comme l'en-tête du tableau de bord
/// web (« Bonjour, Prénom — Enseignant · lundi 21 septembre 2026 »).
class _DashboardHeader extends ConsumerWidget {
  final UniFlowUser? user;
  final UserRole role;

  const _DashboardHeader({required this.user, required this.role});

  /// Le prénom seul, comme sur le web : « Bonjour, Awa » plutôt que le nom
  /// complet, trop long pour un titre.
  static String firstNameOf(String? fullName) {
    final trimmed = (fullName ?? '').trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final firstName = firstNameOf(user?.name);
    final greeting = greetingFor(now);

    return AppTopBar(
      title: firstName.isEmpty ? greeting : '$greeting, $firstName',
      subtitle: '${role.label} · ${formatLongDate(now)}',
      actions: [
        // Recharge les compteurs : le tableau de bord met en cache ses
        // requêtes tant que le compte ne change pas, et un enseignant qui
        // vient de saisir des notes veut les voir sans se déconnecter.
        TopBarIconButton(
          icon: UniIcons.refresh(UniIconStyle.bold),
          tooltip: 'Actualiser',
          onTap: () {
            ref.invalidate(dashboardOverviewProvider);
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(dashboardEnrollmentsProvider);
            ref.invalidate(dashboardAttendanceProvider);
            ref.invalidate(dashboardActivityProvider);
          },
        ),
      ],
    );
  }
}

/// Compteurs de l'établissement : étudiants, enseignants, cours, sessions.
class _AdminStats extends ConsumerWidget {
  const _AdminStats();

  /// « — » plutôt que « null » : une clé absente de la réponse s'affichait
  /// littéralement « null » dans la carte.
  static String count(Map<String, dynamic> stats, String key) {
    final value = stats[key];
    return value == null ? '—' : '$value';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    return statsAsync.when(
      data: (stats) => _StatGrid(
        cards: [
          StatCard(
            label: 'Étudiants',
            value: count(stats, 'studentCount'),
            hint: 'Comptes actifs',
            icon: UniIcons.students(),
            iconBackground: AppColors.primaryBlue,
            imageAsset: 'assets/illustrations/hero_books.jpg',
            index: 0,
          ),
          StatCard(
            label: 'Enseignants',
            value: count(stats, 'teacherCount'),
            hint: 'Comptes actifs',
            icon: UniIcons.teachers(),
            iconBackground: AppColors.teal,
            imageAsset: 'assets/illustrations/course_schedule.jpg',
            index: 1,
          ),
          StatCard(
            label: 'Cours actifs',
            value: count(stats, 'courseCount'),
            hint: 'Toutes filières',
            icon: UniIcons.courses(),
            iconBackground: AppColors.warning,
            imageAsset: 'assets/illustrations/course_books.jpg',
            index: 2,
          ),
          StatCard(
            label: 'Sessions',
            value: count(stats, 'sessionCount'),
            hint: 'Historique',
            icon: UniIcons.schedule(),
            iconBackground: AppColors.purple,
            imageAsset: 'assets/illustrations/course_grades.jpg',
            index: 3,
          ),
        ],
      ),
      loading: () => const DataLoadingView(
        label: 'Chargement des indicateurs…',
        compact: true,
      ),
      error: (error, _) => DataErrorView(
        title: 'Indicateurs indisponibles',
        error: error,
        compact: true,
        onRetry: () => ref.invalidate(dashboardStatsProvider),
      ),
    );
  }
}

/// Compteurs d'un apprenant (ses cours, devoirs à rendre, moyenne, présence)
/// ou d'un enseignant (ses cours, étudiants, devoirs, notes saisies).
class _RoleStats extends ConsumerWidget {
  final UserRole role;

  const _RoleStats({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);
    return overviewAsync.when(
      data: (overview) => _StatGrid(cards: cardsFor(role, overview)),
      loading: () => const DataLoadingView(
        label: 'Chargement de votre tableau de bord…',
        compact: true,
      ),
      error: (error, _) => DataErrorView(
        title: 'Tableau de bord indisponible',
        error: error,
        compact: true,
        onRetry: () => ref.invalidate(dashboardOverviewProvider),
      ),
    );
  }

  /// Cartes par rôle, exposées pour les tests : ce sont les mêmes quatre
  /// indicateurs que `DashboardPage.tsx` pour le même rôle.
  static List<StatCard> cardsFor(UserRole role, DashboardOverview overview) {
    if (role.isLearning) {
      return [
        StatCard(
          label: 'Mes cours',
          value: '${overview.courseCount}',
          hint: 'Ce semestre',
          icon: UniIcons.courses(),
          iconBackground: AppColors.primaryBlue,
          imageAsset: 'assets/illustrations/course_schedule.jpg',
          index: 0,
        ),
        StatCard(
          label: 'Devoirs à rendre',
          value: '${overview.assignmentCount}',
          hint:
              overview.assignmentCount == 0 ? 'Rien en attente' : 'En attente',
          icon: UniIcons.assignments(),
          iconBackground: AppColors.warning,
          imageAsset: 'assets/illustrations/course_books.jpg',
          index: 1,
        ),
        StatCard(
          label: 'Moyenne générale',
          value: overview.averageLabel,
          hint:
              '${overview.gradeCount} note${overview.gradeCount > 1 ? 's' : ''}',
          icon: UniIcons.grades(),
          iconBackground: AppColors.teal,
          imageAsset: 'assets/illustrations/course_grades.jpg',
          index: 2,
        ),
        StatCard(
          label: 'Taux de présence',
          value: overview.attendanceLabel,
          hint: overview.attendanceRate == null
              ? 'Aucun appel enregistré'
              : 'Depuis la rentrée',
          icon: UniIcons.attendance(),
          iconBackground: AppColors.purple,
          imageAsset: 'assets/illustrations/hero_books.jpg',
          index: 3,
        ),
      ];
    }
    return [
      StatCard(
        label: 'Mes cours',
        value: '${overview.courseCount}',
        hint: 'Enseignements',
        icon: UniIcons.courses(),
        iconBackground: AppColors.primaryBlue,
        imageAsset: 'assets/illustrations/course_schedule.jpg',
        index: 0,
      ),
      StatCard(
        label: 'Mes étudiants',
        value: '${overview.studentCount}',
        hint: 'Inscrits à mes cours',
        icon: UniIcons.students(),
        iconBackground: AppColors.teal,
        imageAsset: 'assets/illustrations/hero_books.jpg',
        index: 1,
      ),
      StatCard(
        label: 'Devoirs créés',
        value: '${overview.assignmentCount}',
        hint: 'Tous mes cours',
        icon: UniIcons.assignments(),
        iconBackground: AppColors.warning,
        imageAsset: 'assets/illustrations/course_books.jpg',
        index: 2,
      ),
      StatCard(
        label: 'Notes saisies',
        value: '${overview.gradeCount}',
        hint: overview.averageOn20 == null
            ? 'Aucune note'
            : 'Moyenne ${overview.averageLabel}',
        icon: UniIcons.grades(),
        iconBackground: AppColors.purple,
        imageAsset: 'assets/illustrations/course_grades.jpg',
        index: 3,
      ),
    ];
  }
}

/// Rangée de raccourcis vers les écrans du rôle, comme la section « Accès
/// rapide » du tableau de bord web.
class _QuickActions extends ConsumerWidget {
  final List<AppDestination> destinations;

  const _QuickActions({required this.destinations});

  /// Une couleur de la palette par raccourci, pour que la rangée se lise
  /// comme une suite de tuiles distinctes et non quatre boutons gris.
  static const List<Color> _palette = [
    AppColors.primaryBlue,
    AppColors.teal,
    AppColors.warning,
    AppColors.purple,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      title: 'Accès rapide',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (var i = 0; i < destinations.length; i++)
            _QuickActionTile(
              key: ValueKey('quick-${destinations[i].id}'),
              destination: destinations[i],
              color: _palette[i % _palette.length],
              index: i,
              onTap: () => ref.read(currentDestinationProvider.notifier).state =
                  destinations[i],
            ),
        ],
      ),
    );
  }
}

/// Raccourci « tuile + libellé » : la tuile Phosphor `filled` porte
/// l'identité de l'écran, le libellé la nomme. Toute la carte est cliquable,
/// pas seulement la tuile, sinon un clic sur le texte ne faisait rien.
class _QuickActionTile extends StatefulWidget {
  final AppDestination destination;
  final Color color;
  final int index;
  final VoidCallback onTap;

  const _QuickActionTile({
    super.key,
    required this.destination,
    required this.color,
    required this.index,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.inputFill : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTile(
                  icon: widget.destination.icon(),
                  color: widget.color,
                  size: 44,
                  index: widget.index,
                  semanticLabel: widget.destination.label,
                ),
                const SizedBox(width: 12),
                // Borné : « Unités d'enseignement » sur une fenêtre étroite
                // doit se tronquer plutôt que d'élargir la tuile hors du Wrap.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    widget.destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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

/// Conteneur commun aux cartes du tableau de bord.
class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        // `rounded-xl` du web = 12 px, comme les autres cartes de l'app.
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

/// Grille de cartes de statistiques qui s'adapte à la largeur disponible.
///
/// Remplace une `Row` de quatre `Expanded` : celle-ci conservait quatre
/// colonnes quelle que soit la largeur de la fenêtre, et chaque carte devenait
/// trop étroite pour son contenu — le libellé puis le delta finissaient par
/// déborder. Ici le nombre de colonnes suit la place réelle (4, 2 puis 1).
///
/// Chaque rangée est enveloppée dans un `IntrinsicHeight` avec des enfants
/// étirés, pour que les cartes d'une même rangée aient toutes la même hauteur
/// même si leurs libellés n'occupent pas le même nombre de lignes.
class _StatGrid extends StatelessWidget {
  final List<Widget> cards;
  static const double gap = 16;

  const _StatGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000
            ? 4
            : width >= 640
                ? 2
                : 1;

        final rows = <Widget>[];
        for (var start = 0; start < cards.length; start += columns) {
          final remaining = cards.length - start;
          final take = remaining < columns ? remaining : columns;
          final slice = cards.sublist(start, start + take);

          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    // Une rangée incomplète est complétée par des cases vides :
                    // les cartes présentes gardent ainsi la même largeur que
                    // sur une rangée pleine.
                    Expanded(
                      child:
                          i < slice.length ? slice[i] : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: gap),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}

/// Deux cartes côte à côte sur une fenêtre large, empilées en dessous du seuil.
///
/// Évite l'écueil d'une `Row` fixe : dans une fenêtre étroite, deux graphiques
/// côte à côte deviennent illisibles avant même de déborder.
class _ResponsiveRow extends StatelessWidget {
  final double breakpoint;
  final Widget left;
  final Widget right;
  static const double gap = 18;

  const _ResponsiveRow({
    required this.breakpoint,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: gap), right],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: gap),
              Expanded(child: right),
            ],
          ),
        );
      },
    );
  }
}

/// Message affiché à la place d'un graphique dont les données manquent.
///
/// La hauteur est fixée pour que la carte garde la même silhouette qu'avec un
/// graphique, y compris sous l'`IntrinsicHeight` qui aligne les deux cartes.
class _ChartEmpty extends StatelessWidget {
  final String message;

  const _ChartEmpty({required this.message});

  /// Hauteur d'un graphique : l'état vide occupe la même place pour que la
  /// carte voisine, alignée par `IntrinsicHeight`, ne change pas de taille.
  static const double chartHeight = 180;

  @override
  Widget build(BuildContext context) {
    // `DataEmptyView` (Uni à la loupe) plutôt qu'une icône grise : c'est le
    // même état vide que partout ailleurs. Il défile dans sa hauteur fixe, donc
    // une police système agrandie ne déborde plus vers le bas.
    return SizedBox(
      height: chartHeight,
      child: DataEmptyView(message: message, compact: true),
    );
  }
}

/// Carte "Inscriptions par mois" — courbe alimentée par les inscriptions
/// réellement enregistrées dans `academic_enrollments`.
class _EnrollmentChartCard extends ConsumerWidget {
  const _EnrollmentChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollmentsAsync = ref.watch(dashboardEnrollmentsProvider);

    return _Card(
      title: 'Inscriptions par mois',
      child: enrollmentsAsync.when(
        data: (months) {
          if (months.isEmpty || months.every((month) => month.count == 0)) {
            return const _ChartEmpty(
              message:
                  'Aucune inscription enregistrée sur les 6 derniers mois.\n'
                  'La courbe se remplit depuis la collection « academic_enrollments ».',
            );
          }
          return _EnrollmentLineChart(months: months);
        },
        loading: () => const SizedBox(
          height: _ChartEmpty.chartHeight,
          child: DataLoadingView(
              label: 'Chargement des inscriptions…', compact: true),
        ),
        error: (error, _) => SizedBox(
          height: _ChartEmpty.chartHeight,
          child: DataErrorView(
            title: 'Inscriptions indisponibles',
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(dashboardEnrollmentsProvider),
          ),
        ),
      ),
    );
  }
}

class _EnrollmentLineChart extends StatelessWidget {
  final List<MonthlyCount> months;

  const _EnrollmentLineChart({required this.months});

  /// Plafond de l'axe vertical, arrondi au pas supérieur pour que la courbe ne
  /// touche jamais le bord haut du cadre.
  static double _axisMax(int maxCount) {
    if (maxCount <= 0) return 10;
    final step = maxCount <= 10
        ? 2
        : maxCount <= 50
            ? 10
            : maxCount <= 200
                ? 50
                : 100;
    return ((maxCount / step).ceil() * step).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final maxCount =
        months.map((month) => month.count).reduce((a, b) => a > b ? a : b);
    final maxY = _axisMax(maxCount);
    final interval = maxY / 5;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: AppColors.inputBorder, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= months.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(months[index].label,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 34,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted),
                ),
              ),
            ),
          ),
          lineTouchData: const LineTouchData(enabled: true),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: AppColors.primaryBlue,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                        radius: 3.5,
                        color: AppColors.primaryBlue,
                        strokeWidth: 2,
                        strokeColor: Colors.white),
              ),
              spots: [
                for (int i = 0; i < months.length; i++)
                  FlSpot(i.toDouble(), months[i].count.toDouble()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte "Flux de présence global" — anneau alimenté par les enregistrements
/// de présence. Affiche un état vide explicite quand la collection est absente
/// ou ne contient rien, plutôt qu'une répartition inventée.
class _AttendanceDonutCard extends ConsumerWidget {
  const _AttendanceDonutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(dashboardAttendanceProvider);

    return _Card(
      title: 'Flux de présence global',
      child: attendanceAsync.when(
        data: (breakdown) {
          if (breakdown == null || breakdown.total == 0) {
            return const _ChartEmpty(
              message: 'Aucune donnée de présence.\n'
                  'La répartition se calcule depuis la collection « attendance_records ».',
            );
          }
          return _AttendanceDonut(breakdown: breakdown);
        },
        loading: () => const SizedBox(
          height: _ChartEmpty.chartHeight,
          child: DataLoadingView(
              label: 'Chargement des présences…', compact: true),
        ),
        error: (error, _) => SizedBox(
          height: _ChartEmpty.chartHeight,
          child: DataErrorView(
            title: 'Présences indisponibles',
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(dashboardAttendanceProvider),
          ),
        ),
      ),
    );
  }
}

class _AttendanceDonut extends StatelessWidget {
  final AttendanceBreakdown breakdown;

  const _AttendanceDonut({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    String percent(int value) => '${breakdown.percentOf(value).round()}%';

    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 46,
                sections: [
                  PieChartSectionData(
                      value: breakdown.present.toDouble(),
                      color: AppColors.teal,
                      radius: 22,
                      showTitle: false),
                  PieChartSectionData(
                      value: breakdown.absent.toDouble(),
                      color: AppColors.deepBlue,
                      radius: 22,
                      showTitle: false),
                  PieChartSectionData(
                      value: breakdown.late.toDouble(),
                      color: AppColors.warning,
                      radius: 22,
                      showTitle: false),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // `Flexible` et non une colonne rigide : dans une carte étroite, la
          // légende doit pouvoir se réduire au lieu de comprimer l'anneau
          // jusqu'à le faire disparaître.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendRow(
                    color: AppColors.teal,
                    label: 'Présent',
                    value: percent(breakdown.present)),
                const SizedBox(height: 14),
                _LegendRow(
                    color: AppColors.deepBlue,
                    label: 'Absent',
                    value: percent(breakdown.absent)),
                const SizedBox(height: 14),
                _LegendRow(
                    color: AppColors.warning,
                    label: 'Retard',
                    value: percent(breakdown.late)),
                const SizedBox(height: 14),
                Text(
                  '${breakdown.total} enregistrement${breakdown.total > 1 ? 's' : ''}',
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Carte "Activités récentes" : les derniers documents créés dans l'annuaire,
/// les cours et l'emploi du temps, fusionnés par date de création.
class _RecentActivityCard extends ConsumerWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(dashboardActivityProvider);

    return _Card(
      title: 'Activités récentes',
      child: activityAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const DataEmptyView(
              message: 'Aucune activité enregistrée pour le moment.',
              compact: true,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final entry in entries) _ActivityRow(entry: entry)],
          );
        },
        loading: () => const DataLoadingView(
            label: 'Chargement des activités…', compact: true),
        error: (error, _) => DataErrorView(
          title: 'Activités indisponibles',
          error: error,
          compact: true,
          onRetry: () => ref.invalidate(dashboardActivityProvider),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityEntry entry;

  const _ActivityRow({required this.entry});

  static final Map<ActivityKind, IconData> _icons = {
    ActivityKind.enrollment: UniIcons.addPerson(),
    ActivityKind.course: UniIcons.courses(),
    ActivityKind.schedule: UniIcons.clock(),
  };

  static const Map<ActivityKind, Color> _colors = {
    ActivityKind.enrollment: AppColors.primaryBlue,
    ActivityKind.course: AppColors.success,
    ActivityKind.schedule: AppColors.purple,
  };

  /// « Nom ajouté à l'annuaire », « Cours « X » créé »…
  String get _title {
    switch (entry.kind) {
      case ActivityKind.enrollment:
        return '${entry.subject} ajouté à l\'annuaire';
      case ActivityKind.course:
        return 'Cours « ${entry.subject} » créé';
      case ActivityKind.schedule:
        return 'Créneau en ${entry.subject} ajouté';
    }
  }

  /// Date relative lisible : « Aujourd'hui, 10:24 », « Hier, 16:42 »,
  /// « Il y a 3 jours, 09:15 », puis la date complète au-delà d'une semaine.
  String get _time {
    final moment = entry.createdAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(moment.year, moment.month, moment.day);
    final clock =
        '${moment.hour.toString().padLeft(2, '0')}:${moment.minute.toString().padLeft(2, '0')}';

    final days = today.difference(day).inDays;
    if (days <= 0) return "Aujourd'hui, $clock";
    if (days == 1) return 'Hier, $clock';
    if (days < 7) return 'Il y a $days jours, $clock';
    return '${moment.day.toString().padLeft(2, '0')}/${moment.month.toString().padLeft(2, '0')}/${moment.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _colors[entry.kind] ?? AppColors.primaryBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          IconTile(
            icon: _icons[entry.kind] ?? UniIcons.tray(),
            color: color,
            size: 36,
            variant: IconTileVariant.soft,
            semanticLabel: _title,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _title,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
          Text(_time,
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Section badges de l'apprenant : affichée sous les accès rapides, masquée
/// pour les administrateurs (qui n'ont pas de progression personnelle à suivre).
class _BadgesSection extends ConsumerWidget {
  const _BadgesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(studentBadgesProvider);
    return badgesAsync.when(
      data: (badges) {
        if (badges.isEmpty) return const SizedBox.shrink();
        return DashboardBadgesSection(badges: badges);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Grille des cours modernes — cartes solides aux couleurs UniFlow (Navy, Teal, Amber, Violet).
class _CoursesSectionModern extends ConsumerWidget {
  const _CoursesSectionModern();

  static const List<_CourseTheme> _themes = [
    _CourseTheme(
      gradient: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
      icon: PhosphorIconsBold.laptop,
      accent: Color(0xFF38BDF8),
    ),
    _CourseTheme(
      gradient: [Color(0xFF0F766E), Color(0xFF0D9488)],
      icon: PhosphorIconsBold.mathOperations,
      accent: Color(0xFF2DD4BF),
    ),
    _CourseTheme(
      gradient: [Color(0xFFB45309), Color(0xFFD97706)],
      icon: PhosphorIconsBold.brain,
      accent: Color(0xFFFBBF24),
    ),
    _CourseTheme(
      gradient: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
      icon: PhosphorIconsBold.globeHemisphereWest,
      accent: Color(0xFFA78BFA),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(scopedCoursesProvider);
    final colors = UniFlowColors.of(context);

    return coursesAsync.when(
      data: (courses) {
        final list = courses.take(4).toList();
        final displayList = list.isNotEmpty
            ? list
            : [
                AcademicCourse(
                  id: 'c1',
                  code: 'INF101',
                  name: 'Algorithmique & Structures de Données',
                  description: '',
                  university: 'Université de Yaoundé I',
                  credits: 4,
                  program: 'Informatique',
                  level: 'L1',
                  teacherId: '',
                  teacherName: 'Dr. Mballa',
                ),
                AcademicCourse(
                  id: 'c2',
                  code: 'MAT102',
                  name: 'Algèbre Linéaire & Analyse Réelle',
                  description: '',
                  university: 'Université de Yaoundé I',
                  credits: 4,
                  program: 'Informatique',
                  level: 'L1',
                  teacherId: '',
                  teacherName: 'Pr. Ndongo',
                ),
                AcademicCourse(
                  id: 'c3',
                  code: 'SYS103',
                  name: 'Architecture & Systèmes d\'Exploitation',
                  description: '',
                  university: 'Université de Yaoundé I',
                  credits: 3,
                  program: 'Informatique',
                  level: 'L1',
                  teacherId: '',
                  teacherName: 'Dr. Kamga',
                ),
                AcademicCourse(
                  id: 'c4',
                  code: 'ANG104',
                  name: 'Anglais Professionnel & Communication',
                  description: '',
                  university: 'Université de Yaoundé I',
                  credits: 2,
                  program: 'Informatique',
                  level: 'L1',
                  teacherId: '',
                  teacherName: 'Mme. Biya',
                ),
              ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const PhosphorIcon(
                        PhosphorIconsBold.bookOpen,
                        size: 18,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mes Matières & Modules',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => ref.read(currentDestinationProvider.notifier).state = AppDestination.schedule,
                  icon: const Text('Tout voir', style: TextStyle(fontWeight: FontWeight.w600)),
                  label: const PhosphorIcon(PhosphorIconsBold.arrowRight, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth > 800 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: count == 1 ? 2.6 : 2.1,
                  ),
                  itemCount: displayList.length,
                  itemBuilder: (context, i) {
                    final ue = displayList[i];
                    final theme = _themes[i % _themes.length];

                    return InkWell(
                      onTap: () => ref.read(currentDestinationProvider.notifier).state = AppDestination.schedule,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // En-tête coloré vertical ou bloc icône
                            Container(
                              width: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: theme.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                              ),
                              child: Center(
                                child: PhosphorIcon(
                                  theme.icon,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            // Informations de la matière
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            ue.code,
                                            style: const TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.teal50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${ue.credits} ECTS',
                                            style: const TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.teal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      ue.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colors.text,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        PhosphorIcon(
                                          PhosphorIconsBold.user,
                                          size: 12,
                                          color: colors.muted,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            (ue.teacherName != null && ue.teacherName!.isNotEmpty)
                                                ? ue.teacherName!
                                                : 'Enseignant référent',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.fontFamily,
                                              fontSize: 11,
                                              color: colors.muted,
                                            ),
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
                  },
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CourseTheme {
  final List<Color> gradient;
  final PhosphorIconData icon;
  final Color accent;

  const _CourseTheme({
    required this.gradient,
    required this.icon,
    required this.accent,
  });
}
