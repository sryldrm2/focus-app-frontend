using PomodoraBack.DTOs;

namespace PomodoraBack.Services.Interfaces
{
    public interface IWorkspaceRealtimeService
    {
        Task SyncConnectionWorkspaceGroupsAsync(string connectionId, string userId);
        Task BroadcastPomodoroStartedAsync(string workspaceId, PomodoroSessionDto session);
        Task BroadcastPomodoroPausedAsync(
            string workspaceId,
            WorkspacePomodoroSyncEventDto payload);
        Task BroadcastPomodoroResumedAsync(
            string workspaceId,
            WorkspacePomodoroSyncEventDto payload);
        Task BroadcastPomodoroCancelledAsync(
            string workspaceId,
            WorkspacePomodoroSyncEventDto payload);
        Task BroadcastTaskCreatedAsync(string workspaceId, TaskDto task);
        Task NotifyWorkspaceGroupsUpdatedAsync(string userId);
    }
}
