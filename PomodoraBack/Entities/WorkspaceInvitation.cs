using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using PomodoraBack.Core.Entities;
using PomodoraBack.Core.Enums;

namespace PomodoraBack.Entities;

public class WorkspaceInvitation:IEntity
{
    [Key]
    public string WorkspaceInvitationId { get; set; }=Guid.NewGuid().ToString();
    public string WorkspaceId { get; set; }=string.Empty;
    public string SenderId { get; set; } = string.Empty;
    public string ReceiverId { get; set; } = string.Empty;
    public WorkspaceInvitationStatusEnums Status { get; set; } = WorkspaceInvitationStatusEnums.pending; 
    public DateTime CreatedAt { get; set; }=DateTime.Now;
    public DateTime ExpiresAt { get; set; }
    [ForeignKey(nameof(WorkspaceId))]
    public Workspace Workspace { get; set; } = null!;
    [ForeignKey(nameof(SenderId))]
    public User Sender { get; set; } = null!;
    [ForeignKey(nameof(ReceiverId))]
    public User Recevier { get; set; } = null!;

}
