using AutoMapper;
using Core.Utilities.Results;
using PomodoraBack.Core.Constants;
using PomodoraBack.Core.Enums;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;
using PomodoraBack.Services.Interfaces;
using IResult = Core.Utilities.Results.IResults;
using Task = System.Threading.Tasks.Task;

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
        private readonly IPomodoroTaskDal _taskDal;
        private readonly IWorkspaceDal _workspaceDal;
        private readonly IWorkspaceMemberDal _workspaceMemberDal;
        private readonly IWorkspaceRealtimeService _workspaceRealtimeService;

        public PomodoroSessionService(
            IPomodoroSessionDal pomodoroSessionDal,
            IUserDal userDal,
            IMapper mapper,
            IPomodoroTaskService taskService,
            IPomodoroTaskDal taskDal,
            IWorkspaceDal workspaceDal,
            IWorkspaceMemberDal workspaceMemberDal,
            IWorkspaceRealtimeService workspaceRealtimeService)
        {
            _pomodoroSessionDal = pomodoroSessionDal;
            _userDal = userDal;
            _mapper = mapper;
            _taskService = taskService;
            _taskDal = taskDal;
            _workspaceDal = workspaceDal;
            _workspaceMemberDal = workspaceMemberDal;
            _workspaceRealtimeService = workspaceRealtimeService;
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

            var workspaceOwnerError =
                await ValidateWorkspaceOwnerCanStartAsync(userId, request.TaskId);
            if (workspaceOwnerError != null)
                return workspaceOwnerError;

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

            if (!string.IsNullOrWhiteSpace(request.TaskId))
            {
                var task = await _taskDal.GetAsync(t =>
                    t.TaskId == request.TaskId && t.DeletedAt == null);

                if (!string.IsNullOrWhiteSpace(task?.WorkspaceId))
                {
                    try
                    {
                        await _workspaceRealtimeService.BroadcastPomodoroStartedAsync(
                            task.WorkspaceId,
                            sessionDto);
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine(
                            $"[PomodoroSessionService] WorkspacePomodoroStarted gönderilemedi: {ex.Message}");
                    }
                }
            }

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

        public async Task<IResult> SyncWorkspacePauseAsync(
            string userId,
            string pomoId,
            int secondsLeft)
        {
            var session = await _pomodoroSessionDal.GetAsync(s => s.PomoId == pomoId);
            if (session == null)
                return new ErrorResult(PomodoroConstants.ERROR_SESSION_NOT_FOUND);

            if (session.Status != SessionStatusEnums.OnGoing)
                return new ErrorResult("Sadece devam eden seanslar duraklatılabilir.");

            var workspaceId = await GetWorkspaceIdForSessionAsync(session);
            if (workspaceId == null)
                return new ErrorResult("Bu seans bir oda görevine bağlı değil.");

            if (!await IsWorkspaceMemberAsync(userId, workspaceId))
                return new ErrorResult("Oda üyesi değilsiniz.");

            if (session.UserId == userId)
            {
                session.BreakCount++;
                session.UpdatedAt = DateTime.UtcNow;
                await _pomodoroSessionDal.UpdateAsync(session);
            }

            await BroadcastWorkspaceSyncAsync(
                workspaceId,
                session,
                secondsLeft,
                _workspaceRealtimeService.BroadcastPomodoroPausedAsync);

            return new SuccessResult("Duraklatma senkronize edildi.");
        }

        public async Task<IResult> SyncWorkspaceResumeAsync(
            string userId,
            string pomoId,
            int secondsLeft)
        {
            var session = await _pomodoroSessionDal.GetAsync(s => s.PomoId == pomoId);
            if (session == null)
                return new ErrorResult(PomodoroConstants.ERROR_SESSION_NOT_FOUND);

            if (session.Status != SessionStatusEnums.OnGoing)
                return new ErrorResult("Sadece devam eden seanslar devam ettirilebilir.");

            var workspaceId = await GetWorkspaceIdForSessionAsync(session);
            if (workspaceId == null)
                return new ErrorResult("Bu seans bir oda görevine bağlı değil.");

            if (!await IsWorkspaceMemberAsync(userId, workspaceId))
                return new ErrorResult("Oda üyesi değilsiniz.");

            await BroadcastWorkspaceSyncAsync(
                workspaceId,
                session,
                secondsLeft,
                _workspaceRealtimeService.BroadcastPomodoroResumedAsync);

            return new SuccessResult("Devam ettirme senkronize edildi.");
        }

        public async Task<IResult> SyncWorkspaceCancelAsync(string userId, string pomoId)
        {
            var session = await _pomodoroSessionDal.GetAsync(s => s.PomoId == pomoId);
            if (session == null)
                return new ErrorResult(PomodoroConstants.ERROR_SESSION_NOT_FOUND);

            if (session.Status != SessionStatusEnums.OnGoing)
                return new ErrorResult("Bu seans zaten tamamlanmış veya iptal edilmiş.");

            var workspaceId = await GetWorkspaceIdForSessionAsync(session);
            if (workspaceId == null)
                return new ErrorResult("Bu seans bir oda görevine bağlı değil.");

            if (!await IsWorkspaceMemberAsync(userId, workspaceId))
                return new ErrorResult("Oda üyesi değilsiniz.");

            session.Status = SessionStatusEnums.Cancelled;
            session.UpdatedAt = DateTime.UtcNow;
            await _pomodoroSessionDal.UpdateAsync(session);

            await BroadcastWorkspaceSyncAsync(
                workspaceId,
                session,
                0,
                _workspaceRealtimeService.BroadcastPomodoroCancelledAsync);

            return new SuccessResult(PomodoroConstants.SUCCESS_SESSION_CANCELLED);
        }

        private async Task<ErrorDataResult<PomodoroSessionDto>?> ValidateWorkspaceOwnerCanStartAsync(
            string userId,
            string? taskId)
        {
            if (string.IsNullOrWhiteSpace(taskId))
                return null;

            var task = await _taskDal.GetAsync(t =>
                t.TaskId == taskId && t.DeletedAt == null);
            if (task == null)
                return new ErrorDataResult<PomodoroSessionDto>("Görev bulunamadı.");

            if (string.IsNullOrWhiteSpace(task.WorkspaceId))
                return null;

            var workspace = await _workspaceDal.GetAsync(w =>
                w.WorkspaceId == task.WorkspaceId);
            if (workspace == null)
                return new ErrorDataResult<PomodoroSessionDto>("Oda bulunamadı.");

            if (workspace.OwnerId != userId)
                return new ErrorDataResult<PomodoroSessionDto>(
                    "Oda pomodoro'sunu yalnızca oda sahibi başlatabilir.");

            return null;
        }

        private async Task<string?> GetWorkspaceIdForSessionAsync(PomodoroSession session)
        {
            if (string.IsNullOrWhiteSpace(session.TaskId))
                return null;

            var task = await _taskDal.GetAsync(t =>
                t.TaskId == session.TaskId && t.DeletedAt == null);

            return string.IsNullOrWhiteSpace(task?.WorkspaceId) ? null : task.WorkspaceId;
        }

        private async Task<bool> IsWorkspaceMemberAsync(string userId, string workspaceId)
        {
            var membership = await _workspaceMemberDal.GetAsync(m =>
                m.WorkspaceId == workspaceId && m.UserId == userId);

            return membership != null;
        }

        private async Task BroadcastWorkspaceSyncAsync(
            string workspaceId,
            PomodoroSession session,
            int secondsLeft,
            Func<string, WorkspacePomodoroSyncEventDto, Task> broadcast)
        {
            var payload = new WorkspacePomodoroSyncEventDto
            {
                PomoId = session.PomoId,
                TaskId = session.TaskId,
                SecondsLeft = secondsLeft,
            };

            try
            {
                await broadcast(workspaceId, payload);
            }
            catch (Exception ex)
            {
                Console.WriteLine(
                    $"[PomodoroSessionService] Workspace pomodoro sync gönderilemedi: {ex.Message}");
            }
        }
    }
}
