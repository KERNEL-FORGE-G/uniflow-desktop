// `Databases.*Document` est marqué déprécié par le SDK Dart 26 au profit de
// `TablesDB.*Row` (Appwrite 1.8). Le schéma du projet est encore déclaré en
// collections/documents (`uniflow-we/scripts/appwrite-schema.mjs`) et la
// migration vers TablesDB se fera pour les trois clients en même temps ; on
// ignore la dépréciation ici, fichier par fichier, sans assouplir l'analyse
// globale.
// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/appwrite_models.dart';
import '../models/user_role.dart';
import '../providers/appwrite_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/directory_provider.dart';
import '../repositories/academic_repository.dart';
import '../repositories/management_repository.dart';
import '../services/uniflow_api.dart';
import '../theme/app_theme.dart';
import '../ui/app_button.dart';
import '../ui/app_data_table.dart';
import '../ui/app_dialog.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/data_state_view.dart';
import '../widgets/motion.dart';
import '../widgets/uni_icons.dart';

// ---------------------------------------------------------------------------
// Sélecteur de cours commun
// ---------------------------------------------------------------------------

/// Cours retenu dans les écrans Devoirs / Notes / Présences. Partagé pour
/// qu'un enseignant qui passe des devoirs aux notes retrouve le même cours.
final selectedCourseIdProvider = StateProvider<String?>((ref) => null);

