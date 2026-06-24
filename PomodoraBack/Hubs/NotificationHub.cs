using Microsoft.AspNetCore.SignalR;
using PomodoraBack.Services.Interfaces;
using System.Security.Claims;

namespace PomodoraBack.Hubs
{
    public class NotificationHub : Hub
    {
        private const string UserIdPrefix = "user_";
        private const string WorkspaceIdPrefix = "workspace_";

        private readonly IWorkspaceRealtimeService _workspaceRealtimeService;

        public NotificationHub(IWorkspaceRealtimeService workspaceRealtimeService)
        {
            _workspaceRealtimeService = workspaceRealtimeService;
        }

        public static string GetWorkspaceGroupName(string workspaceId)
        {
            return $"{WorkspaceIdPrefix}{workspaceId}";
        }

        /// <summary>
        /// Kullanıcının üye olduğu tüm workspace SignalR gruplarına bağlantıyı ekler.
        /// </summary>
        public async Task SyncWorkspaceGroups()
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
            {
                Console.WriteLine(
                    $"[NotificationHub] SyncWorkspaceGroups: yetkisiz bağlantı {Context.ConnectionId}");
                return;
            }

            await _workspaceRealtimeService.SyncConnectionWorkspaceGroupsAsync(
                Context.ConnectionId,
                userId);
        }

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

                await _workspaceRealtimeService.SyncConnectionWorkspaceGroupsAsync(
                    Context.ConnectionId,
                    userId);
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
