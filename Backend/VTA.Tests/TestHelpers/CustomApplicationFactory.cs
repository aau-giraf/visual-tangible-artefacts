// File: VTA.Tests/TestHelpers/CustomWebApplicationFactory.cs
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System.Diagnostics;
using VTA.API;
using VTA.API.DbContexts;

public class CustomWebApplicationFactory<TEntryPoint> : WebApplicationFactory<TEntryPoint> where TEntryPoint : class
{
    private string _sshServer;
    private string _sshUsername;
    private string _sshPassword;
    private string _sshLocalPort;
    private string _sshRemotePort;

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureAppConfiguration((context, config) =>
        {
            config.AddJsonFile("appsettings.json", optional: true)
                  .AddEnvironmentVariables();
        });

        builder.ConfigureServices(services =>
        {
            // Remove existing registration of DbContext if any
            var descriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(DbContextOptions<UserContext>));
            if (descriptor != null)
                services.Remove(descriptor);

            // Get configuration from appsettings.json or environment
            var config = services.BuildServiceProvider().GetRequiredService<IConfiguration>();

            // SSH details for tunneling if required
            _sshServer = config["SSH:Server"] ?? Environment.GetEnvironmentVariable("SSH_SERVER");
            _sshUsername = config["SSH:Username"] ?? Environment.GetEnvironmentVariable("SSH_USER");
            _sshPassword = config["SSH:Password"] ?? Environment.GetEnvironmentVariable("SSH_PASSWORD");
            _sshLocalPort = config["SSH:Port"] ?? "13306";
            _sshRemotePort = config["SSH:RemoteDatabasePort"] ?? "3306";

            // Determine if SSH tunnel is required
            bool requiresSshTunnel = string.IsNullOrEmpty(config["DB_SERVER"]);

            if (requiresSshTunnel)
            {
                StartSshTunnel();
            }

            // Use TestConnection for testing
            var connectionString = config.GetConnectionString("TestConnection");

            services.AddDbContext<UserContext>(options =>
            {
                options.UseMySql(connectionString, new MySqlServerVersion(new Version(8, 0, 23)));
            });
        });
    }

    private void StartSshTunnel()
    {
        string arguments;

        if (!string.IsNullOrEmpty(_sshPassword))
        {
            arguments = $"-p \"{_sshPassword}\" ssh -o StrictHostKeyChecking=no -L {_sshLocalPort}:localhost:{_sshRemotePort} {_sshUsername}@{_sshServer} -N";
            
            var processInfo = new ProcessStartInfo
            {
                FileName = "sshpass",
                Arguments = arguments,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            var process = Process.Start(processInfo);
            process.OutputDataReceived += (sender, args) => Console.WriteLine(args.Data);
            process.ErrorDataReceived += (sender, args) => Console.WriteLine(args.Data);
            
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
        }
        else
        {
            arguments = $"-L {_sshLocalPort}:localhost:{_sshRemotePort} {_sshUsername}@{_sshServer} -N";
            
            var processInfo = new ProcessStartInfo
            {
                FileName = "ssh",
                Arguments = arguments,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            var process = Process.Start(processInfo);
            process.OutputDataReceived += (sender, args) => Console.WriteLine(args.Data);
            process.ErrorDataReceived += (sender, args) => Console.WriteLine(args.Data);
            
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
        }

        Console.WriteLine("SSH tunnel started for local testing.");
    }   
}