class _CoursePicker extends ConsumerWidget {
  const _CoursePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(scopedCoursesProvider).valueOrNull ??
        const <AcademicCourse>[];
    final selected = ref.watch(selectedCourseIdProvider);
    final value = courses.any((c) => c.id == selected)
        ? selected
        : (courses.isEmpty ? null : courses.first.id);
    if (value != selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedCourseIdProvider.notifier).state = value;
      });
    }
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: const Text('Aucun cours dans votre périmètre',
              style: TextStyle(fontSize: 13)),
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          items: [
            for (final c in courses)
              DropdownMenuItem(
                value: c.id,
                child: Text('${c.code} · ${c.name} (${c.program} ${c.level})',
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) =>
              ref.read(selectedCourseIdProvider.notifier).state = v,
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _formatDateTime(DateTime d) =>
    '${_formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// Devoirs
// ---------------------------------------------------------------------------

final _assignmentsOfCourseProvider =
    FutureProvider.family<List<AcademicAssignment>, String>(
        (ref, courseId) async {
  final all = await ref.watch(academicRepositoryProvider).getAssignments();
  return all.where((a) => a.courseId == courseId).toList()
    ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
});

final _submissionsProvider =
    FutureProvider.family<List<SubmissionInfo>, String>((ref, assignmentId) {
  return ref.watch(assignmentsApiProvider).submissionsOf(assignmentId);
});

/// Gestion des devoirs. Un enseignant crée, modifie, publie et corrige ;
/// un apprenant voit les sujets de ses cours et ses propres rendus.
class AssignmentsManagementScreen extends ConsumerWidget {
  const AssignmentsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final canEdit = role == UserRole.teacher || role == UserRole.admin;
    final courseId = ref.watch(selectedCourseIdProvider);
    final courses = ref.watch(scopedCoursesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(
          title: 'Devoirs',
          subtitle: canEdit
              ? 'Publiez et corrigez les travaux de vos cours'
              : 'Les travaux demandés dans vos cours',
          actions: [
            if (canEdit)
              AppButton(
                label: 'Nouveau devoir',
                icon: UniIcons.add(UniIconStyle.bold),
                onPressed: courseId == null
                    ? null
                    : () => _openEditor(context, ref, courseId: courseId),
              ),
          ],
        ),
        const Padding(
            padding: EdgeInsets.fromLTRB(28, 18, 28, 0),
            child:
                Align(alignment: Alignment.centerLeft, child: _CoursePicker())),
        Expanded(
          child: courses.when(
            loading: () =>
                const DataLoadingView(label: 'Chargement de vos cours…'),
            error: (e, _) => DataErrorView(
                error: e, onRetry: () => ref.invalidate(scopedCoursesProvider)),
            data: (courseList) {
              final course =
                  courseList.where((c) => c.id == courseId).firstOrNull;
              if (courseId == null) {
                return DataEmptyView(
                  icon: UniIcons.assignments(),
                  message:
                      'Aucun cours dans votre périmètre : les devoirs s\'affichent par cours.',
                );
              }
              final assignments =
                  ref.watch(_assignmentsOfCourseProvider(courseId));
              return assignments.when(
                loading: () =>
                    const DataLoadingView(label: 'Chargement des devoirs…'),
                error: (e, _) => DataErrorView(
                    error: e,
                    onRetry: () =>
                        ref.invalidate(_assignmentsOfCourseProvider(courseId))),
                data: (items) {
                  if (items.isEmpty) {
                    return DataEmptyView(
                      icon: UniIcons.assignments(),
                      message: canEdit
                          ? 'Aucun devoir pour ce cours. Créez le premier avec « Nouveau devoir ».'
                          : 'Aucun devoir publié pour ce cours.',
                    );
                  }
                  return ListView.builder(
                    padding: AppSpacing.pageScroll,
                    itemCount: items.length,
                    itemBuilder: (context, i) => CascadeIn(
                      index: i,
                      child: _AssignmentCard(
                        assignment: items[i],
                        courseName: course?.name,
                        index: i,
                        canEdit: canEdit,
                        onEdit: () => _openEditor(context, ref,
                            courseId: courseId, existing: items[i]),
                        onDelete: () => _delete(context, ref, items[i]),
                        onSubmissions: () =>
                            _openSubmissions(context, items[i]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref,
      {required String courseId, AcademicAssignment? existing}) async {
    final courses =
        ref.read(scopedCoursesProvider).valueOrNull ?? const <AcademicCourse>[];
    final course = courses.where((c) => c.id == courseId).firstOrNull;
    if (course == null) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _AssignmentEditorDialog(course: course, existing: existing),
    );
    if (saved == true) ref.invalidate(_assignmentsOfCourseProvider(courseId));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref,
      AcademicAssignment assignment) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Supprimer ce devoir ?',
      message:
          '« ${assignment.title} » disparaîtra pour tous les étudiants du cours.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(assignmentsApiProvider).delete(assignment.id);
      ref.invalidate(_assignmentsOfCourseProvider(assignment.courseId));
      if (context.mounted) showFeedback(context, message: 'Devoir supprimé.');
    } on AppwriteException catch (e) {
      if (context.mounted) {
        showFeedback(
          context,
          message: 'Suppression refusée.',
          detail: e.code == 401
              ? 'Seul l\'auteur du devoir peut le supprimer.'
              : e.message,
          success: false,
        );
      }
    }
  }

  void _openSubmissions(BuildContext context, AcademicAssignment assignment) {
    Navigator.of(context)
        .push(softRoute(_SubmissionsScreen(assignment: assignment)));
  }
}

class _AssignmentCard extends StatelessWidget {
  final AcademicAssignment assignment;

  /// Nom du cours (le devoir ne porte que le code) : c'est lui qui donne
  /// l'icône de matière, le code seul (« INF201 ») ne dit rien.
  final String? courseName;
  final int index;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSubmissions;

  const _AssignmentCard({
    required this.assignment,
    this.courseName,
    this.index = 0,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    required this.onSubmissions,
  });

  @override
  Widget build(BuildContext context) {
    final due = DateTime.tryParse(assignment.dueDate);
    final overdue = due != null && due.isBefore(DateTime.now());
    final subjectTint = subjectColor(assignment.courseCode);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Un devoir en retard passe en gris : la couleur de matière ne
          // doit pas donner l'impression qu'il est encore d'actualité.
          IconTile(
            icon: subjectIcon(courseName ?? assignment.title,
                code: assignment.courseCode),
            color: overdue ? AppColors.textMuted : subjectTint,
            size: 44,
            variant: overdue ? IconTileVariant.soft : IconTileVariant.filled,
            index: index,
            semanticLabel: assignment.courseCode,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(
                  [
                    assignment.courseCode,
                    if (due != null) 'À rendre le ${_formatDateTime(due)}',
                    if (assignment.status != null &&
                        assignment.status!.isNotEmpty)
                      assignment.status!,
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: overdue ? AppColors.danger : null),
                ),
                if ((assignment.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(assignment.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (canEdit)
            Wrap(
              spacing: 2,
              children: [
                IconButton(
                    tooltip: 'Rendus et correction',
                    onPressed: onSubmissions,
                    icon: PhosphorIcon(UniIcons.checks(UniIconStyle.bold),
                        size: 20)),
                IconButton(
                    tooltip: 'Modifier',
                    onPressed: onEdit,
                    icon: PhosphorIcon(UniIcons.edit(UniIconStyle.bold),
                        size: 20)),
                IconButton(
                    tooltip: 'Supprimer',
                    onPressed: onDelete,
                    icon: PhosphorIcon(UniIcons.delete(UniIconStyle.bold),
                        size: 20, color: AppColors.textMuted)),
              ],
            ),
        ],
      ),
    );
  }
}

class _AssignmentEditorDialog extends ConsumerStatefulWidget {
  final AcademicCourse course;
  final AcademicAssignment? existing;
  const _AssignmentEditorDialog({required this.course, this.existing});

  @override
  ConsumerState<_AssignmentEditorDialog> createState() =>
      _AssignmentEditorDialogState();
}

class _AssignmentEditorDialogState
    extends ConsumerState<_AssignmentEditorDialog> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _maxScore = TextEditingController(text: '20');
  late DateTime _due = DateTime.tryParse(widget.existing?.dueDate ?? '') ??
      DateTime.now()
          .add(const Duration(days: 7))
          .copyWith(hour: 23, minute: 59);
  String _type = 'DEVOIR';
  bool _allowLate = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _maxScore.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_due));
    setState(() => _due = DateTime(
        date.year, date.month, date.day, time?.hour ?? 23, time?.minute ?? 59));
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Le titre est requis.');
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final draft = AssignmentDraft(
      courseId: widget.course.id,
      courseCode: widget.course.code,
      title: _title.text,
      description: _description.text,
      dueDate: _due,
      type: _type,
      maxScore: double.tryParse(_maxScore.text.replaceAll(',', '.')) ?? 20,
      allowLate: _allowLate,
    );
    try {
      final api = ref.read(assignmentsApiProvider);
      if (widget.existing == null) {
        await api.create(draft, teacherId: user.id, teacherName: user.name);
      } else {
        final data = draft.toData(teacherId: user.id, teacherName: user.name)
          ..remove('publishedAt')
          ..remove('status');
        await api.update(widget.existing!.id, data);
      }
      if (!mounted) return;
      showFeedback(context,
          message: widget.existing == null
              ? 'Devoir publié.'
              : 'Devoir mis à jour.');
      Navigator.pop(context, true);
    } on AppwriteException catch (e) {
      setState(() {
        _busy = false;
        _error = e.code == 401
            ? 'Appwrite refuse l\'écriture : seul l\'auteur du devoir peut le modifier.'
            : (e.message ?? 'Enregistrement impossible.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'Nouveau devoir · ${widget.course.code}'
          : 'Modifier le devoir'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                  controller: _title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Titre')),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Consignes', alignLabelWithHint: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'DEVOIR', child: Text('Devoir')),
                        DropdownMenuItem(
                            value: 'TP', child: Text('Travaux pratiques')),
                        DropdownMenuItem(
                            value: 'PROJET', child: Text('Projet')),
                        DropdownMenuItem(value: 'QUIZ', child: Text('Quiz')),
                      ],
                      onChanged: (v) => setState(() => _type = v ?? 'DEVOIR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _maxScore,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Barème'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: 'Date limite',
                      prefixIcon: PhosphorIcon(
                          UniIcons.schedule(UniIconStyle.bold),
                          size: 19)),
                  child: Text(_formatDateTime(_due)),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Accepter les rendus en retard',
                    style: TextStyle(fontSize: 13.5)),
                value: _allowLate,
                onChanged: (v) => setState(() => _allowLate = v),
              ),
              if (_error != null)
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 12.5)),
            ],
          ),
        ),
      ),
      actions: [
        AppButton.secondary(
            label: 'Annuler',
            onPressed: _busy ? null : () => Navigator.pop(context, false)),
        AppButton(
          label: widget.existing == null ? 'Publier' : 'Enregistrer',
          loading: _busy,
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}

/// Rendus d'un devoir et correction.
class _SubmissionsScreen extends ConsumerWidget {
  final AcademicAssignment assignment;
  const _SubmissionsScreen({required this.assignment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissions = ref.watch(_submissionsProvider(assignment.id));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Rendus · ${assignment.title}',
            overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: submissions.when(
        loading: () => const DataLoadingView(label: 'Chargement des remises…'),
        error: (e, _) => DataErrorView(
            error: e,
            onRetry: () => ref.invalidate(_submissionsProvider(assignment.id))),
        data: (items) {
          if (items.isEmpty) {
            return DataEmptyView(
                icon: UniIcons.tray(), message: 'Aucun rendu pour l\'instant.');
          }
          return ListView.builder(
            padding: AppSpacing.pageScroll,
            itemCount: items.length,
            itemBuilder: (context, i) {
              final s = items[i];
              return CascadeIn(
                index: i,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                s.studentName.isEmpty
                                    ? s.studentId
                                    : s.studentName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(
                              [
                                if (s.submittedAt != null)
                                  'Rendu le ${_formatDateTime(s.submittedAt!)}',
                                s.status,
                                if (s.score != null)
                                  '${s.score} / ${assignment.title.isEmpty ? 20 : 20}',
                              ].join('  ·  '),
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (s.fileId.isNotEmpty)
                        IconButton(
                          tooltip: 'Ouvrir le fichier',
                          onPressed: () => launchUrl(Uri.parse(ref
                              .read(appwriteServiceProvider)
                              .fileViewUrl(s.fileId))),
                          icon: PhosphorIcon(
                              UniIcons.attachment(UniIconStyle.bold),
                              size: 20),
                        ),
                      AppButton.secondary(
                        label: s.score == null ? 'Noter' : 'Modifier la note',
                        height: 38,
                        onPressed: () => _grade(context, ref, s),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _grade(
      BuildContext context, WidgetRef ref, SubmissionInfo submission) async {
    final scoreController =
        TextEditingController(text: submission.score?.toString() ?? '');
    final feedbackController = TextEditingController(text: submission.feedback);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Noter ${submission.studentName}'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: scoreController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Note')),
              const SizedBox(height: 12),
              TextField(
                  controller: feedbackController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Commentaire')),
            ],
          ),
        ),
        actions: [
          AppButton.secondary(
              label: 'Annuler',
              onPressed: () => Navigator.pop(dialogContext, false)),
          AppButton(
              label: 'Enregistrer',
              onPressed: () => Navigator.pop(dialogContext, true)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final score = double.tryParse(scoreController.text.replaceAll(',', '.'));
    if (score == null) {
      showFeedback(context, message: 'Note invalide.', success: false);
      return;
    }
    try {
      await ref.read(assignmentsApiProvider).gradeSubmission(submission.id,
          score: score, feedback: feedbackController.text);
      ref.invalidate(_submissionsProvider(assignment.id));
      if (context.mounted) showFeedback(context, message: 'Note enregistrée.');
    } on AppwriteException catch (e) {
      if (context.mounted) {
        showFeedback(
          context,
          message: 'Correction refusée par Appwrite.',
          detail: e.code == 401
              ? 'Le rendu appartient à l\'étudiant ; la correction doit passer par un service serveur (à signaler).'
              : e.message,
          success: false,
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Notes
// ---------------------------------------------------------------------------

final _rosterProvider =
    FutureProvider.family<GradeRoster, String>((ref, courseId) {
  return ref.watch(gradesApiProvider).roster(courseId);
});

final _myGradesProvider = FutureProvider<List<AcademicGrade>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final all = await ref.watch(academicRepositoryProvider).getAllGrades();
  return all.where((g) => g.studentId == user.id).toList();
});

/// Saisie des notes par l'enseignant (grille étudiants × évaluations, via
/// `/academic-grades`) ; un apprenant voit son propre relevé.
class GradesManagementScreen extends ConsumerWidget {
  const GradesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    final canEdit = role == UserRole.teacher || role == UserRole.admin;
    if (!canEdit) return const _MyGradesView();

    final courseId = ref.watch(selectedCourseIdProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(
          title: 'Notes',
          subtitle: 'Saisie et publication des évaluations de vos cours',
          actions: [
            if (courseId != null)
              AppButton(
                label: 'Nouvelle évaluation',
                icon: UniIcons.add(UniIconStyle.bold),
                onPressed: () => _addEvaluation(context, ref, courseId),
              ),
          ],
        ),
        const Padding(
            padding: EdgeInsets.fromLTRB(28, 18, 28, 0),
            child:
                Align(alignment: Alignment.centerLeft, child: _CoursePicker())),
        Expanded(
          child: courseId == null
              ? DataEmptyView(
                  icon: UniIcons.grades(),
                  message: 'Aucun cours dans votre périmètre.')
              : ref.watch(_rosterProvider(courseId)).when(
                    loading: () => const DataLoadingView(
                        label: 'Chargement de la grille de notes…'),
                    error: (e, _) => DataErrorView(
                        error: e,
                        onRetry: () =>
                            ref.invalidate(_rosterProvider(courseId))),
                    data: (roster) => _GradeGrid(roster: roster),
                  ),
        ),
      ],
    );
  }

  Future<void> _addEvaluation(
      BuildContext context, WidgetRef ref, String courseId) async {
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nouvelle évaluation'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: title,
            autofocus: true,
            decoration:
                const InputDecoration(labelText: 'Intitulé (CC1, TP, Examen…)'),
          ),
        ),
        actions: [
          AppButton.secondary(
              label: 'Annuler',
              onPressed: () => Navigator.pop(dialogContext, false)),
          AppButton(
              label: 'Ajouter',
              onPressed: () => Navigator.pop(dialogContext, true)),
        ],
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    ref
        .read(_pendingEvaluationsProvider(courseId).notifier)
        .update((s) => {...s, title.text.trim()});
  }
}

/// Colonnes ajoutées mais encore vides : elles n'existent côté serveur qu'à
/// la première note saisie.
final _pendingEvaluationsProvider =
    StateProvider.family<Set<String>, String>((ref, _) => <String>{});

class _GradeGrid extends ConsumerWidget {
  final GradeRoster roster;
  const _GradeGrid({required this.roster});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(_pendingEvaluationsProvider(roster.courseId));
    final titles = [
      ...roster.evaluationTitles,
      ...pending.where((p) => !roster.evaluationTitles.contains(p))
    ];
    if (roster.students.isEmpty) {
      return DataEmptyView(
          icon: UniIcons.students(),
          message: 'Aucun apprenant inscrit à ce cours.');
    }
    // Une colonne par évaluation, de largeur fixe pour que les notes restent
    // alignées ; au-delà de quelques évaluations la grille défile.
    const evaluationWidth = 104.0;
    return SingleChildScrollView(
      padding: AppSpacing.pageScroll,
      child: AppDataTable<RosterStudent>(
        columns: [
          const AppColumn('Apprenant', flex: 3),
          for (final t in titles)
            AppColumn(t, width: evaluationWidth, align: TextAlign.center),
          const AppColumn('Moyenne', width: 90, align: TextAlign.right),
        ],
        rows: roster.students,
        minWidth: 300 + evaluationWidth * titles.length + 90,
        rowHeight: 46,
        cells: (student, _) => [
          Text(
            '${student.name}${student.matricule.isNotEmpty ? ' · ${student.matricule}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          for (final t in titles)
            // Toute la cellule est cliquable, pas seulement la pastille : une
            // case vide (« — ») serait sinon presque impossible à viser.
            InkWell(
              onTap: () => _edit(
                  context, ref, student, t, roster.gradeOf(student.userId, t)),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: evaluationWidth,
                height: 36,
                child: Center(
                  child: _GradeCell(grade: roster.gradeOf(student.userId, t)),
                ),
              ),
            ),
          Text(_average(student.userId),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
        footer: AppTableFooter(
          label: AppTableFooter.count(roster.students.length, 'apprenant'),
        ),
      ),
    );
  }

  String _average(String studentId) {
    final grades =
        roster.grades.where((g) => g.studentId == studentId).toList();
    if (grades.isEmpty) return '—';
    var weighted = 0.0;
    var coefficients = 0.0;
    for (final g in grades) {
      weighted += (g.score / g.maxScore) * 20 * g.coefficient;
      coefficients += g.coefficient;
    }
    return (weighted / coefficients).toStringAsFixed(2);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, RosterStudent student,
      String title, AcademicGrade? existing) async {
    final score = TextEditingController(
        text: existing == null ? '' : existing.score.toStringAsFixed(0));
    final max = TextEditingController(
        text: existing == null ? '20' : existing.maxScore.toStringAsFixed(0));
    final coefficient = TextEditingController(
        text: existing == null ? '1' : existing.coefficient.toStringAsFixed(0));
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$title · ${student.name}'),
        content: SizedBox(
          width: 360,
          child: Row(
            children: [
              Expanded(
                  child: TextField(
                      controller: score,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Note'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: max,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sur'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: coefficient,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Coef.'))),
            ],
          ),
        ),
        actions: [
          if (existing != null)
            AppButton.danger(
              label: 'Supprimer',
              onPressed: () => Navigator.pop(dialogContext, 'delete'),
            ),
          AppButton.secondary(
              label: 'Annuler',
              onPressed: () => Navigator.pop(dialogContext, null)),
          AppButton(
              label: 'Enregistrer',
              onPressed: () => Navigator.pop(dialogContext, 'save')),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    final api = ref.read(gradesApiProvider);
    try {
      if (action == 'delete' && existing != null) {
        await api.delete(
            courseId: roster.courseId,
            studentId: student.userId,
            gradeId: existing.id);
        if (context.mounted) showFeedback(context, message: 'Note supprimée.');
      } else {
        final value = int.tryParse(score.text.trim());
        final maxValue = int.tryParse(max.text.trim()) ?? 20;
        if (value == null || value < 0 || value > maxValue) {
          if (context.mounted) {
            showFeedback(context,
                message: 'Note invalide (entier entre 0 et $maxValue).',
                success: false);
          }
          return;
        }
        await api.upsert(
          courseId: roster.courseId,
          studentId: student.userId,
          evaluationTitle: title,
          score: value,
          maxScore: maxValue,
          coefficient: int.tryParse(coefficient.text.trim()) ?? 1,
        );
        if (context.mounted) {
          showFeedback(context,
              message: 'Note enregistrée pour ${student.name}.');
        }
      }
      ref.invalidate(_rosterProvider(roster.courseId));
    } on ApiException catch (e) {
      if (context.mounted) {
        showFeedback(context,
            message: 'Refusé par le serveur.',
            detail: e.message,
            success: false);
      }
    }
  }
}

class _GradeCell extends StatelessWidget {
  final AcademicGrade? grade;
  const _GradeCell({this.grade});

  @override
  Widget build(BuildContext context) {
    if (grade == null) {
      return const Text('—', style: TextStyle(color: AppColors.textMuted));
    }
    final ratio = grade!.score / grade!.maxScore;
    final color = ratio >= 0.5 ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6)),
      child: Text(
        '${grade!.score.toStringAsFixed(grade!.score.truncateToDouble() == grade!.score ? 0 : 1)}/${grade!.maxScore.toStringAsFixed(0)}',
        style: TextStyle(
            color: color, fontWeight: FontWeight.w700, fontSize: 12.5),
      ),
    );
  }
}

class _MyGradesView extends ConsumerWidget {
  const _MyGradesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grades = ref.watch(_myGradesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppTopBar(
            title: 'Mes notes',
            subtitle: 'Vos résultats, par cours et par évaluation'),
        Expanded(
          child: grades.when(
            loading: () =>
                const DataLoadingView(label: 'Chargement de vos notes…'),
            error: (e, _) => DataErrorView(
                error: e, onRetry: () => ref.invalidate(_myGradesProvider)),
            data: (items) {
              if (items.isEmpty) {
                return DataEmptyView(
                    icon: UniIcons.grades(),
                    message: 'Aucune note publiée pour l\'instant.');
              }
              // Les notes ne portent que le code du cours ; le nom, quand la
              // liste des cours est déjà chargée, donne une icône parlante.
              final courseNames = {
                for (final c in ref.watch(scopedCoursesProvider).valueOrNull ??
                    const <AcademicCourse>[])
                  c.code: c.name,
              };
              final byCourse = <String, List<AcademicGrade>>{};
              for (final g in items) {
                byCourse.putIfAbsent(g.courseCode, () => []).add(g);
              }
              final codes = byCourse.keys.toList()..sort();
              return ListView.builder(
                padding: AppSpacing.pageScroll,
                itemCount: codes.length,
                itemBuilder: (context, i) {
                  final list = byCourse[codes[i]]!;
                  return CascadeIn(
                    index: i,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconTile(
                                icon: subjectIcon(
                                    courseNames[codes[i]] ?? codes[i],
                                    code: codes[i]),
                                color: subjectColor(codes[i]),
                                size: 36,
                                index: i,
                                semanticLabel: codes[i],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  courseNames[codes[i]] ?? codes[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.h3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final g in list)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputFill,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(g.evaluationTitle,
                                          style: AppTextStyles.bodySmall),
                                      const SizedBox(height: 2),
                                      _GradeCell(grade: g),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bibliothèque
// ---------------------------------------------------------------------------

class LibraryItem {
  final String id;
  final String title;
  final String course;
  final String type;
  final String category;
  final String size;
  final String description;
  final String fileId;
  const LibraryItem({
    required this.id,
    required this.title,
    this.course = '',
    this.type = '',
    this.category = '',
    this.size = '',
    this.description = '',
    this.fileId = '',
  });
}

final libraryProvider = FutureProvider<List<LibraryItem>>((ref) async {
  // Recalculé à chaque changement de compte : les caches du compte précédent
  // survivaient à la déconnexion.
  ref.watch(currentUserProvider.select((u) => u?.id));
  final service = ref.watch(appwriteServiceProvider);
  final response = await service.databases.listDocuments(
    databaseId: service.databaseId,
    collectionId: 'academic_library',
    queries: [Query.orderDesc('\$createdAt'), Query.limit(200)],
  );
  return response.documents.map((d) {
    final data = d.data;
    return LibraryItem(
      id: d.$id,
      title: data['title'] as String? ?? '',
      course: data['course'] as String? ?? '',
      type: data['type'] as String? ?? '',
      category: data['category'] as String? ?? '',
      size: data['size'] as String? ?? '',
      description: data['description'] as String? ?? '',
      fileId: data['fileId'] as String? ?? '',
    );
  }).toList();
});

///// Bibliothèque numérique : documents de `academic_library`, fichiers dans
/// le bucket `uniflow_assets`. Enseignants et administration téléversent.
/// Modèle d'ouvrage académique issu du service /open-library (Uni Book).
class DesktopUniBookItem {
  final String id;
  final String title;
  final List<String> authors;
  final String category;
  final String? coverUrl;
  final String? downloadUrl;
  final String format;
  final String source;
  final int? year;
  final String? description;
  final int downloadsCount;

  const DesktopUniBookItem({
    required this.id,
    required this.title,
    required this.authors,
    required this.category,
    this.coverUrl,
    this.downloadUrl,
    this.format = 'PDF',
    this.source = 'Uni Book',
    this.year,
    this.description,
    this.downloadsCount = 100,
  });

  factory DesktopUniBookItem.fromJson(Map<String, dynamic> json) {
    return DesktopUniBookItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Livre').toString(),
      authors: (json['authors'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      category: (json['category'] ?? 'Général').toString(),
      coverUrl: json['coverUrl'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      format: (json['format'] ?? 'PDF').toString(),
      source: (json['source'] ?? 'Uni Book').toString(),
      year: json['year'] is int ? json['year'] as int : null,
      description: json['description'] as String?,
      downloadsCount: (json['downloadsCount'] as num?)?.toInt() ?? 100,
    );
  }
}

class LibraryManagementScreen extends ConsumerStatefulWidget {
  const LibraryManagementScreen({super.key});

  @override
  ConsumerState<LibraryManagementScreen> createState() =>
      _LibraryManagementScreenState();
}

class _LibraryManagementScreenState
    extends ConsumerState<LibraryManagementScreen> {
  String _selectedCategory = 'Tous';
  String _searchQuery = '';

  // ── Mode Uni Book ──────────────────────────────────────────────────────────
  int _selectedMode = 0; // 0 = Supports de cours, 1 = Uni Book (Recherche libre)
  final _uniBookSearchCtrl = TextEditingController();
  String _selectedUniBookCategory = 'Tous';
  bool _isLoadingUniBook = false;
  String? _uniBookError;
  List<DesktopUniBookItem> _uniBookResults = const [];

  static const _categories = [
    'Tous',
    'Supports de cours',
    'Informatique & IA',
    'Mathématiques & Data',
    'Physique & Sciences',
    'Droit & Sciences Po',
    'Économie & Gestion',
    'Médecine & Santé',
    'Travaux dirigés (TD)',
    'Travaux pratiques (TP)',
    'Annales d\'examens',
    'Fiches de révision',
  ];

  static const _uniBookCategories = [
    'Tous',
    'Informatique',
    'Mathématiques',
    'Physique',
    'Chimie',
    'Biologie',
    'Économie',
    'Sciences',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchUniBook('sciences');
    });
  }

  @override
  void dispose() {
    _uniBookSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchUniBook(String query, {String? category}) async {
    final effectiveCat = category ?? _selectedUniBookCategory;
    final catQuery = effectiveCat == 'Tous' ? '' : effectiveCat;
    final fullQuery = [query.trim(), catQuery].where((s) => s.isNotEmpty).join(' ');
    final searchTerm = fullQuery.isEmpty ? 'informatique mathematiques' : fullQuery;

    setState(() {
      _isLoadingUniBook = true;
      _uniBookError = null;
    });

    try {
      Map<String, dynamic>? res;
      try {
        final raw = await ref.read(uniflowApiProvider).call(
          ApiPaths.openLibrary,
          {
            'action': 'search',
            'query': searchTerm,
            'limit': 35,
          },
        );
        res = raw;
      } catch (_) {
        res = null;
      }

      // Le web UniFlow retransmet l'API book si le BaaS local/cloud tarde ou échoue
      if (res == null || res['ok'] != true) {
        try {
          final client = HttpClient();
          final uri = Uri.parse('https://uniflow.kernelforge.codes/api/books').replace(queryParameters: {
            'q': searchTerm,
            'limit': '35',
          });
          final req = await client.getUrl(uri).timeout(const Duration(seconds: 6));
          final resp = await req.close().timeout(const Duration(seconds: 6));
          if (resp.statusCode == 200) {
            final body = await resp.transform(utf8.decoder).join();
            res = jsonDecode(body) as Map<String, dynamic>;
          }
        } catch (_) {}
      }

      if (mounted) {
        final rawList = res?['books'] ?? res?['results'];
        if (res != null && res['ok'] == true && rawList is List) {
          final books = rawList
              .whereType<Map>()
              .map((m) => DesktopUniBookItem.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          setState(() {
            _uniBookResults = books;
            _isLoadingUniBook = false;
          });
        } else {
          setState(() {
            _uniBookError = res?['error']?.toString() ?? 'Erreur lors de la recherche Uni Book';
            _isLoadingUniBook = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uniBookError = e.toString();
          _isLoadingUniBook = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(libraryProvider);
    final role = ref.watch(currentRoleProvider);
    final canUpload = role == UserRole.teacher || role == UserRole.admin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTopBar(
          title: 'Bibliothèque',
          subtitle: _selectedMode == 0
              ? 'Supports de cours et ressources partagées'
              : 'Uni Book — Accès universel aux manuels et ouvrages académiques libres',
          actions: [
            // ── Sélecteur de mode (Supports vs Uni Book) ──
            Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.primary100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModePill(
                    label: 'Supports de cours',
                    icon: Icons.school_rounded,
                    selected: _selectedMode == 0,
                    onTap: () => setState(() => _selectedMode = 0),
                  ),
                  _ModePill(
                    label: 'Uni Book · Libre',
                    icon: Icons.auto_stories_rounded,
                    selected: _selectedMode == 1,
                    onTap: () {
                      setState(() => _selectedMode = 1);
                      if (_uniBookResults.isEmpty && !_isLoadingUniBook) {
                        _searchUniBook('sciences');
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_selectedMode == 0 && canUpload)
              AppButton(
                label: 'Téléverser',
                icon: UniIcons.upload(UniIconStyle.bold),
                onPressed: () => _upload(context, ref),
              ),
          ],
        ),
        Expanded(
          child: _selectedMode == 0
              ? items.when(
                  loading: () => const DataLoadingView(
                      label: 'Chargement de la bibliothèque…'),
                  error: (e, _) => DataErrorView(
                      error: e, onRetry: () => ref.invalidate(libraryProvider)),
                  data: (list) {
                    final query = _searchQuery.trim().toLowerCase();
                    final filtered = list.where((item) {
                      final matchCat = _selectedCategory == 'Tous' ||
                          item.category
                              .toLowerCase()
                              .contains(_selectedCategory.toLowerCase()) ||
                          (_selectedCategory == 'Supports de cours' &&
                              (item.category.isEmpty ||
                                  item.category
                                      .toLowerCase()
                                      .contains('cours'))) ||
                          (_selectedCategory == 'Travaux dirigés (TD)' &&
                              item.category.toLowerCase().contains('td')) ||
                          (_selectedCategory == 'Travaux pratiques (TP)' &&
                              item.category.toLowerCase().contains('tp')) ||
                          (_selectedCategory == 'Annales d\'examens' &&
                              item.category.toLowerCase().contains('annale')) ||
                          (_selectedCategory == 'Fiches de révision' &&
                              item.category.toLowerCase().contains('fiche'));

                      final matchQuery = query.isEmpty ||
                          item.title.toLowerCase().contains(query) ||
                          item.course.toLowerCase().contains(query) ||
                          item.type.toLowerCase().contains(query) ||
                          item.description.toLowerCase().contains(query);

                      return matchCat && matchQuery;
                    }).toList();

                    return SingleChildScrollView(
                      padding: AppSpacing.pageScroll,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LibraryHeroBanner(totalCount: list.length),
                          const SizedBox(height: AppSpacing.xl),
                          _LibraryFilterBar(
                            categories: _categories,
                            selectedCategory: _selectedCategory,
                            onCategorySelected: (cat) =>
                                setState(() => _selectedCategory = cat),
                            onSearchChanged: (q) =>
                                setState(() => _searchQuery = q),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: DataEmptyView(
                                  icon: UniIcons.library(),
                                  message: list.isEmpty
                                      ? 'Aucune ressource pour l\'instant.'
                                      : 'Aucun document ne correspond à votre recherche.',
                                ),
                              ),
                            )
                          else
                            Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: [
                                for (var i = 0; i < filtered.length; i++)
                                  CascadeIn(
                                    index: i,
                                    child: _LibraryCard(
                                      item: filtered[i],
                                      onOpen: filtered[i].fileId.isEmpty
                                          ? null
                                          : () => launchUrl(Uri.parse(ref
                                              .read(appwriteServiceProvider)
                                              .fileViewUrl(
                                                  filtered[i].fileId))),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                )
              : _buildUniBookView(),
        ),
      ],
    );
  }

  Widget _buildUniBookView() {
    return SingleChildScrollView(
      padding: AppSpacing.pageScroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bannière Uni Book ──
          const _UniBookHeroBanner(),
          const SizedBox(height: AppSpacing.xl),

          // ── Barre de recherche Uni Book + Catégories ──
          _UniBookFilterBar(
            controller: _uniBookSearchCtrl,
            categories: _uniBookCategories,
            selectedCategory: _selectedUniBookCategory,
            onSubmitted: (q) => _searchUniBook(q),
            onCategorySelected: (cat) {
              setState(() => _selectedUniBookCategory = cat);
              _searchUniBook(_uniBookSearchCtrl.text, category: cat);
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Contenu Uni Book ──
          if (_isLoadingUniBook)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: DataLoadingView(
                  label: 'Recherche Uni Book en cours (indexation mondiale)…',
                ),
              ),
            )
          else if (_uniBookError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: DataErrorView(
                  error: _uniBookError!,
                  onRetry: () => _searchUniBook(_uniBookSearchCtrl.text),
                ),
              ),
            )
          else if (_uniBookResults.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: DataEmptyView(
                  icon: Icons.menu_book_rounded,
                  message: 'Aucun ouvrage trouvé pour cette recherche.',
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D9488),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_uniBookResults.length} ouvrages académiques disponibles en accès libre',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                for (var i = 0; i < _uniBookResults.length; i++)
                  CascadeIn(
                    index: i,
                    child: _UniBookDesktopCard(
                      book: _uniBookResults[i],
                      onDownload: _uniBookResults[i].downloadUrl != null
                          ? () => launchUrl(
                              Uri.parse(_uniBookResults[i].downloadUrl!))
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }


  Future<void> _upload(BuildContext context, WidgetRef ref) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Documents', extensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'txt',
          'zip',
          'png',
          'jpg',
          'jpeg'
        ]),
      ],
    );
    if (file == null || !context.mounted) return;
    final courses =
        ref.read(scopedCoursesProvider).valueOrNull ?? const <AcademicCourse>[];
    final title = TextEditingController(text: file.name.split('.').first);
    final description = TextEditingController();
    String? courseId = courses.isEmpty ? null : courses.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Téléverser une ressource'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Titre')),
                const SizedBox(height: 12),
                if (courses.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: courseId,
                    decoration: const InputDecoration(labelText: 'Cours'),
                    items: [
                      for (final c in courses)
                        DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.code} · ${c.name}',
                                overflow: TextOverflow.ellipsis))
                    ],
                    onChanged: (v) => setState(() => courseId = v),
                  ),
                const SizedBox(height: 12),
                TextField(
                    controller: description,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(file.name, style: AppTextStyles.bodySmall)),
              ],
            ),
          ),
          actions: [
            AppButton.secondary(
                label: 'Annuler',
                onPressed: () => Navigator.pop(dialogContext, false)),
            AppButton(
                label: 'Téléverser',
                onPressed: () => Navigator.pop(dialogContext, true)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final service = ref.read(appwriteServiceProvider);
    final user = ref.read(currentUserProvider);
    final course = courses.where((c) => c.id == courseId).firstOrNull;
    try {
      final length = await file.length();
      final created = await service.storage.createFile(
        bucketId: service.chatFilesBucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: file.path, filename: file.name),
        permissions: [Permission.read(Role.users())],
      );
      await service.databases.createDocument(
        databaseId: service.databaseId,
        collectionId: 'academic_library',
        documentId: ID.unique(),
        data: {
          'title': title.text.trim(),
          'courseId': course?.id ?? '',
          'course': course == null ? '' : '${course.code} · ${course.name}',
          'type': file.name.contains('.')
              ? file.name.split('.').last.toUpperCase()
              : '',
          'category': 'Support de cours',
          'size': _humanSize(length),
          'description': description.text.trim(),
          'fileId': created.$id,
        },
        permissions: [
          Permission.read(Role.users()),
          if (user != null) Permission.update(Role.user(user.id)),
          if (user != null) Permission.delete(Role.user(user.id)),
        ],
      );
      ref.invalidate(libraryProvider);
      if (context.mounted) {
        showFeedback(context, message: 'Ressource publiée.', detail: file.name);
      }
    } on AppwriteException catch (e) {
      if (context.mounted) {
        showFeedback(context,
            message: 'Téléversement refusé.',
            detail: e.message,
            success: false);
      }
    }
  }

  static String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}

class _LibraryHeroBanner extends StatelessWidget {
  final int totalCount;
  const _LibraryHeroBanner({required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 320,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppRadius.lg),
                bottomRight: Radius.circular(AppRadius.lg),
              ),
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.black, Colors.transparent],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/illustrations/hero_books.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '$totalCount ressources disponibles',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bibliothèque Numérique Campus',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Accédez à tous les cours, fascicules de TD/TP, annales d\'examens et ressources.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onSearchChanged;

  const _LibraryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un cours, un titre, un mot-clé ou un format…',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cat in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    onSelected: (val) {
                      if (val) onCategorySelected(cat);
                    },
                    selectedColor: AppColors.primaryBlue,
                    backgroundColor: AppColors.cardWhite,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedCategory == cat ? FontWeight.w700 : FontWeight.w500,
                      color: selectedCategory == cat ? Colors.white : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: selectedCategory == cat ? AppColors.primaryBlue : AppColors.inputBorder,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final LibraryItem item;
  final VoidCallback? onOpen;
  const _LibraryCard({required this.item, this.onOpen});

  IconData get _icon {
    const style = UniIcons.defaultStyle;
    return switch (item.type.toUpperCase()) {
      'PDF' => UniIcons.filePdf(style),
      'PPT' || 'PPTX' => UniIcons.filePpt(style),
      'XLS' || 'XLSX' => UniIcons.fileXls(style),
      'PNG' || 'JPG' || 'JPEG' => UniIcons.fileImage(style),
      'ZIP' => UniIcons.fileZip(style),
      _ => UniIcons.fileText(style),
    };
  }

  Color get _tint =>
      item.course.isEmpty ? AppColors.primaryBlue : subjectColor(item.course);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Couverture avec illustration livre réelle ──
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_tint.withValues(alpha: 0.85), _tint],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Image.asset(
                  'assets/illustrations/course_books.jpg',
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.15),
                  colorBlendMode: BlendMode.darken,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(_icon, size: 48, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
              ),
              if (item.type.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    item.category.isEmpty ? 'Document' : item.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _tint,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Informations du document ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (item.course.isNotEmpty)
                      Expanded(
                        child: Text(
                          item.course,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _tint,
                          ),
                        ),
                      ),
                    if (item.size.isNotEmpty)
                      Text(
                        item.size,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onOpen,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PhosphorIcon(
                                UniIcons.openExternal(UniIconStyle.bold),
                                size: 14,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Consulter',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UniBookHeroBanner extends StatelessWidget {
  const _UniBookHeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 300,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppRadius.lg),
                bottomRight: Radius.circular(AppRadius.lg),
              ),
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.black, Colors.transparent],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/illustrations/hero_books.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Uni Book · Recherche Libre & Gratuite',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Uni Book — Bibliothèque Académique Mondiale',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Manuels universitaires, livres de cours, articles scientifiques et ouvrages de référence en accès direct.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UniBookFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onCategorySelected;

  const _UniBookFilterBar({
    required this.controller,
    required this.categories,
    required this.selectedCategory,
    required this.onSubmitted,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.inputBorder),
                  boxShadow: AppShadows.card,
                ),
                child: TextField(
                  controller: controller,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un livre, un manuel, un auteur (ex: Python, Algorithmique, Analyse)…',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D9488), size: 22),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              controller.clear();
                              onSubmitted('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AppButton(
              label: 'Rechercher',
              icon: Icons.search_rounded,
              onPressed: () => onSubmitted(controller.text),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cat in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    onSelected: (val) {
                      if (val) onCategorySelected(cat);
                    },
                    selectedColor: const Color(0xFF0D9488),
                    backgroundColor: AppColors.cardWhite,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedCategory == cat ? FontWeight.w700 : FontWeight.w500,
                      color: selectedCategory == cat ? Colors.white : AppColors.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: selectedCategory == cat ? const Color(0xFF0D9488) : AppColors.inputBorder,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UniBookDesktopCard extends StatelessWidget {
  final DesktopUniBookItem book;
  final VoidCallback? onDownload;

  const _UniBookDesktopCard({
    required this.book,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                color: const Color(0xFF0F172A),
                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackCover(),
                      )
                    : _buildFallbackCover(),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    book.format.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              if (book.year != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${book.year}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Uni Book · Libre',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.authors.isNotEmpty ? book.authors.join(', ') : 'Auteur universitaire',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Consulter / Télécharger',
                    icon: Icons.download_rounded,
                    onPressed: onDownload,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_rounded, size: 40, color: Colors.white70),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

