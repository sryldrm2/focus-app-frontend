using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Concrete
{
    public class UserDal : EfEntityRepositoryBase<User, PomodoroContext>, IUserDal
    {
        public UserDal(PomodoroContext context) : base(context)
        {
        }
    }
}
