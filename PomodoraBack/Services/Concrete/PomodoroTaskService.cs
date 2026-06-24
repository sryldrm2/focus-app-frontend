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
        private readonly IWorkspaceDal _workspaceDal;
        private readonly IWorkspaceMemberDal _workspaceMemberDal;
        private readonly IMapper _mapper;
        private readonly IWorkspaceRealtimeService _workspaceRealtimeService;

        public PomodoroTaskService(
            IPomodoroTaskDal taskDal,
            IUserDal userDal,
            IWorkspaceDal workspaceDal,
            IWorkspaceMemberDal workspaceMemberDal,
            IMapper mapper,
            IWorkspaceRealtimeService workspaceRealtimeService)
        {
            _taskDal = taskDal;
            _userDal = userDal;
            _workspaceDal = workspaceDal;
            _workspaceMemberDal = workspaceMemberDal;
            _mapper = mapper;
            _workspaceRealtimeService = workspaceRealtimeService;
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

            if (!string.IsNullOrWhiteSpace(taskDto.WorkspaceId))
            {
                var workspace = await _workspaceDal.GetAsync(w => w.WorkspaceId == taskDto.WorkspaceId);
                if (workspace == null)
                    return new ErrorDataResult<TaskDto>("Oda bulunamadı.");

                var membership = await _workspaceMemberDal.GetAsync(m =>
                    m.WorkspaceId == taskDto.WorkspaceId && m.UserId == userId);

                if (membership == null)
                    return new ErrorDataResult<TaskDto>("Oda görevi oluşturmak için odanın üyesi olmalısınız.");
            }

            var task = _mapper.Map<TaskEntity>(taskDto);
            task.TaskId = Guid.NewGuid().ToString();
            task.UserId = userId;
            task.CreatedAt = DateTime.Now;
            task.UpdatedAt = null;
            task.DeletedAt = null;

            // Non-nullable entity fields safety
            task.Description = taskDto.Description ?? string.Empty;
            task.WorkspaceId = taskDto.WorkspaceId;

            await _taskDal.AddAsync(task);

            var createdDto = _mapper.Map<TaskDto>(task);

            if (!string.IsNullOrWhiteSpace(taskDto.WorkspaceId))
            {
                try
                {
                    await _workspaceRealtimeService.BroadcastTaskCreatedAsync(
                        taskDto.WorkspaceId,
                        createdDto);
                }
                catch (Exception ex)
                {
                    Console.WriteLine(
                        $"[PomodoroTaskService] WorkspaceTaskCreated gönderilemedi: {ex.Message}");
                }
            }

            return new SuccessDataResult<TaskDto>(createdDto, "Görev oluşturuldu.");
        }

        public async Task<IDataResult<List<TaskDto>>> GetAllAsync(string userId)
        {
            var tasks = await _taskDal.GetListAsync(t =>
                t.UserId == userId && t.DeletedAt == null && t.WorkspaceId == null);

            var taskDtos = _mapper.Map<List<TaskDto>>(tasks);
            return new SuccessDataResult<List<TaskDto>>(taskDtos);
        }

        public async Task<IDataResult<List<TaskDto>>> GetWorkspaceTasksAsync(string userId, string workspaceId)
        {
            var membership = await _workspaceMemberDal.GetAsync(m =>
                m.WorkspaceId == workspaceId && m.UserId == userId);

            if (membership == null)
                return new ErrorDataResult<List<TaskDto>>("Oda görevlerini görmek için odanın üyesi olmalısınız.");

            var tasks = await _taskDal.GetListAsync(t =>
                t.WorkspaceId == workspaceId && t.DeletedAt == null);

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

            if (!string.IsNullOrWhiteSpace(updateTaskDto.WorkspaceId))
            {
                var workspace = await _workspaceDal.GetAsync(w => w.WorkspaceId == updateTaskDto.WorkspaceId);
                if (workspace == null)
                    return new ErrorDataResult<TaskDto>("Oda bulunamadı.");

                var membership = await _workspaceMemberDal.GetAsync(m =>
                    m.WorkspaceId == updateTaskDto.WorkspaceId && m.UserId == userId);

                if (membership == null)
                    return new ErrorDataResult<TaskDto>("Odaya görev taşımak için odanın üyesi olmalısınız.");
            }

            _mapper.Map(updateTaskDto, task);
            task.UpdatedAt = DateTime.Now;

            // Make sure description isn't null after mapping
            task.Description ??= string.Empty;
            task.Title ??= string.Empty;

            await _taskDal.UpdateAsync(task);

            var updatedDto = _mapper.Map<TaskDto>(task);
            return new SuccessDataResult<TaskDto>(updatedDto, "Görev güncellendi.");
        }

        public async Task<IDataResult<TaskDto>> AssignTaskToWorkspaceAsync(string userId, string taskId, AssignTaskToWorkspaceDto dto)
        {
            // Task'ın mevcut kullanıcıya ait olduğunu kontrol et
            var task = await _taskDal.GetAsync(t =>
                t.TaskId == taskId &&
                t.UserId == userId &&
                t.DeletedAt == null);

            if (task == null)
                return new ErrorDataResult<TaskDto>("Görev bulunamadı veya bu göreve erişim yetkiniz yok.");

            // Workspace var mı?
            var workspace = await _workspaceDal.GetAsync(w => w.WorkspaceId == dto.WorkspaceId);
            if (workspace == null)
                return new ErrorDataResult<TaskDto>("Oda bulunamadı.");

            // Kullanıcı o workspace'in üyesi mi?
            var membership = await _workspaceMemberDal.GetAsync(m =>
                m.WorkspaceId == dto.WorkspaceId && m.UserId == userId);

            if (membership == null)
                return new ErrorDataResult<TaskDto>("Görevi odaya aktarmak için odanın üyesi olmalısınız.");

            // Task zaten bu workspace'e mi ait?
            if (task.WorkspaceId == dto.WorkspaceId)
                return new ErrorDataResult<TaskDto>("Görev zaten bu odaya ait.");

            // WorkspaceId güncelle → kişiselden ortak alana taşı
            task.WorkspaceId = dto.WorkspaceId;
            task.UpdatedAt = DateTime.UtcNow;

            await _taskDal.UpdateAsync(task);

            var updatedDto = _mapper.Map<TaskDto>(task);
            return new SuccessDataResult<TaskDto>(updatedDto, "Görev odaya aktarıldı.");
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

        /// <summary>
        /// Bir Pomodoro oturumu başarıyla tamamlandığında çağrılır.
        /// İlgili görevin CompletedPomodoroCount değerini 1 artırır.
        /// Hedef sayıya (PomodoroTargetCount) ulaşıldıysa görevi otomatik olarak Completed yapar.
        /// </summary>
        public async Task<IDataResult<TaskDto>> IncrementPomodoroCountAsync(string taskId)
        {
            // 1. Görevi bul (silinmemiş ve tamamlanmamış)
            var task = await _taskDal.GetAsync(t =>
                t.TaskId == taskId &&
                t.DeletedAt == null);

            if (task == null)
                return new ErrorDataResult<TaskDto>("Görev bulunamadı.");

            // 2. Zaten tamamlanmış veya iptal edilmişse sayacı artırma
            if (task.Status == TaskStatusEnums.Completed || task.Status == TaskStatusEnums.Cancelled)
                return new ErrorDataResult<TaskDto>(
                    $"Bu görev zaten '{task.Status}' durumunda. Pomodoro sayacı artırılamaz.");

            // 3. CompletedPomodoroCount'u 1 artır (null-safe)
            task.CompletedPomodoroCount = (task.CompletedPomodoroCount ?? 0) + 1;
            task.UpdatedAt = DateTime.UtcNow;

            // 4. Eğer görev InProgress değilse, artık InProgress yap
            if (task.Status == TaskStatusEnums.NotStarted || task.Status == TaskStatusEnums.OnHold)
                task.Status = TaskStatusEnums.InProgress;

            // 5. Hedef sayıya ulaşıldıysa görevi otomatik tamamla
            if (task.PomodoroTargetCount.HasValue &&
                task.CompletedPomodoroCount >= task.PomodoroTargetCount)
            {
                task.Status = TaskStatusEnums.Completed;
            }

            await _taskDal.UpdateAsync(task);

            var updatedDto = _mapper.Map<TaskDto>(task);
            
            var message = task.Status == TaskStatusEnums.Completed
                ? $"Tebrikler! Görev tamamlandı. ({task.CompletedPomodoroCount}/{task.PomodoroTargetCount} Pomodoro)"
                : $"Pomodoro sayacı artırıldı. ({task.CompletedPomodoroCount}" +
                  $"{(task.PomodoroTargetCount.HasValue ? $"/{task.PomodoroTargetCount}" : string.Empty)} Pomodoro)";

            return new SuccessDataResult<TaskDto>(updatedDto, message);
        }
    }
}
