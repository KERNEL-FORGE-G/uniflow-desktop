/// Service de gamification UniFlow (desktop).
///
/// Toutes les définitions de badges et quêtes viennent d'Appwrite.
/// Les images de badges viennent du bucket `uniflow_assets` sous `badges/`.
library gamification_service;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/appwrite_provider.dart';
import '../providers/auth_provider.dart';
import '../services/appwrite_service.dart';
import '../models/gamification.dart';
import '../data/quests_catalog_250.dart';

// ─── Constantes ─────────────────────────────────────────────────────────────

const String _databaseId = 'uniflow';
const String _badgesCatalog = 'badges_catalog';
const String _userBadges = 'user_badges';
const String _questsCatalog = 'quests_catalog';
const String _userQuestProg = 'user_quest_progress';
const String _userXp = 'user_xp';
const String _leaderboard = 'leaderboard';
const String _bucketId = 'uniflow_assets';

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class GamificationService {
  GamificationService(this._appwrite);

  final AppwriteService _appwrite;

  Databases get _databases => _appwrite.databases;

  /// URL publique d'un fichier badge dans le bucket.
  String badgeImageUrl(String imageFileId) {
    return _appwrite.fileViewUrl(imageFileId, bucketId: _bucketId);
  }

  Future<List<T>> _listAll<T>(
    String collection,
    T Function(models.Document) fromDoc, {
    List<String> queries = const [],
  }) async {
    final all = <T>[];
    String? cursor;
    for (;;) {
      final q = [...queries, Query.limit(100)];
      if (cursor != null) q.add(Query.cursorAfter(cursor));
      final page = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: collection,
        queries: q,
      );
      all.addAll(page.documents.map(fromDoc));
      if (page.documents.length < 100) break;
      cursor = page.documents.last.$id;
    }
    return all;
  }

  // ── Catalogue de badges ──────────────────────────────────────────────────

  // ── Catalogue de badges ──────────────────────────────────────────────────

  Future<List<BadgeDefinition>> fetchBadgeCatalog() async {
    try {
      final list = await _listAll(
        _badgesCatalog,
        BadgeDefinition.fromDocument,
        queries: [Query.orderAsc('sortOrder')],
      );
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return _fallbackBadgeCatalog();
  }

  Future<List<UserBadge>> fetchUserBadges(String userId) async {
    try {
      return await _listAll(
        _userBadges,
        UserBadge.fromDocument,
        queries: [Query.equal('userId', userId)],
      );
    } catch (_) {
      return const [];
    }
  }

  Future<List<BadgeWithProgress>> fetchBadgesWithProgress(String userId) async {
    try {
      final catalog = await fetchBadgeCatalog();
      final unlocked = await fetchUserBadges(userId);
      final unlockedIds = {for (final b in unlocked) b.badgeId: b};
      return catalog.map((def) {
        final ub = unlockedIds[def.id];
        return BadgeWithProgress(definition: def, userBadge: ub);
      }).toList();
    } catch (_) {
      return _fallbackBadgeCatalog()
          .map((def) => BadgeWithProgress(definition: def))
          .toList();
    }
  }

  static List<BadgeDefinition> _fallbackBadgeCatalog() {
    return const [
      BadgeDefinition(
        id: 'premier_pas',
        name: 'Premier pas',
        description: 'Rendre son premier devoir ou projet académique.',
        unlockedMessage: 'Premier devoir rendu — votre aventure est lancée !',
        category: BadgeCategory.academique,
        rarity: BadgeRarity.common,
        level: BadgeLevel.bronze,
        imageFileId: 'badge_premier_pas.webp',
        criteria: {'type': 'submissions', 'min': 1},
        xpReward: 50,
      ),
      BadgeDefinition(
        id: 'assidu',
        name: 'Assidu',
        description:
            'Être présent à 90 % des séances relevées (au moins 5 séances).',
        unlockedMessage: 'Présence exemplaire confirmée aux cours.',
        category: BadgeCategory.assiduite,
        rarity: BadgeRarity.rare,
        level: BadgeLevel.silver,
        imageFileId: 'badge_assidu.webp',
        criteria: {'type': 'attendance', 'rate': 0.90, 'min_sessions': 5},
        xpReward: 100,
      ),
      BadgeDefinition(
        id: 'ponctuel',
        name: 'Ponctuel',
        description: "Rendre 3 devoirs consécutifs avant l'échéance fixée.",
        unlockedMessage:
            'Trois devoirs rendus dans les délais, sans aucun retard.',
        category: BadgeCategory.assiduite,
        rarity: BadgeRarity.rare,
        level: BadgeLevel.silver,
        imageFileId: 'badge_ponctuel.webp',
        criteria: {'type': 'on_time_submissions', 'min': 3},
        xpReward: 100,
      ),
      BadgeDefinition(
        id: 'major',
        name: 'Major',
        description:
            'Obtenir une moyenne pondérée de 14/20 ou plus sur au moins 3 notes.',
        unlockedMessage: "Moyenne pondérée d'excellence obtenue.",
        category: BadgeCategory.academique,
        rarity: BadgeRarity.epic,
        level: BadgeLevel.gold,
        imageFileId: 'badge_major.webp',
        criteria: {'type': 'gpa', 'min': 14.0, 'min_grades': 3},
        xpReward: 250,
      ),
      BadgeDefinition(
        id: 'entraide',
        name: 'Entraide',
        description:
            "Publier au moins 3 sujets d'entraide ou réponses sur le forum académique.",
        unlockedMessage:
            'La promotion compte sur votre soutien et esprit de partage.',
        category: BadgeCategory.social,
        rarity: BadgeRarity.common,
        level: BadgeLevel.bronze,
        imageFileId: 'badge_entraide.webp',
        criteria: {'type': 'forum_posts', 'min': 3},
        xpReward: 75,
      ),
      BadgeDefinition(
        id: 'sans_faute',
        name: 'Sans faute',
        description:
            "Réussir un quiz d'évaluation avec la note maximale (100 %).",
        unlockedMessage: 'Score parfait obtenu sur une évaluation.',
        category: BadgeCategory.academique,
        rarity: BadgeRarity.epic,
        level: BadgeLevel.gold,
        imageFileId: 'badge_sans_faute.webp',
        criteria: {'type': 'perfect_quiz', 'min': 1},
        xpReward: 150,
      ),
      BadgeDefinition(
        id: 'pionnier',
        name: 'Pionnier UniFlow',
        description: 'Activer son compte et compléter son profil académique.',
        unlockedMessage: 'Profil complété avec succès !',
        category: BadgeCategory.progression,
        rarity: BadgeRarity.common,
        level: BadgeLevel.bronze,
        imageFileId: 'badge_premier_pas.webp',
        criteria: {'type': 'profile_setup'},
        xpReward: 30,
      ),
      BadgeDefinition(
        id: 'bibliothecaire',
        name: 'Explorateur Uni Book',
        description:
            'Consulter et explorer au moins 5 ouvrages scientifiques dans Uni Book.',
        unlockedMessage: 'La soif de connaissances scientifiques récompensée !',
        category: BadgeCategory.academique,
        rarity: BadgeRarity.uncommon,
        level: BadgeLevel.silver,
        imageFileId: 'badge_premier_pas.webp',
        criteria: {'type': 'library_downloads', 'min': 5},
        xpReward: 80,
      ),
      BadgeDefinition(
        id: 'vigilant',
        name: 'Sentinelle Active',
        description: 'Participer aux alertes et signalements du campus.',
        unlockedMessage:
            'Engagement pour la sécurité et la sérénité du campus.',
        category: BadgeCategory.special,
        rarity: BadgeRarity.rare,
        level: BadgeLevel.silver,
        imageFileId: 'badge_assidu.webp',
        criteria: {'type': 'sentinelle_events', 'min': 2},
        xpReward: 120,
      ),
      BadgeDefinition(
        id: 'semaine_parfaite',
        name: 'Semaine Parfaite',
        description:
            '100 % de présence et aucun retard durant une semaine entière de cours.',
        unlockedMessage:
            'Discipline et assiduité totales sur une semaine complète.',
        category: BadgeCategory.assiduite,
        rarity: BadgeRarity.epic,
        level: BadgeLevel.platinum,
        imageFileId: 'badge_assidu.webp',
        criteria: {'type': 'perfect_week', 'min': 1},
        xpReward: 200,
      ),
      BadgeDefinition(
        id: 'marathonien',
        name: 'Marathonien du Savoir',
        description: 'Atteindre un palier de 10 devoirs rendus avec succès.',
        unlockedMessage: 'Constance et rigueur sur la durée !',
        category: BadgeCategory.progression,
        rarity: BadgeRarity.legendary,
        level: BadgeLevel.diamond,
        imageFileId: 'badge_major.webp',
        criteria: {'type': 'submissions', 'min': 10},
        xpReward: 400,
      ),
      BadgeDefinition(
        id: 'ambassadeur',
        name: 'Ambassadeur Campus',
        description:
            'Faire partie du top 10 des étudiants les plus actifs du mois.',
        unlockedMessage: 'Votre rayonnement inspire toute la faculté !',
        category: BadgeCategory.communaute,
        rarity: BadgeRarity.legendary,
        level: BadgeLevel.diamond,
        imageFileId: 'badge_major.webp',
        criteria: {'type': 'rank', 'max': 10},
        xpReward: 500,
      ),
    ];
  }

  // ── Quêtes ───────────────────────────────────────────────────────────────

  Future<List<QuestWithProgress>> fetchActiveQuests(
    String userId, {
    QuestPeriod? period,
  }) async {
    try {
      final queries = [
        Query.equal('userId', userId),
        Query.equal('status', 'active'),
        Query.limit(50),
      ];
      if (period != null) queries.add(Query.equal('period', period.name));

      final progressDocs = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _userQuestProg,
        queries: queries,
      );

      final results = <QuestWithProgress>[];
      for (final prog in progressDocs.documents) {
        final questId = prog.data['questId'] as String?;
        if (questId == null) continue;
        try {
          final questDoc = await _databases.getDocument(
            databaseId: _databaseId,
            collectionId: _questsCatalog,
            documentId: questId,
          );
          results.add(QuestWithProgress(
            definition: QuestDefinition.fromDocument(questDoc),
            progress: UserQuestProgress.fromDocument(prog),
          ));
        } catch (_) {
          continue;
        }
      }
      if (results.isNotEmpty) return results;
    } catch (_) {
      // Fallback automatique vers le catalogue local 250 quêtes
    }
    return _fallbackQuests(userId, period: period);
  }

  /// Charge l'intégralité des 250 quêtes du catalogue avec progression locale.
  Future<List<QuestWithProgress>> fetchAll250Quests(String userId) async {
    return _fallbackQuests(userId, all: true);
  }

  List<QuestWithProgress> _fallbackQuests(
    String userId, {
    QuestPeriod? period,
    bool all = false,
  }) {
    final now = DateTime.now();
    final List<QuestCatalogItem> items;
    if (all) {
      items = QuestAutoAdjuster.allQuests;
    } else if (period == QuestPeriod.daily) {
      items = QuestAutoAdjuster.getDailyQuests(now);
    } else if (period == QuestPeriod.monthly) {
      items = QuestAutoAdjuster.getMonthlyQuests(now);
    } else if (period == QuestPeriod.yearly) {
      items = QuestAutoAdjuster.getYearlyQuests(now);
    } else {
      items = QuestAutoAdjuster.getActiveQuests(now);
    }

    return items.map((q) {
      final pEnum = switch (q.period) {
        'daily' => QuestPeriod.daily,
        'monthly' => QuestPeriod.monthly,
        'yearly' => QuestPeriod.yearly,
        _ => QuestPeriod.weekly,
      };
      const isDone = false;
      const current = 0;

      return QuestWithProgress(
        definition: QuestDefinition(
          id: q.id,
          title: q.title,
          description: q.description,
          period: pEnum,
          criteriaType: QuestCriteriaType.attendSession,
          targetValue: q.targetValue,
          xpReward: q.xpReward,
          iconName: q.iconName,
          colorHex: q.colorHex,
        ),
        progress: UserQuestProgress(
          id: 'prog_${q.id}',
          userId: userId,
          questId: q.id,
          currentValue: current,
          completed: isDone,
          updatedAt: now,
        ),
      );
    }).toList();
  }

  // ── XP & Classement ──────────────────────────────────────────────────────

  Future<UserXp?> fetchUserXp(String userId) async {
    try {
      final page = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _userXp,
        queries: [Query.equal('userId', userId), Query.limit(1)],
      );
      if (page.documents.isNotEmpty) {
        return UserXp.fromDocument(page.documents.first);
      }
    } catch (_) {}
    return UserXp(
      id: 'local_xp_$userId',
      userId: userId,
      totalXp: 0,
      level: 1,
      xpInCurrentLevel: 0,
      xpToNextLevel: 100,
    );
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required String period,
    required String metric,
    int limit = 20,
  }) async {
    final now = DateTime.now();
    final periodKey = _periodKey(period, now);
    try {
      final list = await _listAll(
        _leaderboard,
        LeaderboardEntry.fromDocument,
        queries: [
          Query.equal('period', period),
          Query.equal('metric', metric),
          Query.equal('periodKey', periodKey),
          Query.orderAsc('rank'),
          Query.limit(limit),
        ],
      );
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Fallback classement local de promo
    }
    return _fallbackLeaderboard(period: period, limit: limit);
  }

  List<LeaderboardEntry> _fallbackLeaderboard({
    required String period,
    int limit = 20,
  }) {
    // Le classement commence vide tant qu'aucun utilisateur n'a validé de quêtes
    return const [];
  }

  String _periodKey(String period, DateTime now) {
    if (period == 'annual' || period == 'yearly') return '${now.year}';
    if (period == 'monthly') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }
    final startOfYear = DateTime(now.year, 1, 1);
    final week = ((now.difference(startOfYear).inDays) / 7).ceil();
    return '${now.year}-W${week.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> checkAndAwardBadges(String userId) async {
    try {
      return await _appwrite.executeFunction(
        '/gamification/check-badges',
        {'userId': userId},
      );
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UserXp
// ─────────────────────────────────────────────────────────────────────────────

class UserXp {
  final String id;
  final String userId;
  final int totalXp;
  final int level;
  final int xpInCurrentLevel;
  final int xpToNextLevel;

  const UserXp({
    required this.id,
    required this.userId,
    required this.totalXp,
    required this.level,
    required this.xpInCurrentLevel,
    required this.xpToNextLevel,
  });

  factory UserXp.fromDocument(models.Document doc) {
    final d = doc.data;
    return UserXp(
      id: doc.$id,
      userId: d['userId'] as String? ?? '',
      totalXp: (d['totalXp'] as num?)?.toInt() ?? 0,
      level: (d['level'] as num?)?.toInt() ?? 1,
      xpInCurrentLevel: (d['xpInCurrentLevel'] as num?)?.toInt() ?? 0,
      xpToNextLevel: (d['xpToNextLevel'] as num?)?.toInt() ?? 100,
    );
  }

  double get progressPercent => xpToNextLevel > 0
      ? (xpInCurrentLevel / xpToNextLevel).clamp(0.0, 1.0)
      : 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers Riverpod
// ─────────────────────────────────────────────────────────────────────────────

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final appwrite = ref.watch(appwriteServiceProvider);
  return GamificationService(appwrite);
});

