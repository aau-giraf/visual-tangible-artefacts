using System;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc;
using VTA.API.DTOs;
using VTA.Tests.TestHelpers;

namespace VTA.Tests.IntegrationTests.ControllerTests;

public class CategoriesControllerTests : IClassFixture<CustomApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly Utilities _utilities;

    public CategoriesControllerTests(CustomApplicationFactory factory)
    {
        _client = factory.CreateClient();
        _utilities = new Utilities(_client);
    }

    [Fact]
    public async Task TestGetCategoriesReturnsOk()
    {
        var loginData = _utilities.CreateTestLoginData();

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Categories");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var page = await response.Content.ReadFromJsonAsync<PaginatedResponse<CategoryGetDTO>>();
        Assert.NotNull(page);
        Assert.NotNull(page.Items);
    }

    [Fact]
    public async Task TestPostCategoryReturnsOk()
    {
        var loginData = _utilities.CreateTestLoginData();

        var content = new MultipartFormDataContent();
        content.Add(new StringContent(loginData.UserId.ToString()), nameof(CategoryPostDTO.UserId));
        content.Add(new StringContent("Test Category"), nameof(CategoryPostDTO.Name));

        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Categories");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        request.Content = content;

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var category = await response.Content.ReadFromJsonAsync<CategoryGetDTO>();
        Assert.NotNull(category);
        Assert.Equal("Test Category", category.Name);
    }

    [Fact]
    public async Task TestDeleteCategoryReturnsNoContent()
    {
        var loginData = _utilities.CreateTestLoginData();

        var content = new MultipartFormDataContent();
        content.Add(new StringContent(loginData.UserId.ToString()), nameof(CategoryPostDTO.UserId));
        content.Add(new StringContent("Test Category"), nameof(CategoryPostDTO.Name));

        var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Categories");
        postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        postRequest.Content = content;

        var postResponse = await _client.SendAsync(postRequest);
        Assert.Equal(HttpStatusCode.OK, postResponse.StatusCode);

        var category = await postResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

        var deleteRequest = new HttpRequestMessage(HttpMethod.Delete, $"/api/Categories/{category.CategoryId}");
        deleteRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var deleteResponse = await _client.SendAsync(deleteRequest);
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Categories/{category.CategoryId}");
        getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var getResponse = await _client.SendAsync(getRequest);
        Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);
    }

    [Fact]
    public async Task TestGetCategoryReturnsNotFound()
    {
        var loginData = _utilities.CreateTestLoginData();

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Categories/nonexistent");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        var errorResponse = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        Assert.NotNull(errorResponse);
    }

    [Fact]
    public async Task TestPatchCategoryReturnsNoContent()
    {
        var loginData = _utilities.CreateTestLoginData();

        var content = new MultipartFormDataContent
        {
            { new StringContent(loginData.UserId.ToString()), nameof(CategoryPostDTO.UserId) },
            { new StringContent("Test Category"), nameof(CategoryPostDTO.Name) }
        };

        var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Categories");
        postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        postRequest.Content = content;

        var postResponse = await _client.SendAsync(postRequest);
        Assert.Equal(HttpStatusCode.OK, postResponse.StatusCode);

        var category = await postResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

        var patchDTO = new CategoryPatchDTO
        {
            CategoryId = category.CategoryId,
            Name = "Updated Category"
        };

        var patchContent = new MultipartFormDataContent
        {
            { new StringContent(patchDTO.CategoryId), nameof(CategoryPatchDTO.CategoryId) },
            { new StringContent(patchDTO.Name), nameof(CategoryPatchDTO.Name) }
        };

        var patchRequest = new HttpRequestMessage(HttpMethod.Patch, "/api/Categories");
        patchRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        patchRequest.Content = patchContent;

        var patchResponse = await _client.SendAsync(patchRequest);
        Assert.Equal(HttpStatusCode.NoContent, patchResponse.StatusCode);

        var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Categories/{category.CategoryId}");
        getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var getResponse = await _client.SendAsync(getRequest);
        var updatedCategory = await getResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();
        Assert.Equal("Updated Category", updatedCategory.Name);
    }

    [Fact]
    public async Task TestPatchCategoryReturnsBadRequest()
    {
        var loginData = _utilities.CreateTestLoginData();

        var patchDTO = new CategoryPatchDTO
        {
            CategoryId = "nonexistent",
            Name = "Updated Category"
        };

        var patchContent = new MultipartFormDataContent();
        patchContent.Add(new StringContent(patchDTO.CategoryId), nameof(CategoryPatchDTO.CategoryId));
        patchContent.Add(new StringContent(patchDTO.Name), nameof(CategoryPatchDTO.Name));

        var patchRequest = new HttpRequestMessage(HttpMethod.Patch, "/api/Categories");
        patchRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        patchRequest.Content = patchContent;

        var patchResponse = await _client.SendAsync(patchRequest);
        Assert.Equal(HttpStatusCode.BadRequest, patchResponse.StatusCode);
    }

    [Fact]
    public async Task TestDeleteCategoryReturnsForbidden()
    {
        var loginData1 = _utilities.CreateTestLoginData();
        var loginData2 = _utilities.CreateTestLoginData();

        var content = new MultipartFormDataContent();
        content.Add(new StringContent(loginData1.UserId.ToString()), nameof(CategoryPostDTO.UserId));
        content.Add(new StringContent("Test Category"), nameof(CategoryPostDTO.Name));

        var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Categories");
        postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData1.Token);
        postRequest.Content = content;

        var postResponse = await _client.SendAsync(postRequest);
        Assert.Equal(HttpStatusCode.OK, postResponse.StatusCode);

        var category = await postResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

        var deleteRequest = new HttpRequestMessage(HttpMethod.Delete, $"/api/Categories/{category.CategoryId}");
        deleteRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData2.Token);

        var deleteResponse = await _client.SendAsync(deleteRequest);
        Assert.Equal(HttpStatusCode.Forbidden, deleteResponse.StatusCode);
    }

    [Fact]
    public async Task TrackCategoryUsage_ReturnsNoContent_WithValidCategoryId()
    {
        var loginData = _utilities.CreateTestLoginData();

        // Create a test category
        var category = await CreateTestCategory(loginData, "Test Category");

        // Track usage
        var request = new HttpRequestMessage(HttpMethod.Post, $"/api/Categories/{category.CategoryId}/usage");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify the usage was tracked by getting the category
        var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Categories/{category.CategoryId}");
        getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var getResponse = await _client.SendAsync(getRequest);
        var updatedCategory = await getResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

        Assert.NotNull(updatedCategory);
        Assert.Equal(1, updatedCategory.UsageCount);
        Assert.NotNull(updatedCategory.LastUsedDate);
    }

    [Fact]
    public async Task TrackCategoryUsage_IncrementsUsageCount_OnMultipleCalls()
    {
        var loginData = _utilities.CreateTestLoginData();

        var category = await CreateTestCategory(loginData, "Test Category");

        // Track usage multiple times
        for (int i = 0; i < 3; i++)
        {
            var request = new HttpRequestMessage(HttpMethod.Post, $"/api/Categories/{category.CategoryId}/usage");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
            var response = await _client.SendAsync(request);
            Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        }

        // Verify usage count
        var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Categories/{category.CategoryId}");
        getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var getResponse = await _client.SendAsync(getRequest);
        var updatedCategory = await getResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

        Assert.NotNull(updatedCategory);
        Assert.Equal(3, updatedCategory.UsageCount);
    }

    [Fact]
    public async Task TrackCategoryUsage_UpdatesLastUsedDate()
    {
        var loginData = _utilities.CreateTestLoginData();

        var category = await CreateTestCategory(loginData, "Test Category");

        // Track usage first time
        var request1 = new HttpRequestMessage(HttpMethod.Post, $"/api/Categories/{category.CategoryId}/usage");
        request1.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        await _client.SendAsync(request1);

        // Get first last used date
        var getRequest1 = new HttpRequestMessage(HttpMethod.Get, $"/api/Categories/{category.CategoryId}");
        getRequest1.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var getResponse1 = await _client.SendAsync(getRequest1);
        var category1 = await getResponse1.Content.ReadFromJsonAsync<CategoryGetDTO>();
        var firstLastUsedDate = category1!.LastUsedDate;

        // Wait a bit to ensure timestamp difference
        await Task.Delay(1000);

        // Track usage second time
        var request2 = new HttpRequestMessage(HttpMethod.Post, $"/api/Categories/{category.CategoryId}/usage");
        request2.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        await _client.SendAsync(request2);

        // Get second last used date
        var getRequest2 = new HttpRequestMessage(HttpMethod.Get, $"/api/Categories/{category.CategoryId}");
        getRequest2.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        var getResponse2 = await _client.SendAsync(getRequest2);
        var category2 = await getResponse2.Content.ReadFromJsonAsync<CategoryGetDTO>();

        Assert.NotNull(category2);
        Assert.NotNull(category2.LastUsedDate);
        Assert.True(category2.LastUsedDate > firstLastUsedDate, "LastUsedDate should be updated to a later time");
    }

    [Fact]
    public async Task TrackCategoryUsage_ReturnsNotFound_WithInvalidCategoryId()
    {
        var loginData = _utilities.CreateTestLoginData();

        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Categories/non-existent-id/usage");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task TrackCategoryUsage_ReturnsForbidden_WhenTrackingAnotherUsersCategory()
    {
        var loginData1 = _utilities.CreateTestLoginData();
        var loginData2 = _utilities.CreateTestLoginData();

        var category = await CreateTestCategory(loginData1, "User 1 Category");

        // Try to track usage of user 1's category with user 2's token
        var request = new HttpRequestMessage(HttpMethod.Post, $"/api/Categories/{category.CategoryId}/usage");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData2.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task TrackCategoryUsage_WithoutAuthorization_ReturnsUnauthorized()
    {
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Categories/some-category-id/usage");
        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetMostUsedCategories_ReturnsOk_WithDefaultLimit()
    {
        var loginData = _utilities.CreateTestLoginData();

        // Create multiple categories with different usage counts
        var category1 = await CreateTestCategory(loginData, "Category 1");
        var category2 = await CreateTestCategory(loginData, "Category 2");
        var category3 = await CreateTestCategory(loginData, "Category 3");

        // Track usage with different counts
        await TrackUsage(loginData, category1.CategoryId, 5);
        await TrackUsage(loginData, category2.CategoryId, 3);
        await TrackUsage(loginData, category3.CategoryId, 8);

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Categories/most-used");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var categories = await response.Content.ReadFromJsonAsync<List<CategoryGetDTO>>();
        Assert.NotNull(categories);
        Assert.True(categories.Count <= 5); // Default limit is 5
        Assert.True(categories.Count >= 3); // We created 3 categories
    }

    [Fact]
    public async Task GetMostUsedCategories_ReturnsCategoriesInDescendingOrderByUsageCount()
    {
        var loginData = _utilities.CreateTestLoginData();

        // Create categories with specific usage patterns
        var categoryLow = await CreateTestCategory(loginData, "Low Usage");
        var categoryMedium = await CreateTestCategory(loginData, "Medium Usage");
        var categoryHigh = await CreateTestCategory(loginData, "High Usage");

        // Set different usage counts
        await TrackUsage(loginData, categoryLow.CategoryId, 1);
        await TrackUsage(loginData, categoryMedium.CategoryId, 5);
        await TrackUsage(loginData, categoryHigh.CategoryId, 10);

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Categories/most-used");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var categories = await response.Content.ReadFromJsonAsync<List<CategoryGetDTO>>();
        Assert.NotNull(categories);
        Assert.True(categories.Count >= 3);

        // Verify ordering - highest usage first
        Assert.Equal(categoryHigh.CategoryId, categories[0].CategoryId);
        Assert.Equal(10, categories[0].UsageCount);
        Assert.Equal(categoryMedium.CategoryId, categories[1].CategoryId);
        Assert.Equal(5, categories[1].UsageCount);
        Assert.Equal(categoryLow.CategoryId, categories[2].CategoryId);
        Assert.Equal(1, categories[2].UsageCount);
    }

    [Fact]
    public async Task GetMostUsedCategories_RespectsCustomLimit()
    {
        var loginData = _utilities.CreateTestLoginData();

        // Create 5 categories
        for (int i = 1; i <= 5; i++)
        {
            var category = await CreateTestCategory(loginData, $"Category {i}");
            await TrackUsage(loginData, category.CategoryId, i);
        }

        // Request only top 2
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Categories/most-used?limit=2");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var categories = await response.Content.ReadFromJsonAsync<List<CategoryGetDTO>>();
        Assert.NotNull(categories);
        Assert.Equal(2, categories.Count);

        // Verify they are the top 2
        Assert.Equal(5, categories[0].UsageCount);
        Assert.Equal(4, categories[1].UsageCount);
    }

    [Fact]
    public async Task GetMostUsedCategories_ReturnsEmptyList_WithNoCategories()
    {
        var loginData = _utilities.CreateTestLoginData();

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Categories/most-used");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var categories = await response.Content.ReadFromJsonAsync<List<CategoryGetDTO>>();
        Assert.NotNull(categories);
        Assert.Empty(categories);
    }

    [Fact]
    public async Task GetMostUsedCategories_SortsByLastUsedDate_WhenUsageCountIsEqual()
    {
        var loginData = _utilities.CreateTestLoginData();

        // Create categories with same usage count but different last used dates
        var categoryOlder = await CreateTestCategory(loginData, "Older");
        var categoryNewer = await CreateTestCategory(loginData, "Newer");

        // Track usage with same count but at different times
        await TrackUsage(loginData, categoryOlder.CategoryId, 3);
        await Task.Delay(1000); // Ensure timestamp difference
        await TrackUsage(loginData, categoryNewer.CategoryId, 3);

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Categories/most-used");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var categories = await response.Content.ReadFromJsonAsync<List<CategoryGetDTO>>();
        Assert.NotNull(categories);
        Assert.True(categories.Count >= 2);

        // Both have same usage count
        Assert.Equal(3, categories[0].UsageCount);
        Assert.Equal(3, categories[1].UsageCount);

        // Newer should come first (more recently used)
        Assert.Equal(categoryNewer.CategoryId, categories[0].CategoryId);
        Assert.Equal(categoryOlder.CategoryId, categories[1].CategoryId);
    }

    [Fact]
    public async Task GetMostUsedCategories_OnlyReturnsCurrentUserCategories()
    {
        var loginData1 = _utilities.CreateTestLoginData();
        var loginData2 = _utilities.CreateTestLoginData();

        // Create categories for both users
        var user1Category = await CreateTestCategory(loginData1, "User 1 Category");
        var user2Category = await CreateTestCategory(loginData2, "User 2 Category");

        await TrackUsage(loginData1, user1Category.CategoryId, 10);
        await TrackUsage(loginData2, user2Category.CategoryId, 20);

        // User 1 gets most used categories
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Categories/most-used");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData1.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var categories = await response.Content.ReadFromJsonAsync<List<CategoryGetDTO>>();
        Assert.NotNull(categories);

        // Should only contain user 1's category, not user 2's
        Assert.Contains(categories, c => c.CategoryId == user1Category.CategoryId);
        Assert.DoesNotContain(categories, c => c.CategoryId == user2Category.CategoryId);
    }
    [Fact]
    public async Task GetMostUsedCategories_WithoutAuthorization_ReturnsUnauthorized()
    {
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Categories/most-used");
        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetMostUsedCategories_IncludesArtefacts()
    {
        var loginData = _utilities.CreateTestLoginData();

        var category = await CreateTestCategory(loginData, "Category With Artefacts");
        await TrackUsage(loginData, category.CategoryId, 1);

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Categories/most-used");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var categories = await response.Content.ReadFromJsonAsync<List<CategoryGetDTO>>();
        Assert.NotNull(categories);
        Assert.NotEmpty(categories);

        // Verify artefacts collection is included (even if empty)
        Assert.NotNull(categories[0].Artefacts);
    }

    private async Task<CategoryGetDTO> CreateTestCategory(TestLoginData loginData, string categoryName)
    {
        var content = new MultipartFormDataContent
        {
            { new StringContent(loginData.UserId.ToString()), nameof(CategoryPostDTO.UserId) },
            { new StringContent(categoryName), nameof(CategoryPostDTO.Name) }
        };

        var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Categories");
        postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
        postRequest.Content = content;
        var postResponse = await _client.SendAsync(postRequest);
        Assert.Equal(HttpStatusCode.OK, postResponse.StatusCode);

        var category = await postResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();
        Assert.NotNull(category);

        return category;
    }

    private async Task TrackUsage(TestLoginData loginData, string categoryId, int times)
    {
        for (int i = 0; i < times; i++)
        {
            var request = new HttpRequestMessage(HttpMethod.Post, $"/api/Categories/{categoryId}/usage");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", loginData.Token);
            var response = await _client.SendAsync(request);
            Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

            // Small delay to ensure timestamp differences if needed
            if (i < times - 1)
            {
                await Task.Delay(10);
            }
        }
    }
}
