import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'package:focus_app/core/network/api_base_url.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/features/notifications/models/notification_model.dart';
import 'package:focus_app/features/pomodoro/models/pomodoro_model.dart';
import 'package:focus_app/features/tasks/models/task_model.dart';

final notificationHubServiceProvider =
    Provider<NotificationHubService>((ref) => NotificationHubService());

class NotificationHubService {
  HubConnection? _connection;
  bool _connecting = false;

  void Function(NotificationModel notification)? _onReceive;
  void Function(TaskModel task)? _onWorkspaceTaskCreated;
  void Function(PomodoroSessionModel session)? _onWorkspacePomodoroStarted;

  Future<void> connect({
    required void Function(NotificationModel notification) onReceive,
    void Function(TaskModel task)? onWorkspaceTaskCreated,
    void Function(PomodoroSessionModel session)? onWorkspacePomodoroStarted,
  }) async {
    _onReceive = onReceive;
    _onWorkspaceTaskCreated = onWorkspaceTaskCreated;
    _onWorkspacePomodoroStarted = onWorkspacePomodoroStarted;
    await _openConnection();
  }

  /// Hub bağlantısını kesip yeniden kurar. Callback'ler korunur.
  Future<void> reconnect() async {
    if (_onReceive == null) return;
    await _stopConnection();
    await _openConnection();
  }

  /// Backend'deki workspace SignalR gruplarını DB üyeliklerine göre senkronize eder.
  Future<void> syncWorkspaceGroups() => _invokeSyncWorkspaceGroups();

  Future<void> _openConnection() async {
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

      _registerEventHandlers(connection);

      connection.onclose(({error}) {
        debugPrint('SignalR disconnected: ${error ?? 'unknown'}');
      });

      connection.onreconnected(({connectionId}) {
        debugPrint('SignalR reconnected: $connectionId');
        unawaited(_invokeSyncWorkspaceGroups(connection));
      });

      _connection = connection;
      await _connection!.start();
      debugPrint('SignalR connected');
      await _invokeSyncWorkspaceGroups(_connection!);
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

  void _registerEventHandlers(HubConnection connection) {
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
        _onReceive?.call(notification);
      } catch (e) {
        debugPrint('SignalR ReceiveNotification parse error: $e');
      }
    });

    connection.on('WorkspaceGroupsUpdated', (args) {
      debugPrint('WorkspaceGroupsUpdated geldi');
      unawaited(_invokeSyncWorkspaceGroups(connection));
    });

    connection.on('WorkspaceTaskCreated', (args) {
      if (_onWorkspaceTaskCreated == null) return;
      try {
        debugPrint('WorkspaceTaskCreated geldi');
        final payload = _extractFirstArg(args);
        final json = _asJsonMap(payload);
        if (json == null) {
          debugPrint('WorkspaceTaskCreated parse: payload map degil');
          return;
        }

        final task = TaskModel.fromJson(json);
        _onWorkspaceTaskCreated?.call(task);
      } catch (e) {
        debugPrint('SignalR WorkspaceTaskCreated parse error: $e');
      }
    });

    connection.on('WorkspacePomodoroStarted', (args) {
      try {
        final payload = _extractFirstArg(args);
        debugPrint(
          '[WorkspaceSync] WorkspacePomodoroStarted raw payload: $payload',
        );

        if (_onWorkspacePomodoroStarted == null) {
          debugPrint('WorkspacePomodoroStarted: handler kayıtlı değil');
          return;
        }

        debugPrint('WorkspacePomodoroStarted geldi');
        final json = _asJsonMap(payload);
        if (json == null) {
          debugPrint('WorkspacePomodoroStarted parse: payload map degil');
          return;
        }

        final session = PomodoroSessionModel.fromJson(json);
        _onWorkspacePomodoroStarted?.call(session);
      } catch (e) {
        debugPrint('SignalR WorkspacePomodoroStarted parse error: $e');
      }
    });
  }

  Future<void> _invokeSyncWorkspaceGroups([HubConnection? connection]) async {
    final conn = connection ?? _connection;
    if (conn == null) {
      debugPrint('SyncWorkspaceGroups: bağlantı yok');
      return;
    }
    if (conn.state != HubConnectionState.Connected) {
      debugPrint(
        'SyncWorkspaceGroups: bağlantı hazır değil (state=${conn.state})',
      );
      return;
    }

    try {
      await conn.invoke('SyncWorkspaceGroups');
      debugPrint('[WorkspaceSync] SyncWorkspaceGroups tamamlandı');
    } catch (e) {
      debugPrint('SyncWorkspaceGroups hatası: $e');
    }
  }

  Future<void> _stopConnection() async {
    final connection = _connection;
    _connection = null;

    if (connection == null) return;

    try {
      await connection.stop();
      debugPrint('SignalR stop edildi');
    } catch (e) {
      debugPrint('SignalR stop error: $e');
    }
  }

  Future<void> disconnect() async {
    // Callback'leri önce temizle; dispose sonrası SignalR event'i widget ref'ine ulaşmasın.
    _onReceive = null;
    _onWorkspaceTaskCreated = null;
    _onWorkspacePomodoroStarted = null;

    await _stopConnection();
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
