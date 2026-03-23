using System.Collections;
using Microsoft.AspNetCore.Mvc;
using Core.Utilities.Results;

namespace PomodoraBack.Controllers;

public abstract class BaseController : ControllerBase
{
    // IDataResult için overload - Service'lerden IDataResult dönünce bunu kullan
    protected IActionResult Response<T>(IDataResult<T> result)
    {
        if (!result.Success)
        {
            return BadRequest(new ApiResponse<T>
            {
                Success = false,
                Message = result.Message,
                Data = default
            });
        }

        if (result.Data == null || (result.Data is IEnumerable enumerable && !enumerable.Cast<object>().Any()))
        {
            return NoContent();
        }

        return Ok(new ApiResponse<T>
        {
            Success = true,
            Data = result.Data,
            Message = result.Message ?? "İşlem başarılı."
        });
    }

    // Eski method - Direkt data dönmek için (backward compatibility)
    protected IActionResult Response<T>(T result, string? message = null)
    {
        try
        {
            if (result == null || (result is IEnumerable enumerable && !enumerable.Cast<object>().Any()))
                return NoContent();

            return Ok(new ApiResponse<T>
            {
                Success = true,
                Data = result,
                Message = message ?? "İşlem başarılı."
            });
        }
        catch (UnauthorizedAccessException)
        {
            return ErrorResponse(401, "Yetkisiz erişim.");
        }
        catch (Exception ex)
        {
            return ErrorResponse("Beklenmeyen bir hata oluştu.", [ex.Message]);
        }
    }

    private IActionResult ErrorResponse(string message, List<string>? errors = null)
    {
        return StatusCode(500, new ApiResponse<string>
        {
            Success = false,
            Message = message,
            Errors = errors ?? []
        });
    }
    
    private IActionResult ErrorResponse(int errorCode, string message, List<string>? errors = null)
    {
        return StatusCode(errorCode, new ApiResponse<string>
        {
            Success = false,
            Message = message,
            Errors = errors ?? []
        });
    }
    
    protected class ApiResponse<T>
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public T? Data { get; set; }
        public List<string> Errors { get; set; } = new();
    }
}