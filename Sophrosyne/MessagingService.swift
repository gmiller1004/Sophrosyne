//
//  MessagingService.swift
//  Sophrosyne
//
//  Created by Greg Miller on 9/30/25.
//

import Foundation
import FirebaseMessaging

/// Service class for managing Firebase Cloud Messaging operations
/// Following Sophrosyne rules: Balanced integration with proper error handling
class MessagingService {
    
    // MARK: - Token Management
    
    /// Retrieves the current FCM registration token
    /// - Returns: The FCM token string, or nil if retrieval fails
    /// - Note: This method handles errors gracefully and returns nil on failure
    static func getToken() async -> String? {
        do {
            let token = try await Messaging.messaging().token()
            return token
        } catch {
            print("❌ Failed to retrieve FCM token: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Future Extensions
    // Additional messaging functionality can be added here as needed:
    // - Permission requests
    // - Topic subscriptions
    // - Message handling
}
