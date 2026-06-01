using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Concrete
{
    public class WorkspaceDal : EfEntityRepositoryBase<Workspace, PomodoroContext>, IWorkspaceDal
    {
        public WorkspaceDal(PomodoroContext context) : base(context)
        {
        }
    }
}
