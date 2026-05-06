using PomodoraBack.Core.DataAccess;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Interfaces
{
    /// <summary>
    /// Pomodoro Session veritabanı işlemleri için interface
    /// </summary>
    public interface IPomodoroSessionDal : IEntityRepositoryBase<PomodoroSession>
    {
        /// <summary>
        /// Kullanıcının belirli bir kullanıcının tamamlanan seanslarını getirir
        /// </summary>
        Task<List<PomodoroSession>> GetUserCompletedSessionsAsync(string userId);

        /// <summary>
        /// Kullanıcının devam eden (OnGoing) seansını getirir
        /// </summary>
        Task<PomodoroSession> GetOngoingSessionAsync(string userId);

        /// <summary>
        /// Belirli bir görevle ilişkili tamamlanan seansları getirir
        /// </summary>
        Task<List<PomodoroSession>> GetTaskCompletedSessionsAsync(string taskId);

        /// <summary>
        /// Kullanıcının toplam kazandığı puanı hesaplar
        /// </summary>
        Task<int> GetUserTotalPointsAsync(string userId);

        /// <summary>
        /// Kullanıcının belirli bir tarih aralığındaki seanslarını getirir
        /// </summary>
        Task<List<PomodoroSession>> GetUserSessionsByDateRangeAsync(
            string userId, 
            DateTime startDate, 
            DateTime endDate);

        /// <summary>
        /// Belirli bir görev için yapılan tamamlanan seans sayısını getirir
        /// </summary>
        Task<int> GetTaskCompletedSessionCountAsync(string taskId);
    }
}
