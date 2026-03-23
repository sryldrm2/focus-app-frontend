using Core.Utilities.Results;
using PomodoraBack.Core.DataAccess;
using PomodoraBack.DTOs;

namespace PomodoraBack.Services.Interfaces
{
    public interface IFriendRequest
    {
        Task<IDataResult<FriendRequestDto>> FriendRequestAsync(SendFriendRequestDto friendRequest);
    }
}
