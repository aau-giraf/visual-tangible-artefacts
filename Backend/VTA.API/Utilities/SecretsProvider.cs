﻿using System.Collections.Concurrent;

namespace VTA.API.Utilities;

public class SecretsProvider

{
    // Lazy initialization for singleton instance
    private static readonly Lazy<SecretsProvider> _instance = new Lazy<SecretsProvider>(() => new SecretsProvider());

    // Private constructor to prevent instantiation from outside
    private SecretsProvider()
    {
        // Initialize the dictionary in the constructor
        Secrets = new ConcurrentDictionary<string, string?>();
    }

    // Public property to access the singleton instance
    public static SecretsProvider Instance => _instance.Value;

    // Use ConcurrentDictionary for thread safety
    public ConcurrentDictionary<string, string?> Secrets { get; }

    // Method to add a secret
    public void AddSecret(string key, string? value)
    {
        // Add or update the secret in the concurrent dictionary
        Secrets[key] = value;
    }
}
