using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using PomodoraBack.Services.Interfaces;
using PomodoraBack.DTOs;
using System.Security.Claims;

namespace PomodoraBack.Controllers
{
    
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class PomodoroSessionController : BaseController
    {
        private readonly IPomodoroSessionService _pomodoroSessionService;

        public PomodoroSessionController(IPomodoroSessionService pomodoroSessionService)
        {
            _pomodoroSessionService = pomodoroSessionService;
        }

        /// <summary>
        /// Yeni bir Pomodoro seansı başlatır
        /// </summary>
        /// <param name="request">Seans bilgileri</param>
        /// <returns>Oluşturulan seans</returns>
        [HttpPost("start")]
        public async Task<IActionResult> StartSession([FromBody] CreatePomodoroSessionDto request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _pomodoroSessionService.StartSessionAsync(userId, request);
            
            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }

        /// <summary>
        /// Devam eden seansı başarıyla tamamlar
        /// </summary>
        /// <param name="pomoId">Seans ID'si</param>
        /// <returns>Tamamlanan seans</returns>
        [HttpPost("{pomoId}/complete")]
        public async Task<IActionResult> CompleteSession(string pomoId)
        {
            var result = await _pomodoroSessionService.CompleteSessionAsync(pomoId);
            
            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }

        /// <summary>
        /// Devam eden seansı iptal eder
        /// </summary>
        /// <param name="pomoId">Seans ID'si</param>
        /// <returns>İptal edilen seans</returns>
        [HttpPost("{pomoId}/cancel")]
        public async Task<IActionResult> CancelSession(string pomoId)
        {
            var result = await _pomodoroSessionService.CancelSessionAsync(pomoId);
            
            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }

        /// <summary>
        /// Kullanıcının devam eden seansını getirir
        /// </summary>
        /// <returns>Devam eden seans (varsa)</returns>
        [HttpGet("ongoing")]
        public async Task<IActionResult> GetOngoingSession()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _pomodoroSessionService.GetOngoingSessionAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Kullanıcının tamamlanan tüm seanslarını getirir
        /// </summary>
        /// <returns>Tamamlanan seanslar listesi</returns>
        [HttpGet("completed")]
        public async Task<IActionResult> GetCompletedSessions()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _pomodoroSessionService.GetUserCompletedSessionsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Kullanıcının belirli bir tarih aralığındaki seanslarını getirir
        /// </summary>
        /// <param name="startDate">Başlangıç tarihi (yyyy-MM-dd)</param>
        /// <param name="endDate">Bitiş tarihi (yyyy-MM-dd)</param>
        /// <returns>Tarih aralığında seanslar</returns>
        [HttpGet("date-range")]
        public async Task<IActionResult> GetSessionsByDateRange(
            [FromQuery] DateTime startDate, 
            [FromQuery] DateTime endDate)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            if (startDate > endDate)
                return BadRequest("Başlangıç tarihi, bitiş tarihinden sonra olamaz.");

            var result = await _pomodoroSessionService.GetUserSessionsByDateRangeAsync(
                userId, 
                startDate, 
                endDate);

            return Ok(result);
        }

        /// <summary>
        /// Kullanıcının toplam puanını getirir
        /// </summary>
        /// <returns>Toplam puan</returns>
        [HttpGet("total-points")]
        public async Task<IActionResult> GetTotalPoints()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _pomodoroSessionService.GetUserTotalPointsAsync(userId);
            return Ok(result);
        }

        /// <summary>
        /// Belirli bir görevle ilişkili seansları getirir
        /// </summary>
        /// <param name="taskId">Görev ID'si</param>
        /// <returns>Görevle ilişkili seanslar</returns>
        [HttpGet("task/{taskId}")]
        public async Task<IActionResult> GetTaskSessions(string taskId)
        {
            var result = await _pomodoroSessionService.GetTaskSessionsAsync(taskId);
            return Ok(result);
        }

        /// <summary>
        /// Belirli bir görev için yapılan seans sayısını getirir
        /// </summary>
        /// <param name="taskId">Görev ID'si</param>
        /// <returns>Seans sayısı</returns>
        [HttpGet("task/{taskId}/count")]
        public async Task<IActionResult> GetTaskSessionCount(string taskId)
        {
            var result = await _pomodoroSessionService.GetTaskSessionCountAsync(taskId);
            return Ok(result);
        }

        /// <summary>
        /// Seansın ara verilme sayısını artırır (pause tuşu)
        /// </summary>
        /// <param name="pomoId">Seans ID'si</param>
        /// <returns>Güncellenmiş seans</returns>
        [HttpPost("{pomoId}/break")]
        public async Task<IActionResult> IncrementBreakCount(string pomoId)
        {
            var result = await _pomodoroSessionService.IncrementBreakCountAsync(pomoId);
            
            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }

        /// <summary>
        /// Oda pomodoro duraklatmayı tüm oda üyelerine senkronize eder.
        /// </summary>
        [HttpPost("{pomoId}/workspace-pause")]
        public async Task<IActionResult> SyncWorkspacePause(
            string pomoId,
            [FromBody] WorkspacePomodoroSyncDto request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _pomodoroSessionService.SyncWorkspacePauseAsync(
                userId,
                pomoId,
                request.SecondsLeft);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }

        /// <summary>
        /// Oda pomodoro devam ettirmeyi tüm oda üyelerine senkronize eder.
        /// </summary>
        [HttpPost("{pomoId}/workspace-resume")]
        public async Task<IActionResult> SyncWorkspaceResume(
            string pomoId,
            [FromBody] WorkspacePomodoroSyncDto request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _pomodoroSessionService.SyncWorkspaceResumeAsync(
                userId,
                pomoId,
                request.SecondsLeft);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }

        /// <summary>
        /// Oda pomodoro iptalini tüm oda üyelerine senkronize eder.
        /// </summary>
        [HttpPost("{pomoId}/workspace-cancel")]
        public async Task<IActionResult> SyncWorkspaceCancel(string pomoId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _pomodoroSessionService.SyncWorkspaceCancelAsync(userId, pomoId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
    }
}
