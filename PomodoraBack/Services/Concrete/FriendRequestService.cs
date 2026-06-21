using AutoMapper;
using Core.Utilities.Results;
using Microsoft.EntityFrameworkCore;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;
using PomodoraBack.Services.Interfaces;
using IResult = Core.Utilities.Results.IResults;

namespace PomodoraBack.Services.Concrete
{
    public class FriendRequestService : IFriendRequest
    {
        private readonly IFriendRequestDal _friendRequestDal;
        private readonly IFriendShipDal _friendshipDal;
        private readonly IUserDal _userDal;
        private readonly IMapper _mapper;

        public FriendRequestService(
            IFriendRequestDal friendRequestDal,
            IFriendShipDal friendshipDal,
            IUserDal userDal,
            IMapper mapper)
        {
            _friendRequestDal = friendRequestDal;
            _friendshipDal = friendshipDal;
            _userDal = userDal;
            _mapper = mapper;
        }

        /// <summary>
        /// Arkadaş isteği gönder
        /// </summary>
        public async Task<IDataResult<FriendRequestDto>> SendFriendRequestAsync(string senderId, SendFriendRequestDto friendRequest)
        {
            // Gönderici var mı kontrol et
            var sender = await _userDal.GetAsync(u => u.UserId == senderId);
            if (sender == null)
                return new ErrorDataResult<FriendRequestDto>("Gönderici kullanıcı bulunamadı.");

            // Alıcıyı ID veya Nickname ile bul
            User receiver = null;
            
            if (!string.IsNullOrEmpty(friendRequest.ReceiverId))
            {
                receiver = await _userDal.GetAsync(u => u.UserId == friendRequest.ReceiverId);
            }
            else if (!string.IsNullOrEmpty(friendRequest.ReceiverNickname))
            {
                receiver = await _userDal.GetAsync(u => u.Nickname == friendRequest.ReceiverNickname);
            }
            
            if (receiver == null)
                return new ErrorDataResult<FriendRequestDto>("Alıcı kullanıcı bulunamadı.");

            // ReceiverId'yi belirle
            var receiverId = receiver.UserId;

            // Aynı kişiye istek gönderemez
            if (senderId == receiverId)
                return new ErrorDataResult<FriendRequestDto>("Kendinize arkadaş isteği gönderemezsiniz.");

            // Zaten arkadaş mı kontrol et (soft delete kontrolü ile)
            var existingFriendship = await _friendshipDal.GetAsync(f =>
                ((f.FirstUserId == senderId && f.SecondUserId == receiverId) ||
                (f.FirstUserId == receiverId && f.SecondUserId == senderId)) && f.DeletedAt == null);

            if (existingFriendship != null)
                return new ErrorDataResult<FriendRequestDto>("Zaten bu kullanıcının arkadaşısınız.");

            // Zaten beklemede bir istek var mı kontrol et
            var existingRequest = await _friendRequestDal.GetAsync(fr =>
                (fr.ConsignerId == senderId && fr.ReceiverId == receiverId && !fr.Status) ||
                (fr.ConsignerId == receiverId && fr.ReceiverId == senderId && !fr.Status));

            if (existingRequest != null)
                return new ErrorDataResult<FriendRequestDto>("Bu kullanıcıya zaten bir istek gönderilmiş veya sizden bir istek bekleniyor.");

            // Yeni istek oluştur
            var newFriendRequest = new FriendRequest
            {
                FriendRequestId = Guid.NewGuid().ToString(),
                ConsignerId = senderId,
                ReceiverId = receiverId,
                Status = false,
                CreatedAt = DateTime.UtcNow
            };

            await _friendRequestDal.AddAsync(newFriendRequest);

            var friendRequestDto = _mapper.Map<FriendRequestDto>(newFriendRequest);
            return new SuccessDataResult<FriendRequestDto>(friendRequestDto, "Arkadaş isteği gönderildi.");
        }

