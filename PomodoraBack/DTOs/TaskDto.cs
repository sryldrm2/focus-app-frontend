using PomodoraBack.Core.Enums;

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
        public string Description { get; set; }
        public TaskStatusEnums Status { get; set; }
        public int? Priority { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? DueDate { get; set; }
    }
}
