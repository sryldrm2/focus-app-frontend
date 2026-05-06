using Microsoft.EntityFrameworkCore;
using PomodoraBack.Entities;

namespace PomodoraBack.DataAccess.Context
{
    public class PomodoroContext : DbContext
    {
        public PomodoroContext(DbContextOptions<PomodoroContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<RefreshToken> RefreshTokens { get; set; }
        public DbSet<FriendRequest> FriendRequests { get; set; }
        public DbSet<FriendShip> Friendships { get; set; }
        public DbSet<Entities.Task> Tasks{ get; set; }
        public DbSet <PomodoroSession> PomodoroSessions{ get; set; } 

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                optionsBuilder.UseSqlServer(@"Server=(localdb)\MSSQLLocalDB;Database=PomodoroDB;Trusted_Connection=true");
            }
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.UserId);
                entity.HasIndex(e => e.Email).IsUnique();
                entity.HasIndex(e => e.Nickname).IsUnique();
                
                entity.Property(e => e.TotalPoints)
                    .HasPrecision(18, 2);
            });

            modelBuilder.Entity<RefreshToken>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Token).IsUnique();
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // FriendRequest Configuration
            modelBuilder.Entity<FriendRequest>(entity =>
            {
                entity.HasKey(e => e.FriendRequestId);
                
                // Foreign Key: Consigner (İstek gönderen)
                entity.HasOne(e => e.Consigner)
                    .WithMany()
                    .HasForeignKey(e => e.ConsignerId)
                    .OnDelete(DeleteBehavior.Restrict); // Silme engellemek için
                
                // Foreign Key: Receiver (İstek alan)
                entity.HasOne(e => e.Receiver)
                    .WithMany()
                    .HasForeignKey(e => e.ReceiverId)
                    .OnDelete(DeleteBehavior.Restrict); // Silme engellemek için
                
                // Index
                entity.HasIndex(e => new { e.ConsignerId, e.ReceiverId, e.Status });
            });

            // Friendship Configuration
            modelBuilder.Entity<FriendShip>(entity =>
            {
                entity.HasKey(e => e.FriendShipId);

                // FirstUser
                entity.HasOne(e => e.FirstUser)
                    .WithMany()
                    .HasForeignKey(e => e.FirstUserId)
                    .OnDelete(DeleteBehavior.Restrict);

                // SecondUser
                entity.HasOne(e => e.SecondUser)
                    .WithMany()
                    .HasForeignKey(e => e.SecondUserId)
                    .OnDelete(DeleteBehavior.Restrict);

                // Index: Aynı iki kişi arasında sadece bir friendship olabilir
                entity.HasIndex(e => new { e.FirstUserId, e.SecondUserId }).IsUnique();
            });
            // Task Configuration
            modelBuilder.Entity<Entities.Task>(entity =>
            {
                entity.HasKey(e => e.TaskId);
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Restrict); // Cascade yerine Restrict

                entity.HasIndex(e => new { e.UserId, e.Status });
            });

            // PomodoroSession Configuration
            modelBuilder.Entity<PomodoroSession>(entity =>
            {
                entity.HasKey(e => e.PomoId);

                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Restrict); // Cascade yerine Restrict

                entity.HasOne(e => e.Task)
                    .WithMany()
                    .HasForeignKey(e => e.TaskId)
                    .OnDelete(DeleteBehavior.SetNull);

                entity.HasIndex(e => e.UserId);
                entity.HasIndex(e => new { e.UserId, e.Status, e.StartedAt });
                entity.HasIndex(e => e.TaskId);
            });
        }
    }
}
