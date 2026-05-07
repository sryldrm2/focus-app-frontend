import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:focus_app/core/network/api_base_url.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';

// ── DTO'lar ────────────────────────────────────────────────
class CreateTaskDto {
  final String title;
  final String? description;
  final int? priority;
  final DateTime? dueDate;

  const CreateTaskDto({
    required this.title,
    this.description,
    this.priority,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (priority != null) 'priority': priority,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      };
}

class UpdateTaskDto {
  final String? title;
  final String? description;
  final int? status;
  final int? priority;
  final DateTime? dueDate;

  const UpdateTaskDto({
    this.title,
    this.description,
    this.status,
    this.priority,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      };
}

// ── TaskService ────────────────────────────────────────────
class TaskService {
  String get _baseUrl => apiBaseUrl();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ─── GET /api/tasks ───────────────────────────────────────
  Future<List<TaskModel>> getTasks(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/tasks'),
      headers: _headers(token),
    );
    if (response.statusCode == 204) return [];
    final body = _handleResponse(response);
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── POST /api/tasks ──────────────────────────────────────
  Future<TaskModel> createTask(String token, CreateTaskDto dto) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tasks'),
      headers: _headers(token),
      body: jsonEncode(dto.toJson()),
    );
    final body = _handleResponse(response);
    return TaskModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ─── PUT /api/tasks/{taskId} ──────────────────────────────
  Future<TaskModel> updateTask(
      String token, String taskId, UpdateTaskDto dto) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/tasks/$taskId'),
      headers: _headers(token),
      body: jsonEncode(dto.toJson()),
    );
    final body = _handleResponse(response);
    return TaskModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ─── DELETE /api/tasks/{taskId} ───────────────────────────
  Future<void> deleteTask(String token, String taskId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/tasks/$taskId'),
      headers: _headers(token),
    );
    _handleResponse(response);
  }

  // ─── RESPONSE HANDLER ─────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 204) return {'success': true, 'data': null};
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body['message'] ?? 'Bir hata oluştu.';
    throw Exception(message);
  }
}