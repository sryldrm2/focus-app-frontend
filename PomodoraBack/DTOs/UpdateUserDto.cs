using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    public class UpdateUserDto
    {
        [MaxLength(20)]
        public string? Name { get; set; }
        
        [MaxLength(20)]
        public string? Surname { get; set; }
        
        public string? Nickname { get; set; }
        
        [EmailAddress]
        public string? Email { get; set; }
        
        [MaxLength(30)]
        [MinLength(6)]
        public string? Password { get; set; }
        
        public bool? CurrentStatus { get; set; }
    }
}
