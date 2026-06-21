namespace PomodoraBack.DTOs
{
    /// <summary>
    /// Arkadaş içi liderlik tablosu için döndürülen DTO.
    /// Kullanıcının kendisi ve onaylanmış arkadaşları TotalPoints'e göre sıralanır.
    /// </summary>
    public class FriendLeaderboardDto
    {
        /// <summary>
        /// Arkadaş grubundaki sıralama pozisyonu (1'den başlar)
        /// </summary>
        public int Rank { get; set; }

        /// <summary>
        /// Kullanıcı ID'si
        /// </summary>
        public string UserId { get; set; } = string.Empty;

        /// <summary>
        /// Kullanıcının tam adı (Ad + Soyad)
        /// </summary>
        public string FullName { get; set; } = string.Empty;

        /// <summary>
        /// Kullanıcının benzersiz takma adı
        /// </summary>
        public string Nickname { get; set; } = string.Empty;

        /// <summary>
        /// Toplam kazanılan puan
        /// </summary>
        public int TotalPoints { get; set; }

        /// <summary>
        /// Bu kullanıcı isteği atan kişi mi? Frontend'in mevcut kullanıcıyı
        /// kolayca vurgulaması için kullanılır.
        /// </summary>
        public bool IsCurrentUser { get; set; }
    }
}
