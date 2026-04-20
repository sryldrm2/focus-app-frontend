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

// Services
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IFriendRequest, FriendRequestService>();

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
});

builder.Services.AddAuthorization();

builder.Services.AddControllers();

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
            policy.AllowAnyOrigin()
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

app.MapControllers();

app.Run();
