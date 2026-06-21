using PomodoraBack.Core.Enums;

namespace PomodoraBack.DTOs
{
    public class NotificationDto
    {
        public string NotificationId { get; set; } = string.Empty;
        public string UserId { get; set; } = string.Empty;
        public NotificationTypeEnums Type { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public DateTime? ReadAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public string? RelatedEntityId { get; set; }
        public string? MetadataJson { get; set; }
        public DateTime? TriggerAt { get; set; }
    }
}
