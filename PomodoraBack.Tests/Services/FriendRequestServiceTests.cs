using AutoMapper;
using Core.Utilities.Results;
using Moq;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;
using PomodoraBack.Services.Concrete;
using PomodoraBack.Services.Interfaces;
using System.Linq.Expressions;
using Xunit;

namespace PomodoraBack.Tests.Services;

/// <summary>
/// FriendRequestService için unit testler.
/// Tüm bağımlılıklar (DAL, Mapper, NotificationService) Moq ile izole edilmiştir;
/// veritabanı veya dış servis bağlantısına gerek yoktur.
/// </summary>
public class FriendRequestServiceTests
{
    // ─── Test Fixtures ────────────────────────────────────────────────────────
    private readonly Mock<IFriendRequestDal>    _friendRequestDalMock = new();
    private readonly Mock<IFriendShipDal>       _friendShipDalMock    = new();
    private readonly Mock<IUserDal>             _userDalMock          = new();
    private readonly Mock<IMapper>              _mapperMock           = new();
    private readonly Mock<INotificationService> _notifServiceMock     = new();

    private FriendRequestService CreateSut() => new(
        _friendRequestDalMock.Object,
        _friendShipDalMock.Object,
        _userDalMock.Object,
        _mapperMock.Object,
        _notifServiceMock.Object);

    // Sabit test verileri
    private static readonly User Sender   = new() { UserId = "sender-001",   Name = "Ali",   Surname = "Yılmaz", Nickname = "ali" };
    private static readonly User Receiver = new() { UserId = "receiver-001", Name = "Veli",  Surname = "Demir",  Nickname = "veli" };

    // ─── Yardımcı Mock Kurucular ──────────────────────────────────────────────
    private void SetupUserDal(string userId, User? returnUser)
    {
        _userDalMock
            .Setup(x => x.GetAsync(It.Is<Expression<Func<User, bool>>>(e =>
                e.Compile()(new User { UserId = userId }))))
            .ReturnsAsync(returnUser);
    }

