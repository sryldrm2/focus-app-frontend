using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using PomodoraBack.Services.Interfaces;
using PomodoraBack.DTOs;
using System.Security.Claims;

namespace PomodoraBack.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FriendRequestController : BaseController
    {
        private readonly IFriendRequest _friendRequestService;

        public FriendRequestController(IFriendRequest friendRequestService)
        {
            _friendRequestService = friendRequestService;
        }

        /// <summary>
        /// Arkadaş isteği gönder
        /// </summary>
        [HttpPost("send")]
        [Authorize]
        public async Task<IActionResult> SendFriendRequest([FromBody] SendFriendRequestDto request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _friendRequestService.SendFriendRequestAsync(userId, request);
            
            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }

        /// <summary>
        /// Arkadaş isteğini kabul et
        /// </summary>
        [HttpPost("{friendRequestId}/accept")]
        [Authorize]
        public async Task<IActionResult> AcceptFriendRequest(string friendRequestId)
        {
            var result = await _friendRequestService.AcceptFriendRequestAsync(friendRequestId);
            
            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }

        /// <summary>
        /// Arkadaş isteğini reddet
        /// </summary>
        [HttpPost("{friendRequestId}/reject")]
        [Authorize]
        public async Task<IActionResult> RejectFriendRequest(string friendRequestId)
        {
            var result = await _friendRequestService.RejectFriendRequestAsync(friendRequestId);
            
            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }

        /// <summary>
        /// Beklemede olan arkadaş isteklerini getir
        /// </summary>
        [HttpGet("pending")]
        [Authorize]
        public async Task<IActionResult> GetPendingRequests()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _friendRequestService.GetPendingRequestsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Gönderilen arkadaş isteklerini getir
        /// </summary>
        [HttpGet("sent")]
        [Authorize]
        public async Task<IActionResult> GetSentRequests()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _friendRequestService.GetSentRequestsAsync(userId);
            return Ok(result);
        }
    }
}
