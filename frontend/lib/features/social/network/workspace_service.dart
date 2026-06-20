import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:focus_app/core/network/api_base_url.dart';
import 'package:focus_app/core/network/api_result.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/features/social/models/workspace_model.dart';

class WorkspaceService {
  String get _baseUrl => apiBaseUrl();
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

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.statusCode == 204) {
      return {'success': true, 'data': null};
    }
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Beklenmeyen response body tipi.');
  }

  Exception _exceptionFromResult(Map<String, dynamic> json) {
    final msg = (json['message'] as String?) ?? 'Bir hata oluştu.';
    return Exception(msg);
  }

  Future<ApiResult<WorkspaceModel>> createWorkspace({
    required String workspaceName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/workspaces'),
      headers: await _authHeaders(),
      body: jsonEncode({'workspaceName': workspaceName}),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        return WorkspaceModel.fromJson(raw as Map<String, dynamic>);
      });
    }
    throw _exceptionFromResult(json);
  }

  Future<ApiResult<WorkspaceInvitationModel>> sendInvitation({
    required String workspaceId,
    required String receiverId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/workspaces/invitations'),
      headers: await _authHeaders(),
      body: jsonEncode({'workspaceId': workspaceId, 'receiverId': receiverId}),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        return WorkspaceInvitationModel.fromJson(raw as Map<String, dynamic>);
      });
    }
    throw _exceptionFromResult(json);
  }

  Future<ApiResult<WorkspaceInvitationModel>> acceptInvitation({
    required String invitationId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/workspaces/invitations/$invitationId/accept'),
      headers: await _authHeaders(),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        return WorkspaceInvitationModel.fromJson(raw as Map<String, dynamic>);
      });
    }
    throw _exceptionFromResult(json);
  }

  Future<ApiResult<List<WorkspaceModel>>> getMyWorkspaces() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/workspaces/mine'),
      headers: await _authHeaders(),
    );

    final json = _decodeBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        final list = raw as List<dynamic>? ?? [];
        return list
            .map((e) => WorkspaceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }

    throw _exceptionFromResult(json);
  }

  Future<ApiResult<List<WorkspaceInvitationModel>>>
  getPendingInvitations() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/workspaces/invitations/pending'),
      headers: await _authHeaders(),
    );

    final json = _decodeBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        final list = raw as List<dynamic>? ?? [];
        return list
            .map(
              (e) =>
                  WorkspaceInvitationModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      });
    }

    throw _exceptionFromResult(json);
  }
}
