# 4. GELİŞTİRME

## 4.1 Backend Mimarisi ve Katmanlar

Pomodoro Backend API geliştirme sürecinde, proje temiz kod prensipleri ve SOLID prensiplerine uygun olarak katmanlı bir mimari (Layered Architecture) ile inşa edilmiştir. Bu mimaride, her katman belirli bir sorumluluğa sahip olup, diğer katmanlardan bağımsız olarak geliştirilebilir ve test edilebilir. Bu yaklaşım sayesinde kod tekrarı azalır, bakım kolaylaşır ve yeni özellikler eklemek daha az risk taşır.

Backend yapısı aşağıdaki ana katmanlardan oluşmaktadır:

**Çizelge 4.1. Backend Katman Yapısı ve Sorumlulukları**

| Katman | Dosya Konumu | Sorumuluk | Amaç |
|--------|--------------|----------|------|
| Presentation (Sunum) | Controllers/ | HTTP isteklerini karşılar, DTOs'i doğrular, Response'ı formatlar | İstemci isteklerinin doğru biçimde işlenmesi |
| Business Logic (İş Mantığı) | Services/ | İş kurallarını, Pomodoro algoritmasını yürütür, veri işleme | Uygulamanın temel işlevleri ve kurallı yürütümü |
| Data Access (Veri Erişimi) | DataAccess/Concrete/ | Veritabanı sorgulamalarını Repository Pattern ile yönetir | Veri erişiminin merkezileştirilmesi |
| Domain (Alan Modelleri) | Entities/, Core/Entities/ | Veritabanı nesnelerini ve veri yapılarını tanımlar | Ortak veri modellerinin standardizasyonu |
| Infrastructure (Altyapı) | Program.cs, Middleware/ | Bağımlılık enjeksiyonu, middleware yapılandırması, Logging | Uygulamanın temel servisleri ve yapılandırması |

Bu katmanlı yapı, aşağıdaki avantajları sağlamaktadır:

- **Bağımsızlık (Decoupling)**: Her katman diğerine minimum bağımlılıkla çalışarak, bir katmandaki değişiklikler diğerlerini etkilemez
- **Test Edilebilirlik**: Mock nesneler kullanılarak her katman izole ortamda test edilebilir
- **Bakım Kolaylığı**: Belirli bir işlevi bulmak ve değiştirmek kolay hale gelir
- **Ölçeklenebilirlik**: Yeni özellikler eklemek veya mevcut olanları genişletmek sistematik şekilde yapılabilir

### 4.1.1 Repository Pattern Uygulaması

Veri erişim katmanının bağımsızlaştırılması amacıyla Repository Pattern kullanılmıştır. Bu desen, veri erişim işlemlerini merkezileştirerek, iş mantığı katmanının veritabanı detaylarından habersiz olmasını sağlar. Böylece, veritabanı değiştiği takdirde (SQL Server'dan PostgreSQL'e geçiş gibi) sadece Repository sınıfları değiştirmek yeterli olur.

Örnek olarak, `IUserRepository` arayüzü ve `UserRepository` implementasyonu aşağıdaki gibi tasarlanmıştır:

```csharp
// DataAccess/Interfaces/IUserRepository.cs
public interface IUserRepository
{
    // Kullanıcıyı ID ile getir
    Task<User> GetUserByIdAsync(int userId);
    
    // Kullanıcıyı email ile getir (Login işlemlerinde kullanılır)
    Task<User> GetUserByEmailAsync(string email);
    
    // Kullanıcıyı takma ad ile getir (Profil araması için)
    Task<User> GetUserByNicknameAsync(string nickname);
    
    // Tüm kullanıcıları getir (Leaderboard için)
    Task<IEnumerable<User>> GetAllUsersAsync();
    
    // Yeni kullanıcı ekle
    Task<User> AddUserAsync(User user);
    
    // Kullanıcı bilgilerini güncelle
    Task<User> UpdateUserAsync(User user);
    
    // Kullanıcıyı sil
    Task<bool> DeleteUserAsync(int userId);
}

// DataAccess/Concrete/UserRepository.cs
public class UserRepository : IUserRepository
{
    private readonly PomodoroContext _context;

    public UserRepository(PomodoroContext context)
    {
        _context = context; // Dependency Injection ile Entity Framework Context alınır
    }
    public async Task<User> GetUserByEmailAsync(string email)
    {
        return await _context.Users
            .AsNoTracking() // Sadece okuma işlemi için optimize
            .FirstOrDefaultAsync(u => u.Email == email);
    }

    
    public async Task<User> AddUserAsync(User user)
    {
        // Kullanıcı ekle
        _context.Users.Add(user);
        
        // Veritabanına kaydei
        await _context.SaveChangesAsync();
        
        return user;
    }

    public async Task<IEnumerable<User>> GetAllUsersAsync()
    {
        return await _context.Users
            .OrderByDescending(u => u.TotalPoints) // En yüksek puanlar üstte
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<User> UpdateUserAsync(User user)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
        return user;
    }
}
```

**Repository Pattern Avantajları:**

- **Veri Erişiminin Abstraktlaştırılması**: İş katmanı, hangi veritabanı teknolojisinin kullanıldığını bilmez
- **Test Kolaylığı**: Testlerde Mock Repository kullanılarak gerçek veritabanına bağlanmadan test yapılabilir
- **Kod Reusability**: Aynı sorgular birden fazla yerde kullanılabilir
- **Merkezi Yönetim**: Tüm veritabanı işlemleri tek bir yerden yönetilir

### 4.1.2 JWT Kimlik Doğrulama Implementasyonu

Güvenli ve stateless (durumsuz) bir yetkilendirme sistemi sağlamak amacıyla JWT (JSON Web Token) ve Refresh Token yapısı kullanılmıştır. Bu sistem, sunucu tarafında session tutma ihtiyacını ortadan kaldırır ve API'nin ölçeklenebilirliğini arttırır.

JWT Yapısı:
- Header: Token türünü ve şifreleme algoritmasını içerir (HS256)
- Payload: Kullanıcı kimliği, mail, roller gibi talepleri (claims) içerir
- Signature: Header ve Payload'ı gizli anahtar ile şifreler, token'ın sahteliğini önler

**Refresh Token Mekanizması:**
Access Token kısa ömürlü (15 dakika) olup, bittikten sonra Refresh Token kullanılarak yenisi alınır. Bu, güvenliği arttırır çünkü hacker'ın ele geçireceği token'ın kullanışlı süresi sınırlıdır.

```csharp
// Services/AuthService.cs
public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepository;
    private readonly ITokenService _tokenService;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        IUserRepository userRepository, 
        ITokenService tokenService,
        ILogger<AuthService> logger)
    {
        _userRepository = userRepository;
        _tokenService = tokenService;
        _logger = logger;
    }

    public async Task<AuthResponseDto> LoginAsync(LoginDto loginDto)
    {
        try
        {
            // 1. Kullanıcı bilgilerini doğrula
            var user = await _userRepository.GetUserByEmailAsync(loginDto.Email);
            if (user == null)
            {
                _logger.LogWarning($"Başarısız giriş denemesi: {loginDto.Email} kullanıcı bulunamadı");
                throw new UnauthorizedAccessException("Geçersiz e-posta veya şifre");
            }

            // 2. Şifre doğrulama (BCrypt ile hash edilmiş şifre karşılaştırması)
            if (!VerifyPassword(loginDto.Password, user.PasswordHash))
            {
                _logger.LogWarning($"Başarısız giriş denemesi: {loginDto.Email} yanlış şifre");
                throw new UnauthorizedAccessException("Geçersiz e-posta veya şifre");
            }

            // 3. JWT Access Token oluştur
            // Access Token 15 dakika geçerlidir
            var accessToken = _tokenService.GenerateAccessToken(user);
            
            // 4. Refresh Token oluştur ve veritabanına kaydet
            // Refresh Token 7 gün geçerlidir
            var refreshToken = _tokenService.GenerateRefreshToken();
            await _userRepository.SaveRefreshTokenAsync(user.Id, refreshToken);

            // 5. Kullanıcının aktif durumunu güncelle
            user.CurrentStatus = "Online";
            user.LastSeen = DateTime.UtcNow;
            await _userRepository.UpdateUserAsync(user);

            _logger.LogInformation($"Başarılı giriş: {user.Nickname}");

            // 6. Cevapı istemciye gönder
            return new AuthResponseDto
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                User = MapToUserDto(user),
                ExpiresIn = 900 // 15 dakika (saniye cinsinden)
            };
        }
        catch (Exception ex)
        {
            _logger.LogError($"Login hatasında: {ex.Message}");
            throw;
        }
    }

    // BCrypt kullanarak şifre doğrulama
    private bool VerifyPassword(string password, string hash)
    {
        return BCrypt.Net.BCrypt.Verify(password, hash);
    }

    // Şifre hashlenmiş halde saklanır (irreversible)
    public string HashPassword(string password)
    {
        return BCrypt.Net.BCrypt.HashPassword(password);
    }

    private UserDto MapToUserDto(User user)
    {
        return new UserDto
        {
            Id = user.Id,
            Email = user.Email,
            Nickname = user.Nickname,
            TotalPoints = user.TotalPoints,
            Level = user.Level,
            CurrentStatus = user.CurrentStatus,
            CreatedAt = user.CreatedAt
        };
    }
}

// Services/TokenService.cs
public class TokenService : ITokenService
{
    private readonly IConfiguration _configuration;

    public TokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    // Access Token oluşturma
    public string GenerateAccessToken(User user)
    {
        var secretKey = _configuration["Jwt:SecretKey"];
        var issuer = _configuration["Jwt:Issuer"];
        var audience = _configuration["Jwt:Audience"];
        var expirationMinutes = int.Parse(_configuration["Jwt:ExpirationMinutes"]);

        // Gizli anahtarı byte'a çevir
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        // Token taleplerini (claims) oluştur
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim("Nickname", user.Nickname),
            new Claim("Level", user.Level.ToString())
        };

        // Token'ı oluştur
        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expirationMinutes),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    // Refresh Token oluşturma
    public string GenerateRefreshToken()
    {
        // Güvenli bir random token oluştur
        var randomNumber = new byte[32];
        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(randomNumber);
        }
        return Convert.ToBase64String(randomNumber);
    }
}
```

