using AutoMapper;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;

namespace PomodoraBack.Mappings
{
    public class WorkspaceMappingProfile : Profile
    {
        public WorkspaceMappingProfile()
        {
            CreateMap<Workspace, WorkspaceDto>()
                .ForMember(dest => dest.WorkspaceId, opt => opt.MapFrom(src => src.WorkspaceId))
                .ForMember(dest => dest.OwnerNickName, opt => opt.MapFrom(src => src.Owner.Nickname))
                .ForMember(dest => dest.IsActive, opt => opt.MapFrom(src => src.isActive));

            CreateMap<WorkspaceInvitation, WorkspaceInvitationDto>()
                .ForMember(dest => dest.WorkspaceName, opt => opt.MapFrom(src => src.Workspace.WorkspaceName))
                .ForMember(dest => dest.SenderNickName, opt => opt.MapFrom(src => src.Sender.Nickname));
        }
    }
}
