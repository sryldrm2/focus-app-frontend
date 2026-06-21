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

        /// <summary>
        /// Bildirimi veritabanına kaydetmeden, yalnızca SignalR üzerinden
        /// belirtilen kullanıcıya anlık olarak iletir. FriendStartedFocus gibi
        /// geçici/ephemeral bildirimler için kullanılır.
        /// </summary>
        /// <param name="targetUserId">Bildirimi alacak kullanıcının ID'si</param>
        /// <param name="notification">Gönderilecek bildirim DTO'su</param>
        Task SendRealTimeNotificationAsync(string targetUserId, NotificationDto notification);
    }
}
