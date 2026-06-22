class NotificationModel {
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
      if (raw == 'FriendStartedFocus') return friendStartedFocusType;
      return int.tryParse(raw) ?? 0;
    }
    return 0;
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