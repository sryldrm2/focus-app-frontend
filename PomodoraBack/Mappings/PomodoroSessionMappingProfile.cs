using AutoMapper;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;

namespace PomodoraBack.Mappings
{
    /// <summary>
    /// Pomodoro Session ve Task entity'lerinin DTO'lara mapping'i
    /// </summary>
    public class PomodoroSessionMappingProfile : Profile
    {
        public PomodoroSessionMappingProfile()
        {
            // ===== PomodoroSession Mappings =====
            
            // PomodoroSession -> PomodoroSessionDto
            CreateMap<PomodoroSession, PomodoroSessionDto>()
                .ForMember(dest => dest.Task, opt => opt.MapFrom(src => src.Task))
                .ForMember(dest => dest.User, opt => opt.MapFrom(src => src.User));

            // CreatePomodoroSessionDto -> PomodoroSession
            CreateMap<CreatePomodoroSessionDto, PomodoroSession>()
                .ForMember(dest => dest.PomoId, opt => opt.Ignore())
                .ForMember(dest => dest.UserId, opt => opt.Ignore()) // Service'de set edilecek
                .ForMember(dest => dest.StartedAt, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.CompletedAt, opt => opt.Ignore())
                .ForMember(dest => dest.DeletedAt, opt => opt.Ignore())
                .ForMember(dest => dest.Status, opt => opt.Ignore())
                .ForMember(dest => dest.PointsEarned, opt => opt.Ignore())
                .ForMember(dest => dest.BreakCount, opt => opt.Ignore())
                .ForMember(dest => dest.User, opt => opt.Ignore())
                .ForMember(dest => dest.Task, opt => opt.Ignore());

            // ===== Task Mappings =====

            // Entities.Task -> TaskDto
            CreateMap<Entities.Task, TaskDto>()
                .ForMember(dest => dest.Description, opt => opt.MapFrom(src => src.Description ?? string.Empty));

            // CreateTaskDto -> Entities.Task
            CreateMap<CreateTaskDto, Entities.Task>()
                .ForMember(dest => dest.TaskId, opt => opt.Ignore())
                .ForMember(dest => dest.UserId, opt => opt.Ignore()) // Service'de set edilecek
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.DeletedAt, opt => opt.Ignore())
                .ForMember(dest => dest.User, opt => opt.Ignore());

            // UpdateTaskDto -> Entities.Task
            CreateMap<UpdateTaskDto, Entities.Task>()
                .ForMember(dest => dest.TaskId, opt => opt.Ignore())
                .ForMember(dest => dest.UserId, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.DeletedAt, opt => opt.Ignore())
                .ForMember(dest => dest.User, opt => opt.Ignore())
                .ForMember(dest => dest.UpdatedAt, opt => opt.Ignore())
                .ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null));
        }
    }
}
