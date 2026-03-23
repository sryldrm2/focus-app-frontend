using AutoMapper;
using Core.Utilities.Results;
using Microsoft.Extensions.Options;
using PomodoraBack.Core.Settings;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;
using PomodoraBack.Services.Interfaces;
using IResult = Core.Utilities.Results.IResults;

namespace PomodoraBack.Services.Concrete
{
    public class AuthService : IAuthService
    {
        private readonly IUserDal _userDal;
        private readonly IRefreshTokenDal _refreshTokenDal;
        private readonly IJwtService _jwtService;
        private readonly IMapper _mapper;
        private readonly JwtSettings _jwtSettings;

        public AuthService(
            IUserDal userDal,
            IRefreshTokenDal refreshTokenDal,
            IJwtService jwtService,
            IMapper mapper,
            IOptions<JwtSettings> jwtSettings)
        {
            _userDal = userDal;
            _refreshTokenDal = refreshTokenDal;
            _jwtService = jwtService;
            _mapper = mapper;
            _jwtSettings = jwtSettings.Value;
        }

        public async Task<IDataResult<AuthResponseDto>> RegisterAsync(RegisterDto registerDto)
        {
            var emailExists = await _userDal.GetAsync(u => u.Email == registerDto.Email);
            if (emailExists != null)
                return new ErrorDataResult<AuthResponseDto>("Bu email adresi zaten kayıtlı.");

            var nicknameExists = await _userDal.GetAsync(u => u.Nickname == registerDto.Nickname);
            if (nicknameExists != null)
                return new ErrorDataResult<AuthResponseDto>("Bu kullanıcı adı zaten kullanılıyor.");

            var user = _mapper.Map<User>(registerDto);
            
            user.Password = BCrypt.Net.BCrypt.HashPassword(registerDto.Password);

            await _userDal.AddAsync(user);

            var authResponse = await CreateAuthResponseAsync(user);

            return new SuccessDataResult<AuthResponseDto>(authResponse, "Kayıt başarılı.");
        }

        public async Task<IDataResult<AuthResponseDto>> LoginAsync(LoginDto loginDto)
        {
            
            var user = await _userDal.GetAsync(u => 
                u.Email == loginDto.EmailOrNickname || 
                u.Nickname == loginDto.EmailOrNickname);

            if (user == null)
                return new ErrorDataResult<AuthResponseDto>("Kullanıcı bulunamadı.");

            if (!BCrypt.Net.BCrypt.Verify(loginDto.Password, user.Password))
                return new ErrorDataResult<AuthResponseDto>("Şifre hatalı.");

            user.LastSeen = DateTime.UtcNow;
            user.CurrentStatus = true;
            await _userDal.UpdateAsync(user);

            var authResponse = await CreateAuthResponseAsync(user);

            return new SuccessDataResult<AuthResponseDto>(authResponse, "Giriş başarılı.");
        }

        public async Task<IDataResult<AuthResponseDto>> RefreshTokenAsync(string refreshToken)
        {
            var validationResult = _jwtService.ValidateRefreshToken(refreshToken);
            if (!validationResult.Success)
                return new ErrorDataResult<AuthResponseDto>(validationResult.Message);

            var storedToken = await _refreshTokenDal.GetAsync(rt => 
                rt.Token == refreshToken && 
                !rt.IsRevoked && 
                rt.ExpiresAt > DateTime.UtcNow);

            if (storedToken == null)
                return new ErrorDataResult<AuthResponseDto>("Geçersiz veya süresi dolmuş refresh token.");

            var user = await _userDal.GetAsync(u => u.UserId == storedToken.UserId);
            if (user == null)
                return new ErrorDataResult<AuthResponseDto>("Kullanıcı bulunamadı.");

            storedToken.IsRevoked = true;
            await _refreshTokenDal.UpdateAsync(storedToken);

            var authResponse = await CreateAuthResponseAsync(user);

            return new SuccessDataResult<AuthResponseDto>(authResponse, "Token yenilendi.");
        }

        public async Task<IResult> LogoutAsync(string userId)
        {
            var tokens = await _refreshTokenDal.GetListAsync(rt => rt.UserId == userId && !rt.IsRevoked);
            
            foreach (var token in tokens)
            {
                token.IsRevoked = true;
                await _refreshTokenDal.UpdateAsync(token);
            }

            var user = await _userDal.GetAsync(u => u.UserId == userId);
            if (user != null)
            {
                user.CurrentStatus = false;
                await _userDal.UpdateAsync(user);
            }

            return new SuccessResult("Çıkış başarılı.");
        }

        private async Task<AuthResponseDto> CreateAuthResponseAsync(User user)
        {
            var accessToken = _jwtService.GenerateAccessToken(user.UserId, user.Email, user.Nickname);
            
            var refreshToken = _jwtService.GenerateRefreshToken();
            
            var refreshTokenEntity = new RefreshToken
            {
                UserId = user.UserId,
                Token = refreshToken,
                ExpiresAt = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpirationDays)
            };
            
            await _refreshTokenDal.AddAsync(refreshTokenEntity);

            var userDto = _mapper.Map<UserDto>(user);

            return new AuthResponseDto
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                AccessTokenExpiration = DateTime.UtcNow.AddMinutes(_jwtSettings.AccessTokenExpirationMinutes),
                RefreshTokenExpiration = refreshTokenEntity.ExpiresAt,
                User = userDto
            };
        }
    }
}
