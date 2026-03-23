using PomodoraBack.Core.DataAccess.EntityFramework;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Concrete
{
    public class RefreshTokenDal : EfEntityRepositoryBase<RefreshToken, PomodoroContext>, IRefreshTokenDal
    {
        public RefreshTokenDal(PomodoroContext context) : base(context)
        {
        }
    }
}
