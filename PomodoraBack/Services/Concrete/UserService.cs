using AutoMapper;
using Core.Utilities.Results;
using PomodoraBack.DataAccess.Interfaces;
using PomodoraBack.DTOs;
using PomodoraBack.Entities;
using PomodoraBack.Services.Interfaces;
using IResult = Core.Utilities.Results.IResults;

namespace PomodoraBack.Services.Concrete
{
    public class UserService : IUserService
    {
        private readonly IUserDal _userDal;
        private readonly IMapper _mapper;

        public UserService(IUserDal userDal, IMapper mapper)
        {
            _userDal = userDal;
            _mapper = mapper;
        }

        public async Task<IDataResult<UserDto>> GetByIdAsync(string userId)
        {
            var user = await _userDal.GetAsync(u => u.UserId == userId);
            
            if (user == null)
                return new ErrorDataResult<UserDto>("Kullanıcı bulunamadı.");

            var userDto = _mapper.Map<UserDto>(user);
            return new SuccessDataResult<UserDto>(userDto);
        }

        public async Task<IDataResult<List<UserDto>>> GetAllAsync()
        {
            var users = await _userDal.GetListAsync();
            
            if (users == null || !users.Any())
                return new ErrorDataResult<List<UserDto>>("Kullanıcı bulunamadı.");

            var userDtos = _mapper.Map<List<UserDto>>(users);
            return new SuccessDataResult<List<UserDto>>(userDtos);
        }

        public async Task<IDataResult<UserDto>> UpdateAsync(string userId, UpdateUserDto updateUserDto)
        {
            var user = await _userDal.GetAsync(u => u.UserId == userId);
            
            if (user == null)
                return new ErrorDataResult<UserDto>("Kullanıcı bulunamadı.");

            // Email değişiyorsa kontrol et
            if (!string.IsNullOrEmpty(updateUserDto.Email) && updateUserDto.Email != user.Email)
            {
                var emailExists = await _userDal.GetAsync(u => u.Email == updateUserDto.Email);
                if (emailExists != null)
                    return new ErrorDataResult<UserDto>("Bu email adresi zaten kullanılıyor.");
            }

            // Nickname değişiyorsa kontrol et
            if (!string.IsNullOrEmpty(updateUserDto.Nickname) && updateUserDto.Nickname != user.Nickname)
            {
                var nicknameExists = await _userDal.GetAsync(u => u.Nickname == updateUserDto.Nickname);
                if (nicknameExists != null)
                    return new ErrorDataResult<UserDto>("Bu kullanıcı adı zaten kullanılıyor.");
            }

            // Password hash'lenmesi gerekiyorsa
            if (!string.IsNullOrEmpty(updateUserDto.Password))
            {
                user.Password = BCrypt.Net.BCrypt.HashPassword(updateUserDto.Password);
            }

            // Sadece null olmayan alanları güncelle
            _mapper.Map(updateUserDto, user);
            await _userDal.UpdateAsync(user);

            var userDto = _mapper.Map<UserDto>(user);
            return new SuccessDataResult<UserDto>(userDto, "Kullanıcı güncellendi.");
        }

        public async Task<IResult> DeleteAsync(string userId)
        {
            var user = await _userDal.GetAsync(u => u.UserId == userId);
            
            if (user == null)
                return new ErrorResult("Kullanıcı bulunamadı.");

            
            await _userDal.DeleteAsync(user);
            return new SuccessResult("Kullanıcı silindi.");
        }
    }
}
