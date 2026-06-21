using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PomodoraBack.Core.Enums;
using PomodoraBack.DTOs;
using PomodoraBack.Services.Interfaces;
using System.Security.Claims;

namespace PomodoraBack.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationsController : BaseController
    {
        private readonly INotificationService _notificationService;

        public NotificationsController(INotificationService notificationService)
        {
            _notificationService = notificationService;
        }

        /// <summary>
        /// Yeni bildirim oluştur (Sistem/Servis tarafından kullanılır)
        /// </summary>
        [HttpPost]
        [AllowAnonymous]  // Internal services tarafından çağrılacağı için
        public async Task<IActionResult> CreateNotification([FromBody] CreateNotificationDto request)
        {
            var result = await _notificationService.CreateNotificationAsync(request);
            return Response(result);
        }

        /// <summary>
        /// Giriş yapan kullanıcının tüm bildirimlerini getir
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetMyNotifications([FromQuery] bool? isRead, [FromQuery] int? type)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            NotificationTypeEnums? typeFilter = null;
            if (type.HasValue && Enum.IsDefined(typeof(NotificationTypeEnums), type.Value))
            {
                typeFilter = (NotificationTypeEnums)type.Value;
            }

            var result = await _notificationService.GetUserNotificationsAsync(userId, isRead, typeFilter);
            return Response(result);
        }

        /// <summary>
        /// Belirli bir bildirimi okundu olarak işaretle
        /// </summary>
        [HttpPut("{notificationId}/read")]
        public async Task<IActionResult> MarkAsRead(string notificationId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _notificationService.MarkAsReadAsync(userId, notificationId);
            return Response(result);
        }

        /// <summary>
        /// Tüm bildirimleri okundu olarak işaretle
        /// </summary>
        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _notificationService.MarkAllAsReadAsync(userId);
            return Response(result);
        }

        /// <summary>
        /// Okunmamış bildirim sayısını getir
        /// </summary>
        [HttpGet("unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _notificationService.GetUnreadCountAsync(userId);
            return Response(result);
        }
    }
}
