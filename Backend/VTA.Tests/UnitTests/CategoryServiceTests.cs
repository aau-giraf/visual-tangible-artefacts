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
            var loginData = _utilities.CreateTestLoginData();

            var content = new MultipartFormDataContent();
            content.Add(new StringContent(loginData.UserId.ToString()), nameof(CategoryPostDTO.UserId));
            content.Add(new StringContent("Test Category"), nameof(CategoryPostDTO.Name));

            var request = new HttpRequestMessage(HttpMethod.Post, "/api/Categories");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
            request.Content = content;

            var response = await _client.SendAsync(request);
            var category = await response.Content.ReadFromJsonAsync<CategoryGetDTO>();

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            Assert.NotNull(category);
            Assert.Equal("Test Category", category!.Name);

            var deleteCategoryRequest = new HttpRequestMessage(HttpMethod.Delete, $"/api/Categories/{category.CategoryId}");
            deleteCategoryRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
            var deleteCategoryResponse = await _client.SendAsync(deleteCategoryRequest);
            Assert.Equal(HttpStatusCode.NoContent, deleteCategoryResponse.StatusCode);
        }

        [Fact]
        public async Task GetCategoryById_ShouldReturnCategoryGetDTO()
        {
            var loginData = _utilities.CreateTestLoginData();

            var content = new MultipartFormDataContent();
            content.Add(new StringContent(loginData.UserId.ToString()), nameof(CategoryPostDTO.UserId));
            content.Add(new StringContent("Test Category"), nameof(CategoryPostDTO.Name));

            var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Categories");
            postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
            postRequest.Content = content;

            var postResponse = await _client.SendAsync(postRequest);
            var category = await postResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

            var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Categories/{category!.CategoryId}");
            getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

            var getResponse = await _client.SendAsync(getRequest);
            var fetchedCategory = await getResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

            Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);
            Assert.NotNull(fetchedCategory);
            Assert.Equal(category.CategoryId, fetchedCategory!.CategoryId);

            var deleteCategoryRequest = new HttpRequestMessage(HttpMethod.Delete, $"/api/Categories/{category.CategoryId}");
            deleteCategoryRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
            var deleteCategoryResponse = await _client.SendAsync(deleteCategoryRequest);
            Assert.Equal(HttpStatusCode.NoContent, deleteCategoryResponse.StatusCode);
        }

        [Fact]
        public async Task DeleteCategory_ShouldReturnNoContent()
        {
            var loginData = _utilities.CreateTestLoginData();

            var content = new MultipartFormDataContent();
            content.Add(new StringContent(loginData.UserId.ToString()), nameof(CategoryPostDTO.UserId));
            content.Add(new StringContent("Test Category"), nameof(CategoryPostDTO.Name));

            var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Categories");
            postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
            postRequest.Content = content;

            var postResponse = await _client.SendAsync(postRequest);
            var category = await postResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

            var deleteRequest = new HttpRequestMessage(HttpMethod.Delete, $"/api/Categories/{category!.CategoryId}");
            deleteRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

            var deleteResponse = await _client.SendAsync(deleteRequest);
            Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);
        }
    }
}
