import 'package:focus_app/features/social/models/workspace_model.dart';

class NotificationModel {
  static const int friendRequestType = 0;
  static const int workspaceInvitationType = 1;
  static const int dueDateReminderType = 2;
  static const int friendStartedFocusType = 3;

  final String notificationId;
  final String title;
  final String message;
  final int type;
  final bool isRead;
  final DateTime? createdAt;

  bool get isEphemeral => type == friendStartedFocusType;

  const NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: (json['notificationId'] ??
              json['id'] ??
              json['NotificationId'] ??
              '')
          .toString(),
      title: (json['title'] ?? json['Title'] ?? 'Bildirim').toString(),
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      type: _parseType(json),
      isRead: json['isRead'] ?? json['IsRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : json['CreatedAt'] != null
              ? DateTime.tryParse(json['CreatedAt'].toString())
              : null,
    );
  }

  static int _parseType(Map<String, dynamic> json) {
    final raw = json['type'] ??
        json['Type'] ??
        json['notificationType'] ??
        json['NotificationType'];

    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      switch (raw) {
        case 'FriendRequest':
          return friendRequestType;
        case 'WorkspaceInvitation':
        case 'RoomInvitation':
          return workspaceInvitationType;
        case 'DueDateReminder':
          return dueDateReminderType;
        case 'FriendStartedFocus':
          return friendStartedFocusType;
      }
      return int.tryParse(raw) ?? 0;
    }
    return 0;
  }

  factory NotificationModel.fromWorkspaceInvitation(
    WorkspaceInvitationModel invitation,
  ) {
    return NotificationModel(
      notificationId: invitation.workspaceInvitationId,
      title: 'Oda daveti',
      message:
          '${invitation.senderNickName} sizi "${invitation.workspaceName}" odasına davet etti.',
      type: workspaceInvitationType,
      isRead: false,
      createdAt: invitation.createdAt,
    );
  }

  NotificationModel copyWith({
    String? notificationId,
    String? title,
    String? message,
    int? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}