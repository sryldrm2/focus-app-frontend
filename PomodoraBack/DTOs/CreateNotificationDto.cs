using System.ComponentModel.DataAnnotations;
using PomodoraBack.Core.Enums;

namespace PomodoraBack.DTOs
{
    public class CreateNotificationDto
    {
        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        public NotificationTypeEnums Type { get; set; }

        [Required]
        [MaxLength(120)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(500)]
        public string Message { get; set; } = string.Empty;

        public string? RelatedEntityId { get; set; }
        public string? MetadataJson { get; set; }
        public DateTime? TriggerAt { get; set; }
    }
}
