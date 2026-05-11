import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:focus_app/core/network/api_base_url.dart';
import 'package:focus_app/features/pomodoro/models/pomodoro_model.dart';

// ── Start DTO ─────────────────────────────────────────────
class CreatePomodoroSessionDto {
  final PomodoroType sessionType;
  final int durationMinute;
  final String? taskId;
  final String? notes;

  const CreatePomodoroSessionDto({
    required this.sessionType,
    required this.durationMinute,
    this.taskId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'sessionType': sessionType.value,
    'durationMinute': durationMinute,
    if (taskId != null) 'taskId': taskId,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}

// ── PomodoroService ───────────────────────────────────────
class PomodoroService {
  String get _baseUrl => apiBaseUrl();

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _handleResponse(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final message = body['message'] ?? 'Bir hata oluştu.';
    throw Exception(message);
  }

  // ─── POST /api/PomodoroSession/start ──────────────────
  Future<PomodoroSessionModel> startSession(
    String token,
    CreatePomodoroSessionDto dto,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/PomodoroSession/start'),
      headers: _headers(token),
      body: jsonEncode(dto.toJson()),
    );
    final body = _handleResponse(res);
    return PomodoroSessionModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ─── POST /api/PomodoroSession/{pomoId}/complete ──────
  Future<PomodoroSessionModel> completeSession(
      String token, String pomoId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/PomodoroSession/$pomoId/complete'),
      headers: _headers(token),
    );
    final body = _handleResponse(res);
    return PomodoroSessionModel.fromJson(
        body['data'] as Map<String, dynamic>);
  }

  // ─── POST /api/PomodoroSession/{pomoId}/cancel ────────
  Future<void> cancelSession(String token, String pomoId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/PomodoroSession/$pomoId/cancel'),
      headers: _headers(token),
    );
    _handleResponse(res);
  }

  // ─── POST /api/PomodoroSession/{pomoId}/break ─────────
  Future<void> addBreak(String token, String pomoId) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/PomodoroSession/$pomoId/break'),
      headers: _headers(token),
    );
    _handleResponse(res);
  }

  // ─── GET /api/PomodoroSession/ongoing ─────────────────
  Future<PomodoroSessionModel?> getOngoing(String token) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/PomodoroSession/ongoing'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == false) return null;
    return PomodoroSessionModel.fromJson(
        body['data'] as Map<String, dynamic>);
  }

  // ─── GET /api/PomodoroSession/completed ───────────────
  Future<List<PomodoroSessionModel>> getCompleted(String token) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/PomodoroSession/completed'),
      headers: _headers(token),
    );
    final body = _handleResponse(res);
    final list = body['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => PomodoroSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── GET /api/PomodoroSession/total-points ────────────
  Future<double> getTotalPoints(String token) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/PomodoroSession/total-points'),
      headers: _headers(token),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == false) return 0;
    return (body['data'] as num).toDouble();
  }
}
