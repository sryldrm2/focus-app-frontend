import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:focus_app/core/network/api_base_url.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/core/network/api_result.dart';
import 'package:focus_app/features/profile/models/user_dto.dart';

class UsersService {
  String get _baseUrl => apiBaseUrl();

  Map<String, dynamic> _decodeBody(http.Response response) {
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Beklenmeyen response body tipi.');
  }

  Exception _exceptionFromResult(Map<String, dynamic> json) {
    final msg = (json['message'] as String?) ?? 'Bir hata oluştu.';
    return Exception(msg);
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Access token yok. Lütfen yeniden giriş yap.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Public: GET /api/Users/{id}
  Future<ApiResult<UserDto>> getById(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Users/$id'),
      headers: const {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 204) {
      // BaseController 204 döndürebiliyor
      return const ApiResult(success: true, message: null, data: null);
    }

    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        return UserDto.fromJson(raw as Map<String, dynamic>);
      });
    }
    throw _exceptionFromResult(json);
  }

  /// Auth: PUT /api/Users/{id}
  Future<ApiResult<UserDto>> update(
    String id, {
    String? name,
    String? surname,
    String? nickname,
    String? email,
    String? password,
    bool? currentStatus,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (surname != null) body['surname'] = surname;
    if (nickname != null) body['nickname'] = nickname;
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;
    if (currentStatus != null) body['currentStatus'] = currentStatus;

    final response = await http.put(
      Uri.parse('$_baseUrl/Users/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 204) {
      return const ApiResult(success: true, message: null, data: null);
    }

    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        return UserDto.fromJson(raw as Map<String, dynamic>);
      });
    }
    throw _exceptionFromResult(json);
  }
}