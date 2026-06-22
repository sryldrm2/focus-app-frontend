using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using PomodoraBack.Core.Settings;
using PomodoraBack.DataAccess.Concrete;
using PomodoraBack.DataAccess.Context;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.Services.Concrete;
using PomodoraBack.Services.Interfaces;
using PomodoraBack.Services.BackgroundWorkers;
using PomodoraBack.Middleware;

var builder = WebApplication.CreateBuilder(args);

// JWT Settings
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("JwtSettings"));
var jwtSettings = builder.Configuration.GetSection("JwtSettings").Get<JwtSettings>();

// DbContext
builder.Services.AddDbContext<PomodoroContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection") 
        ?? @"Server=(localdb)\MSSQLLocalDB;Database=PomodoroDB;Trusted_Connection=true"));

// AutoMapper
builder.Services.AddAutoMapper(typeof(Program));

// Repositories
builder.Services.AddScoped<IUserDal, UserDal>();
builder.Services.AddScoped<IRefreshTokenDal, RefreshTokenDal>();
builder.Services.AddScoped<IFriendRequestDal, FriendRequestDal>();
builder.Services.AddScoped<IFriendShipDal, FriendShipDal>();
builder.Services.AddScoped<IPomodoroSessionDal, PomodoroSessionDal>();
builder.Services.AddScoped<IPomodoroTaskDal, PomodoroTaskDal>();
builder.Services.AddScoped<IWorkspaceDal, WorkspaceDal>();
builder.Services.AddScoped<IWorkspaceMemberDal, WorkspaceMemberDal>();
builder.Services.AddScoped<IWorkspaceInvitationDal, WorkspaceInvitationDal>();
builder.Services.AddScoped<INotificationDal, NotificationDal>();

// Services
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IFriendRequest, FriendRequestService>();
builder.Services.AddScoped<IPomodoroSessionService, PomodoroSessionService>();
builder.Services.AddScoped<IPomodoroTaskService, PomodoroTaskService>();
builder.Services.AddScoped<IWorkspaceService, WorkspaceService>();
builder.Services.AddScoped<INotificationService, NotificationService>();

// Background Services
builder.Services.AddHostedService<TaskDueDateReminderWorker>();

// JWT Authentication
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings?.Issuer,
        ValidAudience = jwtSettings?.Audience,
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(jwtSettings?.SecretKey ?? "DefaultSecretKey"))
    };

    // SignalR WebSocket/SSE bağlantıları Authorization header taşıyamaz.
    // Frontend ?access_token=<jwt> query string'i ile bağlandığında
    // bu event token'ı alıp Bearer olarak iletir.
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;

            if (!string.IsNullOrEmpty(accessToken) &&
                path.StartsWithSegments("/notificationHub"))
            {
                context.Token = accessToken;
            }

            return System.Threading.Tasks.Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization();

builder.Services.AddControllers();

// SignalR Configuration
builder.Services.AddSignalR(options =>
{
    options.MaximumReceiveMessageSize = 32 * 1024 * 1024; // 32 MB
});

// Swagger/OpenAPI Configuration
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Pomodoro Back API",
        Version = "v1",
        Description = "Pomodoro Technique API with JWT Authentication"
    });
});

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        policy =>
        {
            policy.AllowCredentials()
                  .SetIsOriginAllowed(hostName => true)  // Tüm originlere izin ver
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Pomodoro Back API v1");
    c.RoutePrefix = string.Empty; // Swagger'ı root'ta aç
    c.DocumentTitle = "Pomodoro Back API";
    c.DisplayRequestDuration();
});

app.UseHttpsRedirection();

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

// LastSeen Middleware
app.UseMiddleware<UpdateLastSeenMiddleware>();

app.MapHub<PomodoraBack.Hubs.NotificationHub>("/notificationHub");
app.MapControllers();

app.Run();
