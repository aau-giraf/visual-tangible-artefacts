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

// DET ER EN TEST CONTROLLER, SÅ JEG (EMIL SUPHI DOGANCI) KAN TESTE CI/CD PIPELINE OG MÅSKE ANDRE TING
// PLS IKK FJERN, PLS PLS, IKKE FJERN, PLS PLS, IKKE FJERN, PLS, FJERN IKKE, I K K E  F J E R N, men hvis I gør er det ok.

namespace VTA.API.Controllers
{
    [Route("api/TestController")]
    [ApiController]
    public class TestController : ControllerBase
    {

        // TEST DEPLOYMENT ENDPOINT
        // GET: api/TestController/TestDeployment
        [HttpGet("TestDeployment")]
        public ActionResult<string> TestDeployment()
        {
            return "Deployment Successful!";
        }
    }
}
