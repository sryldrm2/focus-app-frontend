using AutoMapper;
using Core.Utilities.Results;
using Microsoft.EntityFrameworkCore;
using PomodoraBack.Core.Enums;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;
using PomodoraBack.Services.Interfaces;
using System.Linq;

namespace PomodoraBack.Services.Concrete
{
    public class WorkspaceService : IWorkspaceService
    {
        private const int WorkspaceCapacity = 4;
        private readonly IWorkspaceDal _workspaceDal;
        private readonly IWorkspaceMemberDal _workspaceMemberDal;
        private readonly IWorkspaceInvitationDal _workspaceInvitationDal;
        private readonly IUserDal _userDal;
        private readonly IFriendShipDal _friendshipDal;
        private readonly IMapper _mapper;
        private readonly IWorkspaceRealtimeService _workspaceRealtimeService;

        public WorkspaceService(
            IWorkspaceDal workspaceDal,
            IWorkspaceMemberDal workspaceMemberDal,
            IWorkspaceInvitationDal workspaceInvitationDal,
            IUserDal userDal,
            IFriendShipDal friendshipDal,
            IMapper mapper,
            IWorkspaceRealtimeService workspaceRealtimeService)
        {
            _workspaceDal = workspaceDal;
            _workspaceMemberDal = workspaceMemberDal;
            _workspaceInvitationDal = workspaceInvitationDal;
            _userDal = userDal;
            _friendshipDal = friendshipDal;
            _mapper = mapper;
            _workspaceRealtimeService = workspaceRealtimeService;
        }

        public async Task<IDataResult<WorkspaceDto>> CreateWorkspaceAsync(string ownerId, CreateWorkspaceDto request)
        {
            var owner = await _userDal.GetAsync(u => u.UserId == ownerId);
            if (owner == null)
                return new ErrorDataResult<WorkspaceDto>("Kullanıcı bulunamadı.");

            var workspace = new Workspace
            {
                WorkspaceId = Guid.NewGuid().ToString(),
                OwnerId = ownerId,
                WorkspaceName = request.WorkspaceName,
                CreatedAt = DateTime.UtcNow,
                isActive = true
            };

            await _workspaceDal.AddAsync(workspace);

            var ownerMember = new WorkspaceMember
            {
                WorkspaceId = workspace.WorkspaceId,
                UserId = ownerId,
                JoinedAt = DateTime.UtcNow
            };

            await _workspaceMemberDal.AddAsync(ownerMember);

            var workspaceDto = _mapper.Map<WorkspaceDto>(workspace);
            workspaceDto.MemberCount = 1;
            workspaceDto.OwnerNickName = owner.Nickname;

            return new SuccessDataResult<WorkspaceDto>(workspaceDto, "Oda oluşturuldu.");
        }

        public async Task<IDataResult<WorkspaceInvitationDto>> SendInvitationAsync(string senderId, SendWorkspaceInvitationDto request)
        {
            var sender = await _userDal.GetAsync(u => u.UserId == senderId);
            if (sender == null)
                return new ErrorDataResult<WorkspaceInvitationDto>("Gönderici kullanıcı bulunamadı.");

            if (string.IsNullOrWhiteSpace(request.ReceiverId) && string.IsNullOrWhiteSpace(request.ReceiverNickname))
                return new ErrorDataResult<WorkspaceInvitationDto>("Davet edilecek kullanıcı ID veya nickname ile belirtilmelidir.");

            User? receiver = null;
            if (!string.IsNullOrWhiteSpace(request.ReceiverId))
            {
                receiver = await _userDal.GetAsync(u => u.UserId == request.ReceiverId);
            }
            else if (!string.IsNullOrWhiteSpace(request.ReceiverNickname))
            {
                receiver = await _userDal.GetAsync(u => u.Nickname == request.ReceiverNickname);
            }

            if (receiver == null)
                return new ErrorDataResult<WorkspaceInvitationDto>("Alıcı kullanıcı bulunamadı.");

            var workspace = await _workspaceDal.GetAsync(w => w.WorkspaceId == request.WorkspaceId);
            if (workspace == null)
                return new ErrorDataResult<WorkspaceInvitationDto>("Oda bulunamadı.");

            var isSenderMember = await _workspaceMemberDal.GetAsync(m =>
                m.WorkspaceId == request.WorkspaceId && m.UserId == senderId);

            if (isSenderMember == null)
                return new ErrorDataResult<WorkspaceInvitationDto>("Odaya üye olmayan kullanıcı davet gönderemez.");

            var friendship = await _friendshipDal.GetAsync(f =>
                ((f.FirstUserId == senderId && f.SecondUserId == receiver.UserId) ||
                 (f.FirstUserId == receiver.UserId && f.SecondUserId == senderId)) && f.DeletedAt == null);

            if (friendship == null)
                return new ErrorDataResult<WorkspaceInvitationDto>("Sadece arkadaşlarınızı davet edebilirsiniz.");

            var existingMember = await _workspaceMemberDal.GetAsync(m =>
                m.WorkspaceId == request.WorkspaceId && m.UserId == receiver.UserId);

            if (existingMember != null)
                return new ErrorDataResult<WorkspaceInvitationDto>("Kullanıcı zaten odada.");

            var pendingInvitation = await _workspaceInvitationDal.GetAsync(i =>
                i.WorkspaceId == request.WorkspaceId &&
                i.ReceiverId == receiver.UserId &&
                i.Status == WorkspaceInvitationStatusEnums.pending);

            if (pendingInvitation != null)
                return new ErrorDataResult<WorkspaceInvitationDto>("Bu kullanıcıya zaten bekleyen bir davet var.");

            var memberCount = await _workspaceMemberDal.GetListAsync(m => m.WorkspaceId == request.WorkspaceId);
            if (memberCount.Count >= WorkspaceCapacity)
                return new ErrorDataResult<WorkspaceInvitationDto>("Oda kapasitesi dolu.");

            var invitation = new WorkspaceInvitation
            {
                WorkspaceInvitationId = Guid.NewGuid().ToString(),
                WorkspaceId = request.WorkspaceId,
                SenderId = senderId,
                ReceiverId = receiver.UserId,
                Status = WorkspaceInvitationStatusEnums.pending,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            };

            await _workspaceInvitationDal.AddAsync(invitation);

            var invitationDto = _mapper.Map<WorkspaceInvitationDto>(invitation);
            return new SuccessDataResult<WorkspaceInvitationDto>(invitationDto, "Davet gönderildi.");
        }

