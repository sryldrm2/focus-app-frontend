using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PomodoraBack.DTOs;
using PomodoraBack.Services.Interfaces;
using System.Security.Claims;

namespace PomodoraBack.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : BaseController
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto registerDto)
        {
            var result = await _authService.RegisterAsync(registerDto);
            return Response(result);
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto loginDto)
        {
            var result = await _authService.LoginAsync(loginDto);
            return Response(result);
        }

        [HttpPost("refresh-token")]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenDto refreshTokenDto)
        {
            var result = await _authService.RefreshTokenAsync(refreshTokenDto.RefreshToken);
            return Response(result);
        }

        [Authorize]
        [HttpPost("logout")]
        public async Task<IActionResult> Logout()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { success = false, message = "Kullanıcı kimliği bulunamadı." });

            var result = await _authService.LogoutAsync(userId);
            
            if (!result.Success)
                return BadRequest(new { success = false, message = result.Message });
            
            return Ok(new { success = true, message = result.Message });
        }

        [Authorize]
        [HttpGet("me")]
        public IActionResult GetCurrentUser()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var email = User.FindFirst(ClaimTypes.Email)?.Value;
            var nickname = User.FindFirst("nickname")?.Value;

            return Ok(new 
            { 
                success = true,
                data = new { userId, email, nickname }
            });
        }
    }
}