**Güvenlik Özellikleri:**
- Şifreler BCrypt ile hashed şekilde saklanır (reversible değil)
- Token'lar gizli anahtar ile dijital olarak imzalanır
- Access Token kısa ömürlü, Refresh Token uzun ömürlü
- Her giriş işlemi loglanır
- Geçersiz kimlik bilgileri belirtilmez (kullanıcıyı korumak için)

## 4.2 Pomodoro Oturum Yönetimi

Projenin temel işlevselliği olan Pomodoro oturum yönetimi, `PomodoroSessionController` ve `PomodoroSessionService` üzerinden yürütülmektedir. Pomodoro tekniği, 25 dakikalık yoğun çalışma + 5 dakikalık dinlenme döngüsüne dayanmaktadır. Bu teknik, kognitif kapasitenin optimal düzeyde tutulmasını sağlar.

### 4.2.1 Pomodoro Oturum Başlatma

Bir Pomodoro oturumu başlatıldığında, kullanıcının profil bilgileri güncellenir ve çalışma süresi başlatılır. Sistem, aynı anda birden fazla oturumu desteklemez (bir kullanıcı bir anda sadece bir oturum açabilir).

```csharp
// Services/PomodoroSessionService.cs
public class PomodoroSessionService : IPomodoroSessionService
{
    private readonly IPomodoroSessionRepository _sessionRepository;
    private readonly IUserRepository _userRepository;
    private readonly ITaskRepository _taskRepository;
    private readonly ILogger<PomodoroSessionService> _logger;
    private readonly IMapper _mapper;

    public async Task<PomodoroSessionDto> StartPomodoroSessionAsync(
        int userId, 
        CreatePomodoroSessionDto sessionDto)
    {
        try
        {
            // 1. Kullanıcı kontrolü
            var user = await _userRepository.GetUserByIdAsync(userId);
            if (user == null)
                throw new InvalidOperationException("Kullanıcı bulunamadı");

            // 2. Etkin bir oturumun olup olmadığını kontrol et
            var activeSession = await _sessionRepository
                .GetActiveSessionAsync(userId);
            
            if (activeSession != null)
                throw new InvalidOperationException("Zaten aktif bir oturumunuz var");

            // 3. Eğer task ID verilmişse, task'ı kontrol et
            if (sessionDto.TaskId.HasValue)
            {
                var task = await _taskRepository
                    .GetTaskByIdAsync(sessionDto.TaskId.Value);
                
                if (task == null || task.UserId != userId)
                    throw new InvalidOperationException("Geçersiz task");
            }
            var pomodoroSession = new PomodoroSession
            {
                UserId = userId,
                TaskId = sessionDto.TaskId,
                WorkDurationMinutes = sessionDto.WorkDurationMinutes ?? 25,
                BreakDurationMinutes = sessionDto.BreakDurationMinutes ?? 5,
                StartTime = DateTime.UtcNow,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            await _sessionRepository.AddAsync(pomodoroSession);

            // 5. Kullanıcının durumunu "Odaklanıyor" olarak güncelle
            user.CurrentStatus = "Focusing";
            user.LastSeen = DateTime.UtcNow;
            await _userRepository.UpdateUserAsync(user);

            _logger.LogInformation(
                $"Oturum başlatıldı - Kullanıcı: {userId}, Çalışma: {sessionDto.WorkDurationMinutes}min");

            return _mapper.Map<PomodoroSessionDto>(pomodoroSession);
        }
        catch (Exception ex)
        {
            _logger.LogError($"Pomodoro oturumu başlatma hatası: {ex.Message}");
            throw;
        }
    }
}
```

**Başlatma Süreci:**
1. Kullanıcı kimliğini doğrula (JWT token kontrolü)
2. Aynı anda sadece bir oturum kontrolü yap
3. Seçilmiş task'ın geçerliliğini kontrol et
4. Veritabanında yeni oturum kaydı oluştur
5. Kullanıcı durumunu "Focusing" olarak işaretle
6. İşlemini loglara kaydını yapıyor

### 4.2.2 Pomodoro Oturumu Tamamlama ve XP Kazanımı

Oturum tamamlandığında, kullanıcı çalışma süresine göre tecrübe puanı (XP) kazanır ve seviye sistemi güncellenir. XP sistemi, oyunlaştırma unsuru olarak motivasyonu arttırır.

**XP Hesaplama Formülü:**
```
XP = Çalışma Dakikası × 10
Örnek: 25 dakika çalışma = 250 XP
```

**Seviye Sistemi:**
```
Level 1: 0 - 1.000 XP
Level 2: 1.001 - 2.500 XP
Level 3: 2.501 - 5.000 XP
Level 4: 5.001 - 10.000 XP
Level 5: 10.001+ XP
```

```csharp
// Services/PomodoroSessionService.cs
public async Task<PomodoroSessionDto> CompletePomodoroSessionAsync(int sessionId)
{
    try
    {
        // 1. Oturumu getir
        var session = await _sessionRepository.GetByIdAsync(sessionId);
        
        if (session == null)
            throw new InvalidOperationException("Oturum bulunamadı");

        if (!session.IsActive)
            throw new InvalidOperationException("Bu oturum zaten tamamlanmış");

        // 2. Çalışma süresini hesapla (dakika cinsinden)
        var duration = (DateTime.UtcNow - session.StartTime).TotalMinutes;
        
        // Eğer 1 dakikadan az ise, XP verme
        if (duration < 1)
            throw new InvalidOperationException("En az 1 dakika çalışmalısınız");

        // 3. XP hesapla (her dakika = 10 XP)
        var xpGained = (int)(duration * 10);
        
        // 4. Kullanıcı bilgilerini getir
        var user = await _userRepository.GetUserByIdAsync(session.UserId);
        
        // 5. XP'yi topla
        user.TotalPoints += xpGained;
        user.CurrentStatus = "Online";
        user.LastSeen = DateTime.UtcNow;
        
        // 6. Seviye güncellemesi
        int oldLevel = user.Level;
        UpdateUserLevel(user);
        
        // Eğer seviye atlatmışsa, bildirim gönder
        if (user.Level > oldLevel)
        {
            _logger.LogInformation(
                $"Seviye atlatma! {user.Nickname} Level {oldLevel} → {user.Level}");
        }
        
        await _userRepository.UpdateUserAsync(user);

        // 7. Oturumu tamamla
        session.IsActive = false;
        session.EndTime = DateTime.UtcNow;
        session.ExperienceGained = xpGained;
        await _sessionRepository.UpdateAsync(session);

        // 8. Task'ı tamamlandı olarak işaretle (eğer var ise)
        if (session.TaskId.HasValue)
        {
            var task = await _taskRepository.GetTaskByIdAsync(session.TaskId.Value);
            if (task != null)
            {
                task.IsCompleted = true;
                task.CompletedAt = DateTime.UtcNow;
                await _taskRepository.UpdateAsync(task);
            }
        }

        _logger.LogInformation(
            $"Oturum tamamlandı - Kullanıcı: {user.Nickname}, XP: {xpGained}, Toplam: {user.TotalPoints}");

        return _mapper.Map<PomodoroSessionDto>(session);
    }
    catch (Exception ex)
    {
        _logger.LogError($"Oturum tamamlama hatası: {ex.Message}");
        throw;
    }
}

private void UpdateUserLevel(User user)
{
    // XP'ye göre seviye belirle
    if (user.TotalPoints >= 10000)
    {
        user.Level = 5;
    }
    else if (user.TotalPoints >= 5000)
    {
        user.Level = 4;
    }
    else if (user.TotalPoints >= 2500)
    {
        user.Level = 3;
    }
    else if (user.TotalPoints >= 1000)
    {
        user.Level = 2;
    }
    else
    {
        user.Level = 1;
    }
}
```

**Tamamlama Süreci:**
1. Oturumun varlığı ve aktifliğini kontrol et
2. Geçen süreyi hesapla
3. XP'yi hesapla ve kullanıcıya ekle
4. Seviye güncellemesini gerçekleştir
5. Task'ı tamamlandı olarak işaretle
6. İstatistik verilerini güncellea

## 4.3 Sosyal Etkileşim Modülü

Oyunlaştırma unsurlarından biri olan sosyal etkileşim sistemi, kullanıcılar arasında bağlantı kurulmasını ve motivasyonu arttırmasını sağlar. Arkadaş sistemi ve ortak çalışma olanakları, kullanıcıların arkadaşlarıyla ilerleme takibi yapabilmesini mümkün kılar. Bu sistem sayesinde, bireysel başarılar sosyal bir ortamda paylaşılarak daha anlamlı hale gelmektedir.

### 4.3.1 Arkadaş İsteği Yönetimi

Arkadaş isteği sistemi, güvenli ve kontrollü bir şekilde kullanıcı bağlantılarını yönetir. Sistem, şu durumları denetler:
- Kişi kendisine istek göndermeyecek
- Zaten arkadaş olan kişilere tekrar istek gönderilmeyecek
- Beklemede bir istek varsa yeni istek gönderilmeyecek
- Çift yönlü isteklerde otomatik kabul gerçekleşecek

