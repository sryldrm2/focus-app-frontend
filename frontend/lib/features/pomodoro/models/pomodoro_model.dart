enum PomodoroType {
  workSession(0),
  shortBreakSession(1),
  longBreakSession(2);
 
  final int value;
  const PomodoroType(this.value);
}
 
enum SessionStatus {
  onGoing(0),
  successful(1),
  incomplete(2),
  cancelled(3);
 
  final int value;
  const SessionStatus(this.value);
 
  static SessionStatus fromInt(int v) => SessionStatus.values.firstWhere(
        (e) => e.value == v,
        orElse: () => SessionStatus.onGoing,
      );
}

class PomodoroSessionModel {
  final String pomoId;
  final String userId;
  final String? taskId;
  final PomodoroType sessionType;
  final int durationMinute;
  final int pointsEarned;
  final String? notes;
  final int breakCount;
  final DateTime startedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final SessionStatus status;
 
  const PomodoroSessionModel({
    required this.pomoId,
    required this.userId,
    this.taskId,
    required this.sessionType,
    required this.durationMinute,
    required this.pointsEarned,
    this.notes,
    required this.breakCount,
    required this.startedAt,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    required this.status,
  });

  bool get isCompleted => status == SessionStatus.successful;
  bool get isOngoing => status == SessionStatus.onGoing;
  bool get isIncomplete => status == SessionStatus.incomplete;

  factory PomodoroSessionModel.fromJson(Map<String, dynamic> json) => 
    PomodoroSessionModel(
        pomoId:        json['pomoId'] as String,
        userId:        json['userId'] as String,
        taskId:        json['taskId'] as String?,
        sessionType:   PomodoroType.values.firstWhere(
          (e) => e.value == (json['sessionType'] as int? ?? 0),
          orElse: () => PomodoroType.workSession,
        ),
        durationMinute: json['durationMinute'] as int,
        pointsEarned:   json['pointsEarned'] as int? ?? 0,
        notes:          json['notes'] as String?,
        breakCount:     json['breakCount'] as int? ?? 0,
        startedAt:      DateTime.parse(json['startedAt'] as String),
        createdAt:      DateTime.parse(json['createdAt'] as String),
        updatedAt:      json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        completedAt:    json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        status: SessionStatus.fromInt(json['status'] as int? ?? 0),
      );
}
