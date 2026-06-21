using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace PomodoraBack.Hubs
{
    public class NotificationHub : Hub
    {
        private const string UserIdPrefix = "user_";

        public override async Task OnConnectedAsync()
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!string.IsNullOrEmpty(userId))
            {
                // Kullanıcıyı ID'ye göre grup'a ekle
                // Bu grup'a bildirim göndermek = o kullanıcıya bildirim göndermek anlamına gelir
                var userGroup = $"{UserIdPrefix}{userId}";
                await Groups.AddToGroupAsync(Context.ConnectionId, userGroup);

                // Debug/logging amaçlı
                Console.WriteLine($"[NotificationHub] Kullanıcı bağlandı: UserId={userId}, ConnectionId={Context.ConnectionId}, Grup={userGroup}");
            }
            else
            {
                Console.WriteLine($"[NotificationHub] Yetkisiz bağlantı denemesi: ConnectionId={Context.ConnectionId}");
            }

            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!string.IsNullOrEmpty(userId))
            {
                var userGroup = $"{UserIdPrefix}{userId}";
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, userGroup);

                Console.WriteLine($"[NotificationHub] Kullanıcı koptu: UserId={userId}, ConnectionId={Context.ConnectionId}, Grup={userGroup}");
            }

            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Hub'ı kullanıcı ID'sine göre ulaşabilmek için yardımcı method
        /// </summary>
        public static string GetUserGroupName(string userId)
        {
            return $"{UserIdPrefix}{userId}";
        }
    }
}
