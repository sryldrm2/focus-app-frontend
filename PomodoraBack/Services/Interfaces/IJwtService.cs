using Core.Utilities.Results;
using PomodoraBack.DTOs;

namespace PomodoraBack.Services.Interfaces
{
    public interface IJwtService
    {
        string GenerateAccessToken(string userId, string email, string nickname);
        string GenerateRefreshToken();
        IDataResult<string> ValidateRefreshToken(string refreshToken);
    }
}
