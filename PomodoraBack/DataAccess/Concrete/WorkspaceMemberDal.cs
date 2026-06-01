using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Concrete
{
    public class WorkspaceMemberDal : EfEntityRepositoryBase<WorkspaceMember, PomodoroContext>, IWorkspaceMemberDal
    {
        public WorkspaceMemberDal(PomodoroContext context) : base(context)
        {
        }
    }
}
