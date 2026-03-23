using AutoMapper;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;

namespace PomodoraBack.Mappings
{
    public class UsersMappingProfile : Profile
    {
        public UsersMappingProfile()
        {
            // User Mappings
            CreateMap<User, UserDto>();

            CreateMap<RegisterDto, User>()
                .ForMember(dest => dest.UserId, opt => opt.Ignore())
                .ForMember(dest => dest.CurrentStatus, opt => opt.Ignore())
                .ForMember(dest => dest.TotalPoints, opt => opt.Ignore())
                .ForMember(dest => dest.LastSeen, opt => opt.Ignore())
                .ForMember(dest => dest.DeletedAt, opt => opt.Ignore());

            CreateMap<UserDto, User>()
                .ForMember(dest => dest.Password, opt => opt.Ignore())
                .ForMember(dest => dest.DeletedAt, opt => opt.Ignore());

            CreateMap<UpdateUserDto, User>()
                .ForMember(dest => dest.UserId, opt => opt.Ignore())
                .ForMember(dest => dest.TotalPoints, opt => opt.Ignore())
                .ForMember(dest => dest.LastSeen, opt => opt.Ignore())
                .ForMember(dest => dest.DeletedAt, opt => opt.Ignore())
                .ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null));

            // FriendRequest Mappings
            CreateMap<FriendRequest, FriendRequestDto>()
                .ForMember(dest => dest.Consigner, opt => opt.MapFrom(src => src.Consigner))
                .ForMember(dest => dest.Receiver, opt => opt.MapFrom(src => src.Receiver));

            CreateMap<SendFriendRequestDto, FriendRequest>()
                .ForMember(dest => dest.FriendRequestId, opt => opt.Ignore())
                .ForMember(dest => dest.ConsignerId, opt => opt.Ignore()) // Service'de set edilecek
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore());

            CreateMap<UpdateFriendRequestDto, FriendRequest>()
                .ForMember(dest => dest.ConsignerId, opt => opt.Ignore())
                .ForMember(dest => dest.ReceiverId, opt => opt.Ignore())
                .ForMember(dest => dest.CreatedAt, opt => opt.Ignore())
                .ForMember(dest => dest.Consigner, opt => opt.Ignore())
                .ForMember(dest => dest.Receiver, opt => opt.Ignore());

            // Friendship Mappings
            CreateMap<FriendShip, FriendshipDto>()
                .ForMember(dest => dest.FirstUser, opt => opt.MapFrom(src => src.FirstUser))
                .ForMember(dest => dest.SecondUser, opt => opt.MapFrom(src => src.SecondUser))
                .ForMember(dest => dest.DeletedAt, opt => opt.MapFrom(src => src.DeletedAt));
        }
    }
}
