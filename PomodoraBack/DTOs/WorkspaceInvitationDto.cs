using PomodoraBack.Core.Enums;

namespace PomodoraBack.DTOs
{
    public class WorkspaceInvitationDto
    {
        public string WorkspaceInvitationId { get; set; } = string.Empty;
        public string WorkspaceId { get; set; } = string.Empty;
        public string SenderId { get; set; } = string.Empty;
        public string ReceiverId { get; set; } = string.Empty;
        public WorkspaceInvitationStatusEnums Status { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
