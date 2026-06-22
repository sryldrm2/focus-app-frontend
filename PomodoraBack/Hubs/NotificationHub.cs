using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using PomodoraBack.DataAccess.Interfaces;
using System.Security.Claims;

namespace PomodoraBack.Hubs
{
    [Authorize]
    public class NotificationHub : Hub
    {
        private const string UserIdPrefix      = "user_";
        private const string WorkspaceIdPrefix = "workspace_";

        private readonly IWorkspaceMemberDal _workspaceMemberDal;

        public NotificationHub(IWorkspaceMemberDal workspaceMemberDal)
        {
            _workspaceMemberDal = workspaceMemberDal;
        }

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
                // 1. Kullanıcıyı kişisel bildirim grubuna ekle (user_{userId})
                var userGroup = $"{UserIdPrefix}{userId}";
                await Groups.AddToGroupAsync(Context.ConnectionId, userGroup);

                // 2. Kullanıcının üye olduğu tüm workspace gruplarına ekle (workspace_{id})
                //    Böylece oda içi olaylar (WorkspaceTaskCreated, WorkspacePomodoroStarted)
                //    bu bağlantıya otomatik ulaşır.
                try
                {
                    var workspaceIds = await _workspaceMemberDal.GetUserWorkspaceIdsAsync(userId);
                    foreach (var wsId in workspaceIds)
                    {
                        var wsGroup = $"{WorkspaceIdPrefix}{wsId}";
                        await Groups.AddToGroupAsync(Context.ConnectionId, wsGroup);
                    }

                    Console.WriteLine(
                        $"[NotificationHub] Bağlandı: UserId={userId}, " +
                        $"ConnectionId={Context.ConnectionId}, " +
                        $"Kişisel={userGroup}, WorkspaceGrubu={workspaceIds.Count}");
                }
                catch (Exception ex)
                {
                    // Workspace sorgusu başarısız olsa bile bağlantı düşürülmez.
                    Console.WriteLine(
                        $"[NotificationHub] Workspace grupları yüklenemedi: UserId={userId}, Hata={ex.Message}");
                }
            }
            else
            {
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
                // Kişisel gruptan çıkar
                var userGroup = $"{UserIdPrefix}{userId}";
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, userGroup);

                // Workspace gruplarından çıkar
                try
                {
                    var workspaceIds = await _workspaceMemberDal.GetUserWorkspaceIdsAsync(userId);
                    foreach (var wsId in workspaceIds)
                    {
                        await Groups.RemoveFromGroupAsync(
                            Context.ConnectionId, $"{WorkspaceIdPrefix}{wsId}");
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine(
                        $"[NotificationHub] Disconnect — workspace grupları temizlenemedi: " +
                        $"UserId={userId}, Hata={ex.Message}");
                }

                Console.WriteLine(
                    $"[NotificationHub] Koptu: UserId={userId}, ConnectionId={Context.ConnectionId}");
            }

            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Kullanıcıya ait kişisel SignalR grup adını döndürür.
        /// </summary>
        public static string GetUserGroupName(string userId)
            => $"{UserIdPrefix}{userId}";

        /// <summary>
        /// Workspace'e ait SignalR grup adını döndürür.
        /// Bu gruba event göndermek = odadaki tüm online üyelere göndermek anlamına gelir.
        /// </summary>
        public static string GetWorkspaceGroupName(string workspaceId)
            => $"{WorkspaceIdPrefix}{workspaceId}";
    }
}
