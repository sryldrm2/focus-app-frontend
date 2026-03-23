using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    public class RegisterDto
    {
        [Required]
        [MaxLength(20)]
        public string Name { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(20)]
        public string Surname { get; set; } = string.Empty;
        
        [Required]
        public string Nickname { get; set; } = string.Empty;
        
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(30)]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;
        
        [Required]
        [Compare("Password")]
        public string ConfirmPassword { get; set; } = string.Empty;
    }
}
