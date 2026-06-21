using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations;
using PomodoraBack.Core.Enums;

namespace PomodoraBack.DTOs
{
    /// <summary>
    /// Yeni Görev oluşturmak için DTO
    /// </summary>
    public class CreateTaskDto
    {
        /// <summary>
        /// Görevin ait olduğu oda (opsiyonel)
        /// </summary>
        public string? WorkspaceId { get; set; }

        /// <summary>
        /// Görev başlığı
        /// </summary>
        [Required(ErrorMessage = "Görev başlığı gereklidir")]
        [MaxLength(200, ErrorMessage = "Başlık maksimum 200 karakter olmalıdır")]
        public string Title { get; set; }

        /// <summary>
        /// Görev açıklaması
        /// </summary>
        [MaxLength(1000, ErrorMessage = "Açıklama maksimum 1000 karakter olmalıdır")]
        public string? Description { get; set; }

        /// <summary>
        /// Görev önceliği (1-5 arası, 1=düşük, 5=yüksek)
        /// </summary>
        [Range(1, 5, ErrorMessage = "Öncelik 1 ile 5 arasında olmalıdır")]
        public int? Priority { get; set; }

        /// <summary>
        /// Görevin tamamlanması gereken tarih
        /// </summary>
        public DateTime? DueDate { get; set; }

        /// <summary>
        /// Bu görev için hedeflenen toplam Pomodoro sayısı (opsiyonel)
        /// </summary>
        [Range(1, 500, ErrorMessage = "Pomodoro hedefi 1 ile 500 arasında olmalıdır")]
        public int? PomodoroTargetCount { get; set; }
    }
}