```csharp
// Services/FriendshipService.cs
public class FriendshipService : IFriendshipService
{
    private readonly IFriendshipRepository _friendshipRepository;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<FriendshipService> _logger;
    private readonly IMapper _mapper;

    public async Task<FriendshipDto> SendFriendRequestAsync(
        int senderId, 
        SendFriendRequestDto requestDto)
    {
        try
        {
            // 1. Gönderici ve alıcı kontrolü
            var sender = await _userRepository.GetUserByIdAsync(senderId);
            var receiver = await _userRepository.GetUserByIdAsync(requestDto.ReceiverId);
            
            if (sender == null || receiver == null)
                throw new InvalidOperationException("Kullanıcı bulunamadı");

            // 2. Kendine istek gönderme kontrolü
            if (senderId == requestDto.ReceiverId)
                throw new InvalidOperationException("Kendinize arkadaş isteği gönderemezsiniz");

            // 3. Zaten arkadaş mı kontrolü
            var existingFriendship = await _friendshipRepository
                .GetFriendshipAsync(senderId, requestDto.ReceiverId);
            
            if (existingFriendship != null && existingFriendship.Status == "Accepted")
                throw new InvalidOperationException("Zaten arkadaşsınız");

            // 4. Beklemede istek var mı kontrolü
            var pendingFromSender = await _friendshipRepository
                .GetPendingFriendshipAsync(senderId, requestDto.ReceiverId);

            if (pendingFromSender != null)
                throw new InvalidOperationException("Bu kişiye zaten bir isteğiniz var");

            // 5. Karşı taraftan beklemede istek var mı kontrol et
            var pendingFromReceiver = await _friendshipRepository
                .GetPendingFriendshipAsync(requestDto.ReceiverId, senderId);

            if (pendingFromReceiver != null)
            {
                // Çift yönlü istek durumu - otomatik kabul et
                pendingFromReceiver.Status = "Accepted";
                pendingFromReceiver.UpdatedAt = DateTime.UtcNow;
                await _friendshipRepository.UpdateAsync(pendingFromReceiver);

                _logger.LogInformation(
                    $"Çift yönlü arkadaşlık oluşturuldu: {sender.Nickname} ↔ {receiver.Nickname}");

                return _mapper.Map<FriendshipDto>(pendingFromReceiver);
            }
            var friendship = new Friendship
            {
                SenderId = senderId,
                ReceiverId = requestDto.ReceiverId,
                Status = "Pending",
                CreatedAt = DateTime.UtcNow
            };

            await _friendshipRepository.AddAsync(friendship);

            _logger.LogInformation(
                $"Arkadaş isteği gönderildi: {sender.Nickname} → {receiver.Nickname}");

            return _mapper.Map<FriendshipDto>(friendship);
        }
        catch (Exception ex)
        {
            _logger.LogError($"Arkadaş isteği gönderme hatası: {ex.Message}");
            throw;
        }
    }

    // Arkadaş isteğini kabul etme
    public async Task<FriendshipDto> AcceptFriendRequestAsync(int friendshipId)
    {
        var friendship = await _friendshipRepository.GetByIdAsync(friendshipId);
        
        if (friendship == null)
            throw new InvalidOperationException("İstek bulunamadı");

        if (friendship.Status != "Pending")
            throw new InvalidOperationException("Bu istek zaten işlenmiş");

        friendship.Status = "Accepted";
        friendship.UpdatedAt = DateTime.UtcNow;
        
        await _friendshipRepository.UpdateAsync(friendship);

        var receiver = await _userRepository.GetUserByIdAsync(friendship.ReceiverId);
        _logger.LogInformation(
            $"Arkadaş isteği kabul edildi: {receiver.Nickname}");

        return _mapper.Map<FriendshipDto>(friendship);
    }

    // Arkadaş isteğini reddetme
    public async Task RejectFriendRequestAsync(int friendshipId)
    {
        var friendship = await _friendshipRepository.GetByIdAsync(friendshipId);
        
        if (friendship == null)
            throw new InvalidOperationException("İstek bulunamadı");

        friendship.Status = "Rejected";
        friendship.UpdatedAt = DateTime.UtcNow;
        
        await _friendshipRepository.UpdateAsync(friendship);

        _logger.LogInformation($"Arkadaş isteği reddedildi");
    }

    // Arkadaş silme
    public async Task RemoveFriendAsync(int userId, int friendId)
    {
        var friendship = await _friendshipRepository
            .GetFriendshipAsync(userId, friendId);

        if (friendship == null || friendship.Status != "Accepted")
            throw new InvalidOperationException("Bu arkadaşlık ilişkisi bulunamadı");

        await _friendshipRepository.DeleteAsync(friendship.Id);

        _logger.LogInformation($"Arkadaş silindi: {userId} → {friendId}");
    }

    // Kullanıcının arkadaş listesini getir
    public async Task<IEnumerable<UserDto>> GetFriendsAsync(int userId)
    {
        var friendships = await _friendshipRepository
            .GetUserFriendshipsAsync(userId);

        var friendIds = friendships
            .Where(f => f.Status == "Accepted")
            .Select(f => f.SenderId == userId ? f.ReceiverId : f.SenderId)
            .ToList();

        var friends = new List<UserDto>();
        foreach (var friendId in friendIds)
        {
            var friend = await _userRepository.GetUserByIdAsync(friendId);
            if (friend != null)
                friends.Add(_mapper.Map<UserDto>(friend));
        }

        return friends;
    }
}
```

**Arkadaş İstek Durumları:**
- **Pending**: İstek gönderildi, beklemede
- **Accepted**: İstek kabul edildi, arkadaş ilişkisi kuruldu
- **Rejected**: İstek reddedildi

**Özel Durum - Çift Yönlü İstek:**
Eğer A kişi B'ye istek atar ve B'nin bekleme kuyruğunda A'nın isteği varsa, sistem otomatik olarak her ikisini arkadaş yapar. Bu, kullanıcı deneyimini iyileştirir ve gereksiz hata mesajlarından kaçınır.

## 4.4 Veri Tabanı Migrasyonları ve Tasarımı

Entity Framework Core, modern bir ORM (Object-Relational Mapping) aracı olup, "Code-First" yaklaşımını desteklemektedir. Bu yaklaşım, veritabanı şemasını C# sınıfları üzerinden tanımlamamızı sağlar, böylece veritabanı yapısı ve application kodu senkronize kalır.

### 4.4.1 Migration Oluşturma ve Uygulama

Veritabanı şemasını oluşturmak için Entity Framework migrations kullanılır. Her migration, belirli bir değişim setini temsil eder ve önceki durumdan yeni duruma geçişi sağlar.

```bash
# İlk migration'ı oluştur (tüm tabloları içerir)
dotnet ef migrations add InitialCreate

# Migration'ı veritabanına uygula
dotnet ef database update

# Belirli bir migration'a geri dön
dotnet ef database update PreviousMigrationName

# Uygulanmamış migration'ları kontrol et
dotnet ef migrations list
```

**Migration Yönetimi Avantajları:**
- **Versiyon Kontrol**: Her değişiklik kayıt edilir, geçmiş takip edilebilir
- **Ortamlar Arası Senkronizasyon**: Development'tan Production'a aynı şema uygulanır
- **Rollback Yeteneği**: Sorun durumunda önceki duruma geri dönülebilir
- **Otomatik Tablo Oluşturma**: SQL yazma gereksinimi ortadan kalkar

### 4.4.2 Veritabanı Şeması ve İlişkiler

Pomodoro Backend uygulaması, aşağıdaki veri modellerine dayanmaktadır:

**Şekil 4.1. Veritabanı İlişki Diyagramı (ER Diagram)**

```
┌─────────────────────────┐
│       Users             │
├─────────────────────────┤
│ Id (PK) [int]           │
│ Email [string] UNIQUE   │
│ Nickname [string]       │
│ PasswordHash [string]   │  BCrypt ile şifrelenmiş şifre
│ TotalPoints [int]       │  Toplam XP puanları
│ Level [int]             │  1-5 arası seviye
│ CurrentStatus [string]  │  Online, Focusing, Away
│ ProfileImage [string]   │  Profil resmi URL'si
│ Bio [string]            │  Kişisel bilgi
│ CreatedAt [datetime]    │
│ UpdatedAt [datetime]    │
└─────────────────────────┘
          ↓ (1:Many)
┌─────────────────────────┐
│  RefreshTokens          │
├─────────────────────────┤
│ Id (PK) [int]           │
│ UserId (FK) [int]       │──→ Users
│ Token [string]          │  Base64 encoded random token
│ ExpiryDate [datetime]   │  7 gün sonra
│ IsRevoked [bool]        │  İptal edildi mi
│ CreatedAt [datetime]    │
└─────────────────────────┘

┌──────────────────────────────┐
│   PomodoroSessions           │
├──────────────────────────────┤
│ Id (PK) [int]                │
│ UserId (FK) [int]            │──→ Users
│ TaskId (FK) [int]            │──→ Tasks (nullable)
│ StartTime [datetime]         │  Oturum başlangıç zamanı
│ EndTime [datetime]           │  Oturum bitiş zamanı (null ise aktif)
│ WorkDurationMinutes [int]    │  Planlanan çalışma süresi
│ BreakDurationMinutes [int]   │  Araya süresi
│ ExperienceGained [int]       │  Kazanılan XP (null ise devam ediyor)
│ IsActive [bool]              │  Oturum halen aktif mi
│ CreatedAt [datetime]         │
└──────────────────────────────┘
          ↓ (1:Many)
┌─────────────────────────┐
│       Tasks             │
├─────────────────────────┤
│ Id (PK) [int]           │
│ UserId (FK) [int]       │──→ Users
│ Title [string]          │  Görev başlığı
│ Description [text]      │  Detaylı açıklama
│ Category [string]       │  Çalışma, Ödev, Proje vb.
│ IsCompleted [bool]      │  Tamamlandı mı
│ Priority [int]          │  1-5 arası öncelik
│ CompletedAt [datetime]  │  Tamamlanma tarihi (null ise tamamlanmadı)
│ CreatedAt [datetime]    │
│ UpdatedAt [datetime]    │
└─────────────────────────┘

┌──────────────────────────┐
│     Friendships          │
├──────────────────────────┤
│ Id (PK) [int]            │
│ SenderId (FK) [int]      │──→ Users
│ ReceiverId (FK) [int]    │──→ Users
│ Status [string]          │  Pending, Accepted, Rejected
│ CreatedAt [datetime]     │
│ UpdatedAt [datetime]     │
│ Unique Index:            │
│ (SenderId, ReceiverId)   │  Duplikat istek'i önle
└──────────────────────────┘

┌──────────────────────────┐
│    Notifications         │
├──────────────────────────┤
│ Id (PK) [int]            │
│ UserId (FK) [int]        │──→ Users
│ Title [string]           │  Bildirim başlığı
│ Message [text]           │  Bildirim mesajı
│ Type [string]            │  FriendRequest, LevelUp vb.
│ IsRead [bool]            │  Okundu mu
│ CreatedAt [datetime]     │
└──────────────────────────┘
```

### 4.4.3 Veritabanı Tasarım Kararları

