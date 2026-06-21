using AutoMapper;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;

namespace PomodoraBack.Mappings
{
    public class NotificationMappingProfile : Profile
    {
        public NotificationMappingProfile()
        {
            CreateMap<Notification, NotificationDto>();
        }
    }
}
