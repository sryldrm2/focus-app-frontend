import 'package:focus_app/features/auth/models/user_model.dart';

class FriendRequestModel {
  final String friendRequestId;
  final String consignerId;
  final String receiverId;
  final UserModel? consigner;
  final UserModel? receiver;
  final bool status;
  final DateTime createdAt;

  const FriendRequestModel({
    required this.friendRequestId,
    required this.consignerId,
    required this.receiverId,
    required this.consigner,
    required this.receiver,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      friendRequestId: json['friendRequestId'] ?? '',
      consignerId: json['consignerId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      consigner: json['consigner'] == null
          ? null
          : UserModel.fromJson(json['consigner'] as Map<String, dynamic>),
      receiver: json['receiver'] == null
          ? null
          : UserModel.fromJson(json['receiver'] as Map<String, dynamic>),
      status: json['status'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class FriendshipModel {
  final String friendshipId;
  final String firstUserId;
  final String secondUserId;
  final UserModel firstUser;
  final UserModel secondUser;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const FriendshipModel({
    required this.friendshipId,
    required this.firstUserId,
    required this.secondUserId,
    required this.firstUser,
    required this.secondUser,
    required this.createdAt,
    required this.deletedAt,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      friendshipId: json['friendshipId'] ?? '',
      firstUserId: json['firstUserId'] ?? '',
      secondUserId: json['secondUserId'] ?? '',
      firstUser: UserModel.fromJson(json['firstUser'] as Map<String, dynamic>),
      secondUser: UserModel.fromJson(json['secondUser'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt']),
      deletedAt: json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt']),
    );
  }

  UserModel otherUser(String myUserId) {
    if (firstUserId == myUserId) return secondUser;
    return firstUser;
  }
}

class FriendLeaderboardModel {
  final int rank;
  final String userId;
  final String fullName;
  final String nickname;
  final int totalPoints;
  final bool isCurrentUser;

  const FriendLeaderboardModel({
    required this.rank,
    required this.userId,
    required this.fullName,
    required this.nickname,
    required this.totalPoints,
    required this.isCurrentUser,
  });

  factory FriendLeaderboardModel.fromJson(Map<String, dynamic> json) {
    return FriendLeaderboardModel(
      rank: json['rank'] as int? ?? 0,
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      totalPoints: json['totalPoints'] as int? ?? 0,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  String get displayName {
    final name = fullName.trim();
    if (name.isNotEmpty) return name;
    return nickname;
  }
}