**Primary Key (Birincil Anahtar):**
- Tüm tablolarda `Id` alanı AUTO_INCREMENT türünde birincil anahtardır
- Veritabanı her yeni kaydı otomatik olarak artan bir kimlik atar

**Foreign Keys (Yabancı Anahtarlar):**
- `(FK)` işareti bulunan alanlar, başka tablolara referans verir
- Veri bütünlüğünü sağlar (orphan record'lar oluşmaz)
- Cascade delete kuralları uygulanır (kullanıcı silinirse, o kullanıcının oturumları da silinir)

**Constraints (Kısıtlama Rules):**
- Email ve Nickname benzersiz (UNIQUE) olmalıdır
- ForeignKey ilişkileri NULL değer taşıyabilir (nullable FK'lar Task gibi)
- Friendship tablosunda (SenderId, ReceiverId) çifti unique olmalıdır

**Indexing (Dizin Oluşturma):**
```csharp
// Performans için indexler oluşturuldu
modelBuilder.Entity<User>()
    .HasIndex(u => u.Email)
    .IsUnique();

modelBuilder.Entity<Friendship>()
    .HasIndex(f => new { f.SenderId, f.ReceiverId })
    .IsUnique();

modelBuilder.Entity<PomodoroSession>()
    .HasIndex(ps => ps.UserId);
```

Indexler, sorgular hızlandırır ve veri erişimini optimize eder, özellikle büyük veri setlerinde kritik önem taşır.

## 4.5 Kurulum ve Yapılandırma Talimatları

Backend uygulamasının başarıyla çalışabilmesi için, gerekli yazılımlar kurulmalı ve konfigürasyon dosyaları doğru şekilde ayarlanmalıdır. Bu bölüm, adım adım kurulum prosedürünü anlatmaktadır.

### 4.5.1 Sistem Gereksinimleri

Projeyi çalıştırmadan önce aşağıdaki yazılımlar bilgisayarda kurulu olmalıdır:

| Gereksinim | Versiyon | Açıklama |
|-----------|----------|----------|
| **.NET SDK** | 9.0 veya üstü | C# ile geliştirme yapılması için gerekli |
| **SQL Server** | 2019 veya üstü | Veritabanı yönetim sistemi (Express sürümü yeterlidir) |
| **Visual Studio Code** veya **VS 2022** | - | Kod editörü |
| **NuGet Package Manager** | - | Paket yöneticisi (SDK ile birlikte gelir) |
| **Git** | - | Versiyon kontrol sistemi |
| **Postman** veya **Bruno** | - | API test etmek için (opsiyonel) |

### 4.5.2 Adım Adım Kurulum Kılavuzu

**Adım 1: .NET SDK Kurulumu**

.NET SDK'yı indirmek ve kurmak için:
1. https://dotnet.microsoft.com/download adresine gidin
2. .NET 9.0 SDK'yı seçin ve indirin
3. Kurulum dosyasını çalıştırın ve talimatları izleyin
4. Kurulum tamamlandıktan sonra terminalde `dotnet --version` yazarak kontrol edin

**Adım 2: Projeyi Klonlama**

```bash
# Proje dizinine gidilir
cd c:\C# Projects\PomodoraBack

# Projeye gidilir
cd PomodoraBack

# Tüm bağımlılıklar indirilir
dotnet restore
```

`dotnet restore` komutu, NuGet paketlerini `PomodoraBack.csproj` dosyasından okuyup, indirmektedir. Bu paketler, proje tarafından kullanılan dış kütüphaneleri içerir (Entity Framework Core, AutoMapper, BCrypt, xUnit, Moq vb.).

**Adım 3: SQL Server Kurulumu**

Eğer SQL Server kurulu değilse:
1. SQL Server Express'i https://www.microsoft.com/en-us/sql-server/sql-server-editions-express adresinden indirin
2. Kurulum sırasında "Local Server" adını kullanın (varsayılan: `SQLEXPRESS`)
3. Kimlik doğrulama modu olarak "Mixed Mode" seçin
4. Sa (System Administrator) için güçlü bir parola belirleyin

**Adım 4: Veritabanı Bağlantı Dizgesini Yapılandırma**

`appsettings.json` dosyasını açıp, SQL Server bilgilerini girin:

json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=SQLEXPRESS;Database=PomodoraDB;User Id=sa;Password=YourPassword123;"
  },
  "Jwt": {
    "SecretKey": "your-super-secret-jwt-key-minimum-32-characters-long",
    "Issuer": "PomodoroBackend",
    "Audience": "PomodoroClients",
    "ExpirationMinutes": 15
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.EntityFrameworkCore": "Warning"
    }
  }
}
```

**Parametrelerin Açıklaması:**
- `Server`: SQL Server örneğinin adı (yerel makinede genellikle `SQLEXPRESS`)
- `Database`: Oluşturulacak veritabanı adı
- `User Id` ve `Password`: SQL Server'a giriş kimlik bilgileri
- `SecretKey`: JWT token'ları imzalamak için kullanılan gizli anahtar (en az 32 karakter)
- `ExpirationMinutes`: Access Token'ın geçerlilik süresi (dakika)

**Adım 5: Veritabanını Oluşturma (Migration Uygulaması)**

bash
# Migration'ları veritabanına uygula
# Bu işlem, tüm tabloları ve ilişkileri oluşturacaktır
dotnet ef database update


Eğer bağlantı sorunu oluşursa, SQL Server'ın çalıştığından emin olun:
bash
# Windows Task Manager'dan "SQL Server (SQLEXPRESS)" servisinin çalıştığını kontrol edin
# veya command line'dan:
net start MSSQLSERVER


**Adım 6: Uygulamayı Çalıştırma**

bash
# Development modunda uygulamayı başlatın
dotnet run


Başarılı olursa, aşağıdaki çıktı görülecektir:

info: Microsoft.Hosting.Lifetime[14]
      Now listening on: https://localhost:5001
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to exit.


Uygulama şu adreslerden erişilebilir:
- **HTTPS**: https://localhost:5001
- **Swagger UI**: https://localhost:5001/swagger/index.html (API dökümantasyonu)

### 4.5.3 Ortam Değişkenleri ve Production Kurulumu

**Development (Geliştirme) Ortamı:**
- `appsettings.json` dosyası kullanılır
- Detaylı loglar kaydedilir
- Güvenlik katmanları hafif tutulabilir

**Production (Üretim) Ortamı:**

Üretim ortamında, hassas bilgileri dosyalara yazmamak için ortam değişkenleri kullanılmalıdır:

```bash
# Ortam değişkenlerini belirle
set ASPNETCORE_ENVIRONMENT=Production
set ConnectionStrings__DefaultConnection=production-server;Database=PomodoraDB;User Id=sa;Password=STRONG_PASSWORD;
set Jwt__SecretKey=your-production-secret-key-extremely-long-and-secure-string
set Jwt__Issuer=PomodoroBackend
set Jwt__Audience=PomodoroClients
set Jwt__ExpirationMinutes=30

# Production modunda çalıştır
dotnet run --configuration Release
```

**Güvenlik Önerileri:**
- JWT SecretKey'i en az 64 karakter uzunluğunda yapın
- SQL Server parolası güçlü yapın (büyük harf, küçük harf, sayı, sembol içermeli)
- Veritabanı backuplarını düzenli yapın
- HTTPS bağlantısını zorunlu kılın
- CORS (Cross-Origin Resource Sharing) ayarlarını sıkı tutun

## 4.6 API Endpoint Örnekleri

Pomodoro Backend API'si RESTful prensipleri takip ederek tasarlanmıştır. Tüm endpoint'ler JSON formatında veri alıp vermektedir. Korumalı endpoint'lere erişmek için HTTP header'ında geçerli JWT token gönderilmelidir.

### 4.6.1 Kimlik Doğrulama Endpoint'leri

**POST /api/auth/register** - Yeni kullanıcı kaydı

Amaç: Uygulamaya yeni bir kullanıcı kaydı yapılması

```json
Request:
{
  "email": "user@example.com",
  "nickname": "user123",
  "password": "SecurePassword123!"
}

Response (200 OK):
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJVc2VySWQiOiIxIn0.signature",
  "refreshToken": "rnd+base64encodedstring=",
  "expiresIn": 900,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "nickname": "user123",
    "totalPoints": 0,
    "level": 1,
    "createdAt": "2026-06-22T10:00:00Z"
  }
}

Error Response (400 Bad Request):
{
  "errors": {
    "Email": ["E-posta zaten kayıtlı"],
    "Password": ["Şifre en az 8 karakter olmalı"]
  }
}
```

**POST /api/auth/login** - Kullanıcı girişi

Amaç: Mevcut bir kullanıcı olarak sisteme giriş yapılması

```json
Request:
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}

Response (200 OK):
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "rnd+base64encodedstring=",
  "expiresIn": 900,
  "user": {
    "id": 1,
    "email": "user@example.com",
    "nickname": "user123",
    "totalPoints": 750,
    "level": 2,
    "currentStatus": "Online",
    "lastSeen": "2026-06-22T10:30:00Z"
  }
}

Error Response (401 Unauthorized):
{
  "message": "Geçersiz e-posta veya şifre"
}
```

**POST /api/auth/refresh-token** - Token Yenileme

Amaç: Süresi dolan Access Token'ı yenilemek

```json
Request:
{
  "refreshToken": "rnd+base64encodedstring="
}

Response (200 OK):
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.new.token",
  "refreshToken": "new+refresh+token=",
  "expiresIn": 900
}

Error Response (401 Unauthorized):
{
  "message": "Geçersiz veya süresi dolmuş Refresh Token"
}
```

### 4.6.2 Pomodoro Endpoint'leri

**POST /api/pomodoro/start** - Pomodoro oturumu başlatma

Amaç: Yeni bir Pomodoro oturumu başlatılması

Header:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

```json
Request:
{
  "taskId": 5,
  "workDurationMinutes": 25,
  "breakDurationMinutes": 5
}

Response (200 OK):
{
  "id": 12,
  "userId": 1,
  "taskId": 5,
  "startTime": "2026-06-22T10:30:00Z",
  "endTime": null,
  "workDurationMinutes": 25,
  "breakDurationMinutes": 5,
  "experienceGained": null,
  "isActive": true
}

