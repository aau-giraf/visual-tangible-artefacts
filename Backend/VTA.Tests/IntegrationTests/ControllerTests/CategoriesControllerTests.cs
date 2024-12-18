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
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        var token = signUpResult?.Token;

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Categories");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var categories = await response.Content.ReadFromJsonAsync<List<CategoryGetDTO>>();
        Assert.NotNull(categories);

        await _utilities.DeleteUserAsync(signUpResult!.userId, token);
    }

    [Fact]
    public async Task TestPostCategoryReturnsOk()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        var token = signUpResult?.Token;
        var userId = signUpResult?.userId;

        var categoryPostDTO = new CategoryPostDTO
        {
            UserId = userId!,
            Name = "Test Category"
        };

        var content = new MultipartFormDataContent();
        content.Add(new StringContent(categoryPostDTO.UserId), nameof(CategoryPostDTO.UserId));
        content.Add(new StringContent(categoryPostDTO.Name), nameof(CategoryPostDTO.Name));

        var request = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Categories");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        request.Content = content;

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var category = await response.Content.ReadFromJsonAsync<CategoryGetDTO>();
        Assert.NotNull(category);
        Assert.Equal("Test Category", category.Name);

        await _utilities.DeleteUserAsync(signUpResult!.userId, token);
    }

    [Fact]
    public async Task TestDeleteCategoryReturnsNoContent()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        var token = signUpResult?.Token;
        var userId = signUpResult?.userId;

        var categoryPostDTO = new CategoryPostDTO
        {
            UserId = userId!,
            Name = "Test Category"
        };

        var content = new MultipartFormDataContent();
        content.Add(new StringContent(categoryPostDTO.UserId), nameof(CategoryPostDTO.UserId));
        content.Add(new StringContent(categoryPostDTO.Name), nameof(CategoryPostDTO.Name));

        var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Categories");
        postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        postRequest.Content = content;

        var postResponse = await _client.SendAsync(postRequest);
        Assert.Equal(HttpStatusCode.OK, postResponse.StatusCode);

        var category = await postResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

        var deleteRequest = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/Categories/{category.CategoryId}");
        deleteRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var deleteResponse = await _client.SendAsync(deleteRequest);
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Categories/{category.CategoryId}");
        getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var getResponse = await _client.SendAsync(getRequest);
        Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);

        await _utilities.DeleteUserAsync(signUpResult!.userId, token);
    }

    [Fact]
    public async Task TestGetCategoryReturnsNotFound()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        var token = signUpResult?.Token;

        var request = new HttpRequestMessage(HttpMethod.Get, "/api/Users/Categories/nonexistent");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);

        var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        var errorResponse = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        Assert.NotNull(errorResponse);

        await _utilities.DeleteUserAsync(signUpResult!.userId, token);
    }

    [Fact]
    public async Task TestPatchCategoryReturnsNoContent()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        var token = signUpResult?.Token;
        var userId = signUpResult?.userId;

        var categoryPostDTO = new CategoryPostDTO
        {
            UserId = userId!,
            Name = "Test Category"
        };

        var content = new MultipartFormDataContent
        {
            { new StringContent(categoryPostDTO.UserId), nameof(CategoryPostDTO.UserId) },
            { new StringContent(categoryPostDTO.Name), nameof(CategoryPostDTO.Name) }
        };

        var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Categories");
        postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
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

        var patchRequest = new HttpRequestMessage(HttpMethod.Patch, "/api/Users/Categories");
        patchRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        patchRequest.Content = patchContent;

        var patchResponse = await _client.SendAsync(patchRequest);
        Assert.Equal(HttpStatusCode.NoContent, patchResponse.StatusCode);

        var getRequest = new HttpRequestMessage(HttpMethod.Get, $"/api/Users/Categories/{category.CategoryId}");
        getRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var getResponse = await _client.SendAsync(getRequest);
        var updatedCategory = await getResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();
        Assert.Equal("Updated Category", updatedCategory.Name);

        await _utilities.DeleteUserAsync(signUpResult!.userId, token);
    }

    [Fact]
    public async Task TestPatchCategoryReturnsBadRequest()
    {
        var username = _utilities.GenerateUniqueUsername();
        var (signUpStatus, signUpResult) = await _utilities.SignUpUserAsync(username, "testpassword", "Test User");
        Assert.Equal(HttpStatusCode.OK, signUpStatus);
        var token = signUpResult?.Token;

        var patchDTO = new CategoryPatchDTO
        {
            CategoryId = "nonexistent",
            Name = "Updated Category"
        };

        var patchContent = new MultipartFormDataContent();
        patchContent.Add(new StringContent(patchDTO.CategoryId), nameof(CategoryPatchDTO.CategoryId));
        patchContent.Add(new StringContent(patchDTO.Name), nameof(CategoryPatchDTO.Name));

        var patchRequest = new HttpRequestMessage(HttpMethod.Patch, "/api/Users/Categories");
        patchRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        patchRequest.Content = patchContent;

        var patchResponse = await _client.SendAsync(patchRequest);
        Assert.Equal(HttpStatusCode.BadRequest, patchResponse.StatusCode);

        await _utilities.DeleteUserAsync(signUpResult!.userId, token);
    }

    [Fact]
    public async Task TestDeleteCategoryReturnsForbidden()
    {
        var username1 = _utilities.GenerateUniqueUsername();
        var (signUpStatus1, signUpResult1) = await _utilities.SignUpUserAsync(username1, "password1", "User One");
        Assert.Equal(HttpStatusCode.OK, signUpStatus1);
        var token1 = signUpResult1?.Token;
        var userId1 = signUpResult1?.userId;

        var username2 = _utilities.GenerateUniqueUsername();
        var (signUpStatus2, signUpResult2) = await _utilities.SignUpUserAsync(username2, "password2", "User Two");
        Assert.Equal(HttpStatusCode.OK, signUpStatus2);
        var token2 = signUpResult2?.Token;

        var categoryPostDTO = new CategoryPostDTO
        {
            UserId = userId1!,
            Name = "Test Category"
        };

        var content = new MultipartFormDataContent();
        content.Add(new StringContent(categoryPostDTO.UserId), nameof(CategoryPostDTO.UserId));
        content.Add(new StringContent(categoryPostDTO.Name), nameof(CategoryPostDTO.Name));

        var postRequest = new HttpRequestMessage(HttpMethod.Post, "/api/Users/Categories");
        postRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token1);
        postRequest.Content = content;

        var postResponse = await _client.SendAsync(postRequest);
        Assert.Equal(HttpStatusCode.OK, postResponse.StatusCode);

        var category = await postResponse.Content.ReadFromJsonAsync<CategoryGetDTO>();

        var deleteRequest = new HttpRequestMessage(HttpMethod.Delete, $"/api/Users/Categories/{category.CategoryId}");
        deleteRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token2);

        var deleteResponse = await _client.SendAsync(deleteRequest);
        Assert.Equal(HttpStatusCode.Forbidden, deleteResponse.StatusCode);

        await _utilities.DeleteUserAsync(signUpResult1!.userId, token1);
        await _utilities.DeleteUserAsync(signUpResult2!.userId, token2);
    }
}
