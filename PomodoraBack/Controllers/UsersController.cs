using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PomodoraBack.Controllers;
using PomodoraBack.DTOs;
using PomodoraBack.Services.Interfaces;
using IResult = Core.Utilities.Results.IResults;

namespace PomodoraBack.Controllers
{
    /// <summary>
    /// User management endpoints (CRUD operations - requires authentication)
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    [Produces("application/json")]
    public class UsersController : BaseController
    {
        private readonly IUserService _userService;

        public UsersController(IUserService userService)
        {
            _userService = userService;
        }

        /// <summary>
        /// Get user by ID
        /// </summary>
        /// <param name="id">User ID</param>
        /// <returns>User information</returns>
        /// <response code="200">User found</response>
        /// <response code="204">User not found</response>
        /// <response code="401">Unauthorized</response>
        [HttpGet("{id}")]
        [ProducesResponseType(typeof(UserDto), 200)]
        [ProducesResponseType(204)]
        [ProducesResponseType(401)]
        public async Task<IActionResult> GetById(string id)
        {
            var result = await _userService.GetByIdAsync(id);
            return Response(result);
        }

        /// <summary>
        /// Get all users
        /// </summary>
        /// <returns>List of all users</returns>
        /// <response code="200">Users retrieved successfully</response>
        /// <response code="204">No users found</response>
        /// <response code="401">Unauthorized</response>
        [HttpGet]
        [ProducesResponseType(typeof(List<UserDto>), 200)]
        [ProducesResponseType(204)]
        [ProducesResponseType(401)]
        public async Task<IActionResult> GetAll()
        {
            var result = await _userService.GetAllAsync();
            return Response(result);
        }

        /// <summary>
        /// Update user information
        /// </summary>
        /// <param name="id">User ID</param>
        /// <param name="updateUserDto">Updated user information</param>
        /// <returns>Updated user information</returns>
        /// <response code="200">User updated successfully</response>
        /// <response code="400">Invalid input or user not found</response>
        /// <response code="401">Unauthorized</response>
        [HttpPut("{id}")]
        [ProducesResponseType(typeof(UserDto), 200)]
        [ProducesResponseType(400)]
        [ProducesResponseType(401)]
        public async Task<IActionResult> Update(string id, [FromBody] UpdateUserDto updateUserDto)
        {
            var result = await _userService.UpdateAsync(id, updateUserDto);
            return Response(result);
        }

        /// <summary>
        /// Delete user
        /// </summary>
        /// <param name="id">User ID</param>
        /// <returns>Deletion confirmation</returns>
        /// <response code="200">User deleted successfully</response>
        /// <response code="400">User not found</response>
        /// <response code="401">Unauthorized</response>
        [HttpDelete("{id}")]
        [ProducesResponseType(200)]
        [ProducesResponseType(400)]
        [ProducesResponseType(401)]
        public async Task<IActionResult> Delete(string id)
        {
            var result = await _userService.DeleteAsync(id);
            
            if (!result.Success)
                return BadRequest(new { success = false, message = result.Message });
            
            return Ok(new { success = true, message = result.Message });
        }
    }
}
