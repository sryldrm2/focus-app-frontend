using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PomodoraBack.DTOs;
using PomodoraBack.Services.Interfaces;
using System.Security.Claims;

namespace PomodoraBack.Controllers
{
    [ApiController]
    [Route("api/tasks")]
    [Authorize]
    public class TasksController : BaseController
    {
        private readonly IPomodoroTaskService _taskService;

        public TasksController(IPomodoroTaskService taskService)
        {
            _taskService = taskService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _taskService.GetAllAsync(userId);
            return Response(result);
        }

        [HttpGet("{taskId}")]
        public async Task<IActionResult> GetById(string taskId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _taskService.GetByIdAsync(userId, taskId);
            return Response(result);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateTaskDto request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _taskService.Add(userId, request);
            return Response(result);
        }

        [HttpPut("{taskId}")]
        public async Task<IActionResult> Update(string taskId, [FromBody] UpdateTaskDto request)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _taskService.UpdateAsync(userId, taskId, request);
            return Response(result);
        }

        [HttpDelete("{taskId}")]
        public async Task<IActionResult> Delete(string taskId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId))
                return Unauthorized("Kullanıcı kimliği bulunamadı.");

            var result = await _taskService.DeleteAsync(userId, taskId);

            if (!result.Success)
                return BadRequest(new { success = false, message = result.Message });

            return Ok(new { success = true, message = result.Message });
        }
    }
}