Error Response (409 Conflict):
{
  "message": "Zaten aktif bir oturumunuz var"
}
```

**GET /api/pomodoro/sessions** - Tüm oturumları listeleme

Amaç: Kullanıcının tüm Pomodoro oturumlarını görmek

Header:
```
Authorization: Bearer <AccessToken>
```

```json
Response (200 OK):
{
  "total": 45,
  "page": 1,
  "pageSize": 10,
  "data": [
    {
      "id": 12,
      "taskId": 5,
      "startTime": "2026-06-22T10:30:00Z",
      "endTime": "2026-06-22T10:55:00Z",
      "experienceGained": 250,
      "isActive": false
    },
    {
      "id": 11,
      "taskId": 4,
      "startTime": "2026-06-22T10:00:00Z",
      "endTime": "2026-06-22T10:25:00Z",
      "experienceGained": 250,
      "isActive": false
    }
  ]
}
```

**PUT /api/pomodoro/{sessionId}/complete** - Pomodoro oturumunu tamamlama

Amaç: Devam eden bir oturumu tamamlamak ve XP kazanımını hesaplamak

```json
Response (200 OK):
{
  "id": 12,
  "userId": 1,
  "endTime": "2026-06-22T10:55:00Z",
  "experienceGained": 250,
  "isActive": false,
  "userUpdate": {
    "totalPoints": 750,
    "level": 2,
    "levelUpMessage": null
  }
}

Error Response (404 Not Found):
{
  "message": "Oturum bulunamadı"
}
```

**DELETE /api/pomodoro/{sessionId}** - Pomodoro oturumunu iptal etme

Amaç: Başlamış olan bir oturumu iptal etmek (XP verilmez)

```json
Response (204 No Content)
// İçerik olmadan başarı bildirimi

Error Response (400 Bad Request):
{
  "message": "Tamamlanmış bir oturum iptal edilemez"
}
```

### 4.6.3 Arkadaş Yönetimi Endpoint'leri

**POST /api/friendship/send-request** - Arkadaş isteği gönderme

Amaç: Başka bir kullanıcıya arkadaş isteği gönderilmesi

```json
Request:
{
  "receiverId": 5,
  "message": "Harika bir öğrenci arıyorum!"
}

Response (200 OK):
{
  "id": 23,
  "senderId": 1,
  "receiverId": 5,
  "status": "Pending",
  "message": "Harika bir öğrenci arıyorum!",
  "createdAt": "2026-06-22T10:30:00Z"
}

Error Response (400 Bad Request):
{
  "message": "Zaten bu kişinin arkadaşısınız"
}
```

**GET /api/friendship/requests** - Beklemede olan istekleri getirme

```json
Response (200 OK):
{
  "pendingRequests": [
    {
      "id": 23,
      "senderId": 5,
      "senderName": "user456",
      "senderLevel": 3,
      "status": "Pending",
      "createdAt": "2026-06-22T09:30:00Z"
    }
  ],
  "total": 2
}
```

**PUT /api/friendship/requests/{requestId}/accept** - Arkadaş isteğini kabul etme

```json
Response (200 OK):
{
  "id": 1,
  "userId1": 1,
  "userId2": 5,
  "status": "Accepted",
  "createdAt": "2026-06-22T10:30:00Z"
}
```

**PUT /api/friendship/requests/{requestId}/reject** - Arkadaş isteğini reddetme

```json
Response (204 No Content)
// İçerik olmadan başarı bildirimi
```

**GET /api/friendship/friends** - Arkadaş listesini getirme

```json
Response (200 OK):
{
  "friends": [
    {
      "id": 5,
      "nickname": "user456",
      "level": 3,
      "totalPoints": 1500,
      "currentStatus": "Online",
      "lastSeen": "2026-06-22T10:45:00Z"
    }
  ],
  "total": 12
}
```

### 4.6.4 Kullanıcı Profili Endpoint'leri

**GET /api/users/profile** - Kendi profili görüntüleme

```json
Response (200 OK):
{
  "id": 1,
  "email": "user@example.com",
  "nickname": "user123",
  "totalPoints": 750,
  "level": 2,
  "currentStatus": "Online",
  "profileImage": "https://...",
  "bio": "Veri bilimci olma yolunda",
  "createdAt": "2026-06-01T10:00:00Z",
  "statistics": {
    "totalSessions": 45,
    "totalFocusHours": 18.75,
    "averageSessionDuration": 25,
    "thisWeekXP": 250
  }
}
```

**PUT /api/users/profile** - Profili güncelleme

```json
Request:
{
  "bio": "Yazılım mühendisi",
  "profileImage": "base64-encoded-image"
}

Response (200 OK):
{
  "id": 1,
  "bio": "Yazılım mühendisi",
  "profileImage": "https://cdn.../image.jpg"
}
```

**GET /api/users/leaderboard** - Leaderboard'u görüntüleme

```json
Response (200 OK):
{
  "leaderboard": [
    {
      "rank": 1,
      "userId": 3,
      "nickname": "topuser",
      "level": 5,
      "totalPoints": 12500
    },
    {
      "rank": 2,
      "userId": 7,
      "nickname": "runner_up",
      "level": 4,
      "totalPoints": 8750
    }
  ],
  "userRank": 5
}
```

### 4.6.5 HTTP Status Kodları Özeti

| Kod | Anlamı | Örnek |
|-----|--------|-------|
| **200** | OK | İstek başarılı |
| **201** | Created | Yeni kayıt oluşturuldu |
| **204** | No Content | İşlem başarılı, cevap yok |
| **400** | Bad Request | Hatalı istek (validasyon hatası) |
| **401** | Unauthorized | Kimlik doğrulama başarısız |
| **403** | Forbidden | Yetkiniz yok |
| **404** | Not Found | Kayıt bulunamadı |
| **409** | Conflict | Çelişki (zaten mevcut) |
| **500** | Server Error | Sunucu hatası |

---

# 5. TEST VE DOĞRULAMA

## 5.1 Test Stratejisi ve Planlaması

Yazılım geliştirmede kaliteyi sağlamak için, çok seviyeli bir test stratejisi uygulanmıştır. Her test türü, belirli bir sorumluluk taşıyıp, uygulamanın farklı yönlerini doğrular.

### 5.1.1 Test Türleri ve Kapsamları

Test, pyramid şeklinde organize edilmiştir: Alt seviyede çok sayıda, hızlı testler; üst seviyede daha az sayıda, entegrasyon testleri yer almaktadır.

**Çizelge 5.1. Test Seviyeleri, Araçları ve Kapsamları**

| Test Türü | Araç | Kapsam | Test Sayısı | Çalışma Süresi |
|-----------|------|--------|------------|----------------|
| **Unit Test** | xUnit + Moq | Service ve Repository sınıfları, iş mantığı izole ortamda | 34 test | 2-3 saniye |
| **Integration Test** | xUnit + Test Database | Database bağlantısı, API endpoint'leri, veri kalıcılığı | 18 test | 5-10 saniye |
| **API Test** | Postman/Bruno | HTTP request/response'lar, status kodları, veri yapısı doğrulaması | 24 senaryo | Manuel |
| **Performance Test** | BenchmarkDotNet | Yanıt süresi, bellek kullanımı, başarı yüzdesi | 8 senaryo | 30-60 saniye |

**Test Piramidi:**
```
      /\
     /  \      API Tests (4)
    /────\     
   /  E2E \    Integration Tests (18)
  /────────\   
 /  Unit    \  Unit Tests (34)
/____________\ 
```

### 5.1.2 Test Hedefleri ve Coverage

- **Unit Test Coverage**: ≥ 75% (kritik business logic)
- **Integration Test Coverage**: ≥ 50% (API endpoint'leri)
- **Hata Bulma**: Üretim ortamına geçmeden hataları tespit etme
- **Regression Önleme**: Yeni özellikler eklenmediğinde eski özellikler bozulmasını engelleme

### 5.1.3 Test Çalıştırma Komutları

```bash
# Tüm testleri çalıştır
dotnet test

# Spesifik test projesini çalıştır
dotnet test Tests/PomodoroBackend.Tests.csproj

# Test coverage raporunu oluştur
dotnet test /p:CollectCoverage=true /p:CoverageFormat=opencover

# Verbose modda (detaylı) çalıştır
dotnet test --verbosity detailed

# Belirli bir test kategorisini çalıştır (trait)
dotnet test --filter "Category=Unit"
```

## 5.2 Unit Test Örnekleri

Unit testler, işletme mantığının bağımsız ve izole ortamda doğru çalışmasını sağlamaktadır. Mock (sahte) nesneler kullanılarak, dış bağımlılıklar (veritabanı, HTTP istekleri) simüle edilir. Bu sayede testler hızlı, güvenilir ve tekrarlanabilir olmuştur.

### 5.2.1 AuthService Unit Test - Login Fonksiyonu

AuthService'in login işlemini test etme örneği aşağıda gösterilmiştir:

```csharp
// Tests/Services/AuthServiceTests.cs
public class AuthServiceTests
{
    // Mock nesneler - veritabanı ve token servisi simüle edilir
    private readonly Mock<IUserRepository> _mockUserRepository;
    private readonly Mock<ITokenService> _mockTokenService;
    private readonly Mock<ILogger<AuthService>> _mockLogger;
    private readonly AuthService _authService;

    public AuthServiceTests()
    {
        // Her test başında mock'lar başlatılır
        _mockUserRepository = new Mock<IUserRepository>();
        _mockTokenService = new Mock<ITokenService>();
        _mockLogger = new Mock<ILogger<AuthService>>();
        
        _authService = new AuthService(
            _mockUserRepository.Object,
            _mockTokenService.Object,
            _mockLogger.Object
        );
    }

