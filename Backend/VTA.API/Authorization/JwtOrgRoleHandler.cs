using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;

namespace VTA.API.Authorization;

/// <summary>
/// Reads the org_roles claim from a Core-issued JWT and checks the user's role
/// for the organization specified in the route ({orgId}).
/// Role hierarchy: owner > admin > member.
/// </summary>
public class JwtOrgRoleHandler : IAuthorizationHandler
{
    private static readonly Dictionary<string, int> RoleLevels = new()
    {
        ["member"] = 0,
        ["admin"] = 1,
        ["owner"] = 2,
    };

    private readonly IHttpContextAccessor _httpContextAccessor;

    public JwtOrgRoleHandler(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public Task HandleAsync(AuthorizationHandlerContext context)
    {
        foreach (var requirement in context.PendingRequirements.ToList())
        {
            var minRole = requirement switch
            {
                OrgOwnerRequirement => "owner",
                OrgAdminRequirement => "admin",
                OrgMemberRequirement => "member",
                _ => null
            };

            if (minRole is null)
                continue;

            if (HasMinRole(context.User, minRole))
                context.Succeed(requirement);
            else
                context.Fail();
        }

        return Task.CompletedTask;
    }

    private bool HasMinRole(ClaimsPrincipal user, string minRole)
    {
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext is null)
            return false;

        var orgIdInUrl = httpContext.Request.RouteValues["orgId"]?.ToString();
        if (string.IsNullOrEmpty(orgIdInUrl))
            return false;

        var orgRoles = GetOrgRoles(user);
        if (orgRoles is null || !orgRoles.TryGetValue(orgIdInUrl, out var userRole))
            return false;

        if (!RoleLevels.TryGetValue(userRole, out var userLevel) ||
            !RoleLevels.TryGetValue(minRole, out var requiredLevel))
            return false;

        return userLevel >= requiredLevel;
    }

    private static Dictionary<string, string>? GetOrgRoles(ClaimsPrincipal user)
    {
        var orgRolesClaim = user.FindFirst("org_roles")?.Value;
        if (string.IsNullOrEmpty(orgRolesClaim))
            return null;

        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, string>>(orgRolesClaim);
        }
        catch
        {
            return null;
        }
    }
}
