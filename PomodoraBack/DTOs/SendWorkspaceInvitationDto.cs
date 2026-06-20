using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    public class SendWorkspaceInvitationDto
    {
        [Required(ErrorMessage = "Oda bilgisi gereklidir")]
        public string WorkspaceId { get; set; } = string.Empty;

        public string? ReceiverId { get; set; }

        public string? ReceiverNickname { get; set; }
    }
}
