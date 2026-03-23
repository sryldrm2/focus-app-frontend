using System.Linq.Expressions;
using PomodoraBack.Core.Entities;

namespace PomodoraBack.Core.DataAccess
{
    public interface IEntityRepositoryBase<T> where T : class, IEntity, new()
    {
        Task<T> GetAsync(Expression<Func<T, bool>> filter);
        Task<IList<T>> GetListAsync(Expression<Func<T, bool>> filter = null);
        Task AddAsync(T entity);
        Task UpdateAsync(T entity);
        Task DeleteAsync(T entity);
    }
}
