using Core.Utilities.Results;
using PomodoraBack.DTOs;
using IResult = Core.Utilities.Results.IResults;

namespace PomodoraBack.Services.Interfaces
{
    public interface IAuthService
    {
        Task<IDataResult<AuthResponseDto>> RegisterAsync(RegisterDto registerDto);
        Task<IDataResult<AuthResponseDto>> LoginAsync(LoginDto loginDto);
        Task<IDataResult<AuthResponseDto>> RefreshTokenAsync(string refreshToken);
        Task<IResult> LogoutAsync(string userId);
    }
}
