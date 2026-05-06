using System.ComponentModel.DataAnnotations;
using PomodoraBack.Core.Enums;

namespace PomodoraBack.DTOs
{
    /// <summary>
    /// Yeni Pomodoro seansı oluşturmak için DTO
    /// </summary>
    public class CreatePomodoroSessionDto
    {
        /// <summary>
        /// Seans türü (WorkSession, ShortBreakSession, LongBreakSession)
        /// </summary>
        [Required(ErrorMessage = "Seans türü gereklidir")]
        public PomodoroTypeEnums SessionType { get; set; }

        /// <summary>
        /// Seans süresi (dakika)
        /// Varsayılan: WorkSession = 25, ShortBreak = 5, LongBreak = 15
        /// Custom süreler: 5-60 dakika arası
        /// </summary>
        [Required(ErrorMessage = "Seans süresi gereklidir")]
        [Range(5, 60, ErrorMessage = "Seans süresi 5 ile 60 dakika arasında olmalıdır")]
        public int DurationMinute { get; set; }

        /// <summary>
        /// İlişkili görev ID'si (Opsiyonel)
        /// Eğer null ise freestyle seans (görevsiz)
        /// </summary>
        public string? TaskId { get; set; }

        /// <summary>
        /// Seans notları (Opsiyonel)
        /// </summary>
        [MaxLength(500, ErrorMessage = "Notlar maksimum 500 karakter olmalıdır")]
        public string? Notes { get; set; }
    }
}
