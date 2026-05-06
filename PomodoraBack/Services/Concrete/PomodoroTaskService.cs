using AutoMapper;
using Core.Utilities.Results;
using PomodoraBack.Core.Enums;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.DTOs;
using PomodoraBack.Services.Interfaces;
using IResult = Core.Utilities.Results.IResults;
using TaskEntity = PomodoraBack.Entities.Task;

namespace PomodoraBack.Services.Concrete
{
    public class PomodoroTaskService : IPomodoroTaskService
    {
        private readonly IPomodoroTaskDal _taskDal;
        private readonly IUserDal _userDal;
        private readonly IMapper _mapper;

        public PomodoroTaskService(IPomodoroTaskDal taskDal, IUserDal userDal, IMapper mapper)
        {
            _taskDal = taskDal;
            _userDal = userDal;
            _mapper = mapper;
        }

        public async Task<IDataResult<TaskDto>> GetByIdAsync(string userId, string taskId)
        {
            var task = await _taskDal.GetAsync(t =>
                t.TaskId == taskId &&
                t.UserId == userId &&
                t.DeletedAt == null);

            if (task == null)
                return new ErrorDataResult<TaskDto>("Görev bulunamadı.");

            var taskDto = _mapper.Map<TaskDto>(task);
            return new SuccessDataResult<TaskDto>(taskDto);
        }

        public async Task<IDataResult<TaskDto>> Add(string userId, CreateTaskDto taskDto)
        {
            var user = await _userDal.GetAsync(u => u.UserId == userId);
            if (user == null)
                return new ErrorDataResult<TaskDto>("Kullanıcı bulunamadı.");

            var task = _mapper.Map<TaskEntity>(taskDto);
            task.TaskId = Guid.NewGuid().ToString();
            task.UserId = userId;
            task.CreatedAt = DateTime.Now;
            task.UpdatedAt = null;
            task.DeletedAt = null;

            // Non-nullable entity fields safety
            task.Description = taskDto.Description ?? string.Empty;

            await _taskDal.AddAsync(task);

            var createdDto = _mapper.Map<TaskDto>(task);
            return new SuccessDataResult<TaskDto>(createdDto, "Görev oluşturuldu.");
        }

        public async Task<IDataResult<List<TaskDto>>> GetAllAsync(string userId)
        {
            var tasks = await _taskDal.GetListAsync(t => t.UserId == userId && t.DeletedAt == null);

            var taskDtos = _mapper.Map<List<TaskDto>>(tasks);
            return new SuccessDataResult<List<TaskDto>>(taskDtos);
        }

        public async Task<IDataResult<TaskDto>> UpdateAsync(string userId, string taskId, UpdateTaskDto updateTaskDto)
        {
            var task = await _taskDal.GetAsync(t =>
                t.TaskId == taskId &&
                t.UserId == userId &&
                t.DeletedAt == null);

            if (task == null)
                return new ErrorDataResult<TaskDto>("Görev bulunamadı.");

            _mapper.Map(updateTaskDto, task);
            task.UpdatedAt = DateTime.Now;

            // Make sure description isn't null after mapping
            task.Description ??= string.Empty;
            task.Title ??= string.Empty;

            await _taskDal.UpdateAsync(task);

            var updatedDto = _mapper.Map<TaskDto>(task);
            return new SuccessDataResult<TaskDto>(updatedDto, "Görev güncellendi.");
        }

        public async Task<IResult> DeleteAsync(string userId, string taskId)
        {
            var task = await _taskDal.GetAsync(t =>
                t.TaskId == taskId &&
                t.UserId == userId &&
                t.DeletedAt == null);

            if (task == null)
                return new ErrorResult("Görev bulunamadı.");

            task.DeletedAt = DateTime.UtcNow;
            task.UpdatedAt = DateTime.UtcNow;

            await _taskDal.UpdateAsync(task);
            return new SuccessResult("Görev silindi.");
        }
    }
}