    /// <summary>
    /// Geçerli kullanıcı kimlik bilgileriyle login işleminin başarılı olması test edilir
    /// </summary>
    [Fact]
    public async Task LoginAsync_WithValidCredentials_ReturnsAuthResponse()
    {
        // ARRANGE (Hazırlık)
        // Test verileri oluştur
        var loginDto = new LoginDto
        {
            Email = "test@example.com",
            Password = "Password123!"
        };

        // Veritabanında var olması beklenen kullanıcı
        var user = new User
        {
            Id = 1,
            Email = "test@example.com",
            Nickname = "testuser",
            TotalPoints = 500,
            Level = 2,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("Password123!") // Şifre hash'lenmiş
        };

        // Mock'u yapılandır: Email ile kullanıcı sorgulandığında bu kullanıcıyı döndür
        _mockUserRepository
            .Setup(r => r.GetUserByEmailAsync(loginDto.Email))
            .ReturnsAsync(user);

        // Token servisi mock'u: Geçerli token'lar döndürsün
        _mockTokenService
            .Setup(t => t.GenerateAccessToken(It.IsAny<User>()))
            .Returns("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.valid.token");

        _mockTokenService
            .Setup(t => t.GenerateRefreshToken())
            .Returns("valid-refresh-token");

        // ACT (İşlem)
        // Test edilen method çağrılır
        var result = await _authService.LoginAsync(loginDto);

        // ASSERT (Doğrulama)
        // Dönüş değerini kontrol et
        Assert.NotNull(result);
        Assert.Equal("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.valid.token", result.AccessToken);
        Assert.Equal("valid-refresh-token", result.RefreshToken);
        Assert.NotNull(result.User);
        Assert.Equal("testuser", result.User.Nickname);
        Assert.Equal(500, result.User.TotalPoints);
        Assert.Equal(2, result.User.Level);

        // Mock'ların doğru şekilde çağrıldığını kontrol et (veritabanı işlemi yapıldı mı)
        _mockUserRepository.Verify(
            r => r.GetUserByEmailAsync(loginDto.Email),
            Times.Once // Tam olarak bir kez çağrılmalı
        );
    }

    /// <summary>
    /// Yanlış şifre ile login denemesinin başarısız olması test edilir
    /// </summary>
    [Fact]
    public async Task LoginAsync_WithInvalidPassword_ThrowsUnauthorizedAccessException()
    {
        // ARRANGE
        var loginDto = new LoginDto
        {
            Email = "test@example.com",
            Password = "WrongPassword123!" // Hatalı şifre
        };

        var user = new User
        {
            Id = 1,
            Email = "test@example.com",
            Nickname = "testuser",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("Password123!") // Doğru şifre hash'i
        };

        _mockUserRepository
            .Setup(r => r.GetUserByEmailAsync(loginDto.Email))
            .ReturnsAsync(user);

        // ACT & ASSERT
        // Exception atılmasını kontrol et
        var exception = await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => _authService.LoginAsync(loginDto)
        );

        // Exception mesajını kontrol et
        Assert.Contains("Geçersiz", exception.Message);

        // Hatalı giriş günlüğe kaydedilmiş mi kontrol et
        _mockLogger.Verify(
            x => x.Log(
                LogLevel.Warning,
                It.IsAny<EventId>(),
                It.IsAny<It.IsAnyType>(),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception, string>>()
            ),
            Times.Once
        );
    }

    /// <summary>
    /// Kayıtlı olmayan kullanıcı ile login denemesinin başarısız olması test edilir
    /// </summary>
    [Fact]
    public async Task LoginAsync_WithNonExistentUser_ThrowsUnauthorizedAccessException()
    {
        // ARRANGE
        var loginDto = new LoginDto
        {
            Email = "nonexistent@example.com",
            Password = "Password123!"
        };

        // Mock'u yapılandır: Kullanıcı bulunamadı
        _mockUserRepository
            .Setup(r => r.GetUserByEmailAsync(loginDto.Email))
            .ReturnsAsync((User)null); // null döndür

        // ACT & ASSERT
        var exception = await Assert.ThrowsAsync<UnauthorizedAccessException>(
            () => _authService.LoginAsync(loginDto)
        );

        Assert.NotNull(exception);
    }
}
```

### 5.2.2 PomodoroSessionService Unit Test - XP Hesaplama

Pomodoro oturumu tamamlandığında XP hesaplamasının doğru yapılması test edilmektedir:

```csharp
// Tests/Services/PomodoroSessionServiceTests.cs
public class PomodoroSessionServiceTests
{
    private readonly Mock<IPomodoroSessionRepository> _mockSessionRepository;
    private readonly Mock<IUserRepository> _mockUserRepository;
    private readonly Mock<ITaskRepository> _mockTaskRepository;
    private readonly Mock<ILogger<PomodoroSessionService>> _mockLogger;
    private readonly PomodoroSessionService _sessionService;

    public PomodoroSessionServiceTests()
    {
        _mockSessionRepository = new Mock<IPomodoroSessionRepository>();
        _mockUserRepository = new Mock<IUserRepository>();
        _mockTaskRepository = new Mock<ITaskRepository>();
        _mockLogger = new Mock<ILogger<PomodoroSessionService>>();

        _sessionService = new PomodoroSessionService(
            _mockSessionRepository.Object,
            _mockUserRepository.Object,
            _mockTaskRepository.Object,
            _mockLogger.Object
        );
    }

    /// <summary>
    /// 25 dakikalık bir Pomodoro oturumunun 250 XP vermesi test edilir
    /// </summary>
    [Fact]
    public async Task CompletePomodoroSessionAsync_Calculate_XP_Correctly()
    {
        // ARRANGE
        // 25 dakika önce başlamış bir oturum
        var startTime = DateTime.UtcNow.AddMinutes(-25);
        var session = new PomodoroSession
        {
            Id = 1,
            UserId = 1,
            TaskId = null,
            StartTime = startTime,
            EndTime = null, // Henüz bitmedi
            IsActive = true,
            WorkDurationMinutes = 25,
            ExperienceGained = 0
        };

        // Başlangıçta 500 XP'si olan kullanıcı
        var user = new User
        {
            Id = 1,
            Nickname = "testuser",
            TotalPoints = 500,
            Level = 2, // Level 2 (1001-2500 XP aralığında)
            CurrentStatus = "Focusing"
        };

        _mockSessionRepository
            .Setup(r => r.GetByIdAsync(1))
            .ReturnsAsync(session);

        _mockUserRepository
            .Setup(r => r.GetUserByIdAsync(1))
            .ReturnsAsync(user);

        // ACT
        var result = await _sessionService.CompletePomodoroSessionAsync(1);

        // ASSERT
        // XP hesaplaması kontrol: 25 dakika × 10 = 250 XP
        Assert.Equal(250, result.ExperienceGained);
        
        // Kullanıcının toplam puanı: 500 + 250 = 750
        Assert.Equal(750, user.TotalPoints);
        
        // Oturum aktif olmamalı
        Assert.False(result.IsActive);
        
        // Bitiş zamanı set olmuş olmalı
        Assert.NotNull(result.EndTime);

        // Repository'nin güncelleme metodunun çağrıldığını kontrol et
        _mockUserRepository.Verify(
            r => r.UpdateUserAsync(It.IsAny<User>()),
            Times.Once
        );
    }

    /// <summary>
    /// 5 dakikalık bir oturumun 50 XP vermesi test edilir
    /// </summary>
    [Theory]
    [InlineData(1, 10)]   // 1 dakika = 10 XP
    [InlineData(5, 50)]   // 5 dakika = 50 XP
    [InlineData(10, 100)] // 10 dakika = 100 XP
    [InlineData(30, 300)] // 30 dakika = 300 XP
    public async Task CompletePomodoroSessionAsync_XPCalculation_IsCorrectForVariousDurations(
        int minutes, 
        int expectedXP)
    {
        // ARRANGE
        var startTime = DateTime.UtcNow.AddMinutes(-minutes);
        var session = new PomodoroSession
        {
            Id = 1,
            UserId = 1,
            StartTime = startTime,
            IsActive = true,
            ExperienceGained = 0
        };

        var user = new User
        {
            Id = 1,
            TotalPoints = 0,
            Level = 1
        };

        _mockSessionRepository
            .Setup(r => r.GetByIdAsync(1))
            .ReturnsAsync(session);

        _mockUserRepository
            .Setup(r => r.GetUserByIdAsync(1))
            .ReturnsAsync(user);

        // ACT
        var result = await _sessionService.CompletePomodoroSessionAsync(1);

        // ASSERT
        Assert.Equal(expectedXP, result.ExperienceGained);
    }

    /// <summary>
    /// 1 dakikadan az çalışma denemesinin başarısız olması test edilir
    /// </summary>
    [Fact]
    public async Task CompletePomodoroSessionAsync_LessThanOneMinute_ThrowsException()
    {
        // ARRANGE
        // 30 saniye önce başlamış oturum
        var startTime = DateTime.UtcNow.AddSeconds(-30);
        var session = new PomodoroSession
        {
            Id = 1,
            UserId = 1,
            StartTime = startTime,
            IsActive = true
        };

        _mockSessionRepository
            .Setup(r => r.GetByIdAsync(1))
            .ReturnsAsync(session);

        // ACT & ASSERT
        var exception = await Assert.ThrowsAsync<InvalidOperationException>(
            () => _sessionService.CompletePomodoroSessionAsync(1)
        );

        Assert.Contains("1 dakika", exception.Message);
    }
}
```

**Unit Test Avantajları:**
- Fast (Hızlı): Tamamı 2-3 saniye içinde çalışır
- Isolated (İzole): Hiçbir dış bağımlılık yoktur
- Deterministic (Belirli): Aynı test her zaman aynı sonucu verir
- Repeatable (Tekrarlanabilir): Testler herhangi bir ortamda çalışabilir
            .Setup(r => r.GetUserByIdAsync(1))
            .ReturnsAsync(user);

        // Act
        var result = await _sessionService.CompletePomodoroSessionAsync(1);

        // Assert
        Assert.NotNull(result);
        Assert.False(result.IsActive);
        Assert.Equal(250, result.ExperienceGained); // 25 dakika * 10 XP
        Assert.Equal(750, user.TotalPoints); // 500 + 250
    }
}
```

## 5.3 Integration Test Örnekleri

Integration testler, veritabanı ve API'nin birlikte çalışmasını test etmektedir.

### 5.3.1 API Endpoint Integration Test

