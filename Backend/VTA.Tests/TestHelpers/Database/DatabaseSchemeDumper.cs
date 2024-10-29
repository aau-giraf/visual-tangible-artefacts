using System;
using System.Diagnostics;
using System.IO;

namespace VTA.Tests.TestHelpers.Database
{
    public class DatabaseSchemaDumper
    {
        public static string DumpDatabaseSchema()
        {
            var sshServer = Environment.GetEnvironmentVariable("SSH_DOMAIN") ?? throw new ArgumentNullException("SSH_DOMAIN environment variable not set.");
            var sshUser = Environment.GetEnvironmentVariable("SSH_USER") ?? throw new ArgumentNullException("SSH_USER environment variable not set.");
            var sshPassword = Environment.GetEnvironmentVariable("SSH_PASSWORD") ?? throw new ArgumentNullException("SSH_PASSWORD environment variable not set.");

            var dbUser = Environment.GetEnvironmentVariable("DB_USER") ?? throw new ArgumentNullException("DB_USER environment variable not set.");
            var dbPassword = Environment.GetEnvironmentVariable("DB_PASSWORD") ?? throw new ArgumentNullException("DB_PASSWORD environment variable not set.");
            var databaseName = Environment.GetEnvironmentVariable("DB_NAME") ?? throw new ArgumentNullException("DB_NAME environment variable not set.");
            var dbServer = Environment.GetEnvironmentVariable("DB_SERVER") ?? "localhost";
            var dbPort = Environment.GetEnvironmentVariable("DB_PORT") ?? "3306";

            var schemaFilePath = Path.GetTempFileName();

            var sshTunnelProcess = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "sshpass",
                    Arguments = $"-p '{sshPassword}' ssh -L 13306:{dbServer}:{dbPort} {sshUser}@{sshServer}",
                    RedirectStandardOutput = true,
                    RedirectStandardInput = true,
                    UseShellExecute = false,
                    CreateNoWindow = true,
                }
            };

            sshTunnelProcess.Start();

            try
            {
                var mysqldumpProcess = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = "mysqldump",
                        Arguments = $"--host=localhost --port=13306 --user={dbUser} --password='{dbPassword}' --no-data {databaseName}",
                        RedirectStandardOutput = true,
                        UseShellExecute = false,
                        CreateNoWindow = true,
                    }
                };

                using (var writer = new StreamWriter(schemaFilePath))
                {
                    mysqldumpProcess.Start();
                    writer.Write(mysqldumpProcess.StandardOutput.ReadToEnd());
                    mysqldumpProcess.WaitForExit();
                }
            }
            finally
            {
                sshTunnelProcess.Kill();
            }

            return schemaFilePath;
        }
    }
}
