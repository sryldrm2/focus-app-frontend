import 'package:flutter/foundation.dart';
import 'package:focus_app/features/social/models/workspace_model.dart';
import 'package:focus_app/features/social/network/workspace_service.dart';
import 'package:focus_app/features/social/network/workspace_storage.dart';

class WorkspaceState {
  final List<WorkspaceModel> myWorkspaces;
  final bool isLoading;
  final String? errorMessage;
  final String? lastInvitationId;

  const WorkspaceState({
    this.myWorkspaces = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastInvitationId,
  });

  WorkspaceState copyWith({
    List<WorkspaceModel>? myWorkspaces,
    bool? isLoading,
    String? errorMessage,
    String? lastInvitationId,
    bool clearError = false,
    bool clearLastInvitation = false,
  }) {
    return WorkspaceState(
      myWorkspaces: myWorkspaces ?? this.myWorkspaces,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastInvitationId: clearLastInvitation
          ? null
          : (lastInvitationId ?? this.lastInvitationId),
    );
  }
}

class WorkspaceNotifier extends ChangeNotifier {
  final _service = WorkspaceService();
  WorkspaceState _state = const WorkspaceState();
  WorkspaceState get state => _state;

  void _emit(WorkspaceState s) {
    _state = s;
    notifyListeners();
  }

  void clearError() {
    _emit(_state.copyWith(clearError: true));
  }

  /// StudyRoomsTab açılınca bir kez çağır.
  Future<void> init() async {
    final saved = await WorkspaceStorage.load();
    if (saved.isNotEmpty) {
      _emit(_state.copyWith(myWorkspaces: saved));
    }
  }

  Future<void> _persist() async {
    await WorkspaceStorage.save(_state.myWorkspaces);
  }

  Future<WorkspaceModel?> createWorkspace(String workspaceName) async {
    final name = workspaceName.trim();
    if (name.isEmpty) return null;

    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      final result = await _service.createWorkspace(workspaceName: name);
      final workspace = result.data;
      if (workspace == null) {
        throw Exception('Oda oluşturulamadı.');
      }

      _emit(_state.copyWith(
        isLoading: false,
        myWorkspaces: [..._state.myWorkspaces, workspace],
      ));
      await _persist();
      return workspace;
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      return null;
    }
  }

  Future<bool> sendInvitation({
    required String workspaceId,
    required String receiverId,
  }) async {
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      final result = await _service.sendInvitation(
        workspaceId: workspaceId,
        receiverId: receiverId,
      );
      _emit(_state.copyWith(
        isLoading: false,
        lastInvitationId: result.data?.workspaceInvitationId,
      ));
      return true;
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }

  Future<bool> acceptInvitation(String invitationId) async {
    final id = invitationId.trim();
    if (id.isEmpty) return false;

    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      final result = await _service.acceptInvitation(invitationId: id);
      final inv = result.data;
      if (inv == null) throw Exception('Davet kabul edilemedi.');

      var list = [..._state.myWorkspaces];
      final index = list.indexWhere((w) => w.workspaceId == inv.workspaceId);

      if (index < 0) {
        // Listede yoksa placeholder oda ekle (backend oda detayı dönmüyor)
        list.add(WorkspaceModel(
          workspaceId: inv.workspaceId,
          workspaceName: 'Katıldığın oda',
          ownerId: inv.senderId,
          ownerNickName: '',
          isActive: true,
          createdAt: DateTime.now(),
          memberCount: 1,
        ));
      } else {
        final w = list[index];
        list[index] = WorkspaceModel(
          workspaceId: w.workspaceId,
          workspaceName: w.workspaceName,
          ownerId: w.ownerId,
          ownerNickName: w.ownerNickName,
          isActive: w.isActive,
          createdAt: w.createdAt,
          memberCount: w.memberCount + 1,
        );
      }

      _emit(_state.copyWith(isLoading: false, myWorkspaces: list));
      await _persist();
      return true;
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }

  Future<void> updateMemberCountLocally(
    String workspaceId,
    int memberCount,
  ) async {
    _emit(_state.copyWith(
      myWorkspaces: _state.myWorkspaces
          .map((w) => w.workspaceId == workspaceId
              ? WorkspaceModel(
                  workspaceId: w.workspaceId,
                  workspaceName: w.workspaceName,
                  ownerId: w.ownerId,
                  ownerNickName: w.ownerNickName,
                  isActive: w.isActive,
                  createdAt: w.createdAt,
                  memberCount: memberCount,
                )
              : w)
          .toList(),
    ));
    await _persist();
  }
}