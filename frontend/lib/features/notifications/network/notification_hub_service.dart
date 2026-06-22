import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'package:focus_app/core/network/api_base_url.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/features/notifications/models/notification_model.dart';

final notificationHubServiceProvider =
    Provider<NotificationHubService>((ref) => NotificationHubService());

class NotificationHubService {
  HubConnection? _connection;
  bool _connecting = false;

  Future<void> connect({
    required void Function(NotificationModel notification) onReceive,
  }) async {
    if (_connection != null || _connecting) return;

    _connecting = true;
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        debugPrint('SignalR connect: token yok');
        return;
      }

      final hubUrl = _buildHubUrlWithToken(
        restBaseUrl: apiBaseUrl(),
        token: token,
      );

      debugPrint('SignalR connecting: $hubUrl');

      final connection = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect()
          .build();

      connection.onclose(({error}) {
        debugPrint('SignalR disconnected: ${error ?? 'unknown'}');
      });

      connection.on('ReceiveNotification', (args) {
        try {
          debugPrint('ReceiveNotification geldi');
          final payload = _extractFirstArg(args);
          final json = _asJsonMap(payload);
          if (json == null) {
            debugPrint('ReceiveNotification parse: payload map degil');
            return;
          }

          final notification = NotificationModel.fromJson(json);
          onReceive(notification);
        } catch (e) {
          debugPrint('SignalR ReceiveNotification parse error: $e');
        }
      });

      _connection = connection;
      await _connection!.start();
      debugPrint('SignalR connected');
    } catch (e) {
      debugPrint('SignalR connection error: $e');
      try {
        await _connection?.stop();
      } catch (_) {}
      _connection = null;
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    final connection = _connection;
    _connection = null;

    if (connection == null) return;

    try {
      await connection.stop();
      debugPrint('SignalR stop edildi');
    } catch (e) {
      debugPrint('SignalR disconnect error: $e');
    }
  }

  String _buildHubUrlWithToken({
    required String restBaseUrl,
    required String token,
  }) {
    final hubBase = _stripApiPrefix(restBaseUrl);
    final hubUrl = '$hubBase/notificationHub';
    return '$hubUrl?access_token=${Uri.encodeQueryComponent(token)}';
  }

  String _stripApiPrefix(String restBaseUrl) {
    // REST: http://host:5265/api  -> Hub: http://host:5265/notificationHub
    final trimmed = restBaseUrl.endsWith('/')
        ? restBaseUrl.substring(0, restBaseUrl.length - 1)
        : restBaseUrl;

    if (trimmed.endsWith('/api')) {
      return trimmed.substring(0, trimmed.length - '/api'.length);
    }
    return trimmed;
  }

  dynamic _extractFirstArg(dynamic args) {
    if (args is List && args.isNotEmpty) return args.first;
    return args;
  }

  Map<String, dynamic>? _asJsonMap(dynamic payload) {
    if (payload == null) return null;

    if (payload is Map<String, dynamic>) {
      return payload;
    }

    if (payload is Map) {
      return Map<String, dynamic>.from(payload as Map);
    }

    if (payload is String) {
      final decoded = jsonDecode(payload);
      if (decoded is Map) return Map<String, dynamic>.from(decoded as Map);
    }

    return null;
  }
}

