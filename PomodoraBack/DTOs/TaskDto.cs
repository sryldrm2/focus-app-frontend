using PomodoraBack.Core.Enums;

namespace PomodoraBack.DTOs
{
    /// <summary>
    /// Görev bilgilerini döndürmek için basit DTO
    /// </summary>
    public class TaskDto
    {
        public string TaskId { get; set; }
        public string? WorkspaceId { get; set; }
        public string Title { get; set; }
        public string? Description { get; set; }
        public TaskStatusEnums Status { get; set; }
        public int? Priority { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? DueDate { get; set; }

        /// <summary>
        /// Bu görev için hedeflenen toplam Pomodoro sayısı (null ise hedef belirlenmemiş)
        /// </summary>
        public int? PomodoroTargetCount { get; set; }

        /// <summary>
        /// Bu görev için başarıyla tamamlanan Pomodoro sayısı
        /// </summary>
        public int? CompletedPomodoroCount { get; set; }
    }
}
