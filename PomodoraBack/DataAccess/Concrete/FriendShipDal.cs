using Microsoft.EntityFrameworkCore;
using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Concrete
{
    public class FriendShipDal : EfEntityRepositoryBase<FriendShip, PomodoroContext>, IFriendShipDal
    {
        private readonly PomodoroContext _pomodoroContext;

        public FriendShipDal(PomodoroContext context) : base(context)
        {
            _pomodoroContext = context;
        }

        /// <summary>
        /// Kullanıcının kendisini ve tüm onaylanmış arkadaşlarını
        /// TotalPoints'e göre desc sıralanmış şekilde döndürür.
        /// FriendShip tablosunda durum ayrı tutulmaz; kayıt varsa ve
        /// DeletedAt == null ise arkadaşlık aktif demektir.
        /// </summary>
        public async Task<List<FriendLeaderboardDto>> GetFriendLeaderboardAsync(string currentUserId)
        {
            // 1. Aktif arkadaşlıklardaki karşı tarafların ID'lerini topla
            //    (FirstUserId veya SecondUserId olabilir)
            var friendIds = await _pomodoroContext.Friendships
                .Where(f => f.DeletedAt == null &&
                            (f.FirstUserId == currentUserId || f.SecondUserId == currentUserId))
                .Select(f => f.FirstUserId == currentUserId ? f.SecondUserId : f.FirstUserId)
                .ToListAsync();

            // 2. Gruba mevcut kullanıcıyı da ekle
            var groupIds = friendIds.Append(currentUserId).Distinct().ToList();

            // 3. Bu ID'lere sahip, silinmemiş kullanıcıları getir ve puana göre sırala
            var leaderboard = await _pomodoroContext.Users
                .Where(u => groupIds.Contains(u.UserId) && u.DeletedAt == null)
                .OrderByDescending(u => u.TotalPoints)
                .Select(u => new FriendLeaderboardDto
                {
                    Rank         = 0, // Service katmanında atanacak
                    UserId       = u.UserId,
                    FullName     = u.Name + " " + u.Surname,
                    Nickname     = u.Nickname,
                    TotalPoints  = (int)u.TotalPoints,
                    IsCurrentUser = u.UserId == currentUserId
                })
                .ToListAsync();

            return leaderboard;
        }

        /// <summary>
        /// Kullanıcının onaylanmış (soft-delete edilmemiş) tüm arkadaşlarının
        /// UserId listesini döndürür. Yalnızca ID alanını çeker, JOIN yapmaz.
        /// </summary>
        public async Task<List<string>> GetApprovedFriendIdsAsync(string userId)
        {
            return await _pomodoroContext.Friendships
                .Where(f => f.DeletedAt == null &&
                            (f.FirstUserId == userId || f.SecondUserId == userId))
                .Select(f => f.FirstUserId == userId ? f.SecondUserId : f.FirstUserId)
                .Distinct()
                .ToListAsync();
        }
    }
}
