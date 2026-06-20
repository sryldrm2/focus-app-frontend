using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PomodoraBack.DTOs;
using PomodoraBack.Services.Interfaces;
using System.Security.Claims;

namespace PomodoraBack.Controllers
{
    [ApiController]
    [Route("api/workspaces")]
    [Authorize]
    public class WorkspacesController : BaseController
    {
        private readonly IWorkspaceService _workspaceService;

        public WorkspacesController(IWorkspaceService workspaceService)
        {
            _workspaceService = workspaceService;
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateWorkspaceDto request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _workspaceService.CreateWorkspaceAsync(userId, request);
            return Response(result);
        }

        [HttpPost("invitations")]
        public async Task<IActionResult> SendInvitation([FromBody] SendWorkspaceInvitationDto request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _workspaceService.SendInvitationAsync(userId, request);
            return Response(result);
        }

        [HttpPost("invitations/{invitationId}/accept")]
        public async Task<IActionResult> AcceptInvitation(string invitationId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _workspaceService.AcceptInvitationAsync(userId, invitationId);
            return Response(result);
        }

        [HttpGet("mine")]
        public async Task<IActionResult> GetMyWorkspaces()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _workspaceService.GetMyWorkspacesAsync(userId);
            return Response(result);
        }

        [HttpGet("invitations/pending")]
        public async Task<IActionResult> GetPendingInvitations()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _workspaceService.GetPendingInvitationsAsync(userId);
            return Response(result);
        }
    }
}
