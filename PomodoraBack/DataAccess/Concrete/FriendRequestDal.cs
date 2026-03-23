using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Concrete
{
    public class FriendRequestDal : EfEntityRepositoryBase<FriendRequest, PomodoroContext>, IFriendRequestDal
    {
        public FriendRequestDal(PomodoroContext context) : base(context)
        {
        }
    }
}
