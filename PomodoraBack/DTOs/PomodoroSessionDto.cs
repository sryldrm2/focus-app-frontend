using PomodoraBack.Core.Enums;

namespace PomodoraBack.DTOs
{
    /// <summary>
    /// Pomodoro seansı bilgilerini döndürmek için DTO
    /// </summary>
    public class PomodoroSessionDto
    {
        /// <summary>
        /// Seans ID'si
        /// </summary>
        public string PomoId { get; set; }

        /// <summary>
        /// Kullanıcı ID'si
        /// </summary>
        public string UserId { get; set; }

        /// <summary>
        /// Görev ID'si (null ise freestyle seans)
        /// </summary>
        public string? TaskId { get; set; }

        /// <summary>
        /// Seans türü
        /// </summary>
        public PomodoroTypeEnums SessionType { get; set; }

        /// <summary>
        /// Seans süresi (dakika)
        /// </summary>
        public int DurationMinute { get; set; }

        /// <summary>
        /// Kazanılan puan
        /// </summary>
        public int PointsEarned { get; set; }

        /// <summary>
        /// Seans notları
        /// </summary>
        public string? Notes { get; set; }

        /// <summary>
        /// Ara verilme sayısı
        /// </summary>
        public int BreakCount { get; set; }

        /// <summary>
        /// Seans başlama zamanı
        /// </summary>
        public DateTime StartedAt { get; set; }

        /// <summary>
        /// Seans oluşturulma zamanı
        /// </summary>
        public DateTime CreatedAt { get; set; }

        /// <summary>
        /// Son güncellenme zamanı
        /// </summary>
        public DateTime? UpdatedAt { get; set; }

        /// <summary>
        /// Seans tamamlanma zamanı (null ise henüz tamamlanmadı)
        /// </summary>
        public DateTime? CompletedAt { get; set; }

        /// <summary>
        /// Seans durumu (OnGoing, Successful, Incomplete, Cancelled)
        /// </summary>
        public SessionStatusEnums Status { get; set; }

        /// <summary>
        /// Ilişkili görev bilgisi (opsiyonel)
        /// </summary>
        public TaskDto? Task { get; set; }

        /// <summary>
        /// Kullanıcı bilgisi (opsiyonel)
        /// </summary>
        public UserDto? User { get; set; }

        /// <summary>
        /// Seans geçen toplam süre (CompletedAt - StartedAt) dakika cinsinden
        /// </summary>
        public int? ElapsedMinutes 
        { 
            get
            {
                if (CompletedAt.HasValue)
                {
                    return (int)(CompletedAt.Value - StartedAt).TotalMinutes;
                }
                return null;
            }
        }

        /// <summary>
        /// Seans tamamlandı mı?
        /// </summary>
        public bool IsCompleted => Status == SessionStatusEnums.Successful;

        /// <summary>
        /// Seans devam ediyor mu?
        /// </summary>
        public bool IsOngoing => Status == SessionStatusEnums.OnGoing;

        /// <summary>
        /// Seans tamamlanmamış/iptal mi?
        /// </summary>
        public bool IsIncomplete => Status == SessionStatusEnums.Incomplete || Status == SessionStatusEnums.Cancelled;
    }
}
