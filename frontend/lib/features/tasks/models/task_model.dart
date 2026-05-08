import 'package:flutter/material.dart';
 
enum TaskStatus {
  notStarted(0),
  inProgress(1),
  completed(2),
  cancelled(3),
  onHold(4);
 
  final int value;
  const TaskStatus(this.value);

  static TaskStatus fromInt(int v) => TaskStatus.values.firstWhere(
    (e) => e.value == v,
    orElse: () => TaskStatus.notStarted,
  );
 
  String get label {
    switch (this) {
      case TaskStatus.notStarted:  return 'Başlanmadı';
      case TaskStatus.inProgress:  return 'Devam Ediyor';
      case TaskStatus.completed:   return 'Tamamlandı';
      case TaskStatus.cancelled:   return 'İptal';
      case TaskStatus.onHold:      return 'Beklemede';
    }
  }
}
 
class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final TaskStatus status;
  final int? priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final Color color;
 
  const TaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.status,
    this.priority,
    required this.createdAt,
    this.dueDate,
    this.color = const Color(0xFFE85D04),
  });
 
  bool get isCompleted => status == TaskStatus.completed;

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        taskId:      json['taskId'] as String,
        title:       json['title'] as String,
        description: json['description'] as String? ?? '',
        status:      TaskStatus.fromInt(json['status'] as int? ?? 0),
        priority:    json['priority'] as int?,
        createdAt:   DateTime.parse(json['createdAt'] as String),
        dueDate:     json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
      );
 
  TaskModel copyWith({TaskStatus? status, Color? color}) => TaskModel(
        taskId:      taskId,
        title:       title,
        description: description,
        status:      status ?? this.status,
        priority:    priority,
        createdAt:   createdAt,
        dueDate:     dueDate,
        color:       color ?? this.color,
      );
}
 
// ── Mock veriler ───────────────────────────────────────────
final mockTasks = [
  TaskModel(
    taskId: '1',
    title: 'Matematik çalış',
    description: 'Türev ve integral konuları',
    status: TaskStatus.notStarted,
    priority: 1,
    createdAt: DateTime.now(),
    dueDate: DateTime.now(),
    color: const Color(0xFFE74C3C),
  ),
  TaskModel(
    taskId: '2',
    title: 'Fizik ödevini bitir',
    description: 'Newton yasaları',
    status: TaskStatus.inProgress,
    priority: 2,
    createdAt: DateTime.now(),
    dueDate: DateTime.now(),
    color: const Color(0xFF3498DB),
  ),
  TaskModel(
    taskId: '3',
    title: 'İngilizce essay yaz',
    description: '',
    status: TaskStatus.completed,
    priority: 3,
    createdAt: DateTime.now(),
    dueDate: DateTime.now(),
    color: const Color(0xFF2ECC71),
  ),
];