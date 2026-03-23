namespace PomodoraBack.DTOs
{
    public class UserDto
    {
        public string UserId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Surname { get; set; } = string.Empty;
        public string Nickname { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public bool CurrentStatus { get; set; }
        public decimal TotalPoints { get; set; }
        public DateTime LastSeen { get; set; }
        public DateTime? DeletedAt { get; set; }
        
        /// <summary>
        /// Kullanıcının gerçek zamanlı online durumu.
        /// CurrentStatus = true VE son 5 dakika içinde aktivite varsa true döner.
        /// </summary>
        public bool IsOnline 
        { 
            get 
            {
                var fiveMinutesAgo = DateTime.UtcNow.AddMinutes(-5);
                return CurrentStatus && LastSeen > fiveMinutesAgo;
            }
        }
    }
}
