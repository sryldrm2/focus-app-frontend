import 'package:focus_app/features/social/models/friend_models.dart';

class SocialState {
  final bool isLoading;
  final String? errorMessage;

  final List<FriendRequestModel> pendingRequests;
  final List<FriendRequestModel> sentRequests;
  final List<FriendshipModel> myFriends;

  const SocialState({
    this.isLoading = false,
    this.errorMessage,
    this.pendingRequests = const [],
    this.sentRequests = const [],
    this.myFriends = const [], 
  });

  SocialState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<FriendRequestModel>? pendingRequests,
    List<FriendRequestModel>? sentRequests,
    List<FriendshipModel>? myFriends,
  }) {
    return SocialState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      myFriends: myFriends ?? this.myFriends,
    );
  }
}