        public async Task<IDataResult<WorkspaceInvitationDto>> AcceptInvitationAsync(string receiverId, string invitationId)
        {
            var invitation = await _workspaceInvitationDal.GetAsync(i => i.WorkspaceInvitationId == invitationId);
            if (invitation == null)
                return new ErrorDataResult<WorkspaceInvitationDto>("Davet bulunamadı.");

            if (invitation.ReceiverId != receiverId)
                return new ErrorDataResult<WorkspaceInvitationDto>("Bu daveti kabul etme yetkiniz yok.");

            if (invitation.Status == WorkspaceInvitationStatusEnums.accepted)
                return new ErrorDataResult<WorkspaceInvitationDto>("Davet zaten kabul edilmiş.");

            if (invitation.Status == WorkspaceInvitationStatusEnums.rejected)
                return new ErrorDataResult<WorkspaceInvitationDto>("Davet reddedilmiş.");

            var memberCount = await _workspaceMemberDal.GetListAsync(m => m.WorkspaceId == invitation.WorkspaceId);
            if (memberCount.Count >= WorkspaceCapacity)
                return new ErrorDataResult<WorkspaceInvitationDto>("Oda kapasitesi dolu.");

            var existingMember = await _workspaceMemberDal.GetAsync(m =>
                m.WorkspaceId == invitation.WorkspaceId && m.UserId == receiverId);

            if (existingMember != null)
                return new ErrorDataResult<WorkspaceInvitationDto>("Kullanıcı zaten odada.");

            invitation.Status = WorkspaceInvitationStatusEnums.accepted;
            await _workspaceInvitationDal.UpdateAsync(invitation);

            var member = new WorkspaceMember
            {
                WorkspaceId = invitation.WorkspaceId,
                UserId = receiverId,
                JoinedAt = DateTime.UtcNow
            };

            await _workspaceMemberDal.AddAsync(member);

            try
            {
                await _workspaceRealtimeService.NotifyWorkspaceGroupsUpdatedAsync(receiverId);
            }
            catch (Exception ex)
            {
                Console.WriteLine(
                    $"[WorkspaceService] WorkspaceGroupsUpdated gönderilemedi: {ex.Message}");
            }

            var invitationDto = _mapper.Map<WorkspaceInvitationDto>(invitation);
            return new SuccessDataResult<WorkspaceInvitationDto>(invitationDto, "Davet kabul edildi.");
        }

        public async Task<IDataResult<List<WorkspaceDto>>> GetMyWorkspacesAsync(string userId)
        {
            var memberships = await _workspaceMemberDal.GetListAsync(
                m => m.UserId == userId,
                q => q.Include(x => x.Workspace)
                      .ThenInclude(x => x.Owner));

            if (memberships == null || !memberships.Any())
                return new SuccessDataResult<List<WorkspaceDto>>(new List<WorkspaceDto>(), "Üye olunan oda bulunamadı.");

            var workspaces = memberships
                .Where(m => m.Workspace != null)
                .Select(m => m.Workspace)
                .DistinctBy(w => w.WorkspaceId)
                .ToList();

            var workspaceIds = workspaces.Select(w => w.WorkspaceId).ToList();
            var allMembers = await _workspaceMemberDal.GetListAsync(m => workspaceIds.Contains(m.WorkspaceId));
            var memberCounts = allMembers
                .GroupBy(m => m.WorkspaceId)
                .ToDictionary(g => g.Key, g => g.Count());

            var workspaceDtos = workspaces.Select(workspace =>
            {
                var dto = _mapper.Map<WorkspaceDto>(workspace);
                dto.MemberCount = memberCounts.TryGetValue(workspace.WorkspaceId, out var count) ? count : 0;
                return dto;
            }).ToList();

            return new SuccessDataResult<List<WorkspaceDto>>(workspaceDtos);
        }

        public async Task<IDataResult<List<WorkspaceInvitationDto>>> GetPendingInvitationsAsync(string userId)
        {
            var invitations = await _workspaceInvitationDal.GetListAsync(
                i => i.ReceiverId == userId && i.Status == WorkspaceInvitationStatusEnums.pending,
                q => q.Include(x => x.Workspace)
                      .Include(x => x.Sender));

            if (invitations == null || !invitations.Any())
                return new SuccessDataResult<List<WorkspaceInvitationDto>>(new List<WorkspaceInvitationDto>(), "Bekleyen davet bulunamadı.");

            var invitationDtos = _mapper.Map<List<WorkspaceInvitationDto>>(invitations);
            return new SuccessDataResult<List<WorkspaceInvitationDto>>(invitationDtos);
        }
    }
}
