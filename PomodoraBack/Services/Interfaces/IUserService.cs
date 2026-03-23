using Core.Utilities.Results;
using PomodoraBack.DTOs;
using IResult = Core.Utilities.Results.IResults;

namespace PomodoraBack.Services.Interfaces
{
    public interface IUserService
    {
        Task<IDataResult<UserDto>> GetByIdAsync(string userId);
        Task<IDataResult<List<UserDto>>> GetAllAsync();
        Task<IDataResult<UserDto>> UpdateAsync(string userId, UpdateUserDto updateUserDto);
        Task<IResult> DeleteAsync(string userId);
    }
}
