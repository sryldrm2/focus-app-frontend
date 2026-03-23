using System.ComponentModel.DataAnnotations;
using PomodoraBack.Core.Entities;

namespace PomodoraBack.Entities
{
    public class RefreshToken : IEntity
    {
        [Key]
        public string Id { get; set; } = Guid.NewGuid().ToString();
        
        [Required]
        public string UserId { get; set; } = string.Empty;
        
        [Required]
        public string Token { get; set; } = string.Empty;
        
        public DateTime ExpiresAt { get; set; }
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public bool IsRevoked { get; set; } = false;
        public User User { get; set; } = null!;
    }
}
