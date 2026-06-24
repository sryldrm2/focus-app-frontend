using System.ComponentModel.DataAnnotations;

namespace PomodoraBack.DTOs
{
    /// <summary>
    /// Oda pomodoro duraklatma/devam senkronizasyonu için DTO
    /// </summary>
    public class WorkspacePomodoroSyncDto
    {
        [Required]
        [Range(0, 3600)]
        public int SecondsLeft { get; set; }
    }

    /// <summary>
    /// SignalR üzerinden gönderilen oda pomodoro senkron event'i
    /// </summary>
    public class WorkspacePomodoroSyncEventDto
    {
        public string PomoId { get; set; } = string.Empty;
        public string? TaskId { get; set; }
        public int SecondsLeft { get; set; }
    }
}
