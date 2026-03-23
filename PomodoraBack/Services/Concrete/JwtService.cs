using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Core.Utilities.Results;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using PomodoraBack.Core.Settings;
using PomodoraBack.Services.Interfaces;

namespace PomodoraBack.Services.Concrete
{
    public class JwtService : IJwtService
    {
        private readonly JwtSettings _jwtSettings;

        public JwtService(IOptions<JwtSettings> jwtSettings)
        {
            _jwtSettings = jwtSettings.Value;
        }

        public string GenerateAccessToken(string userId, string email, string nickname)
        {
            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, userId),
                new Claim(JwtRegisteredClaimNames.Email, email),
                new Claim("nickname", nickname),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(JwtRegisteredClaimNames.Iat, DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString())
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.SecretKey));
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _jwtSettings.Issuer,
                audience: _jwtSettings.Audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(_jwtSettings.AccessTokenExpirationMinutes),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public string GenerateRefreshToken()
        {
            var randomNumber = new byte[64];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }

        public IDataResult<string> ValidateRefreshToken(string refreshToken)
        {
            if (string.IsNullOrWhiteSpace(refreshToken))
                return new ErrorDataResult<string>("Refresh token boş olamaz.");

            // Refresh token basit bir random string, burada sadece format kontrolü yapıyoruz
            // Asıl doğrulama veritabanında yapılacak
            try
            {
                Convert.FromBase64String(refreshToken);
                return new SuccessDataResult<string>(refreshToken);
            }
            catch
            {
                return new ErrorDataResult<string>("Geçersiz refresh token formatı.");
            }
        }
    }
}
