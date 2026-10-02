/// Écrans Badges et Quêtes — UniFlow Desktop
///
/// Affiche le catalogue des 100 badges et les 300 quêtes dynamiques
/// (hebdomadaires, mensuelles, annuelles) avec progression et leaderboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gamification.dart';
import '../services/gamification_service.dart';
import '../widgets/app_theme.dart';

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
      final cat = b.badge.category;
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
    final b = item.badge;
    final unlocked = item.isUnlocked;
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
                : ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                        Colors.grey, BlendMode.saturation),
                    child: const Icon(Icons.military_tech_rounded,
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
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questsAsync = ref.watch(activeQuestsProvider);
    return _ScreenShell(
      title: 'Quêtes',
      subtitle: 'Objectifs hebdomadaires, mensuels et annuels',
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFF0D9488),
      bottomBar: questsAsync.maybeWhen(
        data: (_) => TabBar(
          controller: _tab,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF0D9488),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Semaine'),
            Tab(text: 'Mois'),
            Tab(text: 'Année'),
          ],
        ),
        orElse: () => null,
      ),
      child: questsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (quests) {
          final weekly  = quests.where((q) => q.definition.period == QuestPeriod.weekly).toList();
          final monthly = quests.where((q) => q.definition.period == QuestPeriod.monthly).toList();
          final annual  = quests.where((q) => q.definition.period == QuestPeriod.yearly).toList();
          return TabBarView(
            controller: _tab,
            children: [
              _QuestsListDesktop(quests: weekly,  emptyLabel: 'Aucune quête hebdomadaire'),
              _QuestsListDesktop(quests: monthly, emptyLabel: 'Aucune quête mensuelle'),
              _QuestsListDesktop(quests: annual,  emptyLabel: 'Aucune quête annuelle'),
            ],
          );
        },
      ),
    );
  }
}

class _QuestsListDesktop extends StatelessWidget {
  final List<QuestWithProgress> quests;
  final String emptyLabel;
  const _QuestsListDesktop({required this.quests, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return Center(child: Text(emptyLabel,
          style: const TextStyle(color: Color(0xFF64748B))));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: quests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _QuestRowDesktop(item: quests[i]),
    );
  }
}

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withAlpha(12),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
        border: isCompleted
            ? Border.all(color: const Color(0xFF10B981).withAlpha(60), width: 1)
            : null,
      ),
      child: Row(children: [
        // Icône
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.emoji_events_rounded, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        // Titre + desc
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q.title,
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text(q.description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
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
              const SizedBox(width: 10),
              Text('$current/$target',
                  style: TextStyle(fontSize: 11, color: color,
                      fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
        const SizedBox(width: 16),
        // XP
        Column(children: [
          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
          Text('${q.xpReward}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.bold)),
          const Text('XP', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ]),
      ]),
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
  final Widget? bottomBar;

  const _ScreenShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
    this.bottomBar,
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
        if (bottomBar != null)
          Container(
            color: Colors.white,
            child: bottomBar!,
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
