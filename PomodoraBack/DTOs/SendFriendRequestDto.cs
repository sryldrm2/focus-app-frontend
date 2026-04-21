using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    public class SendFriendRequestDto
    {

        public string? ReceiverId { get; set; } = string.Empty;
        
        /// <summary>
        /// Alıcının nickname'i - ReceiverId yerine kullanılabilir
        /// </summary>
        public string? ReceiverNickname { get; set; }
    }
}
