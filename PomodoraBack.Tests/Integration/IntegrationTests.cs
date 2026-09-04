using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using PomodoraBack.Core.Enums;
using PomodoraBack.DataAccess.Concrete;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;
using PomodoraBack.Hubs;
using PomodoraBack.Services.Concrete;
using PomodoraBack.Tests.Infrastructure;

namespace PomodoraBack.Tests.Integration;

/// <summary>
/// Integration testleri — EF Core InMemory veritabanı kullanır.
/// Gerçek DbContext, gerçek DAL, gerçek servis katmanı; yalnızca SignalR mock'lanır.
/// Veritabanı bağlantısı, veri kalıcılığı ve iş kuralı akışları uçtan uca test edilir.
/// </summary>
public class IntegrationTests : IntegrationTestBase
{
    // ═══════════════════════════════════════════════════════════════════════
    // GRUP 1: DAL Katmanı — Veri Erişim ve Kalıcılık
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>
    /// TEST 1: UserDal — Veritabanına kaydedilen kullanıcı geri okunabilmeli
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task UserDal_AddAndRetrieve_PersistsCorrectly()
    {
        var dal  = new UserDal(DbContext);
        var user = new User
        {
            UserId   = "int-user-001",
            Name     = "Entegrasyon",
            Surname  = "Kullanıcısı",
            Nickname = "entegrasyon_u",
            Email    = "entegrasyon@test.com",
            Password = "hashed"
        };

        await dal.AddAsync(user);
        var fetched = await dal.GetAsync(u => u.UserId == "int-user-001");

        Assert.NotNull(fetched);
        Assert.Equal("Entegrasyon",   fetched!.Name);
        Assert.Equal("Kullanıcısı",   fetched.Surname);
        Assert.Equal("entegrasyon@test.com", fetched.Email);
    }

    /// <summary>
    /// TEST 2: UserDal — Silinmiş kullanıcı (soft-delete) sorgulanabilmeli
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task UserDal_SoftDelete_UserStillExistsInDb()
    {
        var user = CreateUser(name: "Silinecek", surname: "Kullanıcı");
        var dal  = new UserDal(DbContext);

        user.DeletedAt = DateTime.UtcNow;
        await dal.UpdateAsync(user);

        // Silinen kullanıcı DB'de hâlâ var
        var inDb    = await dal.GetAsync(u => u.UserId == user.UserId);
        // Ama aktif filtreli sorguda gelmemeli
        var active  = await dal.GetAsync(u => u.UserId == user.UserId && u.DeletedAt == null);

        Assert.NotNull(inDb);
        Assert.NotNull(inDb!.DeletedAt);   // Silinme tarihi atanmış
        Assert.Null(active);               // Aktif sorguda görünmüyor
    }

    /// <summary>
    /// TEST 3: FriendShipDal — GetApprovedFriendIdsAsync doğru arkadaş ID'lerini döndürmeli
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task FriendShipDal_GetApprovedFriendIds_ReturnsCorrectIds()
    {
        var userA  = CreateUser(name: "Ali");
        var userB  = CreateUser(name: "Veli");
        var userC  = CreateUser(name: "Ayşe");

        // A-B arkadaş (aktif)
        DbContext.Friendships.Add(new FriendShip
        {
            FriendShipId  = Guid.NewGuid().ToString(),
            FirstUserId   = userA.UserId,
            SecondUserId  = userB.UserId,
            DeletedAt     = null
        });
        // A-C eski arkadaş (silinmiş)
        DbContext.Friendships.Add(new FriendShip
        {
            FriendShipId  = Guid.NewGuid().ToString(),
            FirstUserId   = userA.UserId,
            SecondUserId  = userC.UserId,
            DeletedAt     = DateTime.UtcNow.AddDays(-1)
        });
        await DbContext.SaveChangesAsync();

        var dal    = new FriendShipDal(DbContext);
        var result = await dal.GetApprovedFriendIdsAsync(userA.UserId);

        Assert.Single(result);
        Assert.Contains(userB.UserId, result);
        Assert.DoesNotContain(userC.UserId, result); // Silinmiş arkadaş gelmemeli
    }

