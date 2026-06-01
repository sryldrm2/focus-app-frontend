using Core.Utilities.Results;
using PomodoraBack.DTOs;
using IResult = Core.Utilities.Results.IResults;

namespace PomodoraBack.Services.Interfaces
{
    public interface IPomodoroTaskService
    {

        Task<IDataResult<TaskDto>> GetByIdAsync(string userId, string taskId);
        Task<IDataResult<TaskDto>> Add(string userId, CreateTaskDto taskDto);
        Task<IDataResult<List<TaskDto>>> GetAllAsync(string userId);
        Task<IDataResult<List<TaskDto>>> GetWorkspaceTasksAsync(string userId, string workspaceId);
        Task<IDataResult<TaskDto>> UpdateAsync(string userId, string taskId, UpdateTaskDto updateTaskDto);
        Task<IDataResult<TaskDto>> AssignTaskToWorkspaceAsync(string userId, string taskId, AssignTaskToWorkspaceDto dto);
        Task<IResult> DeleteAsync(string userId, string taskId);
    }
}
