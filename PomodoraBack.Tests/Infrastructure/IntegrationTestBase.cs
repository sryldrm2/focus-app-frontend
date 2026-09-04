using AutoMapper;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Moq;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Concrete;
using PomodoraBack.Entities;
using PomodoraBack.Core.Enums;
using PomodoraBack.Hubs;

namespace PomodoraBack.Tests.Infrastructure;

/// <summary>
/// EF Core InMemory veritabanı kullanan integration testleri için paylaşılan temel altyapı.
/// Her test kendi izole veritabanı instance'ını alır (paralel çalışma güvenliği).
/// </summary>
public abstract class IntegrationTestBase : IDisposable
{
    protected readonly PomodoroContext DbContext;
    protected readonly IMapper Mapper;
    protected readonly Mock<IHubContext<NotificationHub>> HubContextMock;

    protected IntegrationTestBase()
    {
        // Her test için benzersiz isimli InMemory DB → testler birbirini etkilemez
        var options = new DbContextOptionsBuilder<PomodoroContext>()
            .UseInMemoryDatabase(databaseName: $"TestDb_{Guid.NewGuid()}")
            .Options;

        DbContext = new PomodoroContext(options);

        // AutoMapper: ana projedeki tum profiller taranir
        var mapperConfig = new MapperConfiguration(cfg =>
            cfg.AddMaps(typeof(PomodoraBack.Mappings.UsersMappingProfile).Assembly));
        Mapper = mapperConfig.CreateMapper();

        // SignalR HubContext mock — integration testlerinde gerçek SignalR gerekmiyor
        HubContextMock = new Mock<IHubContext<NotificationHub>>();
        var mockClients     = new Mock<IHubClients>();
        var mockClientProxy = new Mock<IClientProxy>();
        mockClients.Setup(c => c.Group(It.IsAny<string>())).Returns(mockClientProxy.Object);
        HubContextMock.Setup(h => h.Clients).Returns(mockClients.Object);
    }

    // ─── Seed Yardımcıları ─────────────────────────────────────────────────

    protected User CreateUser(string? id = null, string name = "Test", string surname = "Kullanici")
    {
        var user = new User
        {
            UserId   = id ?? Guid.NewGuid().ToString(),
            Name     = name,
            Surname  = surname,
            Nickname = ("nick_" + Guid.NewGuid().ToString("N")).Substring(0, 15),
            Email    = Guid.NewGuid().ToString("N") + "@test.com",
            Password = "hashedpw"
        };
        DbContext.Users.Add(user);
        DbContext.SaveChanges();
        return user;
    }

    protected PomodoraBack.Entities.Task CreateTask(
        string userId, string? workspaceId = null, string title = "Test Gorevi")
    {
        var task = new PomodoraBack.Entities.Task
        {
            TaskId      = Guid.NewGuid().ToString(),
            UserId      = userId,
            WorkspaceId = workspaceId,
            Title       = title,
            Status      = TaskStatusEnums.NotStarted,
            CreatedAt   = DateTime.UtcNow
        };
        DbContext.Tasks.Add(task);
        DbContext.SaveChanges();
        return task;
    }

    protected Workspace CreateWorkspace(string ownerId, string name = "Test Odasi")
    {
        var ws = new Workspace
        {
            WorkspaceId   = Guid.NewGuid().ToString(),
            OwnerId       = ownerId,
            WorkspaceName = name,
            CreatedAt     = DateTime.UtcNow,
            isActive      = true
        };
        DbContext.Workspaces.Add(ws);

        DbContext.WorkspaceMembers.Add(new WorkspaceMember
        {
            WorkspaceId = ws.WorkspaceId,
            UserId      = ownerId,
            JoinedAt    = DateTime.UtcNow
        });

        DbContext.SaveChanges();
        return ws;
    }

    protected Notification CreateNotification(string userId, NotificationTypeEnums type)
    {
        var notif = new Notification
        {
            NotificationId = Guid.NewGuid().ToString(),
            UserId         = userId,
            Type           = type,
            Title          = "Test bildirimi",
            Message        = "Test mesaji",
            IsRead         = false,
            CreatedAt      = DateTime.UtcNow
        };
        DbContext.Notifications.Add(notif);
        DbContext.SaveChanges();
        return notif;
    }

    public void Dispose() => DbContext.Dispose();
}
