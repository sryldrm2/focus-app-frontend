using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;
using PomodoraBack.Core.Entities;

namespace PomodoraBack.Entities;

[PrimaryKey(nameof(WorkspaceId), nameof(UserId))]
public class WorkspaceMember : IEntity
{
    [Required]
    public string WorkspaceId { get; set; } = string.Empty;
    [Required]
    public string UserId { get; set; } = string.Empty;
    public DateTime JoinedAt { get; set; } = DateTime.Now;

    [ForeignKey(nameof(WorkspaceId))]
    public Workspace Workspace { get; set; } = null!;
    [ForeignKey(nameof(UserId))]
    public User User { get; set; } = null!;

}
