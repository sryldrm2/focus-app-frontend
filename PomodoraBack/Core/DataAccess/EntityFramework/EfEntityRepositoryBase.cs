using PomodoraBack.Core.Entities;
using Microsoft.EntityFrameworkCore;
using System.Linq.Expressions;

namespace PomodoraBack.Core.DataAccess.EntityFramework
{
    public class EfEntityRepositoryBase<TEntity, TContext> : IEntityRepositoryBase<TEntity>
        where TEntity : class, IEntity, new()
        where TContext : DbContext
    {
        protected readonly TContext _context;

        public EfEntityRepositoryBase(TContext context)
        {
            _context = context;
        }

        public async Task AddAsync(TEntity entity)
        {
            var addedEntity = _context.Entry(entity);
            addedEntity.State = EntityState.Added;
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(TEntity entity)
        {
            var deletedEntity = _context.Entry(entity);
            deletedEntity.State = EntityState.Deleted;
            await _context.SaveChangesAsync();
        }

        public async Task<TEntity> GetAsync(Expression<Func<TEntity, bool>> filter)
        {
            return await _context.Set<TEntity>().SingleOrDefaultAsync(filter);
        }

        /// <summary>
        /// Navigation property'leri de yüklemeyi destekleyen GetAsync aşırı yüklemesi
        /// </summary>
        public async Task<TEntity> GetAsync(
            Expression<Func<TEntity, bool>> filter,
            Func<IQueryable<TEntity>, IQueryable<TEntity>> includeProperties = null)
        {
            IQueryable<TEntity> query = _context.Set<TEntity>();

            if (includeProperties != null)
                query = includeProperties(query);

            return await query.SingleOrDefaultAsync(filter);
        }

        public async Task<IList<TEntity>> GetListAsync(Expression<Func<TEntity, bool>> filter = null)
        {
            return filter == null
                ? await _context.Set<TEntity>().ToListAsync()
                : await _context.Set<TEntity>().Where(filter).ToListAsync();
        }

        /// <summary>
        /// Navigation property'leri de yüklemeyi destekleyen GetListAsync aşırı yüklemesi
        /// </summary>
        public async Task<IList<TEntity>> GetListAsync(
            Expression<Func<TEntity, bool>> filter,
            Func<IQueryable<TEntity>, IQueryable<TEntity>> includeProperties)
        {
            IQueryable<TEntity> query = _context.Set<TEntity>();

            if (includeProperties != null)
                query = includeProperties(query);

            if (filter != null)
                query = query.Where(filter);

            return await query.ToListAsync();
        }

        public async Task UpdateAsync(TEntity entity)
        {
            var updatedEntity = _context.Entry(entity);
            updatedEntity.State = EntityState.Modified;
            await _context.SaveChangesAsync();
        }
    }
}
