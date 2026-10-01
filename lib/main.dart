import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/preferences_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/uni/uni_mascot.dart';
import 'widgets/uni/uni_scenes.dart';

/// Point d'entrée de l'application Flutter.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Une erreur de rendu non rattrapée affiche Uni qui s'excuse plutôt que le
  // rectangle rouge de Flutter.
  ErrorWidget.builder =
      (details) => UniCrashScreen(details: details.exceptionAsString());
  runApp(const ProviderScope(child: UniFlowApp()));
}

/// Widget racine de l'app UniFlow.
///
/// Au lancement, on résout d'abord la session Appwrite persistée sur la
/// machine ([sessionCheckProvider]) : tant qu'elle n'est pas résolue on affiche
/// un écran de chargement, ce qui évite de flasher la page de connexion pour un
/// utilisateur déjà authentifié.
class UniFlowApp extends ConsumerWidget {
  const UniFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionCheckProvider);
    final user = ref.watch(currentUserProvider);
    final darkMode = ref.watch(preferencesProvider.select((p) => p.darkMode));

    return MaterialApp(
      title: 'UniFlow',
      debugShowCheckedModeBanner:
          false, // masque le bandeau "DEBUG" rouge en haut à droite
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: session.when(
        loading: () => const _SplashScreen(),
        // Un échec de résolution (Appwrite injoignable) ne doit pas bloquer
        // l'app : on laisse l'utilisateur tenter de se connecter.
        error: (_, __) => const LoginScreen(),
        data: (_) {
          if (user == null) return const LoginScreen();
          // _AppEntryPoint gère l'onboarding (premier lancement)
          return const _AppEntryPoint();
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A), // bleu UniFlow
              Color(0xFF2563EB),
              Color(0xFF0D9488), // teal UniFlow
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo UniFlow
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                ),
                child: const UniMascot(pose: UniPose.wave, size: 100),
              ),
              const SizedBox(height: 24),
              // Nom de l'app
              const Text(
                'UniFlow',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Plateforme universitaire intelligente',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.80),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 32),
              // Indicateur de chargement
              SizedBox(
                width: 180,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.20),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chargement…',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Décide entre [OnboardingScreen] (premier lancement) et [MainShell].
///
/// Lit `prefs.onboardingDone` depuis SharedPreferences : si la clé est absente
/// ou false, l'onboarding s'ouvre en modal plein-écran au-dessus du shell, et
/// le shell sous-jacent se charge en arrière-plan (pas de délai à la première
/// connexion).
class _AppEntryPoint extends StatefulWidget {
  const _AppEntryPoint();

  @override
  State<_AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<_AppEntryPoint> {
  bool _checked = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('prefs.onboardingDone') ?? false;
      if (mounted) setState(() {
        _showOnboarding = !done;
        _checked = true;
      });
    } catch (_) {
      if (mounted) setState(() => _checked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const _SplashScreen();
    if (_showOnboarding) {
      return Stack(
        children: [
          const MainShell(),
          const OnboardingScreen(),
        ],
      );
    }
    return const MainShell();
  }
}
