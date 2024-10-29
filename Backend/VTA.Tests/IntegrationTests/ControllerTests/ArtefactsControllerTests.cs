using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.Controllers;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;
using VTA.Tests.Fixtures;
using Xunit;

namespace VTA.Tests.IntegrationTests
{
    public class ArtefactsControllerTests : IClassFixture<DatabaseFixture<ArtefactContext>>
    {
        private readonly ArtefactContext _dbContext;
        private readonly ArtefactsController _controller;

        public ArtefactsControllerTests(DatabaseFixture<ArtefactContext> fixture)
        {
            _dbContext = fixture.DbContext;
            _controller = new ArtefactsController(_dbContext);
        }

        // [Fact]
        // public async Task GetArtefacts_ReturnsArtefactsForUser()
        // {
        //     var userId = "test-user-id";
        //     var artefact1 = new Artefact { ArtefactId = "1", UserId = userId, ImagePath = "path1", CategoryId = "category1", ArtefactIndex = 1 };
        //     var artefact2 = new Artefact { ArtefactId = "2", UserId = userId, ImagePath = "path2", CategoryId = "category2", ArtefactIndex = 2 };

        //     _dbContext.Artefacts.AddRange(artefact1, artefact2);
        //     await _dbContext.SaveChangesAsync();

        //     var result = await _controller.GetArtefacts(userId);

        //     var okResult = Assert.IsType<ActionResult<IEnumerable<ArtefactGetDTO>>>(result);
        //     var artefacts = Assert.IsType<List<ArtefactGetDTO>>(okResult.Value);
        //     Assert.Equal(2, artefacts.Count);
        //     Assert.Contains(artefacts, a => a.ArtefactId == "1");
        //     Assert.Contains(artefacts, a => a.ArtefactId == "2");
        // }
    }
}
