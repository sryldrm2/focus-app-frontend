using Core.Utilities.Results;
using PomodoraBack.DTOs;

namespace PomodoraBack.Services.Interfaces
{
    public interface IWorkspaceService
    {
        Task<IDataResult<WorkspaceDto>> CreateWorkspaceAsync(string ownerId, CreateWorkspaceDto request);
        Task<IDataResult<WorkspaceInvitationDto>> SendInvitationAsync(string senderId, SendWorkspaceInvitationDto request);
        Task<IDataResult<WorkspaceInvitationDto>> AcceptInvitationAsync(string receiverId, string invitationId);
        Task<IDataResult<List<WorkspaceDto>>> GetMyWorkspacesAsync(string userId);
        Task<IDataResult<List<WorkspaceInvitationDto>>> GetPendingInvitationsAsync(string userId);
    }
}
