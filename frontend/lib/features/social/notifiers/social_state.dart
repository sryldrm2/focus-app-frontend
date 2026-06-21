import 'package:focus_app/features/social/models/friend_models.dart';

class SocialState {
  final bool isLoading;
  final String? errorMessage;

  final List<FriendRequestModel> pendingRequests;
  final List<FriendRequestModel> sentRequests;
  final List<FriendshipModel> myFriends;
  final List<FriendLeaderboardModel> leaderboard;
  final bool isLeaderboardLoading;
  final String? leaderboardError;

  const SocialState({
    this.isLoading = false,
    this.errorMessage,
    this.pendingRequests = const [],
    this.sentRequests = const [],
    this.myFriends = const [],
    this.leaderboard = const [],
    this.isLeaderboardLoading = false,
    this.leaderboardError,
  });

  SocialState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<FriendRequestModel>? pendingRequests,
    List<FriendRequestModel>? sentRequests,
    List<FriendshipModel>? myFriends,
    List<FriendLeaderboardModel>? leaderboard,
    bool? isLeaderboardLoading,
    String? leaderboardError,
    bool clearLeaderboardError = false,
  }) {
    return SocialState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      myFriends: myFriends ?? this.myFriends,
      leaderboard: leaderboard ?? this.leaderboard,
      isLeaderboardLoading:
          isLeaderboardLoading ?? this.isLeaderboardLoading,
      leaderboardError: clearLeaderboardError
          ? null
          : (leaderboardError ?? this.leaderboardError),
    );
  }
}