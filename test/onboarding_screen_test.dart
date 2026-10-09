import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniflow/screens/onboarding_screen.dart';

import 'layout_test_support.dart';

void main() {
  setUpAll(loadTestEnv);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createSubject({VoidCallback? onFinished}) {
    return ProviderScope(
      child: MaterialApp(
        home: OnboardingScreen(onFinished: onFinished),
      ),
    );
  }

  testWidgets('Onboarding démarre sur la page 1 et affiche le grand logo',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.textContaining('Bienvenue sur\nUniFlow'), findsOneWidget);
    expect(find.text('Suivant →'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
  });

  testWidgets(
      'Les boutons de navigation permettent de changer de page et revenir',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    bool finished = false;
    await tester.pumpWidget(createSubject(onFinished: () => finished = true));
    await tester.pumpAndSettle();

    // Page 1 -> Page 2
    await tester.tap(find.text('Suivant →'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining('Tout ce dont vous\navez besoin'), findsOneWidget);
    expect(find.text('Continuer →'), findsOneWidget);
    expect(find.text('← Précédent'), findsOneWidget);

    // Retour Page 1
    await tester.tap(find.text('← Précédent'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bienvenue sur\nUniFlow'), findsOneWidget);

    // Page 1 -> Page 2 -> Page 3
    await tester.tap(find.text('Suivant →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer →'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Transformez\nvotre campus'), findsOneWidget);
    expect(find.text('Commencer !'), findsOneWidget);

    // Page 3 -> Terminer
    await tester.tap(find.text('Commencer !'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });

  testWidgets('Le bouton Passer termine directement l\'onboarding',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    bool finished = false;
    await tester.pumpWidget(createSubject(onFinished: () => finished = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });
}
