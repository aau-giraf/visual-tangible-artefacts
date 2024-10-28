using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.Models;
using VTA.API.DTOs;
using VTA.API.Utilities;

namespace VTA.API.Controllers
{
    [Route("api/Assets")]
    [ApiController]
    public class AssetsController : ControllerBase
    {
        // GET: api/Assets/DrinkImages
        [HttpGet("{filepath}")]
        public IActionResult GetDrinkImage(string filepath)
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
}