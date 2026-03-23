using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using PomodoraBack.Core.Entities;

namespace PomodoraBack.Entities
{
    public class FriendRequest : IEntity
    {
        [Key]
        public string FriendRequestId { get; set; } = Guid.NewGuid().ToString();
        
        [Required]
        [ForeignKey(nameof(Consigner))]
        public string ConsignerId { get; set; } = string.Empty;
        
        [Required]
        [ForeignKey(nameof(Receiver))]
        public string ReceiverId { get; set; } = string.Empty;
        
        /// <summary>
        /// Arkadaş isteği durumu: false = bekleniyor, true = kabul edildi
        /// </summary>
        public bool Status { get; set; } = false; 
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        
        // ⭐ Navigation Properties
        public User Consigner { get; set; } = null!; 
        public User Receiver { get; set; } = null!;  
    }
}
