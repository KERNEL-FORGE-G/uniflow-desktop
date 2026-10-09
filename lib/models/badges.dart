import 'package:appwrite/models.dart' as models;

import 'appwrite_models.dart';

/// Les six badges d'un apprenant, portés du mobile vers le desktop.
/// Même assets, même règles métier — un badge affiche le même état sur
/// tous les appareils d'un même compte.
enum StudentBadge {
  premierPas(
    'premier_pas',
    'Premier pas',
    'Rendre son premier devoir.',
    'Premier devoir rendu — la suite est lancée.',
  ),
  assidu(
    'assidu',
    'Assidu',
    'Être présent à 90 % des séances relevées (au moins 5).',
    'Présent à 90 % des séances : une assiduité exemplaire.',
  ),
  ponctuel(
    'ponctuel',
    'Ponctuel',
    "Rendre 3 devoirs, tous avant l'échéance.",
    'Trois devoirs rendus dans les délais, sans exception.',
  ),
  major(
    'major',
    'Major',
    'Obtenir une moyenne pondérée de 14/20 sur au moins 3 notes.',
    "Moyenne pondérée de 14/20 ou plus : un parcours d'excellence.",
  ),
  entraide(
    'entraide',
    'Entraide',
    'Publier 3 sujets sur le forum.',
    'Trois sujets publiés : la promo compte sur vous.',
  ),
  sansFaute(
    'sans_faute',
    'Sans faute',
    'Réussir un quiz avec la note maximale.',
    'Un quiz réussi à 100 % : un sans-faute.',
  );

  const StudentBadge(this.id, this.title, this.rule, this.unlockedMessage);

  final String id;
  final String title;

  /// Ce qu'il faut faire : affiché tant que le badge est verrouillé.
  final String rule;

  /// Ce qui a été accompli : affiché une fois le badge gagné.
  final String unlockedMessage;

  String get asset => 'assets/badges/badge_$id.webp';
}

/// Progression d'un badge : gagné ou non, valeur 0..1, détail chiffré.
class BadgeProgress {
  final StudentBadge badge;
  final double progress;
  final String detail;

  const BadgeProgress({
    required this.badge,
    required this.progress,
    required this.detail,
  });

  bool get unlocked => progress >= 1.0;
  int get percent => (progress.clamp(0.0, 1.0) * 100).round();
}

/// Relevé de présence individuel, tel que stocké dans `attendance_records`.
class AttendanceMark {
  final String sessionId;
  final String status;

  const AttendanceMark({required this.sessionId, required this.status});

  factory AttendanceMark.fromDocument(models.Document doc) => AttendanceMark(
        sessionId: '${doc.data['sessionId'] ?? ''}',
        status: '${doc.data['status'] ?? ''}'.toUpperCase(),
      );

  bool get attended => status == 'PRESENT' || status == 'RETARD';
  bool get excused => status == 'JUSTIFIE';
}

/// Données minimales d'un devoir pour le calcul des badges.
/// Découplé de [AcademicAssignment] (liste admin) pour rester léger.
class BadgeAssignment {
  final String id;
  final DateTime dueDate;
  final bool isQuiz;
  final double maxScore;

  const BadgeAssignment({
    required this.id,
    required this.dueDate,
    this.isQuiz = false,
    this.maxScore = 20,
  });
}

/// Données minimales d'une soumission pour le calcul des badges.
class BadgeSubmission {
  final String assignmentId;
  final DateTime submittedAt;
  final double? score;

  const BadgeSubmission({
    required this.assignmentId,
    required this.submittedAt,
    this.score,
  });
}

/// Tout ce qu'il faut pour calculer les six badges d'un apprenant.
class BadgeInputs {
  final String studentId;
  final List<AttendanceMark> attendance;
  final List<AcademicGrade> grades;
  final List<BadgeAssignment> assignments;
  final List<BadgeSubmission> submissions;
  final int forumPostsByStudent;

  const BadgeInputs({
    required this.studentId,
    this.attendance = const [],
    this.grades = const [],
    this.assignments = const [],
    this.submissions = const [],
    this.forumPostsByStudent = 0,
  });
}

const int kAssiduMinSessions = 5;
const double kAssiduRate = 0.90;
const int kPonctuelSubmissions = 3;
const int kMajorMinGrades = 3;
const double kMajorAverage = 14.0;
const int kEntraidePosts = 3;

/// Calcule les six badges. Pure — même entrée, même sortie.
List<BadgeProgress> computeBadges(BadgeInputs inputs) {
  final byAssignment = {for (final a in inputs.assignments) a.id: a};
  return [
    _premierPas(inputs.submissions),
    _assidu(inputs.attendance),
    _ponctuel(inputs.submissions, byAssignment),
    _major(inputs.grades),
    _entraide(inputs.forumPostsByStudent),
    _sansFaute(inputs.submissions, byAssignment),
  ];
}

