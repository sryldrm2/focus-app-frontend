using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Concrete
{
    public class FriendShipDal : EfEntityRepositoryBase<FriendShip, PomodoroContext>, IFriendShipDal
    {
        public FriendShipDal(PomodoroContext context) : base(context)
        {
        }
    }
}
