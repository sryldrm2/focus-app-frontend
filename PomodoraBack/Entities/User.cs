using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using PomodoraBack.Core.Entities;

namespace PomodoraBack.Entities
{
    public class User: IEntity
    {
        [Key]
        public string UserId { get; set; } = Guid.NewGuid().ToString();
        [Required]
        [MaxLength(20)]
        public string Name { get; set; } = string.Empty;
        [Required]
        [MaxLength(20)]
        public string Surname { get; set; } = string.Empty;
        public string Nickname { get; set; } = string.Empty;
        [Required]
        public string Email { get; set; } = string.Empty ;
        [Required]
        [MaxLength(100)]
        public string Password { get; set; } = string.Empty;
        public bool CurrentStatus { get; set; } = false;
        public decimal TotalPoints { get; set; } = 0;
        public DateTime LastSeen { get; set; } = DateTime.Now;
        public DateTime? DeletedAt { get; set; } = null;
    }
}