BadgeProgress _premierPas(List<BadgeSubmission> submissions) => BadgeProgress(
      badge: StudentBadge.premierPas,
      progress: submissions.isEmpty ? 0 : 1,
      detail: submissions.isEmpty
          ? 'Aucun devoir rendu'
          : '${submissions.length} devoir${submissions.length > 1 ? 's' : ''} rendu${submissions.length > 1 ? 's' : ''}',
    );

BadgeProgress _assidu(List<AttendanceMark> marks) {
  final bySession = <String, AttendanceMark>{};
  for (final mark in marks) {
    final key = mark.sessionId.isEmpty ? '${bySession.length}' : mark.sessionId;
    bySession[key] = mark;
  }
  final counted = bySession.values.where((m) => !m.excused).toList();
  final attended = counted.where((m) => m.attended).length;
  if (counted.isEmpty) {
    return const BadgeProgress(
        badge: StudentBadge.assidu,
        progress: 0,
        detail: 'Aucune séance relevée');
  }
  final rate = attended / counted.length;
  final volume = (counted.length / kAssiduMinSessions).clamp(0.0, 1.0);
  final quality = (rate / kAssiduRate).clamp(0.0, 1.0);
  final progress = counted.length >= kAssiduMinSessions && rate >= kAssiduRate
      ? 1.0
      : (volume < quality ? volume : quality).clamp(0.0, 0.99);
  return BadgeProgress(
    badge: StudentBadge.assidu,
    progress: progress,
    detail:
        '${(rate * 100).round()} % · $attended/${counted.length} séance${counted.length > 1 ? 's' : ''}',
  );
}

BadgeProgress _ponctuel(List<BadgeSubmission> submissions,
    Map<String, BadgeAssignment> byAssignment) {
  var onTime = 0;
  var late = 0;
  for (final s in submissions) {
    final due = byAssignment[s.assignmentId]?.dueDate;
    if (due == null) continue;
    s.submittedAt.isAfter(due) ? late++ : onTime++;
  }
  if (late > 0) {
    return BadgeProgress(
        badge: StudentBadge.ponctuel,
        progress: 0,
        detail: '$late devoir${late > 1 ? 's' : ''} en retard');
  }
  final total = onTime + late;
  return BadgeProgress(
    badge: StudentBadge.ponctuel,
    progress: (onTime / kPonctuelSubmissions).clamp(0.0, 1.0),
    detail: total == 0
        ? 'Aucun devoir rendu'
        : "$onTime/$kPonctuelSubmissions devoir${onTime > 1 ? 's' : ''} à l'heure",
  );
}

BadgeProgress _major(List<AcademicGrade> grades) {
  final usable = grades.where((g) => g.maxScore > 0).toList();
  if (usable.isEmpty) {
    return const BadgeProgress(
        badge: StudentBadge.major, progress: 0, detail: 'Aucune note publiée');
  }
  var weighted = 0.0;
  var weights = 0.0;
  for (final g in usable) {
    final c = g.coefficient > 0 ? g.coefficient : 1.0;
    weighted += (g.score / g.maxScore) * 20 * c;
    weights += c;
  }
  final average = weighted / weights;
  final volume = (usable.length / kMajorMinGrades).clamp(0.0, 1.0);
  final quality = (average / kMajorAverage).clamp(0.0, 1.0);
  final progress = usable.length >= kMajorMinGrades && average >= kMajorAverage
      ? 1.0
      : (volume < quality ? volume : quality).clamp(0.0, 0.99);
  return BadgeProgress(
    badge: StudentBadge.major,
    progress: progress,
    detail:
        "${average.toStringAsFixed(1).replaceAll('.', ',')}/20 · ${usable.length} note${usable.length > 1 ? 's' : ''}",
  );
}

BadgeProgress _entraide(int posts) => BadgeProgress(
      badge: StudentBadge.entraide,
      progress: (posts / kEntraidePosts).clamp(0.0, 1.0),
      detail: posts == 0
          ? 'Aucun sujet publié'
          : "$posts/$kEntraidePosts sujet${posts > 1 ? 's' : ''} publié${posts > 1 ? 's' : ''}",
    );

BadgeProgress _sansFaute(List<BadgeSubmission> submissions,
    Map<String, BadgeAssignment> byAssignment) {
  var perfect = 0;
  var best = 0.0;
  var quizzes = 0;
  for (final s in submissions) {
    final a = byAssignment[s.assignmentId];
    if (a == null || !a.isQuiz) continue;
    final score = s.score;
    if (score == null || a.maxScore <= 0) continue;
    quizzes++;
    final ratio = (score / a.maxScore).clamp(0.0, 1.0);
    if (ratio > best) best = ratio;
    if (ratio >= 1.0) perfect++;
  }
  return BadgeProgress(
    badge: StudentBadge.sansFaute,
    progress: perfect > 0 ? 1.0 : (quizzes == 0 ? 0.0 : best.clamp(0.0, 0.99)),
    detail: quizzes == 0
        ? 'Aucun quiz corrigé'
        : perfect > 0
            ? '$perfect quiz à 100 %'
            : 'Meilleur quiz : ${(best * 100).round()} %',
  );
}
