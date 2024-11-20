using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace VTA.API.Controllers;

[Authorize]
[Route("api/Assets")]
[ApiController]
public class AssetsController : ControllerBase
{
    // GET: api/Assets/Images
    [HttpGet("{filepath}")]
    public IActionResult GetImage(string filepath)
    {
        var imagePath = $"Assets/{filepath}";
        if (!System.IO.File.Exists(imagePath))
        {
            return NotFound();
        }
        var fileBytes = System.IO.File.ReadAllBytes(imagePath);
        return File(fileBytes, "image/jpeg");
    }
}