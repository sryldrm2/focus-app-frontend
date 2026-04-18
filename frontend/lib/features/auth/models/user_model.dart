class UserModel {
  final String userId;
  final String name;
  final String surname;
  final String nickname;
  final String email;
  final bool currentStatus;
  final double totalPoints;
  final DateTime lastSeen;
  final bool isOnline;

  const UserModel({
    required this.userId,
    required this.name,
    required this.surname,
    required this.nickname,
    required this.email,
    required this.currentStatus,
    required this.totalPoints,
    required this.lastSeen,
    required this.isOnline,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId:        json['userId']        ?? '',
      name:          json['name']          ?? '',
      surname:       json['surname']       ?? '',
      nickname:      json['nickname']      ?? '',
      email:         json['email']         ?? '',
      currentStatus: json['currentStatus'] ?? false,
      totalPoints:   (json['totalPoints']  ?? 0).toDouble(),
      lastSeen:      DateTime.parse(json['lastSeen']),
      isOnline:      json['isOnline']      ?? false,
    );
  }
}