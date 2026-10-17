/// Modèles de données académiques pour UniFlow Desktop
library;

class DesktopCourse {
  final String id;
  final String code;
  final String name;
  final String type; // CM, TD, TP
  final int credits;
  final int hours;
  final String teacher;
  final String classroom;
  final int progressPercent;
  final String colorHex;

  DesktopCourse({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.credits,
    required this.hours,
    required this.teacher,
    required this.classroom,
    required this.progressPercent,
    required this.colorHex,
  });
}

class DesktopScheduleSlot {
  final String id;
  final String courseCode;
  final String courseName;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String classroom;
  final String teacher;
  final String type;
  final String program;
  final String level;

  DesktopScheduleSlot({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.classroom,
    required this.teacher,
    required this.type,
    required this.program,
    required this.level,
  });
}

class DesktopAttendance {
  final String id;
  final String courseCode;
  final String date;
  final String time;
  final String status; // 'present', 'late', 'absent'
  final String verifiedBy;

  DesktopAttendance({
    required this.id,
    required this.courseCode,
    required this.date,
    required this.time,
    required this.status,
    required this.verifiedBy,
  });
}