        /// <summary>
        /// Arkadaş isteğini kabul et ve Friendship oluştur
        /// </summary>
        public async Task<IDataResult<FriendRequestDto>> AcceptFriendRequestAsync(string friendRequestId)
        {
            var friendRequest = await _friendRequestDal.GetAsync(fr => fr.FriendRequestId == friendRequestId);
            if (friendRequest == null)
                return new ErrorDataResult<FriendRequestDto>("Arkadaş isteği bulunamadı.");

            if (friendRequest.Status)
                return new ErrorDataResult<FriendRequestDto>("Bu istek zaten kabul edilmiş.");

            // Friendship oluştur
            var friendship = new FriendShip
            {
                FriendShipId = Guid.NewGuid().ToString(),
                FirstUserId = friendRequest.ConsignerId,
                SecondUserId = friendRequest.ReceiverId,
                CreatedAt = DateTime.UtcNow
            };

            // FriendRequest'i güncelle
            friendRequest.Status = true;
            friendRequest.UpdatedAt = DateTime.UtcNow;

            await _friendshipDal.AddAsync(friendship);
            await _friendRequestDal.UpdateAsync(friendRequest);

            var friendRequestDto = _mapper.Map<FriendRequestDto>(friendRequest);
            return new SuccessDataResult<FriendRequestDto>(friendRequestDto, "Arkadaş isteği kabul edildi.");
        }

        /// <summary>
        /// Arkadaş isteğini reddet
        /// </summary>
        public async Task<IDataResult<FriendRequestDto>> RejectFriendRequestAsync(string friendRequestId)
        {
            var friendRequest = await _friendRequestDal.GetAsync(fr => fr.FriendRequestId == friendRequestId);
            if (friendRequest == null)
                return new ErrorDataResult<FriendRequestDto>("Arkadaş isteği bulunamadı.");

            if (friendRequest.Status)
                return new ErrorDataResult<FriendRequestDto>("Bu istek zaten kabul edilmiş, reddedilemez.");

            // İsteği sil
            await _friendRequestDal.DeleteAsync(friendRequest);

            var friendRequestDto = _mapper.Map<FriendRequestDto>(friendRequest);
            return new SuccessDataResult<FriendRequestDto>(friendRequestDto, "Arkadaş isteği reddedildi.");
        }

        /// <summary>
        /// Beklemede olan arkadaş isteklerini getir
        /// </summary>
        public async Task<IDataResult<List<FriendRequestDto>>> GetPendingRequestsAsync(string userId)
        {
            var pendingRequests = await _friendRequestDal.GetListAsync(
                fr => fr.ReceiverId == userId && !fr.Status,
                q => q.Include(x => x.Consigner).Include(x => x.Receiver));

            if (pendingRequests == null || !pendingRequests.Any())
                return new SuccessDataResult<List<FriendRequestDto>>(new List<FriendRequestDto>(), "Beklemede istek bulunamadı.");

            var requestDtos = _mapper.Map<List<FriendRequestDto>>(pendingRequests);
            return new SuccessDataResult<List<FriendRequestDto>>(requestDtos);
        }

        /// <summary>
        /// Gönderilen arkadaş isteklerini getir
        /// </summary>
        public async Task<IDataResult<List<FriendRequestDto>>> GetSentRequestsAsync(string userId)
        {
            var sentRequests = await _friendRequestDal.GetListAsync(
                fr => fr.ConsignerId == userId && !fr.Status,
                q => q.Include(x => x.Consigner).Include(x => x.Receiver));

            if (sentRequests == null || !sentRequests.Any())
                return new SuccessDataResult<List<FriendRequestDto>>(new List<FriendRequestDto>(), "Gönderilen istek bulunamadı.");

            var requestDtos = _mapper.Map<List<FriendRequestDto>>(sentRequests);
            return new SuccessDataResult<List<FriendRequestDto>>(requestDtos);
        }