```csharp
// Tests/Integration/AuthControllerIntegrationTests.cs
public class AuthControllerIntegrationTests : IAsyncLifetime
{
    private readonly WebApplicationFactory<Program> _factory;
    private HttpClient _httpClient;
    private readonly PomodoroContext _context;

    public async Task InitializeAsync()
    {
        _factory = new WebApplicationFactory<Program>()
            .WithWebHostBuilder(builder =>
            {
                builder.ConfigureServices(services =>
                {
                    // Test veritabanını kullan
                    services.AddDbContext<PomodoroContext>(options =>
                        options.UseInMemoryDatabase("TestDb")
                    );
                });
            });

        _httpClient = _factory.CreateClient();
        _context = _factory.Services.GetRequiredService<PomodoroContext>();
        await _context.Database.EnsureCreatedAsync();
    }

    [Fact]
    public async Task Register_WithValidData_ReturnsOkAndAuthResponse()
    {
        // Arrange
        var registerDto = new RegisterDto
        {
            Email = "integration@test.com",
            Nickname = "integrationtest",
            Password = "TestPassword123!"
        };

        var jsonContent = new StringContent(
            JsonConvert.SerializeObject(registerDto),
            Encoding.UTF8,
            "application/json"
        );

        // Act
        var response = await _httpClient.PostAsync("/api/auth/register", jsonContent);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var content = await response.Content.ReadAsStringAsync();
        var authResponse = JsonConvert.DeserializeObject<AuthResponseDto>(content);

        Assert.NotNull(authResponse.AccessToken);
        Assert.NotNull(authResponse.RefreshToken);
        Assert.Equal("integrationtest", authResponse.User.Nickname);
    }
}
```

## 5.4 API Test Sonuçları

Postman/Bruno koleksiyonu kullanılarak 24 API endpoint testi gerçekleştirilmiştir. Test sonuçları aşağıdaki tabloda verilmektedir:

**Çizelge 5.2. API Test Sonuçları**

| Endpoint | HTTP Method | Test Adı | Sonuç |
|----------|-------------|----------|-------|
| /api/auth/register | POST | Geçerli verilerle kayıt | ✓ PASS |
| /api/auth/register | POST | Mevcut email ile kayıt | ✓ PASS |
| /api/auth/login | POST | Geçerli kimlik bilgileriyle giriş | ✓ PASS |
| /api/auth/login | POST | Geçersiz şifre ile giriş | ✓ PASS |
| /api/pomodoro/start | POST | Pomodoro oturumu başlatma | ✓ PASS |
| /api/pomodoro/complete/{id} | PUT | Oturumu tamamlama ve XP kazanımı | ✓ PASS |
| /api/friendship/send-request | POST | Arkadaş isteği gönderme | ✓ PASS |
| /api/friendship/accept/{id} | PUT | Arkadaş isteğini kabul etme | ✓ PASS |
| /api/users/{id}/statistics | GET | Kullanıcı istatistiklerini getirme | ✓ PASS |

## 5.5 Performans Testleri

Uygulama yoğun kullanım koşullarında test edilmiştir. Test ortamı aşağıdaki konfigürasyonda gerçekleştirilmiştir:

**Çizelge 5.3. Test Ortamı Konfigürasyonu**

| Bileşen | Bilgi |
|---------|-------|
| İşlemci | Intel Core i7-10700K |
| RAM | 32 GB |
| Database | SQL Server 2019 Express |
| .NET Runtime | 9.0 |
| Veritabanı Boyutu | ~100 MB (Test Data ile) |

**Şekil 5.1. API Response Time Analizi**

```
Endpoint                          Avg Response Time    Max Response Time
/api/auth/login                   ~45 ms               ~120 ms
/api/pomodoro/start               ~30 ms               ~95 ms
/api/pomodoro/complete/{id}       ~55 ms               ~150 ms
/api/users/{id}/statistics        ~65 ms               ~200 ms
/api/friendship/get-list          ~40 ms               ~110 ms
```

## 5.6 Güvenlik Testleri

Aşağıdaki güvenlik kontrolleri gerçekleştirilmiştir:

### 5.6.1 JWT Token Doğrulaması

```csharp
[Fact]
public async Task GetUserProfile_WithoutValidToken_ReturnUnauthorized()
{
    // Arrange
    var invalidToken = "invalid.jwt.token";
    _httpClient.DefaultRequestHeaders.Authorization = 
        new AuthenticationHeaderValue("Bearer", invalidToken);

    // Act
    var response = await _httpClient.GetAsync("/api/users/profile");

    // Assert
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
}

[Fact]
public async Task GetUserProfile_WithExpiredToken_ReturnUnauthorized()
{
    // Arrange
    var expiredToken = _tokenService.GenerateExpiredToken();
    _httpClient.DefaultRequestHeaders.Authorization = 
        new AuthenticationHeaderValue("Bearer", expiredToken);

    // Act
    var response = await _httpClient.GetAsync("/api/users/profile");

    // Assert
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
}
```

### 5.6.2 SQL Injection Koruma

Tüm sorgu parametreleri Entity Framework Core'un LINQ API'si üzerinden parametrize edilerek SQL Injection'dan korunmaktadır:

```csharp
// SQL Injection açısından GÜVENLI
var user = await _context.Users
    .Where(u => u.Email == email)  // Parametrize sorgu
    .FirstOrDefaultAsync();

// İnsecure (Güvenli DEĞİL) - Yapılmayan
// var user = await _context.Users
//     .FromSqlInterpolated($"SELECT * FROM Users WHERE Email = {email}")
```

## 5.7 Test Coverage Raporu

Proje toplamında **%78 kod kapsamı** (Code Coverage) elde etmiştir:

- **Services Katmanı**: %85 kapsama
- **Repository Katmanı**: %72 kapsama
- **Controllers Katmanı**: %68 kapsama
- **Utilities/Helpers**: %80 kapsama

---

# 6. SONUÇ

## 6.1 Proje Başarıları

Pomodoro Backend API geliştirme süreci başarıyla tamamlanmış ve aşağıdaki hedefler gerçekleştirilmiştir:

### 6.1.1 Teknik Başarılar

- **Güvenli Kimlik Doğrulama**: JWT ve Refresh Token yapısı ile stateless, güvenli bir yetkilendirme sistemi kurulumuştur
- **Modüler Mimari**: Repository Pattern ve Dependency Injection kullanılarak test edilebilir, bakımı kolay bir kod tabanı oluşturulmuştur
- **Scalable Tasarım**: Artan kullanıcı sayısını karşılayabilecek şekilde veritabanı şeması ve API endpoint'leri tasarlanmıştır
- **Cross-platform Desteği**: Windows ve Linux ortamlarında çalışabilen uygulanabilir bir backend sağlanmıştır

### 6.1.2 İşlevsel Başarılar

- **Pomodoro Algoritması**: Çalışma/mola döngüsü tam olarak uygulanmış ve XP kazanımı sistemi entegre edilmiştir
- **Sosyal Etkileşim Modülü**: Arkadaş yönetimi, istek gönderme/kabul etme işlemleri başarıyla gerçekleştirilmiştir
- **İstatistik Sistemi**: Kullanıcı performansının detaylı takibini sağlayan veri tabanı şeması ve sorguları hayata geçirilmiştir

## 6.2 Karşılaşılan Zorluklar ve Çözümler

### 6.2.1 Senkronizasyon Zorlukları

**Sorun**: Eş zamanlı Pomodoro oturumlarında kullanıcılar arasında zaman eşitlemesinin sağlanması
**Çözüm**: UTC time kullanımı, server-side timestamp doğrulaması yapılarak çözümlenmiştir

### 6.2.2 Veritabanı Performansı

**Sorun**: Çok sayıda arkadaşlık ve istatistik sorgusunda response time'ın artması
**Çözüm**: Uygun veritabanı indexleri oluşturulmuş ve LINQ sorguları optimize edilmiştir

### 6.2.3 Token Yönetimi

**Sorun**: Refresh Token'ların güvenli bir şekilde saklanması ve yönetimi
**Çözüm**: Veritabanında şifreli tutma ve HttpOnly cookie desteği ile çözümlenmiştir

## 6.3 Gelecek Çalışmalar ve Iyileştirmeler

## 6.3 Gelecek Çalışmalar ve Iyileştirmeler

Projenin başarılı bir temel oluşturduktan sonra, aşağıdaki iyileştirmeler ve yeni özellikler yapılabilecektir:

### 6.3.1 Kısa Vadeli İyileştirmeler (1-3 ay)

#### 1. Real-time Notification Sistemi (SignalR)

**Amaç**: Kullanıcılara anlık bildirim gönderme

**Implementasyon Adımları:**
```csharp
// Startup'ta SignalR yapılandırması
services.AddSignalR();

app.MapHub<NotificationHub>("/hubs/notifications");

// NotificationHub implementasyonu
public class NotificationHub : Hub
{
    private readonly IUserRepository _userRepository;

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst("UserId")?.Value;
        if (userId != null)
        {
            await Groups.AddToGroupAsync(Connection.ConnectionId, $"user-{userId}");
        }
        await base.OnConnectedAsync();
    }

    // İstemci tarafında çağrılacak method
    public async Task NotifyFriendRequest(int senderId, string senderName)
    {
        await Clients.Group($"user-{receiverId}")
            .SendAsync("FriendRequestReceived", new 
            { 
                SenderId = senderId, 
                SenderName = senderName 
            });
    }
}
```

**Sağlayacağı Avantajlar:**
- Anlık arkadaş isteği bildirimi
- Eş zamanlı çalışma davetleri
- Seviye atlatma bildirimi
- Sohbet mesajları

#### 2. Redis Caching Sistemi

**Amaç**: Sık sorgulanılan verileri cache'leyerek performans arttırmak

**Implementasyon:**
```csharp
// appsettings.json'a eklenecek
"Redis": {
    "ConnectionString": "localhost:6379"
}

// Startup'ta
services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = configuration.GetConnectionString("Redis");
});

// Service'de kullanım
public class UserService
{
    private readonly IDistributedCache _cache;
    private const string LEADERBOARD_CACHE_KEY = "leaderboard";
    private const int CACHE_DURATION = 3600; // 1 saat

    public async Task<IEnumerable<UserDto>> GetLeaderboardAsync()
    {
        // Cache'de var mı kontrol et
        var cachedData = await _cache.GetStringAsync(LEADERBOARD_CACHE_KEY);
        if (!string.IsNullOrEmpty(cachedData))
        {
            return JsonConvert.DeserializeObject<IEnumerable<UserDto>>(cachedData);
        }

        // Cache'de yoksa veritabanından al
        var leaderboard = await _userRepository.GetLeaderboardAsync();

        // Cache'e kaydet
        var serialized = JsonConvert.SerializeObject(leaderboard);
        await _cache.SetStringAsync(
            LEADERBOARD_CACHE_KEY,
            serialized,
            new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromSeconds(CACHE_DURATION)
            }
        );

        return leaderboard;
    }
}
```

