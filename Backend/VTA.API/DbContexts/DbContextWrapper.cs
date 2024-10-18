using Microsoft.EntityFrameworkCore;

namespace VTA.API.DbContexts;

public static class DbContextWrapper
{
    public static WebApplicationBuilder WrapDbContext<TContext>(this WebApplicationBuilder builder) where TContext : DbContext
    {
        string connectionType = "DefaultConnection";

        builder.Services.AddDbContext<TContext>(opt =>
        {
            try
            {
                opt.UseMySql(
                    builder.Configuration.GetConnectionString(connectionType),
                    ServerVersion.AutoDetect(builder.Configuration.GetConnectionString(connectionType)),
                    options =>
                    {
                        options.EnableStringComparisonTranslations();
                        options.EnableRetryOnFailure();
                    }
                );
            }
            catch (Exception e)
            {
                Console.WriteLine($"An error occurred while configuring MySQL: {e.Message}\n\n Falling Back to a volatile DB");

            }
        });
        return builder;
    }
}