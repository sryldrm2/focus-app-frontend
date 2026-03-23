namespace PomodoraBack.DTOs
{
    public class FriendRequestDto
    {
        public string FriendRequestId { get; set; } = string.Empty;
        public string ConsignerId { get; set; } = string.Empty;
        public string ReceiverId { get; set; } = string.Empty;
        
        // Nested DTOs - İlişkili kullanıcıların bilgileri
        public UserDto? Consigner { get; set; }
        public UserDto? Receiver { get; set; }
        
        public bool Status { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
