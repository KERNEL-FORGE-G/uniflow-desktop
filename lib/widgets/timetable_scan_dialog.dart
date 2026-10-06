import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/uni_icons.dart';

class TimetableScanInfo {
  final String program;
  final String level;
  final String fileId;
  final String label;
  final String? classroom;

  const TimetableScanInfo({
    required this.program,
    required this.level,
    required this.fileId,
    required this.label,
    this.classroom,
  });
}

const List<TimetableScanInfo> kDesktopTimetableScans = [
  TimetableScanInfo(program: 'ENR', level: 'L3', fileId: 'edt_scan_enr_l3', label: 'Énergies Renouvelables L3', classroom: 'Salle S012'),
  TimetableScanInfo(program: 'ENR', level: 'L2', fileId: 'edt_scan_enr_l2', label: 'Énergies Renouvelables L2', classroom: 'Salle R110'),
  TimetableScanInfo(program: 'ENR', level: 'L1', fileId: 'edt_scan_enr_l1', label: 'Énergies Renouvelables L1', classroom: 'E206 / R106'),
  TimetableScanInfo(program: 'GEO', level: 'M1', fileId: 'edt_scan_geo_m1', label: 'Géosciences M1', classroom: 'S24B / AIII / R101'),
  TimetableScanInfo(program: 'PHY', level: 'M1', fileId: 'edt_scan_phy_m1', label: 'Physique M1', classroom: 'AIII / S48 / R110'),
  TimetableScanInfo(program: 'GEO', level: 'L2', fileId: 'edt_scan_geo_l2', label: 'Géosciences L2', classroom: 'A350 / A502 / R106'),
  TimetableScanInfo(program: 'GEO', level: 'L3', fileId: 'edt_scan_geo_l3', label: 'Géosciences L3', classroom: 'A350 / A250 / R106'),
  TimetableScanInfo(program: 'PHY', level: 'L3', fileId: 'edt_scan_phy_l3', label: 'Physique L3', classroom: 'AII / A135 / A502'),
  TimetableScanInfo(program: 'PHY', level: 'L2', fileId: 'edt_scan_phy_l2', label: 'Physique L2', classroom: 'A1002 / A502 / A135'),
  TimetableScanInfo(program: 'PHY', level: 'L1', fileId: 'edt_scan_phy_l1', label: 'Physique L1', classroom: 'A1001 / A1002'),
  TimetableScanInfo(program: 'MAT', level: 'L2', fileId: 'edt_scan_mat_l2', label: 'Mathématiques L2', classroom: 'A250 / A1002 / A350'),
  TimetableScanInfo(program: 'MAT', level: 'L3', fileId: 'edt_scan_mat_l3', label: 'Mathématiques L3', classroom: 'AI / A250 / S103'),
  TimetableScanInfo(program: 'MAT', level: 'M1', fileId: 'edt_scan_mat_m1', label: 'Mathématiques M1', classroom: 'S102 / S110 / AI'),
  TimetableScanInfo(program: 'MAT', level: 'L1', fileId: 'edt_scan_mat_l1', label: 'Mathématiques L1', classroom: 'A502 / A1002 / A250'),
  TimetableScanInfo(program: 'INF', level: 'M1', fileId: 'edt_scan_inf_m1', label: 'Informatique M1', classroom: 'S005 / S006 / AIII'),
  TimetableScanInfo(program: 'INF', level: 'L3', fileId: 'edt_scan_inf_l3', label: 'Informatique L3', classroom: 'S008 / S006 / AIII'),
  TimetableScanInfo(program: 'INF', level: 'L2', fileId: 'edt_scan_inf_l2', label: 'Informatique L2', classroom: 'A350 / R108 / R106'),
  TimetableScanInfo(program: 'INF', level: 'L1', fileId: 'edt_scan_inf_l1', label: 'Informatique L1', classroom: 'A1002 / A502 / A250'),
  TimetableScanInfo(program: 'CHM', level: 'L2', fileId: 'edt_scan_chm_l2', label: 'Chimie L2', classroom: 'A502 / R108 / R106'),
  TimetableScanInfo(program: 'CHM', level: 'L3', fileId: 'edt_scan_chm_l3', label: 'Chimie L3', classroom: 'A350 / AI / AII'),
  TimetableScanInfo(program: 'CHM', level: 'M1', fileId: 'edt_scan_chm_m1', label: 'Chimie M1', classroom: 'R108 / AII / E206'),
  TimetableScanInfo(program: 'CHM', level: 'L1', fileId: 'edt_scan_chm_l1', label: 'Chimie L1', classroom: 'A1001 / A502 / A1002'),
  TimetableScanInfo(program: 'MIB', level: 'M1', fileId: 'edt_scan_mib_m1', label: 'Microbiologie M1', classroom: 'AIII / R108 / S005'),
  TimetableScanInfo(program: 'MIB', level: 'L3', fileId: 'edt_scan_mib_l3', label: 'Microbiologie L3', classroom: 'A502 / A250 / AI'),
  TimetableScanInfo(program: 'BOA', level: 'M1', fileId: 'edt_scan_boa_m1', label: 'Biologie des Organismes Animaux M1', classroom: 'S24B / AI / AII'),
  TimetableScanInfo(program: 'BOV', level: 'L3', fileId: 'edt_scan_bov_l3', label: 'Biologie des Organismes Végétaux L3', classroom: 'R106 / AIII / AI'),
  TimetableScanInfo(program: 'BOV', level: 'M1', fileId: 'edt_scan_bov_m1', label: 'Biologie des Organismes Végétaux M1', classroom: 'S58 / E206 / AIII'),
  TimetableScanInfo(program: 'BOA', level: 'L3', fileId: 'edt_scan_boa_l3', label: 'Biologie des Organismes Animaux L3', classroom: 'R106 / A350 / A250'),
  TimetableScanInfo(program: 'BCH', level: 'M1', fileId: 'edt_scan_bch_m1', label: 'Biochimie M1', classroom: 'R106 / E206 / R108'),
  TimetableScanInfo(program: 'BCH', level: 'L3', fileId: 'edt_scan_bch_l3', label: 'Biochimie L3', classroom: 'P1 / P2 / AI / AII'),
  TimetableScanInfo(program: 'BIOS', level: 'L2', fileId: 'edt_scan_bios_l2', label: 'Biosciences L2', classroom: 'A1002 / A250 / R101'),
  TimetableScanInfo(program: 'BIOS', level: 'L1', fileId: 'edt_scan_bios_l1', label: 'Biosciences L1 & Géosciences L1 (Groupes)', classroom: 'A1001 / A1002'),
];