    /// <summary>
    /// TEST 4: FriendShipDal — GetFriendLeaderboardAsync sıralı liste döndürmeli
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task FriendShipDal_GetFriendLeaderboard_ReturnsSortedByPoints()
    {
        var userA = CreateUser(name: "Ali");
        var userB = CreateUser(name: "Veli");

        userA.TotalPoints = 150;
        userB.TotalPoints = 300;
        await DbContext.SaveChangesAsync();

        DbContext.Friendships.Add(new FriendShip
        {
            FriendShipId  = Guid.NewGuid().ToString(),
            FirstUserId   = userA.UserId,
            SecondUserId  = userB.UserId,
            DeletedAt     = null
        });
        await DbContext.SaveChangesAsync();

        var dal    = new FriendShipDal(DbContext);
        var result = await dal.GetFriendLeaderboardAsync(userA.UserId);

        Assert.Equal(2, result.Count);
        Assert.Equal(userB.UserId, result[0].UserId);  // Yüksek puan → ilk sıra
        Assert.Equal(userA.UserId, result[1].UserId);
    }

    /// <summary>
    /// TEST 5: WorkspaceMemberDal — GetUserWorkspaceIdsAsync üye olunan odaları döndürmeli
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task WorkspaceMemberDal_GetUserWorkspaceIds_ReturnsAllMemberWorkspaces()
    {
        var user = CreateUser();
        var ws1  = CreateWorkspace(user.UserId, "Oda 1");
        var ws2  = CreateWorkspace(user.UserId, "Oda 2");
        var ws3  = CreateWorkspace(CreateUser().UserId, "Başkasının Odası");

        var dal    = new WorkspaceMemberDal(DbContext);
        var result = await dal.GetUserWorkspaceIdsAsync(user.UserId);

        Assert.Equal(2, result.Count);
        Assert.Contains(ws1.WorkspaceId, result);
        Assert.Contains(ws2.WorkspaceId, result);
        Assert.DoesNotContain(ws3.WorkspaceId, result);
    }

