using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using PomodoraBack.Core.Entities;

namespace PomodoraBack.Entities;

public class Workspace:IEntity
{
    [Key]
    public string WorkspaceId { get; set; } =  Guid.NewGuid().ToString();
    [Required]
    public string OwnerId { get; set; } = string.Empty;
    [Required]
    public string WorkspaceName { get; set; }= string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public bool isActive { get; set; } = true;

    [ForeignKey(nameof(OwnerId))]
    public User Owner { get; set; } = null!;

}
