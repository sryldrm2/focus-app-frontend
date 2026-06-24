using Core.Utilities.Results;
using PomodoraBack.DTOs;
using IResult = Core.Utilities.Results.IResults;

namespace PomodoraBack.Services.Interfaces
{
    /// <summary>
    /// Pomodoro Session iş mantığı için interface
    /// </summary>
    public interface IPomodoroSessionService
    {
        /// <summary>
        /// Yeni bir Pomodoro seansı başlatır
        /// </summary>
        /// <param name="userId">Kullanıcı ID'si</param>
        /// <param name="request">Seans bilgileri</param>
        /// <returns>Oluşturulan seans</returns>
        Task<IDataResult<PomodoroSessionDto>> StartSessionAsync(
            string userId, 
            CreatePomodoroSessionDto request);

        /// <summary>
        /// Devam eden seansı tamamlar (başarılı)
        /// </summary>
        /// <param name="pomoId">Seans ID'si</param>
        /// <returns>Tamamlanan seans</returns>
        Task<IDataResult<PomodoroSessionDto>> CompleteSessionAsync(string pomoId);

        /// <summary>
        /// Devam eden seansı iptal eder (incomplete/incomplete olarak işaretler)
        /// </summary>
        /// <param name="pomoId">Seans ID'si</param>
        /// <returns>İptal edilen seans</returns>
        Task<IDataResult<PomodoroSessionDto>> CancelSessionAsync(string pomoId);

        /// <summary>
        /// Kullanıcının devam eden seansını getirir
        /// </summary>
        /// <param name="userId">Kullanıcı ID'si</param>
        /// <returns>Devam eden seans (null ise seans yok)</returns>
        Task<IDataResult<PomodoroSessionDto>> GetOngoingSessionAsync(string userId);

        /// <summary>
        /// Kullanıcının tamamlanan tüm seanslarını getirir
        /// </summary>
        /// <param name="userId">Kullanıcı ID'si</param>
        /// <returns>Tamamlanan seanslar listesi</returns>
        Task<IDataResult<List<PomodoroSessionDto>>> GetUserCompletedSessionsAsync(string userId);

        /// <summary>
        /// Kullanıcının belirli bir tarih aralığındaki seanslarını getirir
        /// </summary>
        /// <param name="userId">Kullanıcı ID'si</param>
        /// <param name="startDate">Başlangıç tarihi</param>
        /// <param name="endDate">Bitiş tarihi</param>
        /// <returns>Tarih aralığında seanslar</returns>
        Task<IDataResult<List<PomodoroSessionDto>>> GetUserSessionsByDateRangeAsync(
            string userId,
            DateTime startDate,
            DateTime endDate);

        /// <summary>
        /// Kullanıcının toplam puanını hesaplar
        /// </summary>
        /// <param name="userId">Kullanıcı ID'si</param>
        /// <returns>Toplam puan</returns>
        Task<IDataResult<int>> GetUserTotalPointsAsync(string userId);

        /// <summary>
        /// Belirli bir görevle ilişkili tamamlanan seansları getirir
        /// </summary>
        /// <param name="taskId">Görev ID'si</param>
        /// <returns>Görevle ilişkili seanslar</returns>
        Task<IDataResult<List<PomodoroSessionDto>>> GetTaskSessionsAsync(string taskId);

        /// <summary>
        /// Belirli bir görev için yapılan seans sayısını getirir
        /// </summary>
        /// <param name="taskId">Görev ID'si</param>
        /// <returns>Seans sayısı</returns>
        Task<IDataResult<int>> GetTaskSessionCountAsync(string taskId);

        /// <summary>
        /// Seansın ara verilme sayısını artırır
        /// </summary>
        /// <param name="pomoId">Seans ID'si</param>
        /// <returns>Güncellenen seans</returns>
        Task<IDataResult<PomodoroSessionDto>> IncrementBreakCountAsync(string pomoId);

        /// <summary>
        /// Oda pomodoro duraklatmayı odadaki tüm üyelere senkronize eder.
        /// </summary>
        Task<IResult> SyncWorkspacePauseAsync(string userId, string pomoId, int secondsLeft);

        /// <summary>
        /// Oda pomodoro devam ettirmeyi odadaki tüm üyelere senkronize eder.
        /// </summary>
        Task<IResult> SyncWorkspaceResumeAsync(string userId, string pomoId, int secondsLeft);

        /// <summary>
        /// Oda pomodoro iptalini odadaki tüm üyelere senkronize eder.
        /// </summary>
        Task<IResult> SyncWorkspaceCancelAsync(string userId, string pomoId);
    }
}
