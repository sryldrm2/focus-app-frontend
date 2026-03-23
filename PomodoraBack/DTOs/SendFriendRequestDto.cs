using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    public class SendFriendRequestDto
    {
        [Required]
        public string ReceiverId { get; set; } = string.Empty;
    }
}
