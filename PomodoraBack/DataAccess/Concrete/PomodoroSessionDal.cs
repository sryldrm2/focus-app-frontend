using Microsoft.EntityFrameworkCore;
using PomodoraBack.Core.DataAccess;
using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Entities;
using PomodoraBack.Core.Enums;

namespace PomodoraBack.DataAccess.Concrete
{
    /// <summary>
    /// Pomodoro Session veritabanı işlemleri implementasyonu
    /// </summary>
    public class PomodoroSessionDal : EfEntityRepositoryBase<PomodoroSession, PomodoroContext>, IPomodoroSessionDal
    {
        public PomodoroSessionDal(PomodoroContext context) : base(context)
        {
        }

        /// <summary>
        /// Kullanıcının tamamlanan seanslarını getirir (başarıyla tamamlananlar)
        /// </summary>
        public async Task<List<PomodoroSession>> GetUserCompletedSessionsAsync(string userId)
        {
            return await _context.PomodoroSessions
                .Where(s => s.UserId == userId && s.Status == SessionStatusEnums.Successful)
                .Include(s => s.Task)
                .Include(s => s.User)
                .OrderByDescending(s => s.CompletedAt)
                .ToListAsync();
        }

        /// <summary>
        /// Kullanıcının devam eden seansını getirir (sadece 1 tane olabilir)
        /// </summary>
        public async Task<PomodoroSession> GetOngoingSessionAsync(string userId)
        {
            return await _context.PomodoroSessions
                .FirstOrDefaultAsync(s => s.UserId == userId && s.Status == SessionStatusEnums.OnGoing);
        }

        /// <summary>
        /// Belirli bir görevle ilişkili tamamlanan seansları getirir
        /// </summary>
        public async Task<List<PomodoroSession>> GetTaskCompletedSessionsAsync(string taskId)
        {
            return await _context.PomodoroSessions
                .Where(s => s.TaskId == taskId && s.Status == SessionStatusEnums.Successful)
                .OrderByDescending(s => s.CompletedAt)
                .ToListAsync();
        }

        /// <summary>
        /// Kullanıcının toplam kazandığı puanı hesaplar (tamamlanan seanslar)
        /// </summary>
        public async Task<int> GetUserTotalPointsAsync(string userId)
        {
            var totalPoints = await _context.PomodoroSessions
                .Where(s => s.UserId == userId && s.Status == SessionStatusEnums.Successful)
                .SumAsync(s => s.PointsEarned);
            
            return totalPoints;
        }

        /// <summary>
        /// Kullanıcının belirli bir tarih aralığındaki seanslarını getirir
        /// </summary>
        public async Task<List<PomodoroSession>> GetUserSessionsByDateRangeAsync(
            string userId, 
            DateTime startDate, 
            DateTime endDate)
        {
            return await _context.PomodoroSessions
                .Where(s => s.UserId == userId 
                    && s.CreatedAt >= startDate 
                    && s.CreatedAt <= endDate
                    && s.Status == SessionStatusEnums.Successful)
                .Include(s => s.Task)
                .OrderByDescending(s => s.CompletedAt)
                .ToListAsync();
        }

        /// <summary>
        /// Belirli bir görev için yapılan tamamlanan seans sayısını getirir
        /// </summary>
        public async Task<int> GetTaskCompletedSessionCountAsync(string taskId)
        {
            return await _context.PomodoroSessions
                .CountAsync(s => s.TaskId == taskId && s.Status == SessionStatusEnums.Successful);
        }
    }
}
