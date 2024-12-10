using System.Net;
using VTA.API.DTOs;
using System.Net.Http.Headers;

using VTA.Tests.TestHelpers;
using System.Net.Http.Json;

namespace VTA.Tests.UnitTests
{
    public class CategoryServiceTests : IClassFixture<CustomApplicationFactory>
    {
        private readonly HttpClient _client;
        private readonly Utilities _utilities;

        public CategoryServiceTests(CustomApplicationFactory factory)
        {
            _client = factory.CreateClient();
            _utilities = new Utilities(_client);
        }

        [Fact]
        public async Task CreateCategory_ShouldReturnCategoryGetDTO()
        {
            var username = _utilities.GenerateUniqueUsername();
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");

            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var categoryPostDTO = new CategoryPostDTO
            {
                UserId = signUpResult!.userId,
                Name = "Test Category"
            };

            var content = new MultipartFormDataContent();
            content.Add(new StringContent(categoryPostDTO.UserId), nameof(CategoryPostDTO.UserId));
            content.Add(new StringContent(categoryPostDTO.Name), nameof(CategoryPostDTO.Name));

            var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Categories");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", signUpResult.Token);
            request.Content = content;

            var response = await _client.SendAsync(request);
            var category = await response.Content.ReadFromJsonAsync<CategoryGetDTO>();

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            Assert.NotNull(category);
            Assert.Equal(categoryPostDTO.Name, category!.Name);

            var deleteCategoryRequest = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/Categories/{category.CategoryId}");
            deleteCategoryRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", signUpResult.Token);
            var deleteCategoryResponse = await _client.SendAsync(deleteCategoryRequest);
            Assert.Equal(HttpStatusCode.NoContent, deleteCategoryResponse.StatusCode);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        }

        [Fact]
        public async Task GetCategoryById_ShouldReturnCategoryGetDTO()
        {
            var username = _utilities.GenerateUniqueUsername();
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");

            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var categoryPostDTO = new CategoryPostDTO
            {
                UserId = signUpResult!.userId,
                Name = "Test Category"
            };

            var content = new MultipartFormDataContent();
            content.Add(new StringContent(categoryPostDTO.UserId), nameof(CategoryPostDTO.UserId));
            content.Add(new StringContent(categoryPostDTO.Name), nameof(CategoryPostDTO.Name));

            var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Categories");
            postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", signUpResult.Token);
            postRequest.Content = content;

            var postResponse = await _client.SendAsync(postRequest);
            var category = await postResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

            var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Categories/{category!.CategoryId}");
            getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", signUpResult.Token);

            var getResponse = await _client.SendAsync(getRequest);
            var fetchedCategory = await getResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

            Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);
            Assert.NotNull(fetchedCategory);
            Assert.Equal(category.CategoryId, fetchedCategory!.CategoryId);

            var deleteCategoryRequest = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/Categories/{category.CategoryId}");
            deleteCategoryRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", signUpResult.Token);
            var deleteCategoryResponse = await _client.SendAsync(deleteCategoryRequest);
            Assert.Equal(HttpStatusCode.NoContent, deleteCategoryResponse.StatusCode);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        }

        [Fact]
        public async Task DeleteCategory_ShouldReturnNoContent()
        {
            var username = _utilities.GenerateUniqueUsername();
            var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");

            Assert.Equal(HttpStatusCode.OK, signUpStatus);
            Assert.NotNull(signUpResult?.Token);

            var categoryPostDTO = new CategoryPostDTO
            {
                UserId = signUpResult!.userId,
                Name = "Test Category"
            };

            var content = new MultipartFormDataContent();
            content.Add(new StringContent(categoryPostDTO.UserId), nameof(CategoryPostDTO.UserId));
            content.Add(new StringContent(categoryPostDTO.Name), nameof(CategoryPostDTO.Name));

            var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Categories");
            postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", signUpResult.Token);
            postRequest.Content = content;

            var postResponse = await _client.SendAsync(postRequest);
            var category = await postResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

            var deleteRequest = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/Categories/{category!.CategoryId}");
            deleteRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", signUpResult.Token);

            var deleteResponse = await _client.SendAsync(deleteRequest);
            Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

            var deleteStatus = await _utilities.DeleteUserAsync(signUpResult.userId, signUpResult.Token);
            Assert.Equal(HttpStatusCode.NoContent, deleteStatus);
        }
    }
}