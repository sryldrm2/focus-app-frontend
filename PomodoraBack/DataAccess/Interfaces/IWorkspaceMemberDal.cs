using PomodoraBack.Core.DataAccess;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Interfaces
{
    public interface IWorkspaceMemberDal : IEntityRepositoryBase<WorkspaceMember>
    {
        /// <summary>
        /// Kullanıcının üye olduğu tüm workspace'lerin ID listesini döndürür.
        /// SignalR grup yönetimi gibi hafif sorgular için yalnızca ID alanını çeker.
        /// </summary>
        /// <param name="userId">Kullanıcı ID'si</param>
        System.Threading.Tasks.Task<List<string>> GetUserWorkspaceIdsAsync(string userId);
    }
}
