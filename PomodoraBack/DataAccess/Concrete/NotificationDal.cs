using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Concrete
{
    public class NotificationDal : EfEntityRepositoryBase<Notification, PomodoroContext>, INotificationDal
    {
        public NotificationDal(PomodoroContext context) : base(context)
        {
        }
    }
}
