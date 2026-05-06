using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using PomodoraBack.Core.Entities;
using PomodoraBack.Core.Enums;

namespace PomodoraBack.Entities
{
    public class PomodoroSession:IEntity
    {    
        [Key]
        public string PomoId { get; set; } = Guid.NewGuid().ToString();

       [Required]
        public string UserId { get; set; } = string.Empty;

        public string? TaskId { get; set; } = null;

        // Oturumun türü: Çalışma mı, Kısa Mola mı, Uzun Mola mı?
        public PomodoroTypeEnums SessionType { get; set; } = PomodoroTypeEnums.WorkSession;

        public int DurationMinute { get; set; } = 25; // Default: 25 dakika (standart work session)

        public int PointsEarned { get; set; } = 0;
        public string? Notes { get; set; } = null;
        public int BreakCount { get; set; } = 0;

        public DateTime StartedAt { get; set; } = DateTime.Now;
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? UpdatedAt { get; set; } = null;

        // Oturumun bittiği zaman (başarıyla tamamlanmadıysa null kalabilir)
        public DateTime? CompletedAt { get; set; } = null; 
        public DateTime? DeletedAt { get; set; } = null;

        // Oturumun durumu: Başarılı mı, Yarıda mı kesildi?
        public SessionStatusEnums Status { get; set; } = SessionStatusEnums.OnGoing;

        [ForeignKey(nameof(UserId))]
        public User User { get; set; } = null!;

        [ForeignKey(nameof(TaskId))]
        public Task? Task { get; set; } = null;
        
    }
}