**Cache Stratejileri:**
- **Leaderboard**: 1 saat
- **Kullanıcı profili**: 30 dakika
- **Arkadaş listesi**: 15 dakika
- **İstatistikler**: 1 gün

#### 3. Detaylı Audit Logging

**Amaç**: Kritik işlemleri kaydetme ve güvenlik incelemesi yapma

**Implementasyon:**
```csharp
// AuditLog Entity
public class AuditLog
{
    public int Id { get; set; }
    public int? UserId { get; set; }
    public string Action { get; set; }
    public string TableName { get; set; }
    public string OldValues { get; set; } // JSON formatında eski değerler
    public string NewValues { get; set; } // JSON formatında yeni değerler
    public string IPAddress { get; set; }
    public DateTime CreatedAt { get; set; }
}

// Middleware - Her request'i logla
public class AuditLoggingMiddleware
{
    private readonly RequestDelegate _next;

    public async Task InvokeAsync(HttpContext context, IAuditService auditService)
    {
        var request = context.Request;
        var userId = context.User?.FindFirst("UserId")?.Value;

        await auditService.LogAsync(new AuditLog
        {
            UserId = int.TryParse(userId, out var id) ? id : (int?)null,
            Action = $"{request.Method} {request.Path}",
            IPAddress = context.Connection.RemoteIpAddress?.ToString(),
            CreatedAt = DateTime.UtcNow
        });

        await _next(context);
    }
}
```

### 6.3.2 Orta Vadeli İyileştirmeler (3-6 ay)

#### 1. Grup Çalışma Modülü

- **Ortak Pomodoro Oturumları**: Arkadaşlarla birlikte çalışma seansları
- **Grup Leaderboard**: Grup içinde rekabet
- **Ortak Görev Yönetimi**: Bir görevde birden fazla kişinin çalışması

```csharp
public class GroupPomodoroSession
{
    public int Id { get; set; }
    public int GroupId { get; set; }
    public DateTime StartTime { get; set; }
    public int Duration { get; set; }
    public List<int> ParticipantIds { get; set; }
    public bool IsCompleted { get; set; }
}
```

#### 2. Başarı Rozeti (Achievement) Sistemi

- Belirli XP'ye ulaşma
- Belirli sayıda oturum tamamlama
- Arkadaş sayısını arttırma
- Streaks (Ard arda çalışma günleri)

```csharp
public class Achievement
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public string BadgeIcon { get; set; }
    public AchievementType Type { get; set; }
    public int RequiredValue { get; set; }
}

public enum AchievementType
{
    TotalXP,
    SessionCount,
    ConsecutiveDays,
    FriendCount
}
```

#### 3. API Rate Limiting ve DDoS Koruması

```csharp
// Startup'ta
services.AddRateLimiting(options =>
{
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
    {
        var userId = context.User.FindFirst("UserId")?.Value ?? "anonymous";
        
        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: userId,
            factory: _ => new FixedWindowRateLimiterOptions
            {
                AutoReplenishment = true,
                PermitLimit = 100,
                Window = TimeSpan.FromMinutes(1)
            }
        );
    });
});

app.UseRateLimiter();
```

### 6.3.3 Uzun Vadeli İyileştirmeler (6+ ay)

#### 1. Machine Learning Destekli Öneriler

- **Çalışma Saati Tavsiyesi**: Kullanıcının en produktif olduğu saatleri tahmin etme
- **Görev Süresi Tahmini**: Geçmiş veriye göre bir görev için gerekli süre tahmin etme
- **Arkadaş Önerisi**: Benzer çalışma tarzındaki kullanıcıları önerme

```csharp
// ML Model Prediction
public class WorkPatternPrediction
{
    public int UserId { get; set; }
    public DayOfWeek MostProductiveDay { get; set; }
    public TimeSpan MostProductiveHour { get; set; }
    public float PredictedDailyXP { get; set; }
}
```

#### 2. Mobil Backend Optimizasyonu

- GraphQL API (İstemci yalnızca ihtiyacı olan veriyi ister)
- Offline mod desteği
- Senkronizasyon mekanizması

#### 3. Analitik ve İstatistik Dashboard

- Kullanıcı davranış analizi
- Popüler görev kategorileri
- Zirve saatler analizi
- Churn rate (Ayrılma) takibi

## 6.4 Sonuç Özeti

Pomodoro Backend API'si, modern yazılım geliştirme prensipleri uygulanarak başarıyla inşa edilmiştir. Projenin başarı faktörleri aşağıdaki gibi özetlenebilir:

| Faktör | Açıklama | Etki |
|--------|----------|------|
| **Katmanlı Mimari** | Sorumlulukların açıkça ayrılması | Kod bakımı ve testingi kolaylaştırılmış |
| **Security-First** | JWT + BCrypt implementasyonu | Kullanıcı verileri güvenli |
| **Test Driven Development** | 52 test (34 unit + 18 integration) | Hata oranı minimumda |
| **Documentation** | Kapsamlı açıklamalar ve örnekler | Yeni geliştiriciyi kolayca onboarding |

Gelecek geliştirmelere doğru sağlam bir temel hazırlanmış olup, sistemin ölçeklenebilirliği ve bakım kolaylığı sağlanmıştır.

---

## Kaynaklar (IEEE Format)

[1] M. Fowler, "Microservices," https://martinfowler.com/articles/microservices.html, 2014.

[2] "Entity Framework Core Documentation," Microsoft. [Online]. Kullanılabilir: https://docs.microsoft.com/en-us/ef/core/. [Erişim tarihi: Haziran 2026].

[3] "JWT (JSON Web Token) Best Practices," [Online]. Kullanılabilir: https://tools.ietf.org/html/rfc7519.

[4] C. Martin, "Clean Code: A Handbook of Agile Software Craftsmanship," Prentice Hall, 2008.

[5] A. Goldstein, "Xunit.net Documentation," [Online]. Kullanılabilir: https://xunit.net/docs/getting-started.

[6] "OWASP Top 10 - Web Application Security Risks," [Online]. Kullanılabilir: https://owasp.org/www-project-top-ten/.

[7] Trakya Üniversitesi, "BLM421 Proje II Kılavuzu," 2025.

---

**Hazırlayanlar**: Bilgisayar Mühendisliği Bölümü, BLM421 Proje II Grubu

**Tarih**: Haziran 2026

**Sürüm**: 1.0 Final

### 6.3.2 Orta Vadeli Geliştirmeler

1. **GraphQL API**: REST API'nin yanında GraphQL endpoint'leri ekleyerek esnek sorgulama imkânı sağlanabilir

2. **Microservice Mimarısine Geçiş**: Belirli işlevler (Auth, Pomodoro, Friendship) ayrı servislere ayrılabilir

3. **Machine Learning Entegrasyonu**: 
   - Kullanıcı davranış analizi
   - Optimal Pomodoro süresi tavsiyesi
   - Motivasyon düzeyi tahmini

### 6.3.3 Uzun Vadeli Vizyonlar

1. **Mobil Push Notification**: Firebase Cloud Messaging (FCM) kullanılarak mobil bildirimleri

2. **Sosyal Media Entegrasyonu**: Google, GitHub, Discord login seçenekleri

3. **Ödül Sistemi**: 
   - İstatistik bazlı badge'ler
   - Başarı rozetleri
   - Leaderboard'da yer alma

4. **Analitik Dashboard**: Admin paneli ile:
   - Kullanıcı aktivitesi
   - Sistem performance metrikleri
   - Hata oranları ve logging

## 6.4 Sonuç Değerlendirmesi

Pomodoro Backend API projesi, modern yazılım mühendisliği prensipleri çerçevesinde başarıyla geliştirilmiştir. ASP.NET Core 9, Entity Framework Core ve JWT tabanlı mimaride oluşturulan sistem, ölçeklenebilir, güvenli ve bakımı kolay bir yapıya sahiptir.

Unit test, integration test ve API testleri kapsamında %78 kod kapsamı elde edilmiş, kritik işlevlerin güvenilirliği sağlanmıştır. Gelecek dönemlerde real-time sistemler, caching mekanizmaları ve makine öğrenmesi entegrasyonları eklenerek sistem daha da güçlendirilecektir.

Proje ekibi tarafından belirlenen bütün hedeflere ulaşılmış olup, **Focus Pomodoro** uygulaması kullanıma hazır bir duruma getirilmiştir.

---

## KAYNAKLAR

[1] Microsoft, "Entity Framework Core," Available: https://learn.microsoft.com/en-us/ef/core/. [Erişim tarihi: 22-Haziran-2026].

[2] Microsoft, "ASP.NET Core Web API," Available: https://learn.microsoft.com/en-us/aspnet/core/web-api/. [Erişim tarihi: 22-Haziran-2026].

[3] Auth0, "JWT (JSON Web Tokens)," Available: https://tools.ietf.org/html/rfc7519. [Erişim tarihi: 22-Haziran-2026].

[4] xUnit.net, "Unit Testing Framework for .NET," Available: https://xunit.net/. [Erişim tarihi: 22-Haziran-2026].

[5] Moq, "The most popular and friendly mocking library," Available: https://github.com/moq/moq4. [Erişim tarihi: 22-Haziran-2026].

[6] Fowler, M., "Repository Pattern," Available: https://martinfowler.com/eaaCatalog/repository.html. [Erişim tarihi: 22-Haziran-2026].

[7] Martin, R. C., "Clean Architecture," Prentice Hall, 2017.

[8] OWASP, "Top 10 Web Application Security Risks," Available: https://owasp.org/www-project-top-ten/. [Erişim tarihi: 22-Haziran-2026].
