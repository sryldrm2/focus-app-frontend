using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    public class SendWorkspaceInvitationDto
    {
        [Required(ErrorMessage = "Oda bilgisi gereklidir")]
        public string WorkspaceId { get; set; } = string.Empty;

        [Required(ErrorMessage = "Davet edilecek kullanıcı gereklidir")]
        public string ReceiverId { get; set; } = string.Empty;
    }
}
