using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using PomodoraBack.Core.Entities;
using PomodoraBack.Core.Enums;

namespace PomodoraBack.Entities
{
    public class Notification : IEntity
    {
        [Key]
        public string NotificationId { get; set; } = Guid.NewGuid().ToString();

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

        public bool IsRead { get; set; } = false;
        public DateTime? ReadAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // RelatedEntityId can point to FriendRequestId, WorkspaceInvitationId or TaskId.
        public string? RelatedEntityId { get; set; }

        // Optional free-form metadata for future notification scenarios.
        public string? MetadataJson { get; set; }

        // Useful for due-date reminders and scheduled notifications.
        public DateTime? TriggerAt { get; set; }

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;
    }
}
