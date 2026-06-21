using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using PomodoraBack.Core.Entities;
using PomodoraBack.Core.Enums;

namespace PomodoraBack.Entities
{
    public class Task:IEntity
    {
        [Key]
        public string TaskId { get; set; } = Guid.NewGuid().ToString();

        [Required]
        public string UserId { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; } = null;
        /// <summary>
        /// 0: NotStarted, 1: InProgress, 2: Completed, 3: Cancelled, 4: OnHold
        /// </summary>
        public TaskStatusEnums Status { get; set; } = TaskStatusEnums.NotStarted;
        public string? WorkspaceId { get; set; } = null;
        public int? Priority { get; set; } = null;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? UpdatedAt { get; set; } = null;
        public DateTime? DueDate { get; set; } = null;
        public DateTime? DeletedAt { get; set; } = null;

        /// <summary>
        /// Bu görev için hedeflenen toplam Pomodoro sayısı (opsiyonel)
        /// </summary>
        public int? PomodoroTargetCount { get; set; } = null;

        /// <summary>
        /// Bu görev için başarıyla tamamlanan Pomodoro sayısı
        /// </summary>
        public int? CompletedPomodoroCount { get; set; } = 0;

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;
        [ForeignKey(nameof(WorkspaceId))]
        public Workspace? Workspace { get; set; }
    }
}
