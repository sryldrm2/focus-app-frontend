using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    public class UpdateFriendRequestDto
    {
        [Required]
        public string FriendRequestId { get; set; } = string.Empty;

        /// <summary>
        /// true = kabul et, false = reddet
        /// </summary>
        [Required]
        public bool Accept { get; set; }
    }
}
