using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    public class RefreshTokenDto
    {
        [Required]
        public string RefreshToken { get; set; } = string.Empty;
    }
}
