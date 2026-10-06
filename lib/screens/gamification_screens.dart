/// Écrans Badges et Quêtes — UniFlow Desktop
///
/// Affiche le catalogue des 100 badges et les 300 quêtes dynamiques
/// (hebdomadaires, mensuelles, annuelles) avec progression et leaderboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quests_catalog_250.dart';
import '../models/gamification.dart';
import '../providers/auth_provider.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/phosphor.dart';
import '../widgets/uni/archlord_mascot.dart';
import '../widgets/uni/uni_mascot.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ÉCRAN BADGES
// ═══════════════════════════════════════════════════════════════════════════

class BadgesDesktopScreen extends ConsumerWidget {
  const BadgesDesktopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(badgesWithProgressProvider);
    return _ScreenShell(
      title: 'Badges',
      subtitle: '100 badges à débloquer',
      icon: Icons.military_tech_rounded,
      color: const Color(0xFF8B5CF6),
      child: badgesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (badges) => _BadgesGrid(badges: badges),
      ),
    );
  }
}

class _BadgesGrid extends StatelessWidget {
  final List<BadgeWithProgress> badges;
  const _BadgesGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const Center(
        child: Text('Aucun badge disponible pour l\'instant.',
            style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    // Grouper par catégorie
    final categories = <String, List<BadgeWithProgress>>{};
    for (final b in badges) {
      final cat = b.definition.category.name;
      categories.putIfAbsent(cat, () => []).add(b);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories.keys.elementAt(i);
        final items = categories[cat]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Row(children: [
                Container(
                  width: 4, height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_categoryLabel(cat),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const SizedBox(width: 8),
                Text('(${items.length})',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ]),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisExtent: 200,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, j) => _BadgeCard(item: items[j]),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  String _categoryLabel(String cat) {
    const labels = {
      'attendance':  'Assiduité',
      'academic':    'Académique',
      'social':      'Social',
      'forum':       'Forum',
      'streak':      'Régularité',
      'leaderboard': 'Classement',
      'library':     'Bibliothèque',
      'special':     'Spécial',
    };
    return labels[cat] ?? cat;
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeWithProgress item;
  const _BadgeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final b = item.definition;
    final unlocked = item.unlocked;
    final pct = item.progressPercent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: unlocked
            ? Border.all(color: const Color(0xFF8B5CF6).withAlpha(80), width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Badge image ou icône placeholder
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? const Color(0xFF8B5CF6).withAlpha(25)
                  : const Color(0xFFE2E8F0),
            ),
            child: unlocked
                ? const Icon(Icons.military_tech_rounded,
                    size: 32, color: Color(0xFF8B5CF6))
                : const ColorFiltered(
                    colorFilter: ColorFilter.mode(
                        Colors.grey, BlendMode.saturation),
                    child: Icon(Icons.military_tech_rounded,
                        size: 32, color: Color(0xFFCBD5E1)),
                  ),
          ),
          const SizedBox(height: 8),
          Text(b.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: unlocked ? const Color(0xFF1E293B) : const Color(0xFF94A3B8))),
          const SizedBox(height: 6),
          if (!unlocked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 4,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(height: 4),
            Text('$pct%',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ] else ...[
            const Icon(Icons.check_circle_rounded,
                size: 14, color: Color(0xFF10B981)),
          ],
        ]),
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

class _ScreenShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  const _ScreenShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(230), const Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(subtitle,
                  style: TextStyle(fontSize: 13,
                      color: Colors.white.withAlpha(180))),
            ]),
          ]),
        ),
        Expanded(
          child: Container(
            color: AppColors.background,
            child: child,
          ),
        ),
      ],
    );
  }
}

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