    /// <summary>
    /// TEST 6: PomodoroTaskDal — Workspace görevi vs kişisel görev ayrımı
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task TaskDal_WorkspaceVsPersonal_FilteredCorrectly()
    {
        var user  = CreateUser();
        var ws    = CreateWorkspace(user.UserId);
        var wsTask = CreateTask(user.UserId, ws.WorkspaceId, "Oda görevi");
        var myTask = CreateTask(user.UserId, null,           "Kişisel görev");

        var dal = new PomodoroTaskDal(DbContext);

        var personal   = await dal.GetListAsync(t => t.UserId == user.UserId && t.WorkspaceId == null  && t.DeletedAt == null);
        var workspace_ = await dal.GetListAsync(t => t.UserId == user.UserId && t.WorkspaceId == ws.WorkspaceId && t.DeletedAt == null);

        Assert.Single(personal);
        Assert.Equal("Kişisel görev", personal[0].Title);

        Assert.Single(workspace_);
        Assert.Equal("Oda görevi", workspace_[0].Title);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GRUP 2: Servis Katmanı — Gerçek DB + Servis Entegrasyonu
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>
    /// TEST 7: PomodoroTaskService — Görev oluşturma DB'ye kalıcı olarak kaydolur
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task TaskService_Add_PersistsToDatabase()
    {
        var user    = CreateUser();
        var taskDal = new PomodoroTaskDal(DbContext);
        var userDal = new UserDal(DbContext);
        var wsDal   = new WorkspaceDal(DbContext);
        var wsMDal  = new WorkspaceMemberDal(DbContext);

        var sut = new PomodoroTaskService(taskDal, userDal, wsDal, wsMDal, Mapper, HubContextMock.Object);
        var dto = new CreateTaskDto { Title = "Entegrasyon Görevi", Description = "Test" };

        var result = await sut.Add(user.UserId, dto);

        // Sonuç başarılı olmalı
        Assert.True(result.Success);
        Assert.Equal("Entegrasyon Görevi", result.Data?.Title);

        // DB'de gerçekten var mı?
        var inDb = await DbContext.Tasks
            .FirstOrDefaultAsync(t => t.Title == "Entegrasyon Görevi" && t.UserId == user.UserId);
        Assert.NotNull(inDb);
    }

    /// <summary>
    /// TEST 8: PomodoroTaskService — Workspace görevi tüm üyelere görünmeli
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task TaskService_GetWorkspaceTasks_ReturnsAllMembersTasks()
    {
        var user1 = CreateUser(name: "Üye 1");
        var user2 = CreateUser(name: "Üye 2");
        var ws    = CreateWorkspace(user1.UserId);

        // user2'yi odaya ekle
        DbContext.WorkspaceMembers.Add(new WorkspaceMember
        {
            WorkspaceId = ws.WorkspaceId, UserId = user2.UserId, JoinedAt = DateTime.UtcNow
        });
        await DbContext.SaveChangesAsync();

        CreateTask(user1.UserId, ws.WorkspaceId, "Görev A");
        CreateTask(user2.UserId, ws.WorkspaceId, "Görev B");
        CreateTask(user1.UserId, null, "Kişisel"); // Bu gelmesin

        var sut = new PomodoroTaskService(
            new PomodoroTaskDal(DbContext), new UserDal(DbContext),
            new WorkspaceDal(DbContext), new WorkspaceMemberDal(DbContext),
            Mapper, HubContextMock.Object);

        var result = await sut.GetWorkspaceTasksAsync(user1.UserId, ws.WorkspaceId);

        Assert.True(result.Success);
        Assert.Equal(2, result.Data?.Count);
        Assert.Contains(result.Data!, t => t.Title == "Görev A");
        Assert.Contains(result.Data!, t => t.Title == "Görev B");
        Assert.DoesNotContain(result.Data!, t => t.Title == "Kişisel");
    }

    /// <summary>
    /// TEST 9: PomodoroTaskService — Soft-delete sonrası görev listede görünmemeli
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task TaskService_Delete_SoftDeletesTask()
    {
        var user = CreateUser();
        var task = CreateTask(user.UserId);
        var sut  = new PomodoroTaskService(
            new PomodoroTaskDal(DbContext), new UserDal(DbContext),
            new WorkspaceDal(DbContext), new WorkspaceMemberDal(DbContext),
            Mapper, HubContextMock.Object);

        await sut.DeleteAsync(user.UserId, task.TaskId);

        // DB'den çekilince DeletedAt dolu olmalı
        var deleted = await DbContext.Tasks.FindAsync(task.TaskId);
        Assert.NotNull(deleted!.DeletedAt);

        // Liste sorgusunda görünmemeli
        var list = await sut.GetAllAsync(user.UserId);
        Assert.DoesNotContain(list.Data!, t => t.TaskId == task.TaskId);
    }

    /// <summary>
    /// TEST 10: PomodoroTaskService — IncrementPomodoroCount hedef tamamlandığında görev Completed olmalı
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task TaskService_IncrementPomodoro_AutoCompletesTask()
    {
        var user = CreateUser();
        var task = new PomodoraBack.Entities.Task
        {
            TaskId               = Guid.NewGuid().ToString(),
            UserId               = user.UserId,
            Title                = "Hedefli Görev",
            Status               = TaskStatusEnums.NotStarted,
            PomodoroTargetCount  = 2,
            CompletedPomodoroCount = 0,
            CreatedAt            = DateTime.UtcNow
        };
        DbContext.Tasks.Add(task);
        await DbContext.SaveChangesAsync();

        var sut = new PomodoroTaskService(
            new PomodoroTaskDal(DbContext), new UserDal(DbContext),
            new WorkspaceDal(DbContext), new WorkspaceMemberDal(DbContext),
            Mapper, HubContextMock.Object);

        await sut.IncrementPomodoroCountAsync(task.TaskId); // 1. pomodoro
        var result = await sut.IncrementPomodoroCountAsync(task.TaskId); // 2. pomodoro → hedef!

        Assert.True(result.Success);
        Assert.Equal(TaskStatusEnums.Completed, result.Data?.Status);
        Assert.Equal(2, result.Data?.CompletedPomodoroCount);
    }

    /// <summary>
    /// TEST 11: NotificationDal — Kullanıcıya ait bildirimler filtrelenerek getirilmeli
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task NotificationDal_GetListByUser_ReturnsOnlyUserNotifications()
    {
        var user1 = CreateUser();
        var user2 = CreateUser();

        CreateNotification(user1.UserId, NotificationTypeEnums.FriendRequest);
        CreateNotification(user1.UserId, NotificationTypeEnums.FriendRequest);
        CreateNotification(user2.UserId, NotificationTypeEnums.FriendRequest);

        var dal    = new NotificationDal(DbContext);
        var result = await dal.GetListAsync(n => n.UserId == user1.UserId);

        Assert.Equal(2, result.Count);
        Assert.All(result, n => Assert.Equal(user1.UserId, n.UserId));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GRUP 3: WorkspaceService Entegrasyon
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>
    /// TEST 12: WorkspaceService — Oda oluşturulunca sahip otomatik üye olmalı
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task WorkspaceService_Create_OwnerBecomesFirstMember()
    {
        var owner = CreateUser(name: "Oda Sahibi");
        var sut = new WorkspaceService(
            new WorkspaceDal(DbContext), new WorkspaceMemberDal(DbContext),
            new WorkspaceInvitationDal(DbContext), new UserDal(DbContext),
            new FriendShipDal(DbContext), Mapper, HubContextMock.Object);

        var result = await sut.CreateWorkspaceAsync(owner.UserId, new CreateWorkspaceDto
        {
            WorkspaceName = "Yeni Oda"
        });

        Assert.True(result.Success);
        Assert.Equal("Yeni Oda", result.Data?.WorkspaceName);

        var memberships = await DbContext.WorkspaceMembers
            .Where(m => m.WorkspaceId == result.Data!.WorkspaceId)
            .ToListAsync();
        Assert.Single(memberships);
        Assert.Equal(owner.UserId, memberships[0].UserId);
    }

    /// <summary>
    /// TEST 13: WorkspaceService — Kapasite (4) dolunca oda daveti reddedilmeli
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task WorkspaceService_AcceptInvitation_BlockedWhenCapacityFull()
    {
        var owner  = CreateUser(name: "Sahip");
        var ws     = CreateWorkspace(owner.UserId);

        // Kapasiteyi doldur (owner + 3 = 4)
        for (int i = 0; i < 3; i++)
        {
            var extra = CreateUser();
            DbContext.WorkspaceMembers.Add(new WorkspaceMember
            {
                WorkspaceId = ws.WorkspaceId, UserId = extra.UserId, JoinedAt = DateTime.UtcNow
            });
        }
        await DbContext.SaveChangesAsync();

        // 5. kişi için davet oluştur
        var newUser    = CreateUser(name: "5. Kişi");
        var invitation = new WorkspaceInvitation
        {
            WorkspaceInvitationId = Guid.NewGuid().ToString(),
            WorkspaceId           = ws.WorkspaceId,
            SenderId              = owner.UserId,
            ReceiverId            = newUser.UserId,
            Status                = WorkspaceInvitationStatusEnums.pending,
            CreatedAt             = DateTime.UtcNow,
            ExpiresAt             = DateTime.UtcNow.AddDays(7)
        };
        DbContext.WorkspaceInvitations.Add(invitation);
        await DbContext.SaveChangesAsync();

        var sut = new WorkspaceService(
            new WorkspaceDal(DbContext), new WorkspaceMemberDal(DbContext),
            new WorkspaceInvitationDal(DbContext), new UserDal(DbContext),
            new FriendShipDal(DbContext), Mapper, HubContextMock.Object);

        var result = await sut.AcceptInvitationAsync(newUser.UserId, invitation.WorkspaceInvitationId);

        Assert.False(result.Success);
        Assert.Equal("Oda kapasitesi dolu.", result.Message);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GRUP 4: API Endpoint — Yetkisiz Erişim (401 Kontrolü)
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>
    /// TEST 14: NotificationHub — GetUserGroupName format doğruluğu (integration)
    /// </summary>
    [Fact]
    public void NotificationHub_GroupNames_AreCorrectlyFormatted()
    {
        const string uid = "test-user-xyz";
        const string wid = "workspace-abc";

        Assert.Equal("user_test-user-xyz",        NotificationHub.GetUserGroupName(uid));
        Assert.Equal("workspace_workspace-abc",   NotificationHub.GetWorkspaceGroupName(wid));
    }

    /// <summary>
    /// TEST 15: PomodoroConstants — Süre sınır değerleri doğru tanımlanmış
    /// </summary>
    [Fact]
    public void PomodoroConstants_Boundaries_AreCorrect()
    {
        Assert.Equal(5,  PomodoraBack.Core.Constants.PomodoroConstants.MIN_CUSTOM_DURATION);
        Assert.Equal(60, PomodoraBack.Core.Constants.PomodoroConstants.MAX_CUSTOM_DURATION);
        Assert.Equal(25, PomodoraBack.Core.Constants.PomodoroConstants.WORK_SESSION_DURATION);
        Assert.Equal(5,  PomodoraBack.Core.Constants.PomodoroConstants.SHORT_BREAK_DURATION);
        Assert.Equal(15, PomodoraBack.Core.Constants.PomodoroConstants.LONG_BREAK_DURATION);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GRUP 5: Veri Kalıcılığı — Çapraz Tablo ve Kısıtlar
    // ═══════════════════════════════════════════════════════════════════════

    /// <summary>
    /// TEST 16: Notification — IsRead güncelleme kalıcı olmalı
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task NotificationDal_MarkAsRead_PersistsReadStatus()
    {
        var user  = CreateUser();
        var notif = CreateNotification(user.UserId, NotificationTypeEnums.FriendRequest);
        var dal   = new NotificationDal(DbContext);

        var toUpdate = await dal.GetAsync(n => n.NotificationId == notif.NotificationId);
        Assert.NotNull(toUpdate);
        Assert.False(toUpdate!.IsRead);

        toUpdate.IsRead = true;
        toUpdate.ReadAt = DateTime.UtcNow;
        await dal.UpdateAsync(toUpdate);

        var updated = await dal.GetAsync(n => n.NotificationId == notif.NotificationId);
        Assert.True(updated!.IsRead);
        Assert.NotNull(updated.ReadAt);
    }

    /// <summary>
    /// TEST 17: Task — AssignToWorkspace görevi odaya taşımalı
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task TaskService_AssignToWorkspace_UpdatesWorkspaceId()
    {
        var user = CreateUser();
        var ws   = CreateWorkspace(user.UserId);
        var task = CreateTask(user.UserId, null, "Taşınacak Görev"); // kişisel görev

        var sut = new PomodoroTaskService(
            new PomodoroTaskDal(DbContext), new UserDal(DbContext),
            new WorkspaceDal(DbContext), new WorkspaceMemberDal(DbContext),
            Mapper, HubContextMock.Object);

        var result = await sut.AssignTaskToWorkspaceAsync(user.UserId, task.TaskId,
            new AssignTaskToWorkspaceDto { WorkspaceId = ws.WorkspaceId });

        Assert.True(result.Success);
        Assert.Equal(ws.WorkspaceId, result.Data?.WorkspaceId);

        var inDb = await DbContext.Tasks.FindAsync(task.TaskId);
        Assert.Equal(ws.WorkspaceId, inDb!.WorkspaceId);
    }

    /// <summary>
    /// TEST 18: FriendShipDal — Her iki yönden arkadaşlık ID sorgusunda eşit sonuç
    /// </summary>
    [Fact]
    public async System.Threading.Tasks.Task FriendShipDal_FriendIds_SymmetricFromBothDirections()
    {
        var userA = CreateUser(name: "A");
        var userB = CreateUser(name: "B");

        // B, A'nın FirstUser olduğu bir friendship kaydı
        DbContext.Friendships.Add(new FriendShip
        {
            FriendShipId  = Guid.NewGuid().ToString(),
            FirstUserId   = userA.UserId,
            SecondUserId  = userB.UserId,
            DeletedAt     = null
        });
        await DbContext.SaveChangesAsync();

        var dal = new FriendShipDal(DbContext);

        var friendsOfA = await dal.GetApprovedFriendIdsAsync(userA.UserId);
        var friendsOfB = await dal.GetApprovedFriendIdsAsync(userB.UserId);

        // Her ikisi de diğerini arkadaş olarak görmeli (çift yönlü)
        Assert.Contains(userB.UserId, friendsOfA);
        Assert.Contains(userA.UserId, friendsOfB);
    }
}
