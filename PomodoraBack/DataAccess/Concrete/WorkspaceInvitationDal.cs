using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Concrete
{
    public class WorkspaceInvitationDal : EfEntityRepositoryBase<WorkspaceInvitation, PomodoroContext>, IWorkspaceInvitationDal
    {
        public WorkspaceInvitationDal(PomodoroContext context) : base(context)
        {
        }
    }
}
