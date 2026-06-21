using AutoMapper;
using Core.Utilities.Results;
using Microsoft.AspNetCore.SignalR;
using PomodoraBack.Core.Enums;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;
using PomodoraBack.Hubs;
using PomodoraBack.Services.Interfaces;

namespace PomodoraBack.Services.Concrete
{
    public class NotificationService : INotificationService
    {
        private readonly INotificationDal _notificationDal;
        private readonly IUserDal _userDal;
        private readonly IMapper _mapper;
        private readonly IHubContext<NotificationHub> _hubContext;

        public NotificationService(
            INotificationDal notificationDal,
            IUserDal userDal,
            IMapper mapper,
            IHubContext<NotificationHub> hubContext)
        {
            _notificationDal = notificationDal;
            _userDal = userDal;
            _mapper = mapper;
            _hubContext = hubContext;
        }

        public async Task<IDataResult<NotificationDto>> CreateNotificationAsync(CreateNotificationDto request)
        {
            var user = await _userDal.GetAsync(u => u.UserId == request.UserId);
            if (user == null)
                return new ErrorDataResult<NotificationDto>("Kullanıcı bulunamadı.");

            var notification = new Notification
            {
                NotificationId = Guid.NewGuid().ToString(),
                UserId = request.UserId,
                Type = request.Type,
                Title = request.Title,
                Message = request.Message,
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                RelatedEntityId = request.RelatedEntityId,
                MetadataJson = request.MetadataJson,
                TriggerAt = request.TriggerAt
            };

            await _notificationDal.AddAsync(notification);

            var dto = _mapper.Map<NotificationDto>(notification);

            // Bildirim başarıyla kaydedildikten sonra, eğer kullanıcı online ise SignalR üzerinden gönder
            try
            {
                var userGroup = NotificationHub.GetUserGroupName(request.UserId);
                await _hubContext.Clients.Group(userGroup).SendAsync("ReceiveNotification", dto);
            }
            catch (Exception ex)
            {
                // SignalR hatası oluşsa bile bildirim database'e kaydedilmiş olduğu için
                // hata loglanabilir ancak başarısız response dönmeyiz
                Console.WriteLine($"[NotificationService] SignalR gönderimi hatası: {ex.Message}");
            }

            return new SuccessDataResult<NotificationDto>(dto, "Bildirim oluşturuldu.");
        }

        public async Task<IDataResult<List<NotificationDto>>> GetUserNotificationsAsync(
            string userId,
            bool? isRead = null,
            NotificationTypeEnums? type = null)
        {
            var notifications = await _notificationDal.GetListAsync(
                n => n.UserId == userId
                     && (!isRead.HasValue || n.IsRead == isRead.Value)
                     && (!type.HasValue || n.Type == type.Value),
                q => q.OrderByDescending(x => x.CreatedAt));

            if (notifications == null || !notifications.Any())
                return new SuccessDataResult<List<NotificationDto>>(new List<NotificationDto>(), "Bildirim bulunamadı.");

            var dtos = _mapper.Map<List<NotificationDto>>(notifications);
            return new SuccessDataResult<List<NotificationDto>>(dtos);
        }

        public async Task<IDataResult<NotificationDto>> MarkAsReadAsync(string userId, string notificationId)
        {
            var notification = await _notificationDal.GetAsync(n =>
                n.NotificationId == notificationId && n.UserId == userId);

            if (notification == null)
                return new ErrorDataResult<NotificationDto>("Bildirim bulunamadı.");

            if (!notification.IsRead)
            {
                notification.IsRead = true;
                notification.ReadAt = DateTime.UtcNow;
                await _notificationDal.UpdateAsync(notification);
            }

            var dto = _mapper.Map<NotificationDto>(notification);
            return new SuccessDataResult<NotificationDto>(dto, "Bildirim okundu olarak işaretlendi.");
        }

        public async Task<IDataResult<int>> MarkAllAsReadAsync(string userId)
        {
            var unreadNotifications = await _notificationDal.GetListAsync(n =>
                n.UserId == userId && !n.IsRead);

            if (unreadNotifications == null || unreadNotifications.Count == 0)
                return new SuccessDataResult<int>(0, "Okunmamış bildirim bulunamadı.");

            foreach (var notification in unreadNotifications)
            {
                notification.IsRead = true;
                notification.ReadAt = DateTime.UtcNow;
                await _notificationDal.UpdateAsync(notification);
            }

            return new SuccessDataResult<int>(unreadNotifications.Count, "Tüm bildirimler okundu olarak işaretlendi.");
        }

        public async Task<IDataResult<int>> GetUnreadCountAsync(string userId)
        {
            var unreadNotifications = await _notificationDal.GetListAsync(n =>
                n.UserId == userId && !n.IsRead);

            return new SuccessDataResult<int>(unreadNotifications.Count);
        }
    }
}
