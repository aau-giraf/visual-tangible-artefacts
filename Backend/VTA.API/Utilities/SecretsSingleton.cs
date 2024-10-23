namespace VTA.API.Utilities
{
    using System;
    using System.Collections.Concurrent;

    public class SecretsSingleton
    {
        // Lazy initialization for singleton instance
        private static readonly Lazy<SecretsSingleton> _instance = new Lazy<SecretsSingleton>(() => new SecretsSingleton());

        // Private constructor to prevent instantiation from outside
        private SecretsSingleton()
        {
            // Initialize the dictionary in the constructor
            Secrets = new ConcurrentDictionary<string, string?>();
        }

        // Public property to access the singleton instance
        public static SecretsSingleton Instance => _instance.Value;

        // Use ConcurrentDictionary for thread safety
        public ConcurrentDictionary<string, string?> Secrets { get; }

        // Method to add a secret
        public void AddSecret(string key, string? value)
        {
            // Add or update the secret in the concurrent dictionary
            Secrets[key] = value;
        }
    }

}
