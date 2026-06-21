import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:focus_app/core/network/api_base_url.dart';
import 'package:focus_app/features/notifications/models/notification_model.dart';

class NotificationService {
  String get _baseUrl => apiBaseUrl();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<NotificationModel>> getNotifications(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Notifications'),
      headers: _headers(token),
    );

    if (response.statusCode == 204) return [];

    final body = _handleResponse(response);
    final list = body['data'] as List<dynamic>? ?? [];

    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Notifications/unread-count'),
      headers: _headers(token),
    );

    final body = _handleResponse(response);
    final data = body['data'];

    if (data is int) return data;
    return int.tryParse(data.toString()) ?? 0;
  }

  Future<void> markAsRead(String token, String notificationId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/Notifications/$notificationId/read'),
      headers: _headers(token),
    );

    _handleResponse(response);
  }

  Future<void> markAllAsRead(String token) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/Notifications/read-all'),
      headers: _headers(token),
    );

    _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 204) {
      return {'success': true, 'data': null};
    }

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] ?? 'Bildirim işlemi sırasında hata oluştu.';
    throw Exception(message);
  }
}