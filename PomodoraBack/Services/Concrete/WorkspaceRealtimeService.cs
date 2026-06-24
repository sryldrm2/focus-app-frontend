using Microsoft.AspNetCore.SignalR;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.DTOs;
using PomodoraBack.Hubs;
using PomodoraBack.Services.Interfaces;

namespace PomodoraBack.Services.Concrete
{
    public class WorkspaceRealtimeService : IWorkspaceRealtimeService
    {
        private readonly IWorkspaceMemberDal _workspaceMemberDal;
        private readonly IHubContext<NotificationHub> _hubContext;

        public WorkspaceRealtimeService(
            IWorkspaceMemberDal workspaceMemberDal,
            IHubContext<NotificationHub> hubContext)
        {
            _workspaceMemberDal = workspaceMemberDal;
            _hubContext = hubContext;
        }

        public async Task SyncConnectionWorkspaceGroupsAsync(string connectionId, string userId)
        {
            var memberships = await _workspaceMemberDal.GetListAsync(m => m.UserId == userId);
            foreach (var membership in memberships)
            {
                var group = NotificationHub.GetWorkspaceGroupName(membership.WorkspaceId);
                await _hubContext.Groups.AddToGroupAsync(connectionId, group);
                Console.WriteLine(
                    $"[WorkspaceRealtime] connection={connectionId} user={userId} joined {group}");
            }
        }

        public async Task BroadcastPomodoroStartedAsync(string workspaceId, PomodoroSessionDto session)
        {
            var group = NotificationHub.GetWorkspaceGroupName(workspaceId);
            await _hubContext.Clients.Group(group).SendAsync("WorkspacePomodoroStarted", session);
            Console.WriteLine(
                $"[WorkspaceRealtime] WorkspacePomodoroStarted -> {group} pomoId={session.PomoId}");
        }

        public async Task BroadcastPomodoroPausedAsync(
            string workspaceId,
            WorkspacePomodoroSyncEventDto payload)
        {
            var group = NotificationHub.GetWorkspaceGroupName(workspaceId);
            await _hubContext.Clients.Group(group)
                .SendAsync("WorkspacePomodoroPaused", payload);
            Console.WriteLine(
                $"[WorkspaceRealtime] WorkspacePomodoroPaused -> {group} pomoId={payload.PomoId}");
        }

        public async Task BroadcastPomodoroResumedAsync(
            string workspaceId,
            WorkspacePomodoroSyncEventDto payload)
        {
            var group = NotificationHub.GetWorkspaceGroupName(workspaceId);
            await _hubContext.Clients.Group(group)
                .SendAsync("WorkspacePomodoroResumed", payload);
            Console.WriteLine(
                $"[WorkspaceRealtime] WorkspacePomodoroResumed -> {group} pomoId={payload.PomoId}");
        }

        public async Task BroadcastPomodoroCancelledAsync(
            string workspaceId,
            WorkspacePomodoroSyncEventDto payload)
        {
            var group = NotificationHub.GetWorkspaceGroupName(workspaceId);
            await _hubContext.Clients.Group(group)
                .SendAsync("WorkspacePomodoroCancelled", payload);
            Console.WriteLine(
                $"[WorkspaceRealtime] WorkspacePomodoroCancelled -> {group} pomoId={payload.PomoId}");
        }

        public async Task BroadcastTaskCreatedAsync(string workspaceId, TaskDto task)
        {
            var group = NotificationHub.GetWorkspaceGroupName(workspaceId);
            await _hubContext.Clients.Group(group).SendAsync("WorkspaceTaskCreated", task);
            Console.WriteLine(
                $"[WorkspaceRealtime] WorkspaceTaskCreated -> {group} taskId={task.TaskId}");
        }

        public async Task NotifyWorkspaceGroupsUpdatedAsync(string userId)
        {
            var userGroup = NotificationHub.GetUserGroupName(userId);
            await _hubContext.Clients.Group(userGroup).SendAsync("WorkspaceGroupsUpdated");
            Console.WriteLine(
                $"[WorkspaceRealtime] WorkspaceGroupsUpdated -> {userGroup}");
        }
    }
}
