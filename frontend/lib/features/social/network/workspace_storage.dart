import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_app/features/social/models/workspace_model.dart';

class WorkspaceStorage {
  static const _key = 'my_workspaces_v1';

  static Future<List<WorkspaceModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
      .map((e) => WorkspaceModel.fromJson(e as Map<String, dynamic>))
      .toList();
  }

  static Future<void> save(List<WorkspaceModel> workspaces) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = workspaces
      .map((w) => {
              'workspaceId': w.workspaceId,
              'workspaceName': w.workspaceName,
              'ownerId': w.ownerId,
              'ownerNickName': w.ownerNickName,
              'isActive': w.isActive,
              'createdAt': w.createdAt.toIso8601String(),
              'memberCount': w.memberCount,
            })
        .toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }
}