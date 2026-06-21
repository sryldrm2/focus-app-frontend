using PomodoraBack.Core.DataAccess;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Interfaces
{
    public interface IFriendShipDal : IEntityRepositoryBase<FriendShip>
    {
        /// <summary>
        /// Kullanıcının kendisini ve onaylanmış (silinmemiş) arkadaşlarını
        /// TotalPoints'e göre büyükten küçüğe sıralı şekilde döndürür.
        /// Friendships + Users tablolarını JOIN'ler.
        /// </summary>
        /// <param name="currentUserId">Giriş yapan kullanıcının ID'si</param>
        /// <returns>Sıralanmış kullanıcı listesi (Rank henüz atanmamış)</returns>
        Task<List<FriendLeaderboardDto>> GetFriendLeaderboardAsync(string currentUserId);
    }
}