        /// <summary>
        /// İki kullanıcı arasındaki friendship'i getir
        /// </summary>
        public async Task<IDataResult<FriendshipDto>> GetFriendshipAsync(string userId, string friendId)
        {
            var friendship = await _friendshipDal.GetAsync(
                f => ((f.FirstUserId == userId && f.SecondUserId == friendId) ||
                     (f.FirstUserId == friendId && f.SecondUserId == userId)) && f.DeletedAt == null,
                q => q.Include(x => x.FirstUser).Include(x => x.SecondUser));

            if (friendship == null)
                return new ErrorDataResult<FriendshipDto>("Arkadaşlık ilişkisi bulunamadı.");

            var friendshipDto = _mapper.Map<FriendshipDto>(friendship);
            return new SuccessDataResult<FriendshipDto>(friendshipDto);
        }

        /// <summary>
        /// Kullanıcının arkadaşlarını getir
        /// </summary>
        public async Task<IDataResult<List<FriendshipDto>>> GetFriendsAsync(string userId)
        {
            var friendships = await _friendshipDal.GetListAsync(
                f => (f.FirstUserId == userId || f.SecondUserId == userId) && f.DeletedAt == null,
                q => q.Include(x => x.FirstUser).Include(x => x.SecondUser));

            if (friendships == null || !friendships.Any())
                return new SuccessDataResult<List<FriendshipDto>>(new List<FriendshipDto>(), "Arkadaş bulunamadı.");

            var friendshipDtos = _mapper.Map<List<FriendshipDto>>(friendships);
            return new SuccessDataResult<List<FriendshipDto>>(friendshipDtos);
        }

        /// <summary>
        /// Arkadaşlığı kaldır (soft delete)
        /// </summary>
        public async Task<IResult> RemoveFriendAsync(string userId, string friendId)
        {
            var friendship = await _friendshipDal.GetAsync(f =>
                (f.FirstUserId == userId && f.SecondUserId == friendId) ||
                (f.FirstUserId == friendId && f.SecondUserId == userId));

            if (friendship == null)
                return new ErrorResult("Arkadaşlık ilişkisi bulunamadı.");

            friendship.DeletedAt = DateTime.UtcNow;
            await _friendshipDal.UpdateAsync(friendship);

            return new SuccessResult("Arkadaş kaldırıldı.");
        }

        /// <summary>
        /// İki kullanıcı arkadaş mı kontrol et
        /// </summary>
        public async Task<IDataResult<bool>> AreFriendsAsync(string userId, string friendId)
        {
            var friendship = await _friendshipDal.GetAsync(f =>
                ((f.FirstUserId == userId && f.SecondUserId == friendId) ||
                (f.FirstUserId == friendId && f.SecondUserId == userId)) && f.DeletedAt == null);

            bool areFriends = friendship != null;
            return new SuccessDataResult<bool>(areFriends);
        }

        /// <summary>
        /// Kullanıcının kendisini ve onaylanmış arkadaşlarını
        /// TotalPoints'e göre sıralayıp Rank numarası atanmış
        /// liderlik tablosu listesi döndürür.
        /// </summary>
        public async Task<IDataResult<List<FriendLeaderboardDto>>> GetFriendLeaderboardAsync(string currentUserId)
        {
            // Kullanıcı var mı kontrol et
            var user = await _userDal.GetAsync(u => u.UserId == currentUserId && u.DeletedAt == null);
            if (user == null)
                return new ErrorDataResult<List<FriendLeaderboardDto>>("Kullanıcı bulunamadı.");

            // DAL'dan TotalPoints desc sıralı listeyi al (Rank = 0 olarak gelir)
            var sortedList = await _friendshipDal.GetFriendLeaderboardAsync(currentUserId);

            // LINQ ile 1'den başlayan Rank numaralarını ata
            var rankedList = sortedList
                .Select((entry, index) =>
                {
                    entry.Rank = index + 1;
                    return entry;
                })
                .ToList();

            return new SuccessDataResult<List<FriendLeaderboardDto>>(
                rankedList,
                $"Liderlik tablosu getirildi. Toplam {rankedList.Count} kişi.");
        }
    }
}
