using System;
using System.Diagnostics;
using System.IO;

namespace VTA.Tests.TestHelpers.Database
{
    public class DatabaseSchemaDumper
    {
        public static string DumpDatabaseSchema()
        {
            var username = Environment.GetEnvironmentVariable("DB_USER") ?? throw new ArgumentNullException("DB_USER environment variable not set.");
            var password = Environment.GetEnvironmentVariable("DB_PASSWORD") ?? throw new ArgumentNullException("DB_PASSWORD environment variable not set.");
            var databaseName = Environment.GetEnvironmentVariable("DB_NAME") ?? throw new ArgumentNullException("DB_NAME environment variable not set.");
            var server = Environment.GetEnvironmentVariable("DB_SERVER") ?? "localhost";
            var port = Environment.GetEnvironmentVariable("DB_PORT") ?? "3306";

            var schemaFilePath = Path.GetTempFileName();

            var process = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "mysqldump",
                    Arguments = $"--host={server} --port={port} --user={username} --password={password} --no-data {databaseName}",
                    RedirectStandardOutput = true,
                    RedirectStandardInput = true,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                }
            };

            using (var writer = new StreamWriter(schemaFilePath))
            {
                process.Start();
                writer.Write(process.StandardOutput.ReadToEnd());
                process.WaitForExit();
            }

            return schemaFilePath;
        }
    }
}
