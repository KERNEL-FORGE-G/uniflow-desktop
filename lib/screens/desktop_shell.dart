import 'package:flutter/material.dart';
import '../services/local_visio_server.dart';
import 'dashboard_screen.dart';
import 'schedule_screen.dart';
import 'visio_screen.dart';
import 'courses_screen.dart';
import 'zlibrary_screen.dart';
import 'assistant_screen.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedIndex = 0;
  final LocalVisioServer _server = LocalVisioServer.instance;

  @override
  void initState() {
    super.initState();
    // Démarrage automatique du serveur de visio local dès le lancement du desktop
    _server.startServer();
  }

  void _onNavigate(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onNavigate: _onNavigate),
      const ScheduleScreen(),
      const VisioScreen(),
      const CoursesScreen(),
      const ZLibraryScreen(),
      const AssistantScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // =================================================================
          // SIDEBAR DESKTOP MODERNE
          // =================================================================
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A), // Slate 900
              border: Border(
                right: BorderSide(color: Color(0xFF1E293B)),
              ),
            ),
            child: Column(
              children: [
                // Logo & Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'UF',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UniFlow',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                            ),
                            Text(
                              'KERNEL FORGE Desktop',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Color(0xFF1E293B), height: 1),

                // Éléments de Navigation
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildNavItem(0, 'Tableau de Bord', Icons.dashboard_rounded),
                      _buildNavItem(1, 'Emploi du Temps', Icons.calendar_month_rounded),
                      _buildNavItem(
                        2,
                        'Visioconférence Amphi',
                        Icons.videocam_rounded,
                        badgeText: _server.isRunning ? 'Direct' : null,
                        badgeColor: const Color(0xFF10B981),
                      ),
                      _buildNavItem(3, 'Mes Cours & UE', Icons.menu_book_rounded),
                      _buildNavItem(4, 'Bibliothèque Z-Library', Icons.local_library_rounded),
                      _buildNavItem(
                        5,
                        'Uni Copilot IA',
                        Icons.auto_awesome_rounded,
                        badgeText: 'GROQ',
                        badgeColor: const Color(0xFF0D9488),
                      ),
                    ],
                  ),
                ),

                // Footer de la Sidebar : Statut Serveur Visio Local
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _server.isRunning ? const Color(0xFF10B981) : Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _server.isRunning ? 'Serveur Visio Local Actif' : 'Serveur En Attente',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Port ${_server.port} · P2P LAN',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => setState(() => _selectedIndex = 2),
                        child: const Text(
                          'Gérer la salle & inviter →',
                          style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // Profil Utilisateur
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF1E3A8A),
                        backgroundImage: AssetImage('assets/mascot/uni_copilot_3d.png'),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Étudiant UY1',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Licence 3 · ICT4D',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =================================================================
          // CONTENU PRINCIPAL
          // =================================================================
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String title,
    IconData icon, {
    String? badgeText,
    Color? badgeColor,
  }) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? const Color(0xFF0D9488)).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: (badgeColor ?? const Color(0xFF0D9488)).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor ?? const Color(0xFF0D9488),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
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
