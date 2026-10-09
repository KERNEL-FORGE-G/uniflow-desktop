/// Widgets gamification UniFlow Desktop
/// Rappels programme, résumé quêtes, highlight badge
/// Style : fond blanc, ombres douces, zéro glassmorphism
library gamification_widgets;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gamification.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/phosphor.dart';
import '../widgets/uni/uni_mascot.dart';
import '../widgets/uni/archlord_mascot.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  1. DailyReminderCard — rappel programme du jour
// ─────────────────────────────────────────────────────────────────────────────

class DailyReminderCard extends ConsumerWidget {
  final VoidCallback? onViewSchedule;
  const DailyReminderCard({super.key, this.onViewSchedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(activeQuestsProvider);
    final xpAsync = ref.watch(currentXpProvider);

    return questsAsync.when(
      loading: () => const _ReminderSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (quests) {
        final today = quests
            .where((q) => q.definition.period == QuestPeriod.daily)
            .toList();
        final xpVal = xpAsync.valueOrNull;
        final level = xpVal != null ? XpLevel.fromXp(xpVal) : null;

        return _ReminderCard(
          todayQuests: today,
          level: level,
          xp: xpVal,
          onViewSchedule: onViewSchedule,
        );
      },
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final List<QuestWithProgress> todayQuests;
  final XpLevel? level;
  final int? xp;
  final VoidCallback? onViewSchedule;

  const _ReminderCard({
    required this.todayQuests,
    this.level,
    this.xp,
    this.onViewSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final done = todayQuests.where((q) => q.completed).length;
    final total = todayQuests.length;
    final pct = total == 0 ? 0.0 : done / total;
    final pose = done == total && total > 0 ? UniPose.wave : UniPose.pointing;
    final arch =
        done == total && total > 0 ? ArchlordPose.thumbs : ArchlordPose.explain;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.primary100, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Contenu principal ─────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Titre
                  Row(
                    children: [
                      const Icon(PhosphorIconsBold.sparkle,
                          size: 16, color: AppColors.primaryBlue),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Programme du jour',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      if (level != null) ...[
                        const SizedBox(width: 4),
                        _LevelChip(level: level!),
                      ],
                    ],
                  ),
                  // Barre XP
                  if (xp != null) ...[
                    const SizedBox(height: 8),
                    _XpBar(xp: xp!, level: level!),
                  ],
                  const SizedBox(height: 12),
                  // Progression quêtes du jour
                  Row(
                    children: [
                      Text(
                        '$done / $total quêtes',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppColors.teal100,
                            color: AppColors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Quêtes du jour (max 4)
                  if (todayQuests.isEmpty)
                    const Text(
                      'Toutes tes quêtes du jour sont terminées 🎉',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    )
                  else
                    ...todayQuests.take(4).map(
                          (q) => _QuestLine(quest: q),
                        ),
                  // Bouton voir emploi du temps
                  if (onViewSchedule != null) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: onViewSchedule,
                      icon:
                          const Icon(PhosphorIconsBold.calendarBlank, size: 14),
                      label: const Text('Voir l\'emploi du temps'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // ── Mascottes ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                ArchlordMascot(pose: arch, size: 60),
                const SizedBox(width: 4),
                UniMascot(pose: pose, size: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderSkeleton extends StatelessWidget {
  const _ReminderSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final XpLevel level;
  const _LevelChip({required this.level});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.teal],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Niv. ${level.level}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  final int xp;
  final XpLevel level;
  const _XpBar({required this.xp, required this.level});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$xp / ${level.xpForNext} XP',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            Text(
              '${level.progressPercent.toStringAsFixed(0)} %',
              style: const TextStyle(fontSize: 11, color: AppColors.teal),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: level.progressPercent / 100,
            minHeight: 6,
            backgroundColor: AppColors.primary100,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }
}

class _QuestLine extends StatelessWidget {
  final QuestWithProgress quest;
  const _QuestLine({required this.quest});
  @override
  Widget build(BuildContext context) {
    final done = quest.completed;
    final pct = quest.progressPercent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            done ? PhosphorIconsBold.checkCircle : PhosphorIconsBold.circle,
            size: 14,
            color: done ? AppColors.teal : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              quest.definition.title,
              style: TextStyle(
                fontSize: 12,
                color: done ? AppColors.textSecondary : AppColors.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${pct.toInt()} %',
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.teal,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  2. QuestSummaryWidget — résumé quêtes actives (desktop, 2 colonnes)
// ─────────────────────────────────────────────────────────────────────────────

class QuestSummaryWidget extends ConsumerWidget {
  final VoidCallback? onViewAll;
  const QuestSummaryWidget({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(activeQuestsProvider);
    return questsAsync.when(
      loading: () => const _QuestSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (quests) => _QuestSummaryBody(quests: quests, onViewAll: onViewAll),
    );
  }
}

class _QuestSummaryBody extends StatelessWidget {
  final List<QuestWithProgress> quests;
  final VoidCallback? onViewAll;
  const _QuestSummaryBody({required this.quests, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final daily =
        quests.where((q) => q.definition.period == QuestPeriod.daily).toList();
    final monthly = quests
        .where((q) => q.definition.period == QuestPeriod.monthly)
        .toList();
    final yearly =
        quests.where((q) => q.definition.period == QuestPeriod.yearly).toList();

    final doneJour = daily.where((q) => q.completed).length;
    final doneMois = monthly.where((q) => q.completed).length;
    final doneAnnee = yearly.where((q) => q.completed).length;

    final totalJour = daily.length;
    final totalMois = monthly.length;
    final totalAnnee = yearly.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                const Icon(PhosphorIconsBold.trophy,
                    size: 16, color: AppColors.teal),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'Quêtes actives',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.teal50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '250',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal),
                  ),
                ),
                const Spacer(),
                if (onViewAll != null)
                  InkWell(
                    onTap: onViewAll,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'Voir tout →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Stats jour / mois / année côte à côte
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                    child: _PeriodStat(
                        label: 'Aujourd\'hui',
                        done: doneJour,
                        total: totalJour > 0 ? totalJour : 6,
                        color: const Color(0xFFF59E0B))),
                const SizedBox(width: 8),
                Expanded(
                    child: _PeriodStat(
                        label: 'Ce mois',
                        done: doneMois,
                        total: totalMois > 0 ? totalMois : 8,
                        color: AppColors.teal)),
                const SizedBox(width: 8),
                Expanded(
                    child: _PeriodStat(
                        label: 'Cette année',
                        done: doneAnnee,
                        total: totalAnnee > 0 ? totalAnnee : 12,
                        color: const Color(0xFF8B5CF6))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 3 premières quêtes
          if (quests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children:
                    quests.take(3).map((q) => _QuestRow(quest: q)).toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _PeriodStat extends StatelessWidget {
  final String label;
  final int done;
  final int total;
  final Color color;
  const _PeriodStat(
      {required this.label,
      required this.done,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            '$done / $total',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.15),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  final QuestWithProgress quest;
  const _QuestRow({required this.quest});

  @override
  Widget build(BuildContext context) {
    final done = quest.completed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            done ? PhosphorIconsBold.checkCircle : PhosphorIconsBold.circle,
            size: 14,
            color: done ? AppColors.teal : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              quest.definition.title,
              style: TextStyle(
                fontSize: 12,
                color: done ? AppColors.textSecondary : AppColors.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${quest.definition.xpReward} XP',
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.teal,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestSkeleton extends StatelessWidget {
  const _QuestSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  3. BadgeHighlightWidget — badge récent mis en valeur
// ─────────────────────────────────────────────────────────────────────────────

class BadgeHighlightWidget extends ConsumerWidget {
  final VoidCallback? onSeeAll;
  const BadgeHighlightWidget({super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(badgesWithProgressProvider);
    return badgesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (badges) {
        final unlocked = badges.where((b) => b.unlocked).toList();
        if (unlocked.isEmpty) return const SizedBox.shrink();
        final recent = unlocked.last;
        return _BadgeHighlightCard(badge: recent, onSeeAll: onSeeAll);
      },
    );
  }
}

class _BadgeHighlightCard extends StatelessWidget {
  final BadgeWithProgress badge;
  final VoidCallback? onSeeAll;
  const _BadgeHighlightCard({required this.badge, this.onSeeAll});

  Color _rarityColor(BadgeRarity r) => switch (r) {
        BadgeRarity.common => const Color(0xFF6B7280),
        BadgeRarity.uncommon => const Color(0xFF10B981),
        BadgeRarity.rare => const Color(0xFF3B82F6),
        BadgeRarity.epic => const Color(0xFF8B5CF6),
        BadgeRarity.legendary => const Color(0xFFF59E0B),
      };

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(badge.definition.rarity);
    final imageId = badge.definition.imageFileId;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: imageId.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      'https://cloud.appwrite.io/v1/storage/buckets/uniflow_assets/files/$imageId/view',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          PhosphorIconsBold.trophy,
                          size: 28,
                          color: color),
                    ),
                  )
                : Icon(PhosphorIconsBold.trophy, size: 28, color: color),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge.definition.rarity.name.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: color,
                            letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('NOUVEAU BADGE',
                        style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  badge.definition.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                Text(
                  badge.definition.description,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Bouton voir tous
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              child: const Text('Voir tout →'),
            ),
        ],
      ),
    );
  }
}
