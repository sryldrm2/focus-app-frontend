import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:focus_app/core/network/api_base_url.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/core/network/api_result.dart';
import 'package:focus_app/features/social/models/friend_models.dart';

class SocialService {
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
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
    throw Exception('Beklenmeyen response body tipi.');
  }

  Exception _exceptionFromResult(Map<String, dynamic> json, http.Response r) {
    final msg = (json['message'] as String?) ?? 'Bir hata oluştu.';
    return Exception(msg);
  }

  // -------- FriendRequest --------
  Future<ApiResult<FriendRequestModel>> sendFriendRequest({
    required String receiverNickname,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/FriendRequest/send'),
      headers: await _authHeaders(),
      body: jsonEncode({'receiverNickname': receiverNickname}),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        return FriendRequestModel.fromJson(raw as Map<String, dynamic>);
      });
    }
    throw _exceptionFromResult(json, response);
  }
  Future<ApiResult<FriendRequestModel>> acceptFriendRequest({
    required String friendRequestId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/FriendRequest/$friendRequestId/accept'),
      headers: await _authHeaders(),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        return FriendRequestModel.fromJson(raw as Map<String, dynamic>);
      });
    }
    throw _exceptionFromResult(json, response);
  }
  Future<ApiResult<FriendRequestModel>> rejectFriendRequest({
    required String friendRequestId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/FriendRequest/$friendRequestId/reject'),
      headers: await _authHeaders(),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        return FriendRequestModel.fromJson(raw as Map<String, dynamic>);
      });
    }
    throw _exceptionFromResult(json, response);
  }
  Future<ApiResult<List<FriendRequestModel>>> getPendingRequests() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/FriendRequest/pending'),
      headers: await _authHeaders(),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        final list = (raw as List<dynamic>? ?? const []);
        return list
            .map((e) => FriendRequestModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
    throw _exceptionFromResult(json, response);
  }
  Future<ApiResult<List<FriendRequestModel>>> getSentRequests() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/FriendRequest/sent'),
      headers: await _authHeaders(),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        final list = (raw as List<dynamic>? ?? const []);
        return list
            .map((e) => FriendRequestModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
    throw _exceptionFromResult(json, response);
  }

  // -------- Friendship --------
  Future<ApiResult<List<FriendshipModel>>> getMyFriends() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Friendship/my-friends'),
      headers: await _authHeaders(),
    );

    final json = _decodeBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        final list = (raw as List<dynamic>? ?? const []);
        return list
            .map((e) => FriendshipModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
    throw _exceptionFromResult(json, response);
  }

  Future<ApiResult<List<FriendshipModel>>> getUserFriends({
    required String userId,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Friendship/$userId/friends'),
      headers: await _authHeaders(),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        final list = (raw as List<dynamic>? ?? const []);
        return list
            .map((e) => FriendshipModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
    throw _exceptionFromResult(json, response);
  }
  Future<ApiResult<FriendshipModel>> getFriendship({
    required String friendId,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Friendship/$friendId/check'),
      headers: await _authHeaders(),
    );
    final json = _decodeBody(response);
    // backend burada “bulunamadı” için BadRequest dönüyor
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        return FriendshipModel.fromJson(raw as Map<String, dynamic>);
      });
    }
    throw _exceptionFromResult(json, response);
  }
  Future<ApiResult<bool>> areFriends({
    required String friendId,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Friendship/$friendId/are-friends'),
      headers: await _authHeaders(),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) => raw == true);
    }
    throw _exceptionFromResult(json, response);
  }
  Future<ApiResult<void>> removeFriend({
    required String friendId,
  }) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/Friendship/$friendId'),
      headers: await _authHeaders(),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (_) => null);
    }
    throw _exceptionFromResult(json, response);
  }

  Future<ApiResult<List<FriendLeaderboardModel>>> getFriendLeaderboard() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/Friendship/leaderboard'),
      headers: await _authHeaders(),
    );
    final json = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResult.fromJson(json, (raw) {
        final list = (raw as List<dynamic>? ?? const []);
        return list
            .map(
              (e) => FriendLeaderboardModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList();
      });
    }
    throw _exceptionFromResult(json, response);
  }
}