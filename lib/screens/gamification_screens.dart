/// Écrans Badges et Quêtes — UniFlow Desktop
///
/// Affiche les 6 badges académiques réels de l'étudiant, le catalogue
/// étendu de distinctions, et les quêtes dynamiques avec progression.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_catalog_250.dart';
import '../models/badges.dart';
import '../models/gamification.dart';
import '../providers/auth_provider.dart';
import '../providers/badges_provider.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/phosphor.dart';
import '../widgets/uni/archlord_mascot.dart';
import '../widgets/uni/uni_mascot.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ÉCRAN BADGES — RESILIENT, COMPLET ET FLUIDE
// ═══════════════════════════════════════════════════════════════════════════

class BadgesDesktopScreen extends ConsumerStatefulWidget {
  const BadgesDesktopScreen({super.key});

  @override
  ConsumerState<BadgesDesktopScreen> createState() => _BadgesDesktopScreenState();
}

class _BadgesDesktopScreenState extends ConsumerState<BadgesDesktopScreen> {
  String _selectedCategory = 'all';
  String _statusFilter = 'all'; // 'all', 'unlocked', 'locked'
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(studentBadgesProvider);
    ref.invalidate(badgesWithProgressProvider);
    ref.invalidate(userXpProvider);
  }

  @override
  Widget build(BuildContext context) {
    final studentBadgesAsync = ref.watch(studentBadgesProvider);
    final catalogBadgesAsync = ref.watch(badgesWithProgressProvider);
    final userXpAsync = ref.watch(userXpProvider);

    // Données par défaut ou réelles (résilience absolue via valueOrNull)
    final studentBadges = studentBadgesAsync.valueOrNull ?? const <BadgeProgress>[];
    final catalogBadges = catalogBadgesAsync.valueOrNull ?? const <BadgeWithProgress>[];
    final userXp = userXpAsync.valueOrNull?.totalXp ?? 0;

    // Statistiques combinées
    final unlockedStudent = studentBadges.where((b) => b.unlocked).length;
    final totalStudent = studentBadges.isEmpty ? 6 : studentBadges.length;

    final unlockedCatalog = catalogBadges.where((b) => b.unlocked).length;
    final totalCatalog = catalogBadges.length;

    final totalUnlocked = unlockedStudent + unlockedCatalog;
    final totalBadges = totalStudent + totalCatalog;
    final overallPercent = totalBadges > 0
        ? ((totalUnlocked / totalBadges) * 100).round()
        : 0;

    // Filtrer le catalogue étendu
    final filteredCatalog = catalogBadges.where((b) {
      if (_selectedCategory != 'all' && b.definition.category.name != _selectedCategory) {
        return false;
      }
      if (_statusFilter == 'unlocked' && !b.unlocked) {
        return false;
      }
      if (_statusFilter == 'locked' && b.unlocked) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final name = b.definition.name.toLowerCase();
        final desc = b.definition.description.toLowerCase();
        if (!name.contains(_searchQuery) && !desc.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Bannière Hero Décorée ──
          _BadgesHeroBanner(
            unlockedTotal: totalUnlocked,
            unlockedAcademic: unlockedStudent,
            totalAcademic: totalStudent,
            overallPercent: overallPercent,
            totalXp: userXp,
            onRefresh: _refreshAll,
          ),

          // ── Contenu principal scrollable sans conflit ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SECTION BADGES ACADÉMIQUES DU COMPTE (RÉELS)
                  _SectionHeader(
                    icon: PhosphorIconsBold.graduationCap,
                    title: 'Mes Badges Académiques',
                    badgeCount: '$unlockedStudent / $totalStudent débloqués',
                    subtitle:
                        'Évalués en direct sur votre présence aux cours, vos devoirs rendus, vos notes d\'examen et le forum.',
                  ),
                  const SizedBox(height: 16),
                  if (studentBadgesAsync.isLoading && studentBadges.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _StudentBadgesGrid(
                      badges: studentBadges.isNotEmpty
                          ? studentBadges
                          : _defaultStudentBadges(),
                      onTapBadge: (badge) => _showStudentBadgeModal(context, badge),
                    ),

                  const SizedBox(height: 36),

                  // 2. SECTION CATALOGUE ÉTENDU & DISTINCTIONS
                  _SectionHeader(
                    icon: PhosphorIconsBold.medal,
                    title: 'Catalogue des Distinctions & Trophées',
                    badgeCount: '${catalogBadges.length} trophées',
                    subtitle:
                        'Explorez les paliers de fidélité, de rapidité et d\'excellence communautaire UniFlow.',
                  ),
                  const SizedBox(height: 16),

                  // Filtres de recherche et catégories
                  _CatalogFiltersBar(
                    searchCtrl: _searchCtrl,
                    selectedCategory: _selectedCategory,
                    statusFilter: _statusFilter,
                    onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                    onStatusChanged: (status) => setState(() => _statusFilter = status),
                  ),
                  const SizedBox(height: 20),

                  if (catalogBadgesAsync.isLoading && catalogBadges.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filteredCatalog.isEmpty)
                    _CatalogEmptyState(onResetFilters: () {
                      setState(() {
                        _selectedCategory = 'all';
                        _statusFilter = 'all';
                        _searchCtrl.clear();
                      });
                    })
                  else
                    _CatalogBadgesGrid(
                      items: filteredCatalog,
                      onTapBadge: (badge) => _showCatalogBadgeModal(context, badge),
                    ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BadgeProgress> _defaultStudentBadges() {
    return StudentBadge.values
        .map((b) => BadgeProgress(badge: b, progress: 0.0, detail: b.rule))
        .toList();
  }

  void _showStudentBadgeModal(BuildContext context, BadgeProgress progress) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _BadgeDetailDialog(
        title: progress.badge.title,
        assetPath: progress.badge.asset,
        isUnlocked: progress.unlocked,
        percent: progress.percent,
        detailText: progress.detail,
        ruleText: progress.badge.rule,
        congratsMessage: progress.badge.unlockedMessage,
        isAcademic: true,
      ),
    );
  }

  void _showCatalogBadgeModal(BuildContext context, BadgeWithProgress item) {
    final criteria = item.definition.criteria;
    final target = criteria['target'] ?? criteria['threshold'] ?? criteria['count'] ?? '1';
    showDialog<void>(
      context: context,
      builder: (ctx) => _BadgeDetailDialog(
        title: item.definition.name,
        assetPath: null,
        isUnlocked: item.unlocked,
        percent: item.progressPercent,
        detailText: item.definition.description,
        ruleText: 'Condition : $target ${_targetUnit(item.definition.category)}',
        congratsMessage: 'Félicitations ! Vous avez accompli cette distinction.',
        isAcademic: false,
        xpReward: item.definition.xpReward,
      ),
    );
  }

  String _targetUnit(BadgeCategory cat) {
    switch (cat) {
      case BadgeCategory.assiduite:
        return 'séances de présence requises';
      case BadgeCategory.academique:
        return 'devoirs ou examens requis';
      case BadgeCategory.social:
        return 'interactions d\'entraide ou forum';
      case BadgeCategory.progression:
        return 'paliers de cours et semestres validés';
      case BadgeCategory.communaute:
        return 'points de communauté ou classement';
      case BadgeCategory.special:
        return 'actions spéciales d\'excellence';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BANNIÈRE HERO DU HAUT
// ═══════════════════════════════════════════════════════════════════════════

class _BadgesHeroBanner extends StatelessWidget {
  final int unlockedTotal;
  final int unlockedAcademic;
  final int totalAcademic;
  final int overallPercent;
  final int totalXp;
  final VoidCallback onRefresh;

  const _BadgesHeroBanner({
    required this.unlockedTotal,
    required this.unlockedAcademic,
    required this.totalAcademic,
    required this.overallPercent,
    required this.totalXp,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF4338CA), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mascotte Uni diplômé
              const UniMascot(pose: UniPose.graduate, size: 68),
              const SizedBox(width: 16),

              // Titre & description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIconsBold.medal, color: Color(0xFFFFD700), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Trophées & Badges d\'Excellence',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '$unlockedAcademic / $totalAcademic académiques',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Valorisez votre assiduité, vos résultats et vos accomplissements sur UniFlow.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Bouton Actualiser
              Tooltip(
                message: 'Actualiser les badges',
                child: InkWell(
                  onTap: onRefresh,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(PhosphorIconsBold.arrowsClockwise, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 4 Cartes de stats KPI en Wrap responsive
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _HeroKpiCard(
                label: 'Total Trophées',
                value: '$unlockedTotal',
                icon: PhosphorIconsBold.trophy,
                color: const Color(0xFFFFD700),
              ),
              _HeroKpiCard(
                label: 'Académiques',
                value: '$unlockedAcademic / $totalAcademic',
                icon: PhosphorIconsBold.graduationCap,
                color: const Color(0xFF38BDF8),
              ),
              _HeroKpiCard(
                label: 'Progression',
                value: '$overallPercent%',
                icon: PhosphorIconsBold.chartLineUp,
                color: const Color(0xFF34D399),
              ),
              _HeroKpiCard(
                label: 'XP Cumulé',
                value: '$totalXp',
                icon: PhosphorIconsBold.star,
                color: const Color(0xFFFBBF24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final PhosphorIconData icon;
  final Color color;

  const _HeroKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EN-TÊTE DE SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final PhosphorIconData icon;
  final String title;
  final String badgeCount;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.badgeCount,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
              ),
              child: Text(
                badgeCount,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6D28D9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRILLE DES 6 BADGES ACADÉMIQUES
// ═══════════════════════════════════════════════════════════════════════════

class _StudentBadgesGrid extends StatelessWidget {
  final List<BadgeProgress> badges;
  final ValueChanged<BadgeProgress> onTapBadge;

  const _StudentBadgesGrid({
    required this.badges,
    required this.onTapBadge,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final int crossAxisCount;
        if (w >= 1200) {
          crossAxisCount = 6;
        } else if (w >= 850) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          itemCount: badges.length,
          itemBuilder: (context, i) {
            final b = badges[i];
            return _StudentBadgeCard(
              progress: b,
              onTap: () => onTapBadge(b),
            );
          },
        );
      },
    );
  }
}

class _StudentBadgeCard extends StatelessWidget {
  final BadgeProgress progress;
  final VoidCallback onTap;

  const _StudentBadgeCard({
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.unlocked;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                : const Color(0xFFE2E8F0),
            width: unlocked ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: unlocked
                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                  : const Color(0xFF1E3A8A).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image 3D du badge
            SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    progress.badge.asset,
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                    color: unlocked ? null : Colors.grey,
                    colorBlendMode: unlocked ? null : BlendMode.saturation,
                    errorBuilder: (_, __, ___) => Icon(
                      PhosphorIconsFill.medal,
                      size: 56,
                      color: unlocked ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  if (!unlocked)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          PhosphorIconsFill.lock,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Titre du badge
            Text(
              progress.badge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: unlocked ? AppColors.textPrimary : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),

            // Règle courte ou statut
            Text(
              progress.badge.rule,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                height: 1.25,
              ),
            ),
            const Spacer(),

            // Statut ou Barre de progression
            if (unlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsBold.checkCircle, size: 12, color: Color(0xFF047857)),
                    SizedBox(width: 4),
                    Text(
                      'Débloqué',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      progress.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ),
                  Text(
                    '${progress.percent}%',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTRES ET CATALOGUE ÉTENDU
// ═══════════════════════════════════════════════════════════════════════════

class _CatalogFiltersBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String selectedCategory;
  final String statusFilter;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onStatusChanged;

  const _CatalogFiltersBar({
    required this.searchCtrl,
    required this.selectedCategory,
    required this.statusFilter,
    required this.onCategoryChanged,
    required this.onStatusChanged,
  });

  static const _categories = [
    ('all', 'Tous'),
    ('academique', 'Académique'),
    ('assiduite', 'Assiduité'),
    ('social', 'Social & Forum'),
    ('progression', 'Progression'),
    ('communaute', 'Communauté'),
    ('special', 'Spécial'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Champ recherche + filtres de statut
          Row(
            children: [
              // Champ de recherche
              Expanded(
                flex: 3,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un badge ou un mot-clé...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(PhosphorIconsBold.magnifyingGlass,
                          size: 16, color: Color(0xFF64748B)),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => searchCtrl.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Segmented / Filter chips pour Statut
              _StatusFilterChip(
                label: 'Tous',
                selected: statusFilter == 'all',
                onTap: () => onStatusChanged('all'),
              ),
              const SizedBox(width: 6),
              _StatusFilterChip(
                label: 'Débloqués',
                selected: statusFilter == 'unlocked',
                onTap: () => onStatusChanged('unlocked'),
              ),
              const SizedBox(width: 6),
              _StatusFilterChip(
                label: 'À débloquer',
                selected: statusFilter == 'locked',
                onTap: () => onStatusChanged('locked'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Chips de catégories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = selectedCategory == cat.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.$2),
                    selected: isSelected,
                    onSelected: (_) => onCategoryChanged(cat.$1),
                    backgroundColor: const Color(0xFFF1F5F9),
                    selectedColor: const Color(0xFFEDE9FE),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF475569),
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1E3A8A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRILLE CATALOGUE ÉTENDU
// ═══════════════════════════════════════════════════════════════════════════

class _CatalogBadgesGrid extends StatelessWidget {
  final List<BadgeWithProgress> items;
  final ValueChanged<BadgeWithProgress> onTapBadge;

  const _CatalogBadgesGrid({
    required this.items,
    required this.onTapBadge,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final int crossAxisCount;
        if (w >= 1200) {
          crossAxisCount = 5;
        } else if (w >= 900) {
          crossAxisCount = 4;
        } else if (w >= 650) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return _CatalogBadgeCard(
              item: item,
              onTap: () => onTapBadge(item),
            );
          },
        );
      },
    );
  }
}

class _CatalogBadgeCard extends StatelessWidget {
  final BadgeWithProgress item;
  final VoidCallback onTap;

  const _CatalogBadgeCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = item.definition;
    final unlocked = item.unlocked;
    final pct = item.progressPercent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: unlocked
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                  : const Color(0xFF1E3A8A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: unlocked
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                : const Color(0xFFE2E8F0),
            width: unlocked ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pastille XP + Catégorie
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _categoryShortLabel(b.category.name),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    '+${b.xpReward} XP',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Icône / Médaille
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                    : const Color(0xFFF1F5F9),
              ),
              child: Center(
                child: Icon(
                  unlocked ? PhosphorIconsFill.medal : PhosphorIconsFill.lock,
                  size: 26,
                  color: unlocked ? const Color(0xFF8B5CF6) : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Nom du badge
            Text(
              b.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: unlocked ? AppColors.textPrimary : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 3),

            // Description courte
            Text(
              b.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
            ),
            const Spacer(),

            // Progression ou Validé
            if (!unlocked) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$pct%',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsBold.check, size: 11, color: Color(0xFF047857)),
                    SizedBox(width: 3),
                    Text(
                      'Acquis',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _categoryShortLabel(String cat) {
    const labels = {
      'assiduite': 'Assiduité',
      'academique': 'Notes',
      'social': 'Social',
      'progression': 'Parcours',
      'communaute': 'Rang',
      'special': 'Spécial',
    };
    return labels[cat] ?? cat;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ÉTAT VIDE CATALOGUE
// ═══════════════════════════════════════════════════════════════════════════

class _CatalogEmptyState extends StatelessWidget {
  final VoidCallback onResetFilters;

  const _CatalogEmptyState({required this.onResetFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(PhosphorIconsBold.funnel, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'Aucun trophée ne correspond à vos filtres',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Essayez de modifier votre recherche ou de réinitialiser la catégorie.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onResetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIALOGUE DÉTAILLÉ DU BADGE
// ═══════════════════════════════════════════════════════════════════════════

class _BadgeDetailDialog extends StatelessWidget {
  final String title;
  final String? assetPath;
  final bool isUnlocked;
  final int percent;
  final String detailText;
  final String ruleText;
  final String congratsMessage;
  final bool isAcademic;
  final int? xpReward;

  const _BadgeDetailDialog({
    required this.title,
    required this.assetPath,
    required this.isUnlocked,
    required this.percent,
    required this.detailText,
    required this.ruleText,
    required this.congratsMessage,
    required this.isAcademic,
    this.xpReward,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge illustration ou médaille
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFFF1F5F9),
                  border: Border.all(
                    color: isUnlocked
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: assetPath != null
                      ? Image.asset(
                          assetPath!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            PhosphorIconsFill.medal,
                            size: 48,
                            color: isUnlocked
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                          ),
                        )
                      : Icon(
                          isUnlocked ? PhosphorIconsFill.medal : PhosphorIconsFill.lock,
                          size: 48,
                          color: isUnlocked
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF94A3B8),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Titre et badges tags
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isUnlocked ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUnlocked ? 'Débloqué & Actif' : 'En progression ($percent%)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked ? const Color(0xFF047857) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                  if (xpReward != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        '+$xpReward XP',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),

              // Explication de la condition
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Objectif requis :',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ruleText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Votre statut actuel :',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detailText,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Mascotte Uni avec conseil
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  UniMascot(
                    pose: isUnlocked ? UniPose.celebrate : UniPose.wave,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUnlocked
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Text(
                        isUnlocked
                            ? congratsMessage
                            : 'Conseil d\'Uni : Continuez vos efforts chaque jour, chaque devoir et séance vous rapproche de ce badge !',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked
                              ? const Color(0xFF166534)
                              : const Color(0xFF1E40AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Bouton Fermer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Compris !',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ÉCRAN QUÊTES
// ═══════════════════════════════════════════════════════════════════════════

class QuestsDesktopScreen extends ConsumerStatefulWidget {
  const QuestsDesktopScreen({super.key});

  @override
  ConsumerState<QuestsDesktopScreen> createState() => _QuestsDesktopScreenState();
}

class _QuestsDesktopScreenState extends ConsumerState<QuestsDesktopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userXpAsync = ref.watch(userXpProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero Banner Gamification & Mascottes ──
          Container(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Mascotte Uni
                const UniMascot(pose: UniPose.graduate, size: 76),
                const SizedBox(width: 18),
                // Titre & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(PhosphorIconsBold.trophy, color: Color(0xFFFFD700), size: 22),
                          const SizedBox(width: 8),
                          const Text(
                            'Quêtes & Défis Académiques',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              '250 quêtes auto-ajustées',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Objectifs ajustés par jour, mois et année universitaire avec classement en temps réel.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Carte XP & Niveau
                userXpAsync.when(
                  loading: () => const SizedBox(width: 160),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (userXp) {
                    final totalXp = userXp?.totalXp ?? 450;
                    final level = XpLevel.fromXp(totalXp);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Niveau ${level.level}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                level.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 4),
                              Text(
                                '$totalXp XP',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• ${level.xpInLevel}/${level.xpForNextLevel}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 150,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: level.progress,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation(Color(0xFF0D9488)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                // Mascotte Archlord
                const ArchlordMascot(pose: ArchlordPose.thumbs, size: 76),
              ],
            ),
          ),

          // ── Onglets de navigation ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: const Color(0xFF1E3A8A),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF0D9488),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(
                  icon: Icon(PhosphorIconsBold.sun, size: 16),
                  text: "Aujourd'hui (Jour)",
                ),
                Tab(
                  icon: Icon(PhosphorIconsBold.calendarBlank, size: 16),
                  text: 'Ce mois (Mois)',
                ),
                Tab(
                  icon: Icon(PhosphorIconsBold.trophy, size: 16),
                  text: 'Cette année (Année)',
                ),
                Tab(
                  icon: Icon(PhosphorIconsBold.books, size: 16),
                  text: 'Catalogue (250)',
                ),
                Tab(
                  icon: Icon(PhosphorIconsBold.chartBar, size: 16),
                  text: 'Classement (Leaderboard)',
                ),
              ],
            ),
          ),

          // ── Contenu des onglets ──
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _PeriodQuestsView(
                  provider: dailyQuestsProvider,
                  periodTitle: 'Quêtes du jour',
                  periodSubtitle: '6 quêtes renouvelées chaque matin automatiquement pour dynamiser ton quotidien universitaire',
                  badgeColor: const Color(0xFFF59E0B),
                ),
                _PeriodQuestsView(
                  provider: monthlyQuestsProvider,
                  periodTitle: 'Quêtes du mois',
                  periodSubtitle: '8 quêtes adaptées au calendrier universitaire et aux examens du mois en cours',
                  badgeColor: const Color(0xFF0D9488),
                ),
                _PeriodQuestsView(
                  provider: yearlyQuestsProvider,
                  periodTitle: 'Quêtes annuelles',
                  periodSubtitle: '12 jalons majeurs de ton année académique : projets, assiduité d\'élite et stages',
                  badgeColor: const Color(0xFF8B5CF6),
                ),
                const _All250QuestsView(),
                _LeaderboardDesktopView(currentUserId: user?.id ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VUE PAR PÉRIODE (Jour, Mois, Année)
// ─────────────────────────────────────────────────────────────────────────────

class _PeriodQuestsView extends ConsumerWidget {
  final FutureProvider<List<QuestWithProgress>> provider;
  final String periodTitle;
  final String periodSubtitle;
  final Color badgeColor;

  const _PeriodQuestsView({
    required this.provider,
    required this.periodTitle,
    required this.periodSubtitle,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(provider);

    return questsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (quests) {
        final completedCount = quests.where((q) => q.completed).length;
        final totalCount = quests.length;
        final totalXpAvailable = quests.fold(0, (acc, q) => acc + q.definition.xpReward);

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Bandeau d'information
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(PhosphorIconsBold.target, color: badgeColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          periodTitle,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          periodSubtitle,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$completedCount / $totalCount terminées',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: badgeColor),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '+$totalXpAvailable XP disponibles',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (quests.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('Aucune quête disponible pour cette période.', style: TextStyle(color: Color(0xFF64748B))),
                ),
              )
            else
              ...quests.map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QuestRowDesktop(item: q),
                  )),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VUE CATALOGUE COMPLET (250 QUÊTES AVEC RECHERCHE & FILTRE CATÉGORIE)
// ─────────────────────────────────────────────────────────────────────────────

class _All250QuestsView extends ConsumerStatefulWidget {
  const _All250QuestsView();

  @override
  ConsumerState<_All250QuestsView> createState() => _All250QuestsViewState();
}

class _All250QuestsViewState extends ConsumerState<_All250QuestsView> {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  static final _categoryFilters = [
    ('all', 'Toutes (250)', PhosphorIconsBold.squaresFour),
    ('assiduity', 'Assiduité', PhosphorIconsBold.clock),
    ('organization', 'Organisation', PhosphorIconsBold.calendarCheck),
    ('academic', 'Académique', PhosphorIconsBold.graduationCap),
    ('library', 'Bibliothèque', PhosphorIconsBold.bookBookmark),
    ('social', 'Social & Campus', PhosphorIconsBold.users),
    ('health', 'Santé & Équilibre', PhosphorIconsBold.sparkle),
    ('challenge', 'Défis & Projets', PhosphorIconsBold.lightning),
  ];

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(all250QuestsProvider);

    return questsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (allQuests) {
        // Filtrage
        final filtered = allQuests.where((item) {
          final q = item.definition;
          if (_selectedCategory != 'all') {
            final catalogItem = kAllQuests250.firstWhere(
              (c) => c.id == q.id,
              orElse: () => kAllQuests250.first,
            );
            if (catalogItem.category != _selectedCategory) {
              return false;
            }
          }
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchesTitle = q.title.toLowerCase().contains(query);
            final matchesDesc = q.description.toLowerCase().contains(query);
            if (!matchesTitle && !matchesDesc) return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Barre d'outils et recherche
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      // Champ de recherche
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher parmi les 250 quêtes (titre, sujet, objectif)...',
                            prefixIcon: const Icon(PhosphorIconsBold.magnifyingGlass, size: 18, color: Color(0xFF64748B)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${filtered.length} / ${allQuests.length} quêtes',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filtres de catégories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categoryFilters.map((f) {
                        final isSelected = _selectedCategory == f.$1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            avatar: Icon(
                              f.$3,
                              size: 15,
                              color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                            ),
                            label: Text(f.$2),
                            selectedColor: const Color(0xFF1E3A8A),
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                            ),
                            onSelected: (_) => setState(() => _selectedCategory = f.$1),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Grille de quêtes
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune quête ne correspond à votre filtre.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _QuestRowDesktop(item: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLASSEMENT / LEADERBOARD DES ÉTUDIANTS (AVEC PODIUM OR / ARGENT / BRONZE)
// ─────────────────────────────────────────────────────────────────────────────

class _LeaderboardDesktopView extends ConsumerStatefulWidget {
  final String currentUserId;
  const _LeaderboardDesktopView({required this.currentUserId});

  @override
  ConsumerState<_LeaderboardDesktopView> createState() => _LeaderboardDesktopViewState();
}

class _LeaderboardDesktopViewState extends ConsumerState<_LeaderboardDesktopView> {
  String _period = 'weekly'; // 'weekly', 'monthly', 'annual'

  @override
  Widget build(BuildContext context) {
    final provider = switch (_period) {
      'monthly' => monthlyLeaderboardProvider,
      'annual'  => annualLeaderboardProvider,
      _         => weeklyLeaderboardProvider,
    };

    final lbAsync = ref.watch(provider);

    return Column(
      children: [
        // Sélecteur de période de classement
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(PhosphorIconsBold.trophy, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 10),
              const Text(
                'Classement des étudiants',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const Spacer(),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'weekly', label: Text('Cette semaine')),
                  ButtonSegment(value: 'monthly', label: Text('Ce mois')),
                  ButtonSegment(value: 'annual', label: Text('Cette année')),
                ],
                selected: {_period},
                onSelectionChanged: (val) {
                  if (val.isNotEmpty) setState(() => _period = val.first);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        // Contenu Podium & Liste
        Expanded(
          child: lbAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(message: e.toString()),
            data: (entries) {
              if (entries.isEmpty) {
                return const Center(
                  child: Text('Aucun étudiant classé pour cette période pour le moment.',
                      style: TextStyle(color: Color(0xFF64748B))),
                );
              }

              final top1 = entries.isNotEmpty ? entries[0] : null;
              final top2 = entries.length > 1 ? entries[1] : null;
              final top3 = entries.length > 2 ? entries[2] : null;
              final rest = entries.length > 3 ? entries.sublist(3) : <LeaderboardEntry>[];

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // ── Podium Top 3 ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Podium d\'excellence',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // 2ème place (Argent)
                            if (top2 != null)
                              _PodiumStep(
                                entry: top2,
                                rank: 2,
                                medalColor: const Color(0xFF94A3B8),
                                podiumHeight: 100,
                                isCurrentUser: top2.userId == widget.currentUserId,
                              )
                            else
                              const SizedBox(width: 140),

                            const SizedBox(width: 16),

                            // 1ère place (Or)
                            if (top1 != null)
                              _PodiumStep(
                                entry: top1,
                                rank: 1,
                                medalColor: const Color(0xFFFFD700),
                                podiumHeight: 140,
                                isCurrentUser: top1.userId == widget.currentUserId,
                              ),

                            const SizedBox(width: 16),

                            // 3ème place (Bronze)
                            if (top3 != null)
                              _PodiumStep(
                                entry: top3,
                                rank: 3,
                                medalColor: const Color(0xFFCD7F32),
                                podiumHeight: 80,
                                isCurrentUser: top3.userId == widget.currentUserId,
                              )
                            else
                              const SizedBox(width: 140),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Tableau des autres rangs (4 à 50) ──
                  if (rest.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Tous les participants classés',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: rest.asMap().entries.map((item) {
                          final rankNumber = item.key + 4;
                          final entry = item.value;
                          final isMe = entry.userId == widget.currentUserId;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF0D9488).withValues(alpha: 0.08) : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: item.key < rest.length - 1 ? const Color(0xFFF1F5F9) : Colors.transparent,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '#$rankNumber',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: isMe ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isMe ? const Color(0xFF0D9488) : const Color(0xFF1E3A8A),
                                  child: Text(
                                    entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.displayName,
                                        style: TextStyle(
                                          fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                                          fontSize: 14,
                                          color: isMe ? const Color(0xFF0D9488) : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      if (isMe)
                                        const Text(
                                          'Votre position',
                                          style: TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.w600),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${entry.score} XP',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final Color medalColor;
  final double podiumHeight;
  final bool isCurrentUser;

  const _PodiumStep({
    required this.entry,
    required this.rank,
    required this.medalColor,
    required this.podiumHeight,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rank == 1)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('👑', style: TextStyle(fontSize: 24)),
            ),
          CircleAvatar(
            radius: rank == 1 ? 32 : 26,
            backgroundColor: medalColor.withValues(alpha: 0.2),
            child: CircleAvatar(
              radius: rank == 1 ? 28 : 22,
              backgroundColor: medalColor,
              child: Text(
                entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: rank == 1 ? const Color(0xFF78350F) : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: rank == 1 ? 20 : 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: rank == 1 ? 14 : 12.5,
              fontWeight: FontWeight.w700,
              color: isCurrentUser ? const Color(0xFF0D9488) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${entry.score} XP',
            style: TextStyle(
              fontSize: rank == 1 ? 13 : 11.5,
              fontWeight: FontWeight.w800,
              color: medalColor == const Color(0xFFFFD700) ? const Color(0xFFB45309) : medalColor,
            ),
          ),
          const SizedBox(height: 8),
          // Pilier du podium
          Container(
            height: podiumHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: medalColor.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: medalColor.withValues(alpha: 0.35)),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: rank == 1 ? 28 : 22,
                  fontWeight: FontWeight.w900,
                  color: medalColor == const Color(0xFFFFD700) ? const Color(0xFFB45309) : medalColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIGNE DE QUÊTE COMMUNE (CARTE SOLIDE)
// ─────────────────────────────────────────────────────────────────────────────

class _QuestRowDesktop extends StatelessWidget {
  final QuestWithProgress item;
  const _QuestRowDesktop({required this.item});

  @override
  Widget build(BuildContext context) {
    final q = item.definition;
    final isCompleted = item.completed;
    final current = item.currentValue;
    final target  = item.targetValue;
    final pct     = item.ratio;

    final color = isCompleted ? const Color(0xFF10B981) : const Color(0xFF0D9488);

    final periodBadge = switch (q.period) {
      QuestPeriod.daily   => ('JOUR', const Color(0xFFF59E0B)),
      QuestPeriod.monthly => ('MOIS', const Color(0xFF0D9488)),
      QuestPeriod.yearly  => ('ANNÉE', const Color(0xFF8B5CF6)),
      _                   => ('DÉFI', const Color(0xFF3B82F6)),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Icône avec badge période
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.emoji_events_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Titre + badge période + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: periodBadge.$2.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        periodBadge.$1,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: periodBadge.$2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  q.description,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$current / $target',
                      style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // XP & Statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      '+${q.xpReward} XP',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (isCompleted)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'Terminée',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                    ),
                  ],
                )
              else
                Text(
                  '${(pct * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS PARTAGÉS
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          const Text('Impossible de charger les données',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ]),
      ),
    );
  }
}
