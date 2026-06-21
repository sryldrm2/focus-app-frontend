using AutoMapper;
using Core.Utilities.Results;
using Microsoft.Extensions.Logging;
using PomodoraBack.Core.Constants;
using PomodoraBack.Core.Enums;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;
using PomodoraBack.Services.Interfaces;
using IResult = Core.Utilities.Results.IResults;

namespace PomodoraBack.Services.Concrete
{
    /// <summary>
    /// Pomodoro Session iş mantığı implementasyonu
    /// </summary>
    public class PomodoroSessionService : IPomodoroSessionService
    {
        private readonly IPomodoroSessionDal _pomodoroSessionDal;
        private readonly IUserDal _userDal;
        private readonly IMapper _mapper;
        private readonly IPomodoroTaskService _taskService;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<PomodoroSessionService> _logger;

        public PomodoroSessionService(
            IPomodoroSessionDal pomodoroSessionDal,
            IUserDal userDal,
            IMapper mapper,
            IPomodoroTaskService taskService,
            IServiceScopeFactory scopeFactory,
            ILogger<PomodoroSessionService> logger)
        {
            _pomodoroSessionDal = pomodoroSessionDal;
            _userDal = userDal;
            _mapper = mapper;
            _taskService = taskService;
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        /// <summary>
        /// Yeni bir Pomodoro seansı başlatır
        /// </summary>
        public async Task<IDataResult<PomodoroSessionDto>> StartSessionAsync(
            string userId, 
            CreatePomodoroSessionDto request)
        {
            // 1. Kullanıcı kontrol et
            var user = await _userDal.GetAsync(u => u.UserId == userId);
            if (user == null)
                return new ErrorDataResult<PomodoroSessionDto>(
                    PomodoroConstants.ERROR_USER_NOT_FOUND);

            // 2. Devam eden seans var mı kontrol et
            var ongoingSession = await _pomodoroSessionDal.GetOngoingSessionAsync(userId);
            if (ongoingSession != null)
                return new ErrorDataResult<PomodoroSessionDto>(
                    PomodoroConstants.ERROR_SESSION_ALREADY_ONGOING);

            // 3. Seans süresi kontrol et
            if (request.DurationMinute < PomodoroConstants.MIN_CUSTOM_DURATION || 
                request.DurationMinute > PomodoroConstants.MAX_CUSTOM_DURATION)
                return new ErrorDataResult<PomodoroSessionDto>(
                    PomodoroConstants.ERROR_INVALID_DURATION);

            // 4. Yeni seans oluştur
            var session = new PomodoroSession
            {
                PomoId = Guid.NewGuid().ToString(),
                UserId = userId,
                TaskId = request.TaskId,
                SessionType = request.SessionType,
                DurationMinute = request.DurationMinute,
                Notes = request.Notes,
                StartedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                Status = SessionStatusEnums.OnGoing,
                PointsEarned = 0,
                BreakCount = 0
            };

            await _pomodoroSessionDal.AddAsync(session);

            var sessionDto = _mapper.Map<PomodoroSessionDto>(session);

            // Arkadaşlara anlık "odaklanmaya başladı" bildirimi gönder.
            // Ana akışı bloke etmemek için fire-and-forget pattern kullanılır.
            // IServiceScopeFactory ile kendi bağımsız scope'unu açar;
            // HTTP scope dispose edilse bile background task güvenle çalışır.
            var capturedScopeFactory = _scopeFactory;
            var capturedLogger = _logger;
            var capturedUserId = userId;
            var capturedUserName = user.Name;
            var capturedSessionId = session.PomoId;
            var capturedTaskId = session.TaskId;

            _ = System.Threading.Tasks.Task.Run(async () =>
            {
                await using var scope = capturedScopeFactory.CreateAsyncScope();
                var friendShipDal = scope.ServiceProvider.GetRequiredService<IFriendShipDal>();
                var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

                await DispatchFocusStartedNotificationsAsync(
                    capturedUserId,
                    capturedUserName,
                    capturedSessionId,
                    capturedTaskId,
                    friendShipDal,
                    notificationService,
                    capturedLogger);
            });

            return new SuccessDataResult<PomodoroSessionDto>(
                sessionDto, 
                PomodoroConstants.SUCCESS_SESSION_STARTED);
        }

        /// <summary>
        /// Devam eden seansı tamamlar (başarılı)
        /// </summary>
        public async Task<IDataResult<PomodoroSessionDto>> CompleteSessionAsync(string pomoId)
        {
            // 1. Seans bul
            var session = await _pomodoroSessionDal.GetAsync(s => s.PomoId == pomoId);
            if (session == null)
                return new ErrorDataResult<PomodoroSessionDto>(
                    PomodoroConstants.ERROR_SESSION_NOT_FOUND);

            // 2. Seans durumu kontrol et (OnGoing olmalı)
            if (session.Status != SessionStatusEnums.OnGoing)
                return new ErrorDataResult<PomodoroSessionDto>(
                    "Bu seans zaten tamamlanmış veya iptal edilmiş.");

            // 3. Puan hesapla (her 1 dakika = 1 puan)
            int points = PomodoroConstants.CalculatePoints(
                session.DurationMinute, 
                session.SessionType);

            // 4. Seansı güncelle
            session.Status = SessionStatusEnums.Successful;
            session.CompletedAt = DateTime.UtcNow;
            session.UpdatedAt = DateTime.UtcNow;
            session.PointsEarned = points;

            // 5. Kullanıcının toplam puanını güncelle
            var user = await _userDal.GetAsync(u => u.UserId == session.UserId);
            if (user != null)
            {
                user.TotalPoints += points;
                await _userDal.UpdateAsync(user);
            }

            // 6. Seansı kaydet
            await _pomodoroSessionDal.UpdateAsync(session);

            // 7. İlişkili bir görev varsa Pomodoro sayacını artır
            //    (Yalnızca WorkSession tipindeki seanslar görev sayacını etkiler)
            if (!string.IsNullOrWhiteSpace(session.TaskId) &&
                session.SessionType == PomodoroTypeEnums.WorkSession)
            {
                await _taskService.IncrementPomodoroCountAsync(session.TaskId);
            }

            var sessionDto = _mapper.Map<PomodoroSessionDto>(session);
            return new SuccessDataResult<PomodoroSessionDto>(
                sessionDto, 
                $"{points} puan kazandınız! {PomodoroConstants.SUCCESS_SESSION_COMPLETED}");
        }

        /// <summary>
        /// Devam eden seansı iptal eder
        /// </summary>
        public async Task<IDataResult<PomodoroSessionDto>> CancelSessionAsync(string pomoId)
        {
            // 1. Seans bul
            var session = await _pomodoroSessionDal.GetAsync(s => s.PomoId == pomoId);
            if (session == null)
                return new ErrorDataResult<PomodoroSessionDto>(
                    PomodoroConstants.ERROR_SESSION_NOT_FOUND);

            // 2. Seans durumu kontrol et (OnGoing olmalı)
            if (session.Status != SessionStatusEnums.OnGoing)
                return new ErrorDataResult<PomodoroSessionDto>(
                    "Bu seans zaten tamamlanmış veya iptal edilmiş.");

            // 3. Seansı iptal et
            session.Status = SessionStatusEnums.Cancelled;
            session.UpdatedAt = DateTime.UtcNow;

            await _pomodoroSessionDal.UpdateAsync(session);

            var sessionDto = _mapper.Map<PomodoroSessionDto>(session);
            return new SuccessDataResult<PomodoroSessionDto>(
                sessionDto, 
                PomodoroConstants.SUCCESS_SESSION_CANCELLED);
        }

        /// <summary>
        /// Kullanıcının devam eden seansını getirir
        /// </summary>
        public async Task<IDataResult<PomodoroSessionDto>> GetOngoingSessionAsync(string userId)
        {
            var session = await _pomodoroSessionDal.GetOngoingSessionAsync(userId);
            if (session == null)
                return new ErrorDataResult<PomodoroSessionDto>("Devam eden seans yok.");

            var sessionDto = _mapper.Map<PomodoroSessionDto>(session);
            return new SuccessDataResult<PomodoroSessionDto>(sessionDto);
        }

        /// <summary>
        /// Kullanıcının tamamlanan tüm seanslarını getirir
        /// </summary>
        public async Task<IDataResult<List<PomodoroSessionDto>>> GetUserCompletedSessionsAsync(string userId)
        {
            var sessions = await _pomodoroSessionDal.GetUserCompletedSessionsAsync(userId);
            var sessionDtos = _mapper.Map<List<PomodoroSessionDto>>(sessions);
            return new SuccessDataResult<List<PomodoroSessionDto>>(sessionDtos);
        }

        /// <summary>
        /// Kullanıcının belirli bir tarih aralığındaki seanslarını getirir
        /// </summary>
        public async Task<IDataResult<List<PomodoroSessionDto>>> GetUserSessionsByDateRangeAsync(
            string userId,
            DateTime startDate,
            DateTime endDate)
        {
            // Tarih aralığını normalize et
            var normalizedStartDate = startDate.Date;
            var normalizedEndDate = endDate.Date.AddDays(1).AddTicks(-1);

            var sessions = await _pomodoroSessionDal.GetUserSessionsByDateRangeAsync(
                userId, 
                normalizedStartDate, 
                normalizedEndDate);

            var sessionDtos = _mapper.Map<List<PomodoroSessionDto>>(sessions);
            return new SuccessDataResult<List<PomodoroSessionDto>>(sessionDtos);
        }

        /// <summary>
        /// Kullanıcının toplam puanını hesaplar
        /// </summary>
        public async Task<IDataResult<int>> GetUserTotalPointsAsync(string userId)
        {
            var user = await _userDal.GetAsync(u => u.UserId == userId);
            if (user == null)
                return new ErrorDataResult<int>(PomodoroConstants.ERROR_USER_NOT_FOUND);

            // User entity'deki TotalPoints'i döndür (zaten veritabanında hesaplanmış)
            return new SuccessDataResult<int>((int)user.TotalPoints);
        }

        /// <summary>
        /// Belirli bir görevle ilişkili tamamlanan seansları getirir
        /// </summary>
        public async Task<IDataResult<List<PomodoroSessionDto>>> GetTaskSessionsAsync(string taskId)
        {
            var sessions = await _pomodoroSessionDal.GetTaskCompletedSessionsAsync(taskId);
            var sessionDtos = _mapper.Map<List<PomodoroSessionDto>>(sessions);
            return new SuccessDataResult<List<PomodoroSessionDto>>(sessionDtos);
        }

        /// <summary>
        /// Belirli bir görev için yapılan seans sayısını getirir
        /// </summary>
        public async Task<IDataResult<int>> GetTaskSessionCountAsync(string taskId)
        {
            var count = await _pomodoroSessionDal.GetTaskCompletedSessionCountAsync(taskId);
            return new SuccessDataResult<int>(count);
        }

        /// <summary>
        /// Seansın ara verilme sayısını artırır
        /// </summary>
        public async Task<IDataResult<PomodoroSessionDto>> IncrementBreakCountAsync(string pomoId)
        {
            // 1. Seans bul
            var session = await _pomodoroSessionDal.GetAsync(s => s.PomoId == pomoId);
            if (session == null)
                return new ErrorDataResult<PomodoroSessionDto>(
                    PomodoroConstants.ERROR_SESSION_NOT_FOUND);

            // 2. Devam eden seans mi kontrol et
            if (session.Status != SessionStatusEnums.OnGoing)
                return new ErrorDataResult<PomodoroSessionDto>(
                    "Sadece devam eden seanslar için ara verilebilir.");

            // 3. Break count'ı artır
            session.BreakCount++;
            session.UpdatedAt = DateTime.UtcNow;

            await _pomodoroSessionDal.UpdateAsync(session);

            var sessionDto = _mapper.Map<PomodoroSessionDto>(session);
            return new SuccessDataResult<PomodoroSessionDto>(
                sessionDto, 
                $"Ara verildi. Toplam ara: {session.BreakCount}");
        }
        /// <summary>
        /// Kullanıcının onaylanmış tüm arkadaşlarına FriendStartedFocus tipinde
        /// anlık SignalR bildirimi gönderir. DB'ye kayıt yapılmaz.
        /// Her arkadaş için ayrı try-catch ile izole çalışır; birinin hatası
        /// diğerlerinin bildirimini engellemez.
        /// </summary>
        /// <summary>
        /// Kullanıcının onaylanmış tüm arkadaşlarına FriendStartedFocus tipinde
        /// anlık SignalR bildirimi gönderir. DB'ye kayıt yapılmaz.
        /// Her arkadaş için ayrı try-catch ile izole çalışır; birinin hatası
        /// diğerlerinin bildirimini engellemez.
        /// Scope dışarıdan enjekte edilir; bu metod kendi bağımsız DI scope'unda çalışır.
        /// </summary>
        private static async System.Threading.Tasks.Task DispatchFocusStartedNotificationsAsync(
            string userId,
            string userName,
            string sessionId,
            string? taskId,
            IFriendShipDal friendShipDal,
            INotificationService notificationService,
            ILogger<PomodoroSessionService> logger)
        {
            try
            {
                logger.LogInformation(
                    "[FocusNotification] {UserId} için arkadaş bildirimleri başlatıldı. SessionId={SessionId}",
                    userId, sessionId);

                var friendIds = await friendShipDal.GetApprovedFriendIdsAsync(userId);

                if (friendIds == null || friendIds.Count == 0)
                {
                    logger.LogInformation(
                        "[FocusNotification] {UserId} için onaylı arkadaş bulunamadı; bildirim gönderilmedi.",
                        userId);
                    return;
                }

                var notificationDto = new NotificationDto
                {
                    // NotificationId: ephemeral bildirim olduğu için DB primary key
                    // gerekmez; referans amaçlı geçici bir GUID atıyoruz.
                    NotificationId  = Guid.NewGuid().ToString(),
                    UserId          = userId,
                    Type            = NotificationTypeEnums.FriendStartedFocus,
                    Title           = "Arkadaşın odaklanmaya başladı! 🍅",
                    Message         = $"{userName} odaklanmaya başladı, sen de ona katıl!",
                    IsRead          = false,
                    CreatedAt       = DateTime.UtcNow,
                    // RelatedEntityId: önce sessionId, yoksa taskId kullan
                    RelatedEntityId = !string.IsNullOrWhiteSpace(sessionId) ? sessionId : taskId
                };

                foreach (var friendId in friendIds)
                {
                    try
                    {
                        await notificationService.SendRealTimeNotificationAsync(friendId, notificationDto);

                        logger.LogInformation(
                            "[FocusNotification] {UserId} → {FriendId} bildirimi gönderildi.",
                            userId, friendId);
                    }
                    catch (Exception ex)
                    {
                        // Tek bir arkadaşa gönderim başarısız olsa bile diğerleri etkilenmez.
                        logger.LogWarning(
                            ex,
                            "[FocusNotification] {UserId} → {FriendId} bildirimi gönderilemedi.",
                            userId, friendId);
                    }
                }

                logger.LogInformation(
                    "[FocusNotification] {UserId} seansı için {Count} arkadaşa bildirim gönderildi.",
                    userId, friendIds.Count);
            }
            catch (Exception ex)
            {
                // Arkadaş listesi çekilemezse veya genel bir hata oluşursa
                // sadece loglayıp susturuyoruz; ana seans başlatma akışı etkilenmez.
                logger.LogError(
                    ex,
                    "[FocusNotification] {UserId} için bildirim dağıtımında beklenmeyen hata. SessionId={SessionId}",
                    userId, sessionId);
            }
        }
    }
}