class TimetableScanDialog extends StatefulWidget {
  final String? initialProgram;
  final String? initialLevel;

  const TimetableScanDialog({
    super.key,
    this.initialProgram,
    this.initialLevel,
  });

  @override
  State<TimetableScanDialog> createState() => _TimetableScanDialogState();
}

class _TimetableScanDialogState extends State<TimetableScanDialog> {
  late TimetableScanInfo _selected;
  final TransformationController _transformController = TransformationController();
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    final p = (widget.initialProgram ?? '').toUpperCase();
    final l = (widget.initialLevel ?? '').toUpperCase();
    _selected = kDesktopTimetableScans.firstWhere(
      (s) => s.program == p && s.level == l,
      orElse: () => kDesktopTimetableScans.first,
    );
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    setState(() {
      _zoom = 1.0;
      _transformController.value = Matrix4.identity();
    });
  }

  void _adjustZoom(double factor) {
    setState(() {
      _zoom = (_zoom * factor).clamp(0.5, 4.0);
      _transformController.value = Matrix4.diagonal3Values(_zoom, _zoom, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isICT4D = (widget.initialProgram ?? '').toUpperCase() == 'ICT4D';
    final imageUrl =
        'https://vps.kernelforge.codes/v1/storage/buckets/uniflow_academic/files/${_selected.fileId}/view?project=uniflow';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 1080,
        height: 780,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.cardHover,
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                border: Border(bottom: BorderSide(color: AppColors.inputBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        UniIcons.document(UniIconStyle.bold),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Affichage Officiel — Faculté des Sciences UY1',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.teal100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '2026-2027',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tealDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Scan original certifié par le Doyen Luc C. Owono Owono',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Dropdown selection
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TimetableScanInfo>(
                        value: _selected,
                        items: kDesktopTimetableScans.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              '${s.program} ${s.level} — ${s.label}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selected = val;
                              _resetZoom();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Zoom in/out/reset
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: PhosphorIcon(UniIcons.chevronLeft(UniIconStyle.bold), size: 16),
                          tooltip: 'Zoom arrière',
                          onPressed: () => _adjustZoom(0.8),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                        Text(
                          '${(_zoom * 100).round()}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: PhosphorIcon(UniIcons.chevronRight(UniIconStyle.bold), size: 16),
                          tooltip: 'Zoom avant',
                          onPressed: () => _adjustZoom(1.2),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                        TextButton(
                          onPressed: _resetZoom,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(28, 28),
                          ),
                          child: const Text('1:1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            if (isICT4D)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                color: const Color(0xFFEBF4FF),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Licence professionnelle ICT4D (L1, L2, L3) : emploi du temps interactif actif sur votre écran. '
                        'Le visualiseur affiche ici les feuilles officielles de la Faculté.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                  ],
                ),
              ),

            // Viewer content
            Expanded(
              child: Container(
                color: const Color(0xFF0F172A),
                child: ClipRect(
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.4,
                    maxScale: 5.0,
                    child: Center(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                  : null,
                              color: AppColors.teal,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.broken_image_outlined, size: 48, color: Colors.white54),
                                const SizedBox(height: 12),
                                Text(
                                  'Impossible de charger le scan (${_selected.fileId})',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
                border: Border(top: BorderSide(color: AppColors.inputBorder)),
              ),
              child: Row(
                children: [
                  Text(
                    _selected.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                      fontSize: 13,
                    ),
                  ),
                  if (_selected.classroom != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '· Salles : ${_selected.classroom}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                  const Spacer(),
                  const Text(
                    'Appwrite Storage : uniflow_academic',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
