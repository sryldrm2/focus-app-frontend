using Core.Utilities.Results;
using PomodoraBack.Core.DataAccess;
using PomodoraBack.DTOs;
using IResult = Core.Utilities.Results.IResults;

namespace PomodoraBack.Services.Interfaces
{
    public interface IFriendRequest
    {
        // Friend Request işlemleri
        Task<IDataResult<FriendRequestDto>> SendFriendRequestAsync(string senderId, SendFriendRequestDto friendRequest);
        Task<IDataResult<FriendRequestDto>> AcceptFriendRequestAsync(string friendRequestId);
        Task<IDataResult<FriendRequestDto>> RejectFriendRequestAsync(string friendRequestId);
        Task<IDataResult<List<FriendRequestDto>>> GetPendingRequestsAsync(string userId);
        Task<IDataResult<List<FriendRequestDto>>> GetSentRequestsAsync(string userId);
        
        // Friendship işlemleri
        Task<IDataResult<FriendshipDto>> GetFriendshipAsync(string userId, string friendId);
        Task<IDataResult<List<FriendshipDto>>> GetFriendsAsync(string userId);
        Task<IResult> RemoveFriendAsync(string userId, string friendId);
        Task<IDataResult<bool>> AreFriendsAsync(string userId, string friendId);

        /// <summary>
        /// Giriş yapan kullanıcının kendisini ve onaylanmış arkadaşlarını
        /// TotalPoints'e göre büyükten küçüğe sıralayarak Rank atanmış
        /// liderlik tablosu listesi döndürür.
        /// </summary>
        /// <param name="currentUserId">İsteği atan kullanıcının ID'si</param>
        Task<IDataResult<List<FriendLeaderboardDto>>> GetFriendLeaderboardAsync(string currentUserId);
    }
}
