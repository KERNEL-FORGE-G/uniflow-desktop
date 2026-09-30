import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/badges.dart';
import '../providers/appwrite_provider.dart';
import '../providers/auth_provider.dart';
import '../repositories/academic_repository.dart';

/// Relevés de présence individuels de l'apprenant connecté.
///
/// `getStudentAttendance()` agrège par étudiant (vue admin). Ici on veut
/// les enregistrements bruts de `attendance_records` pour calculer le taux
/// de présence personnel et l'assiduité badge.
final _myRawAttendanceProvider =
    FutureProvider<List<AttendanceMark>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final service = ref.read(appwriteServiceProvider);
  try {
    final response = await service.databases.listDocuments(
      databaseId: service.databaseId,
      collectionId: 'attendance_records',
      queries: [Query.equal('studentId', user.id), Query.limit(2000)],
    );
    return response.documents.map(AttendanceMark.fromDocument).toList();
  } catch (_) {
    return const [];
  }
});

/// Devoirs et soumissions de l'apprenant connecté, format badge.
final _myBadgeAssignmentsProvider =
    FutureProvider<({List<BadgeAssignment> assignments, List<BadgeSubmission> submissions})>(
        (ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return (assignments: const <BadgeAssignment>[], submissions: const <BadgeSubmission>[]);
  final service = ref.read(appwriteServiceProvider);
  try {
    // Soumissions de cet apprenant
    final subResponse = await service.databases.listDocuments(
      databaseId: service.databaseId,
      collectionId: 'assignment_submissions',
      queries: [Query.equal('studentId', user.id), Query.limit(500)],
    );
    final submissions = subResponse.documents.map((doc) {
      final submittedRaw = doc.data['submittedAt'] ?? '';
      DateTime submitted;
      try {
        submitted = DateTime.parse(submittedRaw.toString());
      } catch (_) {
        submitted = DateTime.now();
      }
      final scoreRaw = doc.data['score'];
      return BadgeSubmission(
        assignmentId: '${doc.data['assignmentId'] ?? doc.data['taskId'] ?? ''}',
        submittedAt: submitted,
        score: scoreRaw == null ? null : double.tryParse('$scoreRaw'),
      );
    }).toList();

    if (submissions.isEmpty) {
      return (assignments: const <BadgeAssignment>[], submissions: const <BadgeSubmission>[]);
    }

    // Devoirs référencés par les soumissions
    final assignmentIds =
        submissions.map((s) => s.assignmentId).where((id) => id.isNotEmpty).toSet().toList();
    final assignments = <BadgeAssignment>[];
    // Requêtes par lots de 25 (limite Appwrite)
    for (var i = 0; i < assignmentIds.length; i += 25) {
      final chunk = assignmentIds.sublist(
          i, i + 25 > assignmentIds.length ? assignmentIds.length : i + 25);
      try {
        final aRes = await service.databases.listDocuments(
          databaseId: service.databaseId,
          collectionId: 'academic_assignments',
          queries: [Query.equal('\$id', chunk), Query.limit(25)],
        );
        for (final doc in aRes.documents) {
          DateTime due;
          try {
            due = DateTime.parse('${doc.data['dueDate'] ?? ''}');
          } catch (_) {
            due = DateTime.now().add(const Duration(days: 30));
          }
          final typeRaw = '${doc.data['type'] ?? ''}'.toUpperCase();
          assignments.add(BadgeAssignment(
            id: doc.$id,
            dueDate: due,
            isQuiz: typeRaw == 'QUIZ',
            maxScore: double.tryParse('${doc.data['maxScore'] ?? 20}') ?? 20,
          ));
        }
      } catch (_) {
        // Un lot manquant : on continue avec ce qu'on a.
      }
    }
    return (assignments: assignments, submissions: submissions);
  } catch (_) {
    return (assignments: const <BadgeAssignment>[], submissions: const <BadgeSubmission>[]);
  }
});

/// Nombre de sujets forum publiés par l'apprenant connecté.
final _myForumPostCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  final service = ref.read(appwriteServiceProvider);
  try {
    final response = await service.databases.listDocuments(
      databaseId: service.databaseId,
      collectionId: 'forum_posts',
      queries: [Query.equal('authorId', user.id), Query.limit(100)],
    );
    return response.documents.length;
  } catch (_) {
    return 0;
  }
});

/// Les six badges de l'apprenant connecté, calculés sur ses données réelles.
///
/// Chaque source défaillante est traitée comme vide : mieux vaut afficher
/// 0 % de progression qu'un accueil cassé.
final studentBadgesProvider = FutureProvider<List<BadgeProgress>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];

  final repository = ref.watch(academicRepositoryProvider);

  final (attendance, grades, assignmentsData, posts) = await (
    ref.watch(_myRawAttendanceProvider.future),
    repository.getAllGrades(),
    ref.watch(_myBadgeAssignmentsProvider.future),
    ref.watch(_myForumPostCountProvider.future),
  ).wait;

  // Filtrer les notes de cet apprenant.
  final myGrades = grades
      .where((g) => g.studentId == user.id || g.studentId.isEmpty)
      .toList();

  return computeBadges(BadgeInputs(
    studentId: user.id,
    attendance: attendance,
    grades: myGrades,
    assignments: assignmentsData.assignments,
    submissions: assignmentsData.submissions,
    forumPostsByStudent: posts,
  ));
});
