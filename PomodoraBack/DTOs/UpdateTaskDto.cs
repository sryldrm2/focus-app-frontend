using System.ComponentModel.DataAnnotations;
using PomodoraBack.Core.Enums;

namespace PomodoraBack.DTOs
{
    /// <summary>
    /// Görev güncellemek için DTO
    /// </summary>
    public class UpdateTaskDto
    {
        /// <summary>
        /// Görev başlığı
        /// </summary>
        [MaxLength(200, ErrorMessage = "Başlık maksimum 200 karakter olmalıdır")]
        public string? Title { get; set; }

        /// <summary>
        /// Görev açıklaması
        /// </summary>
        [MaxLength(1000, ErrorMessage = "Açıklama maksimum 1000 karakter olmalıdır")]
        public string? Description { get; set; }

        /// <summary>
        /// Görev durumu
        /// </summary>
        public TaskStatusEnums? Status { get; set; }

        /// <summary>
        /// Görev önceliği (1-5 arası, 1=düşük, 5=yüksek)
        /// </summary>
        [Range(1, 5, ErrorMessage = "Öncelik 1 ile 5 arasında olmalıdır")]
        public int? Priority { get; set; }

        /// <summary>
        /// Görevin tamamlanması gereken tarih
        /// </summary>
        public DateTime? DueDate { get; set; }
    }
}
