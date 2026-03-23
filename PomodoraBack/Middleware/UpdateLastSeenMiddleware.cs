using System.Security.Claims;
using PomodoraBack.DataAccess.Interfaces;

namespace PomodoraBack.Middleware
{
    public class UpdateLastSeenMiddleware
    {
        private readonly RequestDelegate _next;

        public UpdateLastSeenMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context, IUserDal userDal)
        {
            // Eğer kullanıcı authenticated ise
            if (context.User.Identity?.IsAuthenticated == true)
            {
                var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!string.IsNullOrEmpty(userId))
                {
                    try
                    {
                        // Kullanıcıyı bul
                        var user = await userDal.GetAsync(u => u.UserId == userId);
                        
                        if (user != null)
                        {
                            // LastSeen'i güncelle
                            user.LastSeen = DateTime.UtcNow;
                            user.CurrentStatus = true;
                            await userDal.UpdateAsync(user);
                        }
                    }
                    catch
                    {
                        // Hata olursa middleware chain'i kırma, devam et
                    }
                }
            }

            // Sonraki middleware'e devam et
            await _next(context);
        }
    }
}