    private void SetupSenderAndReceiver()
    {
        _userDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<User, bool>>>()))
            .ReturnsAsync((Expression<Func<User, bool>> predicate) =>
            {
                var compiled = predicate.Compile();
                if (compiled(Sender))   return Sender;
                if (compiled(Receiver)) return Receiver;
                return null;
            });
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 1: Gönderici bulunamazsa hata dönmeli
    // ─────────────────────────────────────────────────────────────────────────
    [Fact]
    public async System.Threading.Tasks.Task SendFriendRequestAsync_SenderNotFound_ReturnsError()
    {
        // Arrange
        _userDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<User, bool>>>()))
            .ReturnsAsync((User?)null);

        var sut = CreateSut();

        // Act
        var result = await sut.SendFriendRequestAsync("ghost-user", new SendFriendRequestDto
        {
            ReceiverId = Receiver.UserId
        });

        // Assert
        Assert.False(result.Success);
        Assert.Equal("Gönderici kullanıcı bulunamadı.", result.Message);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 2: Alıcı bulunamazsa hata dönmeli (ReceiverId ile)
    // ─────────────────────────────────────────────────────────────────────────
    [Fact]
    public async System.Threading.Tasks.Task SendFriendRequestAsync_ReceiverNotFound_ById_ReturnsError()
    {
        // Arrange: Sender var, Receiver yok
        _userDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<User, bool>>>()))
            .ReturnsAsync((Expression<Func<User, bool>> expr) =>
            {
                var fn = expr.Compile();
                if (fn(Sender)) return Sender;
                return null; // Receiver bulunamıyor
            });

        var sut = CreateSut();

        // Act
        var result = await sut.SendFriendRequestAsync(Sender.UserId, new SendFriendRequestDto
        {
            ReceiverId = "nonexistent-id"
        });

        // Assert
        Assert.False(result.Success);
        Assert.Equal("Alıcı kullanıcı bulunamadı.", result.Message);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 3: Alıcı Nickname ile bulunabilmeli
    // ─────────────────────────────────────────────────────────────────────────
    [Fact]
    public async System.Threading.Tasks.Task SendFriendRequestAsync_ReceiverFoundByNickname_Succeeds()
    {
        // Arrange
        SetupSenderAndReceiver();

        _friendShipDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<FriendShip, bool>>>()))
            .ReturnsAsync((FriendShip?)null); // Arkadaş değil

        _friendRequestDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<FriendRequest, bool>>>()))
            .ReturnsAsync((FriendRequest?)null); // Bekleyen istek yok

        var createdRequest = new FriendRequest
        {
            FriendRequestId = "req-001",
            ConsignerId = Sender.UserId,
            ReceiverId  = Receiver.UserId
        };
        _friendRequestDalMock
            .Setup(x => x.AddAsync(It.IsAny<FriendRequest>()))
            .Returns(System.Threading.Tasks.Task.CompletedTask);

        _mapperMock
            .Setup(x => x.Map<FriendRequestDto>(It.IsAny<FriendRequest>()))
            .Returns(new FriendRequestDto { FriendRequestId = "req-001" });

        _notifServiceMock
            .Setup(x => x.CreateNotificationAsync(It.IsAny<CreateNotificationDto>()))
            .ReturnsAsync(new SuccessDataResult<NotificationDto>(new NotificationDto()));

        var sut = CreateSut();

        // Act
        var result = await sut.SendFriendRequestAsync(Sender.UserId, new SendFriendRequestDto
        {
            ReceiverNickname = Receiver.Nickname // ID değil, Nickname ile
        });

        // Assert
        Assert.True(result.Success);
        Assert.Equal("req-001", result.Data?.FriendRequestId);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 4: Kendine istek gönderilmesi engellenmeli
    // ─────────────────────────────────────────────────────────────────────────
    [Fact]
    public async System.Threading.Tasks.Task SendFriendRequestAsync_SelfRequest_ReturnsError()
    {
        // Arrange: Sender ve Receiver aynı kişi
        _userDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<User, bool>>>()))
            .ReturnsAsync(Sender);

        var sut = CreateSut();

        // Act
        var result = await sut.SendFriendRequestAsync(Sender.UserId, new SendFriendRequestDto
        {
            ReceiverId = Sender.UserId // Aynı ID!
        });

        // Assert
        Assert.False(result.Success);
        Assert.Equal("Kendinize arkadaş isteği gönderemezsiniz.", result.Message);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 5: Zaten arkadaşlarsa yeni istek gönderilememeli
    // ─────────────────────────────────────────────────────────────────────────
    [Fact]
    public async System.Threading.Tasks.Task SendFriendRequestAsync_AlreadyFriends_ReturnsError()
    {
        // Arrange
        SetupSenderAndReceiver();

        _friendShipDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<FriendShip, bool>>>()))
            .ReturnsAsync(new FriendShip // Mevcut arkadaşlık var
            {
                FriendShipId  = "fs-001",
                FirstUserId   = Sender.UserId,
                SecondUserId  = Receiver.UserId,
                DeletedAt     = null
            });

        var sut = CreateSut();

        // Act
        var result = await sut.SendFriendRequestAsync(Sender.UserId, new SendFriendRequestDto
        {
            ReceiverId = Receiver.UserId
        });

        // Assert
        Assert.False(result.Success);
        Assert.Equal("Zaten bu kullanıcının arkadaşısınız.", result.Message);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 6: Bekleyen istek varsa yeni istek gönderilememeli
    // ─────────────────────────────────────────────────────────────────────────
    [Fact]
    public async System.Threading.Tasks.Task SendFriendRequestAsync_PendingRequestExists_ReturnsError()
    {
        // Arrange
        SetupSenderAndReceiver();

        _friendShipDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<FriendShip, bool>>>()))
            .ReturnsAsync((FriendShip?)null); // Arkadaş değil

        _friendRequestDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<FriendRequest, bool>>>()))
            .ReturnsAsync(new FriendRequest // Bekleyen istek var
            {
                FriendRequestId = "req-existing",
                ConsignerId     = Sender.UserId,
                ReceiverId      = Receiver.UserId,
                Status          = false
            });

        var sut = CreateSut();

        // Act
        var result = await sut.SendFriendRequestAsync(Sender.UserId, new SendFriendRequestDto
        {
            ReceiverId = Receiver.UserId
        });

        // Assert
        Assert.False(result.Success);
        Assert.Contains("zaten bir istek gönderilmiş", result.Message);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 7: Başarılı istek gönderimi — DB'ye kaydedilmeli
    // ─────────────────────────────────────────────────────────────────────────
    [Fact]
    public async System.Threading.Tasks.Task SendFriendRequestAsync_ValidRequest_SavesToDatabase()
    {
        // Arrange
        SetupSenderAndReceiver();

        _friendShipDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<FriendShip, bool>>>()))
            .ReturnsAsync((FriendShip?)null);

        _friendRequestDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<FriendRequest, bool>>>()))
            .ReturnsAsync((FriendRequest?)null);

        FriendRequest? capturedRequest = null;
        _friendRequestDalMock
            .Setup(x => x.AddAsync(It.IsAny<FriendRequest>()))
            .Callback<FriendRequest>(req => capturedRequest = req)
            .Returns(System.Threading.Tasks.Task.CompletedTask);

        _mapperMock
            .Setup(x => x.Map<FriendRequestDto>(It.IsAny<FriendRequest>()))
            .Returns(new FriendRequestDto());

        _notifServiceMock
            .Setup(x => x.CreateNotificationAsync(It.IsAny<CreateNotificationDto>()))
            .ReturnsAsync(new SuccessDataResult<NotificationDto>(new NotificationDto()));

        var sut = CreateSut();

        // Act
        var result = await sut.SendFriendRequestAsync(Sender.UserId, new SendFriendRequestDto
        {
            ReceiverId = Receiver.UserId
        });

        // Assert
        Assert.True(result.Success);
        Assert.NotNull(capturedRequest);
        Assert.Equal(Sender.UserId,   capturedRequest!.ConsignerId);
        Assert.Equal(Receiver.UserId, capturedRequest.ReceiverId);
        Assert.False(capturedRequest.Status); // Beklemede
        _friendRequestDalMock.Verify(x => x.AddAsync(It.IsAny<FriendRequest>()), Times.Once);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 8: Başarılı istek sonrasında bildirim gönderilmeli
    // ─────────────────────────────────────────────────────────────────────────
    [Fact]
    public async System.Threading.Tasks.Task SendFriendRequestAsync_ValidRequest_SendsNotificationToReceiver()
    {
        // Arrange
        SetupSenderAndReceiver();

        _friendShipDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<FriendShip, bool>>>()))
            .ReturnsAsync((FriendShip?)null);

        _friendRequestDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<FriendRequest, bool>>>()))
            .ReturnsAsync((FriendRequest?)null);

        _friendRequestDalMock
            .Setup(x => x.AddAsync(It.IsAny<FriendRequest>()))
            .Returns(System.Threading.Tasks.Task.CompletedTask);

        _mapperMock
            .Setup(x => x.Map<FriendRequestDto>(It.IsAny<FriendRequest>()))
            .Returns(new FriendRequestDto());

        CreateNotificationDto? capturedNotif = null;
        _notifServiceMock
            .Setup(x => x.CreateNotificationAsync(It.IsAny<CreateNotificationDto>()))
            .Callback<CreateNotificationDto>(dto => capturedNotif = dto)
            .ReturnsAsync(new SuccessDataResult<NotificationDto>(new NotificationDto()));

        var sut = CreateSut();

        // Act
        await sut.SendFriendRequestAsync(Sender.UserId, new SendFriendRequestDto
        {
            ReceiverId = Receiver.UserId
        });

        // Assert: Bildirim alıcıya gönderilmeli
        _notifServiceMock.Verify(x => x.CreateNotificationAsync(It.IsAny<CreateNotificationDto>()), Times.Once);
        Assert.NotNull(capturedNotif);
        Assert.Equal(Receiver.UserId, capturedNotif!.UserId); // Alıcıya gönderilmeli
        Assert.Contains(Sender.Name,  capturedNotif.Message); // Sender'ın adı mesajda olmalı
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 9: Bildirim servisi çökse bile istek başarılı dönmeli (hata toleransı)
    // ─────────────────────────────────────────────────────────────────────────
    [Fact]
    public async System.Threading.Tasks.Task SendFriendRequestAsync_NotificationFails_RequestStillSucceeds()
    {
        // Arrange
        SetupSenderAndReceiver();

        _friendShipDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<FriendShip, bool>>>()))
            .ReturnsAsync((FriendShip?)null);

        _friendRequestDalMock
            .Setup(x => x.GetAsync(It.IsAny<Expression<Func<FriendRequest, bool>>>()))
            .ReturnsAsync((FriendRequest?)null);

        _friendRequestDalMock
            .Setup(x => x.AddAsync(It.IsAny<FriendRequest>()))
            .Returns(System.Threading.Tasks.Task.CompletedTask);

        _mapperMock
            .Setup(x => x.Map<FriendRequestDto>(It.IsAny<FriendRequest>()))
            .Returns(new FriendRequestDto());

        // Bildirim servisi exception fırlatıyor
        _notifServiceMock
            .Setup(x => x.CreateNotificationAsync(It.IsAny<CreateNotificationDto>()))
            .ThrowsAsync(new Exception("SignalR bağlantısı yok"));

        var sut = CreateSut();

        // Act — exception fırlatılmamalı, istek başarılı dönmeli
        var result = await sut.SendFriendRequestAsync(Sender.UserId, new SendFriendRequestDto
        {
            ReceiverId = Receiver.UserId
        });

        // Assert
        Assert.True(result.Success);
        Assert.Equal("Arkadaş isteği gönderildi.", result.Message);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 10: PomodoroConstants — Puan hesaplama doğruluğu
    // ─────────────────────────────────────────────────────────────────────────
    [Theory]
    [InlineData(25, PomodoraBack.Core.Enums.PomodoroTypeEnums.WorkSession,       25)]
    [InlineData(5,  PomodoraBack.Core.Enums.PomodoroTypeEnums.ShortBreakSession,  5)]
    [InlineData(15, PomodoraBack.Core.Enums.PomodoroTypeEnums.LongBreakSession,  15)]
    [InlineData(30, PomodoraBack.Core.Enums.PomodoroTypeEnums.WorkSession,       30)]
    [InlineData(10, PomodoraBack.Core.Enums.PomodoroTypeEnums.ShortBreakSession, 10)]
    public void PomodoroConstants_CalculatePoints_ReturnsExpected(
        int duration, PomodoraBack.Core.Enums.PomodoroTypeEnums type, int expectedPoints)
    {
        // Act
        var points = PomodoraBack.Core.Constants.PomodoroConstants.CalculatePoints(duration, type);

        // Assert
        Assert.Equal(expectedPoints, points);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TEST 11: NotificationHub — Grup adı yardımcı metodlarının doğruluğu
    // ─────────────────────────────────────────────────────────────────────────
    [Fact]
    public void NotificationHub_GetUserGroupName_ReturnsCorrectFormat()
    {
        const string userId      = "user-abc-123";
        const string workspaceId = "ws-xyz-456";

        var userGroup      = PomodoraBack.Hubs.NotificationHub.GetUserGroupName(userId);
        var workspaceGroup = PomodoraBack.Hubs.NotificationHub.GetWorkspaceGroupName(workspaceId);

        Assert.Equal("user_user-abc-123",  userGroup);
        Assert.Equal("workspace_ws-xyz-456", workspaceGroup);
    }
}
