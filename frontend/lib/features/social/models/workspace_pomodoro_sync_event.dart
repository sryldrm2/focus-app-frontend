class WorkspacePomodoroSyncEvent {
  final String pomoId;
  final String? taskId;
  final int secondsLeft;

  const WorkspacePomodoroSyncEvent({
    required this.pomoId,
    this.taskId,
    required this.secondsLeft,
  });

  factory WorkspacePomodoroSyncEvent.fromJson(Map<String, dynamic> json) =>
      WorkspacePomodoroSyncEvent(
        pomoId: _string(json, 'pomoId', 'PomoId'),
        taskId: _optionalString(json, 'taskId', 'TaskId'),
        secondsLeft: _int(json, 'secondsLeft', 'SecondsLeft'),
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
}
