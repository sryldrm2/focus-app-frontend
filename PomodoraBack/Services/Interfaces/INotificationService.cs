using Core.Utilities.Results;
using PomodoraBack.Core.Enums;
using PomodoraBack.DTOs;

namespace PomodoraBack.Services.Interfaces
{
    public interface INotificationService
    {
        Task<IDataResult<NotificationDto>> CreateNotificationAsync(CreateNotificationDto request);
        Task<IDataResult<List<NotificationDto>>> GetUserNotificationsAsync(
            string userId,
            bool? isRead = null,
            NotificationTypeEnums? type = null);
        Task<IDataResult<NotificationDto>> MarkAsReadAsync(string userId, string notificationId);
        Task<IDataResult<int>> MarkAllAsReadAsync(string userId);
        Task<IDataResult<int>> GetUnreadCountAsync(string userId);
    }
}
