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

  int get remainingSeconds {
    final totalSeconds = durationMinute * 60;
    final elapsedSeconds = DateTime.now()
        .difference(startedAt.toLocal())
        .inSeconds;

    final remaining = totalSeconds - elapsedSeconds;

    return remaining > 0 ? remaining : 0;
  }

  factory PomodoroSessionModel.fromJson(Map<String, dynamic> json) =>
      PomodoroSessionModel(
        pomoId: _string(json, 'pomoId', 'PomoId'),
        userId: _string(json, 'userId', 'UserId'),
        taskId: _optionalString(json, 'taskId', 'TaskId'),
        sessionType: PomodoroType.values.firstWhere(
          (e) => e.value == _int(json, 'sessionType', 'SessionType'),
          orElse: () => PomodoroType.workSession,
        ),
        durationMinute: _int(json, 'durationMinute', 'DurationMinute'),
        pointsEarned: _int(json, 'pointsEarned', 'PointsEarned'),
        notes: _optionalString(json, 'notes', 'Notes'),
        breakCount: _int(json, 'breakCount', 'BreakCount'),
        startedAt: DateTime.parse(_string(json, 'startedAt', 'StartedAt')),
        createdAt: DateTime.parse(_string(json, 'createdAt', 'CreatedAt')),
        updatedAt: _optionalDate(json, 'updatedAt', 'UpdatedAt'),
        completedAt: _optionalDate(json, 'completedAt', 'CompletedAt'),
        status: _parseStatus(json['status'] ?? json['Status']),
      );

  static String _string(
    Map<String, dynamic> json,
    String camel,
    String pascal,
  ) =>
      (json[camel] ?? json[pascal] ?? '').toString();

  static String? _optionalString(
    Map<String, dynamic> json,
    String camel,
    String pascal,
  ) {
    final value = json[camel] ?? json[pascal];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int _int(Map<String, dynamic> json, String camel, String pascal) {
    final raw = json[camel] ?? json[pascal];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static DateTime? _optionalDate(
    Map<String, dynamic> json,
    String camel,
    String pascal,
  ) {
    final raw = json[camel] ?? json[pascal];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static SessionStatus _parseStatus(dynamic raw) {
    if (raw is int) return SessionStatus.fromInt(raw);
    if (raw is num) return SessionStatus.fromInt(raw.toInt());
    if (raw is String) {
      switch (raw) {
        case 'OnGoing':
        case 'onGoing':
          return SessionStatus.onGoing;
        case 'Successful':
        case 'successful':
          return SessionStatus.successful;
        case 'Incomplete':
        case 'incomplete':
          return SessionStatus.incomplete;
        case 'Cancelled':
        case 'cancelled':
          return SessionStatus.cancelled;
      }
      return int.tryParse(raw) != null
          ? SessionStatus.fromInt(int.parse(raw))
          : SessionStatus.onGoing;
    }
    return SessionStatus.onGoing;
  }
}
