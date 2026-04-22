class UserDto {
    final String userId;
    final String name;
    final String surname;
    final String nickname;
    final String email;
    final bool currentStatus;
    final double totalPoints;
    final DateTime lastSeen;
    final bool isOnline;

    const UserDto({
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

    factory UserDto.fromJson(Map<String, dynamic> json) {
        return UserDto(
            userId: json['userId'] ?? '',
            name: json['name'] ?? '',
            surname: json['surname'] ?? '',
            nickname: json['nickname'] ?? '',
            email: json['email'] ?? '',
            currentStatus: json['currentStatus'] ?? false,
            totalPoints: (json['totalPoints'] ?? 0).toDouble(),
            lastSeen: DateTime.parse(json['lastSeen']),
            isOnline: json['isOnline'] ?? false,
        );
    }

    String get displayName {
        final full = ('$name $surname').trim();
        return full.isNotEmpty ? full : nickname;
    }
}

