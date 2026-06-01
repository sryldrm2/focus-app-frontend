using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    /// <summary>
    /// Kişisel bir task'ı workspace'e aktarmak için DTO (Senaryo 2)
    /// </summary>
    public class AssignTaskToWorkspaceDto
    {
        [Required(ErrorMessage = "Oda bilgisi gereklidir")]
        public string WorkspaceId { get; set; } = string.Empty;
    }
}
