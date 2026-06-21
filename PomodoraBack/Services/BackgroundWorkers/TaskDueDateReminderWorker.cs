using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using PomodoraBack.Core.Enums;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DTOs;
using PomodoraBack.Services.Interfaces;

namespace PomodoraBack.Services.BackgroundWorkers
{
    /// <summary>
    /// Background worker that periodically scans for tasks with approaching due dates
    /// and sends reminder notifications to users.
    /// </summary>
    public class TaskDueDateReminderWorker : BackgroundService
    {
        private readonly IServiceScopeFactory _serviceScopeFactory;
        private readonly ILogger<TaskDueDateReminderWorker> _logger;
        private PeriodicTimer? _timer;
        private const int IntervalMinutes = 5;

        public TaskDueDateReminderWorker(
            IServiceScopeFactory serviceScopeFactory,
            ILogger<TaskDueDateReminderWorker> logger)
        {
            _serviceScopeFactory = serviceScopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("[TaskDueDateReminderWorker] Background service started.");
            
            _timer = new PeriodicTimer(TimeSpan.FromMinutes(IntervalMinutes));

            try
            {
                while (await _timer.WaitForNextTickAsync(stoppingToken))
                {
                    await ProcessTaskRemindersAsync(stoppingToken);
                }
            }
            catch (OperationCanceledException)
            {
                _logger.LogInformation("[TaskDueDateReminderWorker] Background service stopping.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[TaskDueDateReminderWorker] An unexpected error occurred.");
            }
            finally
            {
                _timer?.Dispose();
            }
        }

        private async Task ProcessTaskRemindersAsync(CancellationToken stoppingToken)
        {
            try
            {
                _logger.LogInformation("[TaskDueDateReminderWorker] Processing task reminders at {Time}", DateTime.UtcNow);

                using (var scope = _serviceScopeFactory.CreateScope())
                {
                    var context = scope.ServiceProvider.GetRequiredService<PomodoroContext>();
                    var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

                    // Get tasks with approaching due dates (within 1 hour from now)
                    var now = DateTime.UtcNow;
                    var oneHourLater = now.AddHours(1);

                    var tasksNeedingReminder = await context.Tasks
                        .Where(t =>
                            t.DueDate.HasValue &&
                            t.DueDate.Value > now &&
                            t.DueDate.Value <= oneHourLater &&
                            t.Status != TaskStatusEnums.Completed &&
                            t.Status != TaskStatusEnums.Cancelled &&
                            t.DeletedAt == null)
                        .ToListAsync(stoppingToken);

                    _logger.LogInformation("[TaskDueDateReminderWorker] Found {Count} tasks needing reminders.", tasksNeedingReminder.Count);

                    foreach (var task in tasksNeedingReminder)
                    {
                        // Check if reminder notification already exists for this task
                        var existingReminder = await context.Notifications
                            .AnyAsync(n =>
                                n.UserId == task.UserId &&
                                n.Type == NotificationTypeEnums.DueDateReminder &&
                                n.RelatedEntityId == task.TaskId,
                                stoppingToken);

                        if (existingReminder)
                        {
                            _logger.LogDebug(
                                "[TaskDueDateReminderWorker] Reminder notification already exists for task {TaskId}.",
                                task.TaskId);
                            continue;
                        }

                        // Create notification
                        var createNotificationDto = new CreateNotificationDto
                        {
                            UserId = task.UserId,
                            Type = NotificationTypeEnums.DueDateReminder,
                            Title = "Task Due Soon",
                            Message = $"Your task \"{task.Title}\" is due at {task.DueDate:G}",
                            RelatedEntityId = task.TaskId,
                            MetadataJson = null,
                            TriggerAt = task.DueDate
                        };

                        var result = await notificationService.CreateNotificationAsync(createNotificationDto);

                        if (result.Success)
                        {
                            _logger.LogInformation(
                                "[TaskDueDateReminderWorker] Reminder notification created for task {TaskId} (user: {UserId}).",
                                task.TaskId,
                                task.UserId);
                        }
                        else
                        {
                            _logger.LogWarning(
                                "[TaskDueDateReminderWorker] Failed to create reminder for task {TaskId}: {Message}",
                                task.TaskId,
                                result.Message);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[TaskDueDateReminderWorker] Error processing task reminders.");
            }
        }

        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation("[TaskDueDateReminderWorker] Background service is stopping.");
            _timer?.Dispose();
            await base.StopAsync(cancellationToken);
        }
    }
}
