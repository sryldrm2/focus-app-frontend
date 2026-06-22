import 'package:flutter/foundation.dart';
import 'package:focus_app/core/network/api_result.dart';
import 'package:focus_app/features/social/models/workspace_model.dart';
import 'package:focus_app/features/social/network/workspace_service.dart';
import 'package:focus_app/features/social/network/workspace_storage.dart';

class WorkspaceState {
  final List<WorkspaceModel> myWorkspaces;
  final List<WorkspaceInvitationModel> pendingInvitations;
  final bool isLoading;
  final String? errorMessage;
  final String? lastInvitationId;

  const WorkspaceState({
    this.myWorkspaces = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastInvitationId,
    this.pendingInvitations = const [],
  });

  WorkspaceState copyWith({
    List<WorkspaceModel>? myWorkspaces,
    bool? isLoading,
    String? errorMessage,
    String? lastInvitationId,
    bool clearError = false,
    bool clearLastInvitation = false,
    List<WorkspaceInvitationModel>? pendingInvitations,
  }) {
    return WorkspaceState(
      myWorkspaces: myWorkspaces ?? this.myWorkspaces,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastInvitationId: clearLastInvitation
          ? null
          : (lastInvitationId ?? this.lastInvitationId),
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
    );
  }
}

class WorkspaceNotifier extends ChangeNotifier {
  final _service = WorkspaceService();
  WorkspaceState _state = const WorkspaceState();
  WorkspaceState get state => _state;
  final Set<String> _knownInvitationIds = {};
  bool _invitationBaselineReady = false;

  void _emit(WorkspaceState s) {
    _state = s;
    notifyListeners();
  }

  void clearError() {
    _emit(_state.copyWith(clearError: true));
  }

  /// StudyRoomsTab açılınca bir kez çağır.
  Future<void> init() async {
    _emit(_state.copyWith(isLoading: true, clearError: true));

    try {
      final results = await Future.wait([
        _service.getMyWorkspaces(),
        _service.getPendingInvitations(),
      ]);

      final workspacesResult = results[0] as ApiResult<List<WorkspaceModel>>;
      final invitationsResult =
          results[1] as ApiResult<List<WorkspaceInvitationModel>>;

      _emit(
        _state.copyWith(
          isLoading: false,
          myWorkspaces: workspacesResult.data ?? [],
          pendingInvitations: invitationsResult.data ?? [],
        ),
      );
      _syncInvitationBaseline(invitationsResult.data ?? []);
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
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

      _emit(
        _state.copyWith(
          isLoading: false,
          myWorkspaces: [..._state.myWorkspaces, workspace],
        ),
      );
      await _persist();
      return workspace;
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
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
      _emit(
        _state.copyWith(
          isLoading: false,
          lastInvitationId: result.data?.workspaceInvitationId,
        ),
      );
      return true;
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  void _syncInvitationBaseline(List<WorkspaceInvitationModel> invitations) {
    _knownInvitationIds
      ..clear()
      ..addAll(invitations.map((i) => i.workspaceInvitationId));
    _invitationBaselineReady = true;
  }

  /// Backend davet için SignalR göndermediğinden bekleyen davetleri periyodik kontrol eder.
  /// Yeni davetleri döndürür; ilk baseline yüklemesinde bildirim üretmez.
  Future<List<WorkspaceInvitationModel>> pollPendingInvitations() async {
    try {
      final result = await _service.getPendingInvitations();
      final invitations = result.data ?? [];

      final newInvitations = _invitationBaselineReady
          ? invitations
              .where(
                (inv) => !_knownInvitationIds.contains(inv.workspaceInvitationId),
              )
              .toList()
          : <WorkspaceInvitationModel>[];

      _knownInvitationIds.addAll(
        invitations.map((inv) => inv.workspaceInvitationId),
      );
      _invitationBaselineReady = true;

      _emit(_state.copyWith(pendingInvitations: invitations));
      return newInvitations;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> acceptInvitation(String invitationId) async {
    final id = invitationId.trim();
    if (id.isEmpty) return false;

    _emit(_state.copyWith(isLoading: true, clearError: true));

    try {
      final result = await _service.acceptInvitation(invitationId: id);

      if (result.data == null) {
        throw Exception('Davet kabul edilemedi.');
      }

      final workspacesResult = await _service.getMyWorkspaces();
      final invitationsResult = await _service.getPendingInvitations();

      _emit(
        _state.copyWith(
          isLoading: false,
          myWorkspaces: workspacesResult.data ?? [],
          pendingInvitations: invitationsResult.data ?? [],
        ),
      );
      _syncInvitationBaseline(invitationsResult.data ?? []);

      return true;
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  Future<void> updateMemberCountLocally(
    String workspaceId,
    int memberCount,
  ) async {
    _emit(
      _state.copyWith(
        myWorkspaces: _state.myWorkspaces
            .map(
              (w) => w.workspaceId == workspaceId
                  ? WorkspaceModel(
                      workspaceId: w.workspaceId,
                      workspaceName: w.workspaceName,
                      ownerId: w.ownerId,
                      ownerNickName: w.ownerNickName,
                      isActive: w.isActive,
                      createdAt: w.createdAt,
                      memberCount: memberCount,
                    )
                  : w,
            )
            .toList(),
      ),
    );
    await _persist();
  }
}
