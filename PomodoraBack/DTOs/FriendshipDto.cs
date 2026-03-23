namespace PomodoraBack.DTOs
{
    public class FriendshipDto
    {
        public string FriendshipId { get; set; } = string.Empty;
        public string FirstUserId { get; set; } = string.Empty;
        public string SecondUserId { get; set; } = string.Empty;
        
        // Navigation properties
        public UserDto FirstUser { get; set; } = null!;
        public UserDto SecondUser { get; set; } = null!;
        
        public DateTime CreatedAt { get; set; }
        public DateTime? DeletedAt { get; set; }
    }
}
