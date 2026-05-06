using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Entities;
using Task = PomodoraBack.Entities.Task;

namespace PomodoraBack.DataAccess.Concrete
{
    public class PomodoroTaskDal: EfEntityRepositoryBase<Task, PomodoroContext>, IPomodoroTaskDal
    {
        public PomodoroTaskDal(PomodoroContext context) : base(context)
        {
        }
    }
}
