using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using PomodoraBack.Services.Interfaces;
using System.Security.Claims;

namespace PomodoraBack.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FriendshipController : BaseController
    {
        private readonly IFriendRequest _friendRequestService;

        public FriendshipController(IFriendRequest friendRequestService)
        {
            _friendRequestService = friendRequestService;
        }

        /// <summary>
        /// Kullanıcının arkadaşlarını getir
        /// </summary>
        [HttpGet("my-friends")]
        [Authorize]
        public async Task<IActionResult> GetMyFriends()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _friendRequestService.GetFriendsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Başka bir kullanıcının arkadaşlarını getir
        /// </summary>
        [HttpGet("{userId}/friends")]
        [Authorize]
        public async Task<IActionResult> GetUserFriends(string userId)
        {
            var result = await _friendRequestService.GetFriendsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// İki kullanıcı arasındaki arkadaşlığı getir
        /// </summary>
        [HttpGet("{friendId}/check")]
        [Authorize]
        public async Task<IActionResult> GetFriendship(string friendId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _friendRequestService.GetFriendshipAsync(userId, friendId);
            
            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }

        /// <summary>
        /// İki kullanıcı arkadaş mı kontrol et
        /// </summary>
        [HttpGet("{friendId}/are-friends")]
        [Authorize]
        public async Task<IActionResult> AreFriends(string friendId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _friendRequestService.AreFriendsAsync(userId, friendId);
            return Ok(result);
        }

        /// <summary>
        /// Arkadaşı kaldır
        /// </summary>
        [HttpDelete("{friendId}")]
        [Authorize]
        public async Task<IActionResult> RemoveFriend(string friendId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _friendRequestService.RemoveFriendAsync(userId, friendId);
            
            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
    }
}