final badgesWithProgressProvider =
    FutureProvider<List<BadgeWithProgress>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(gamificationServiceProvider).fetchBadgesWithProgress(user.id);
});

final activeQuestsProvider =
    FutureProvider<List<QuestWithProgress>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'guest';
  return ref.read(gamificationServiceProvider).fetchActiveQuests(userId);
});

final dailyQuestsProvider =
    FutureProvider<List<QuestWithProgress>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'guest';
  return ref
      .read(gamificationServiceProvider)
      .fetchActiveQuests(userId, period: QuestPeriod.daily);
});

final weeklyQuestsProvider =
    FutureProvider<List<QuestWithProgress>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'guest';
  return ref
      .read(gamificationServiceProvider)
      .fetchActiveQuests(userId, period: QuestPeriod.weekly);
});

final monthlyQuestsProvider =
    FutureProvider<List<QuestWithProgress>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'guest';
  return ref
      .read(gamificationServiceProvider)
      .fetchActiveQuests(userId, period: QuestPeriod.monthly);
});

final yearlyQuestsProvider =
    FutureProvider<List<QuestWithProgress>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'guest';
  return ref
      .read(gamificationServiceProvider)
      .fetchActiveQuests(userId, period: QuestPeriod.yearly);
});

final all250QuestsProvider =
    FutureProvider<List<QuestWithProgress>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'guest';
  return ref.read(gamificationServiceProvider).fetchAll250Quests(userId);
});

final userXpProvider = FutureProvider<UserXp?>((ref) async {
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'guest';
  return ref.read(gamificationServiceProvider).fetchUserXp(userId);
});

final currentXpProvider = FutureProvider<int>((ref) async {
  final xp = await ref.watch(userXpProvider.future);
  return xp?.totalXp ?? 0;
});

final weeklyLeaderboardProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  return ref
      .read(gamificationServiceProvider)
      .fetchLeaderboard(period: 'weekly', metric: 'xp');
});

final monthlyLeaderboardProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  return ref
      .read(gamificationServiceProvider)
      .fetchLeaderboard(period: 'monthly', metric: 'xp');
});

final annualLeaderboardProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  return ref
      .read(gamificationServiceProvider)
      .fetchLeaderboard(period: 'annual', metric: 'xp');
});
