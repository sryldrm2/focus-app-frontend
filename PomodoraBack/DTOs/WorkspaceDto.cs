namespace PomodoraBack.DTOs;


public class WorkspaceDto
{
    public string WorkspaceId { get; set; } = string.Empty;
    public string WorkspaceName { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public string OwnerNickName { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int MemberCount { get; set; }
}
