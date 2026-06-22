using Microsoft.EntityFrameworkCore;
using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Concrete
{
    public class WorkspaceMemberDal : EfEntityRepositoryBase<WorkspaceMember, PomodoroContext>, IWorkspaceMemberDal
    {
        private readonly PomodoroContext _pomodoroContext;

        public WorkspaceMemberDal(PomodoroContext context) : base(context)
        {
            _pomodoroContext = context;
        }

        /// <summary>
        /// Kullanıcının üye olduğu tüm workspace'lerin ID listesini döndürür.
        /// Yalnızca WorkspaceId alanını çeker; JOIN yapmaz.
        /// </summary>
        public async System.Threading.Tasks.Task<List<string>> GetUserWorkspaceIdsAsync(string userId)
        {
            return await _pomodoroContext.WorkspaceMembers
                .Where(m => m.UserId == userId)
                .Select(m => m.WorkspaceId)
                .Distinct()
                .ToListAsync();
        }
    }
}

