import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniflow/models/badges.dart';
import 'package:uniflow/models/gamification.dart';
import 'package:uniflow/providers/badges_provider.dart';
import 'package:uniflow/screens/gamification_screens.dart';
import 'package:uniflow/services/gamification_service.dart';
import 'package:uniflow/theme/app_theme.dart';

void main() {
  testWidgets('BadgesDesktopScreen se monte sans crash et affiche les sections clés',
      (tester) async {
    tester.view.physicalSize = const Size(1366, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockBadges = [
      const BadgeProgress(
        badge: StudentBadge.premierPas,
        progress: 1.0,
        detail: '1 devoir rendu',
      ),
      const BadgeProgress(
        badge: StudentBadge.assidu,
        progress: 0.6,
        detail: '3 / 5 séances',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentBadgesProvider.overrideWith((ref) async => mockBadges),
          userXpProvider.overrideWith((ref) async => const UserXp(
                id: 'ux_1',
                userId: 'user_1',
                totalXp: 450,
                level: 3,
                xpInCurrentLevel: 50,
                xpToNextLevel: 100,
              )),
          badgesWithProgressProvider.overrideWith((ref) async => [
            BadgeWithProgress(
              definition: const BadgeDefinition(
                id: 'test_1',
                name: 'Trophée Assidu Test',
                description: 'Assister à ses cours',
                unlockedMessage: 'Bravo !',
                category: BadgeCategory.assiduite,
                rarity: BadgeRarity.common,
                level: BadgeLevel.bronze,
                imageFileId: 'badge_assidu',
                criteria: {'target': 5},
                xpReward: 50,
              ),
              userBadge: UserBadge(
                id: 'ub_1',
                userId: 'user_1',
                badgeId: 'test_1',
                unlockedAt: DateTime.now(),
                progressPercent: 100,
                progressDetail: '5 / 5 séances',
              ),
            ),
          ]),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: BadgesDesktopScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Vérifie la présence du Hero banner et du titre
    expect(find.text("Trophées & Badges d'Excellence"), findsOneWidget);

    // Vérifie les sections
    expect(find.text('Mes Badges Académiques'), findsOneWidget);
    expect(find.text('Catalogue des Distinctions & Trophées'), findsOneWidget);

    // Vérifie le badge académique débloqué
    expect(find.text('Premier pas'), findsOneWidget);
    expect(find.text('Débloqué'), findsWidgets);

    // Vérifie le badge du catalogue
    expect(find.text('Trophée Assidu Test'), findsOneWidget);

    // Clic sur le badge académique pour ouvrir la modale détaillée
    await tester.tap(find.text('Premier pas'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Vérifie le dialogue de détail
    expect(find.text('Compris !'), findsOneWidget);
    expect(find.text('Premier devoir rendu — la suite est lancée.'), findsOneWidget);

    // Fermeture du dialogue
    await tester.tap(find.text('Compris !'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Compris !'), findsNothing);
  });
}
