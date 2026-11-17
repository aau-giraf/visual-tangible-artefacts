using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Text;
using Microsoft.AspNetCore.Http.HttpResults;

using Backendv2.src.API.Routes.DTOs.ArtefactsDto;


namespace VTA.API.Controllers
{
    public class ArtefactHandler
    {
        public static IResult GetAll(ArtefactsDto artefactsDto)
        {
            var artefacts = await ar;
            /*var artefactGetDTOs = artefacts
            .Select(artefact => DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString()))
            .ToList();*/


            //return TypedResults.ok(new List<artefacts> {});

            return artefactGetDto;
            
        }
    

    }



}