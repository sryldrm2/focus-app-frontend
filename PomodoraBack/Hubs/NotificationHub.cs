using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace PomodoraBack.Hubs
{
    [Authorize]
    public class NotificationHub : Hub
    {
        private const string UserIdPrefix = "user_";

        public override async Task OnConnectedAsync()
        {
            // JWT kütüphanelerine göre claim adı farklı olabilir.
            // Önce standart NameIdentifier, sonra raw "sub", sonra SignalR'ın
            // kendi UserIdentifier özelliği kontrol edilir.
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
                      ?? Context.User?.FindFirst("sub")?.Value
                      ?? Context.UserIdentifier;

            if (!string.IsNullOrEmpty(userId))
            {
                // Kullanıcıyı ID'ye göre gruba ekle.
                // Bu gruba bildirim göndermek = o kullanıcıya bildirim göndermek.
                var userGroup = $"{UserIdPrefix}{userId}";
                await Groups.AddToGroupAsync(Context.ConnectionId, userGroup);

                Console.WriteLine(
                    $"[NotificationHub] Bağlandı: UserId={userId}, " +
                    $"ConnectionId={Context.ConnectionId}, Grup={userGroup}");
            }
            else
            {
                // Token geçerliydi ama UserId claim'i bulunamadı — olağandışı durum.
                Console.WriteLine(
                    $"[NotificationHub] Bağlantı kuruldu fakat UserId claim'i yok. " +
                    $"ConnectionId={Context.ConnectionId}");
            }

            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
                      ?? Context.User?.FindFirst("sub")?.Value
                      ?? Context.UserIdentifier;

            if (!string.IsNullOrEmpty(userId))
            {
                var userGroup = $"{UserIdPrefix}{userId}";
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, userGroup);

                Console.WriteLine(
                    $"[NotificationHub] Koptu: UserId={userId}, " +
                    $"ConnectionId={Context.ConnectionId}, Grup={userGroup}");
            }

            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Servis katmanından kullanıcıya ait SignalR grup adını üretmek için
        /// kullanılan yardımcı metod.
        /// </summary>
        public static string GetUserGroupName(string userId)
        {
            return $"{UserIdPrefix}{userId}";
        }
    }
}
