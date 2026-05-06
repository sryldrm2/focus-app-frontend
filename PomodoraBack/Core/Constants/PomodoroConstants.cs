using PomodoraBack.Core.Enums;

namespace PomodoraBack.Core.Constants
{
    /// <summary>
    /// Pomodoro Tekniği sabitlerini içerir
    /// </summary>
    public static class PomodoroConstants
    {
        // ===== STANDART SÜRELERİ =====
        /// <summary>
        /// Standart çalışma seansı süresi (dakika)
        /// </summary>
        public const int WORK_SESSION_DURATION = 25;

        /// <summary>
        /// Kısa mola süresi (dakika)
        /// </summary>
        public const int SHORT_BREAK_DURATION = 5;

        /// <summary>
        /// Uzun mola süresi (dakika)
        /// </summary>
        public const int LONG_BREAK_DURATION = 15;

        // ===== CUSTOM SÜRELERİ İÇİN LİMİTLER =====
        /// <summary>
        /// Minimum custom seans süresi (dakika)
        /// </summary>
        public const int MIN_CUSTOM_DURATION = 5;

        /// <summary>
        /// Maksimum custom seans süresi (dakika)
        /// </summary>
        public const int MAX_CUSTOM_DURATION = 60;

        // ===== POMODORO DÖNGÜSÜ =====
        /// <summary>
        /// Kaç tane çalışma seansından sonra uzun mola alınır
        /// Örnek: 4 çalışma seansı → uzun mola
        /// </summary>
        public const int SESSIONS_BEFORE_LONG_BREAK = 4;

        // ===== PUAN SİSTEMİ =====
        /// <summary>
        /// Standart çalışma seansı (25 dk) için kazanılan puan
        /// </summary>
        public const int POINTS_PER_WORK_SESSION = 25;

        /// <summary>
        /// Kısa mola (5 dk) tamamlaması için kazanılan puan
        /// </summary>
        public const int POINTS_PER_SHORT_BREAK = 5;

        /// <summary>
        /// Uzun mola (15 dk) tamamlaması için kazanılan puan
        /// </summary>
        public const int POINTS_PER_LONG_BREAK = 15;

        /// <summary>
        /// Custom seans için her dakika başına kazanılan puan
        /// Örnek: 30 dakika custom seans = 30 puan
        /// </summary>
        public const int POINTS_PER_MINUTE = 1;

        // ===== HATA MESAJLARI =====
        /// <summary>
        /// Devam eden seans varken yeni seans başlatamayacağını belirten mesaj
        /// </summary>
        public const string ERROR_SESSION_ALREADY_ONGOING = "Devam eden bir seans var. Önce onu tamamlayın.";

        /// <summary>
        /// Süresi geçerli aralıkta olmayan seans hatasını belirten mesaj
        /// </summary>
        public const string ERROR_INVALID_DURATION = "Seans süresi 5 ile 60 dakika arasında olmalıdır.";

        /// <summary>
        /// Kullanıcı bulunamadığını belirten mesaj
        /// </summary>
        public const string ERROR_USER_NOT_FOUND = "Kullanıcı bulunamadı.";

        /// <summary>
        /// Seans bulunamadığını belirten mesaj
        /// </summary>
        public const string ERROR_SESSION_NOT_FOUND = "Seans bulunamadı.";

        // ===== BAŞARI MESAJLARI =====
        /// <summary>
        /// Seans başarıyla başlatıldığını belirten mesaj
        /// </summary>
        public const string SUCCESS_SESSION_STARTED = "Seans başlatıldı.";

        /// <summary>
        /// Seans başarıyla tamamlandığını belirten mesaj
        /// </summary>
        public const string SUCCESS_SESSION_COMPLETED = "Seans tamamlandı.";

        /// <summary>
        /// Seans başarıyla iptal edildiğini belirten mesaj
        /// </summary>
        public const string SUCCESS_SESSION_CANCELLED = "Seans iptal edildi.";

        // ===== YARDIMCI FONKSİYONLAR =====
        /// <summary>
        /// Seans süresine göre kazanılacak puanı hesaplar
        /// 
        /// KURAL:
        /// - Standart süreler: Sabit puan (25, 5, 15 dakika)
        /// - Custom süreler: Her 1 dakika = 1 puan
        /// 
        /// ÖRNEKLER:
        /// - 25 dakika work = 25 puan
        /// - 30 dakika custom work = 30 puan (her dakika 1 puan)
        /// - 5 dakika short break = 5 puan
        /// - 10 dakika custom break = 10 puan
        /// </summary>
        /// <param name="durationMinute">Seans süresi (dakika)</param>
        /// <param name="sessionType">Seans türü</param>
        /// <returns>Kazanılacak puan</returns>
        public static int CalculatePoints(int durationMinute, PomodoroTypeEnums sessionType)
        {
            // Custom süreler için: her 1 dakika = 1 puan
            // Standart süreler de bu kurala uygun zaten:
            // - 25 dakika work = 25 puan
            // - 5 dakika short break = 5 puan
            // - 15 dakika long break = 15 puan
            
            return durationMinute * POINTS_PER_MINUTE;
        }
    }
}
