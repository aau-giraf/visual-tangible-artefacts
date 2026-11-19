using Microsoft.AspNetCore.Http.HttpResults;
using Backendv2.src.API.Routes;
using Backendv2.src.API.DTOs;
using Backendv2.DB.Data;

namespace Backendv2.src.API.Controllers

{
    public class ArtefactBoardHandler
    {
        private readonly VtaDevContext _VTADevContext; 

        ArtefactBoardHandler(VtaDevContext vtaDevContext)
        {
            _VTADevContext = vtaDevContext;
        }
    }

    

}


