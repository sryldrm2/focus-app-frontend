import 'package:flutter/foundation.dart';
import 'package:focus_app/features/social/models/workspace_model.dart';
import 'package:focus_app/features/social/network/workspace_service.dart';
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
      await _service.acceptInvitation(invitationId: id);
      _emit(_state.copyWith(isLoading: false));
      return true;
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
      return false;
    }
  }
  void updateMemberCountLocally(String workspaceId, int memberCount) {
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
  }
}