import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/desktop_shell.dart';
import 'services/local_visio_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Démarrage initial du service de visioconférence local embarqué
  try {
    await LocalVisioServer.instance.startServer();
  } catch (e) {
    debugPrint('Erreur démarrage serveur visio local: \$e');
  }

  runApp(const UniFlowDesktopApp());
}

class UniFlowDesktopApp extends StatelessWidget {
  const UniFlowDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniFlow Desktop · KERNEL FORGE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF0D9488),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const DesktopShell(),
    );
  }
}
