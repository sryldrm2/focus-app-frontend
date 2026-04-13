import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl = "http://10.0.2.2:5000/api";

  // ─── LOGIN ────────────────────────────────────────────────
  Future <Map<String, dynamic>> login({
    required String emailOrNickname,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: { 'Content-Type': 'application/json'},
      body: jsonEncode({
        'emailOrNickname': emailOrNickname,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  // ─── REGISTER ─────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String name,
    required String surname,
    required String nickname,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'surname': surname,
        'nickname': nickname,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      }),
    );
    return _handleResponse(response);
  }

  // ─── REFRESH TOKEN ────────────────────────────────────────
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    return _handleResponse(response);
  }

  // ─── LOGOUT ───────────────────────────────────────────────
  Future<void> logout(String accessToken) async {
    await http.post(
      Uri.parse('$_baseUrl/auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
  }

  // ─── ME ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getMe(String accessToken) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );
    return _handleResponse(response);
  }

  // ─── RESPONSE HANDLER ─────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body['message'] ?? 'Bir hata oluştu.';
    throw Exception(message);
  }
}