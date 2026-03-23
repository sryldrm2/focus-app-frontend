using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using PomodoraBack.Core.Entities;

namespace PomodoraBack.Entities
{
    public class FriendShip : IEntity
    {
        [Key]
        public string FriendShipId { get; set; } = Guid.NewGuid().ToString();

        [Required]
        [ForeignKey(nameof(FirstUser))]
        public string FirstUserId { get; set; } = string.Empty;

        [Required]
        [ForeignKey(nameof(SecondUser))]
        public string SecondUserId { get; set; } = string.Empty;

        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow; 
        
        public DateTime? DeletedAt { get; set; } = null;
        
        
        public User FirstUser { get; set; } = null!;   
        public User SecondUser { get; set; } = null!;  
    }
}
