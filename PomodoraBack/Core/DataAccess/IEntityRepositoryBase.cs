using System.Linq.Expressions;
using PomodoraBack.Core.Entities;

namespace PomodoraBack.Core.DataAccess
{
    public interface IEntityRepositoryBase<T> where T : class, IEntity, new()
    {
        Task<T> GetAsync(Expression<Func<T, bool>> filter);
        
        /// <summary>
        /// Navigation property'leri yüklemeyi destekleyen GetAsync aşırı yüklemesi
        /// </summary>
        Task<T> GetAsync(
            Expression<Func<T, bool>> filter,
            Func<IQueryable<T>, IQueryable<T>> includeProperties);
        
        Task<IList<T>> GetListAsync(Expression<Func<T, bool>> filter = null);
        
        /// <summary>
        /// Navigation property'leri yüklemeyi destekleyen GetListAsync aşırı yüklemesi
        /// </summary>
        Task<IList<T>> GetListAsync(
            Expression<Func<T, bool>> filter,
            Func<IQueryable<T>, IQueryable<T>> includeProperties);
        
        Task AddAsync(T entity);
        Task UpdateAsync(T entity);
        Task DeleteAsync(T entity);
    }
}
