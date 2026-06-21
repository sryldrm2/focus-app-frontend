enum WorkspaceInvitationStatus {
  pending(0),
  accepted(1),
  rejected(2);

  final int value;
  const WorkspaceInvitationStatus(this.value);

  static WorkspaceInvitationStatus fromInt(int v) {
    return WorkspaceInvitationStatus.values.firstWhere(
      (e) => e.value == v,
      orElse: () => WorkspaceInvitationStatus.pending,
    );
  }
}

class WorkspaceModel {
  static const int maxCapacity = 4;

  final String workspaceId;
  final String workspaceName;
  final String ownerId;
  final String ownerNickName;
  final bool isActive;
  final DateTime createdAt;
  final int memberCount;

  const WorkspaceModel({
    required this.workspaceId,
    required this.workspaceName,
    required this.ownerId,
    required this.ownerNickName,
    required this.isActive,
    required this.createdAt,
    required this.memberCount,
  });

  bool get isFull => memberCount >= maxCapacity;

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      workspaceId: json['workspaceId'] as String? ?? '',
      workspaceName: json['workspaceName'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      ownerNickName: json['ownerNickName'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      memberCount: json['memberCount'] as int? ?? 1,
    );
  }
}

class WorkspaceInvitationModel {
  final String workspaceInvitationId;
  final String workspaceId;
  final String workspaceName;
  final String senderId;
  final String senderNickName;
  final String receiverId;
  final WorkspaceInvitationStatus status;
  final DateTime createdAt;

  const WorkspaceInvitationModel({
    required this.workspaceInvitationId,
    required this.workspaceId,
    required this.workspaceName,
    required this.senderId,
    required this.senderNickName,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  factory WorkspaceInvitationModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceInvitationModel(
      workspaceInvitationId: json['workspaceInvitationId'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? '',
      workspaceName: json['workspaceName'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderNickName: json['senderNickName'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      status: WorkspaceInvitationStatus.fromInt(json['status'] as int? ?? 0),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}