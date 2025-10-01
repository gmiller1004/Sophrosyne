//
//  Config.swift
//  Sophrosyne
//
//  Created by Greg Miller on 9/30/25.
//

import Foundation

/// Configuration management for API keys and sensitive data
/// Following Sophrosyne rules: Balanced security with proper key management
struct Config {
    
    // MARK: - API Keys
    
    /// Grok API key retrieved from environment or configuration
    /// Priority: Environment Variable > Bundle Configuration > Default
    static var grokAPIKey: String {
        // First try environment variable
        if let envKey = ProcessInfo.processInfo.environment["GROK_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Then try bundle configuration
        if let bundleKey = Bundle.main.object(forInfoDictionaryKey: "GROK_API_KEY") as? String, !bundleKey.isEmpty {
            return bundleKey
        }
        
        // Fallback to default (should be replaced in production)
        return "your_key_here"
    }
    
    // MARK: - Environment Detection
    
    /// Determines if running in development mode
    static var isDevelopment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Determines if API key is properly configured
    static var isAPIKeyConfigured: Bool {
        return grokAPIKey != "your_key_here" && !grokAPIKey.isEmpty
    }
    
    // MARK: - Security Helpers
    
    /// Returns a masked version of the API key for logging
    static var maskedAPIKey: String {
        let key = grokAPIKey
        if key.count <= 8 {
            return String(repeating: "*", count: key.count)
        }
        return String(key.prefix(4)) + String(repeating: "*", count: key.count - 8) + String(key.suffix(4))
    }
}
