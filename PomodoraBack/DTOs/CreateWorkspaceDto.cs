using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    public class CreateWorkspaceDto
    {
        [Required(ErrorMessage = "Oda adı gereklidir")]
        [MaxLength(100, ErrorMessage = "Oda adı maksimum 100 karakter olmalıdır")]
        public string WorkspaceName { get; set; } = string.Empty;
    }
}
