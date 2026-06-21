class NotificationModel {
  final String notificationId;
  final String title;
  final String message;
  final int type;
  final bool isRead;
  final DateTime? createdAt;

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
      type: json['type'] ?? json['notificationType'] ?? json['NotificationType'] ?? 0,
      isRead: json['isRead'] ?? json['IsRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
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