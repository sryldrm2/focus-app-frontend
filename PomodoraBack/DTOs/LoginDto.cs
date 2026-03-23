using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    public class LoginDto
    {
        [Required]
        public string EmailOrNickname { get; set; } = string.Empty;
        
        [Required]
        public string Password { get; set; } = string.Empty;
    }
}
