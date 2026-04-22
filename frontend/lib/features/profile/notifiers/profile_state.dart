import 'package:focus_app/features/profile/models/user_dto.dart';

class ProfileState {
    final bool isLoading;
    final String? errorMessage;
    final UserDto? user;
    final int friendCount;

    const ProfileState({
        this.isLoading = false,
        this.errorMessage,
        this.user,
        this.friendCount = 0,
    });

    ProfileState copyWith({
        bool? isLoading,
        String? errorMessage,
        UserDto? user,
        int? friendCount,
    }) {
        return ProfileState(
            isLoading: isLoading ?? this.isLoading,
            errorMessage: errorMessage,
            user: user ?? this.user,
            friendCount: friendCount ?? this.friendCount,
        );
    }
}