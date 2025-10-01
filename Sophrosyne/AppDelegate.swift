//
//  AppDelegate.swift
//  Sophrosyne
//
//  Created by Greg Miller on 9/30/25.
//

import UIKit
import FirebaseMessaging
import UserNotifications

/// AppDelegate for handling Firebase Messaging and other app lifecycle events
/// Following Sophrosyne rules: Balanced integration with proper error handling
class AppDelegate: NSObject, UIApplicationDelegate {
    
    /// Called when the app finishes launching
    /// Sets up Firebase Messaging delegate for push notification handling
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Configure Firebase Messaging delegate
        Messaging.messaging().delegate = self
        
        // Set up notification center delegate for handling local notifications
        UNUserNotificationCenter.current().delegate = self
        
        print("✅ AppDelegate: Notification center delegate set")
        
        return true
    }
    
    /// Called when the app successfully registers for remote notifications
    /// Sets the APNS token for Firebase Messaging to enable push notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 APNS Device Token received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        
        // Set the APNS token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }
    
    /// Called when the app fails to register for remote notifications
    /// Logs the error for debugging purposes
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {
    
    /// Called when the FCM registration token is updated
    /// This method is called on app start and whenever a new token is generated
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 Firebase Messaging Token: \(fcmToken ?? "nil")")
        
        // TODO: Send token to server for push notification targeting
        // This would typically involve sending the token to your backend service
        // to enable targeted push notifications for this user
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// Called when a notification is received while the app is in the foreground
    /// Handles local notifications and navigates to verse detail view
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("📱 AppDelegate: Notification tap received!")
        print("📱 Notification title: \(response.notification.request.content.title)")
        print("📱 Notification body: \(response.notification.request.content.body)")
        print("📱 UserInfo: \(response.notification.request.content.userInfo)")
        
        // Parse the notification content
        let userInfo = response.notification.request.content.userInfo
        
        // Extract verse and reflection from userInfo
        guard let reflection = userInfo["reflection"] as? String else {
            print("❌ No reflection found in notification userInfo")
            completionHandler()
            return
        }
        
        let verse = response.notification.request.content.body
        print("📖 Verse: \(verse)")
        print("💭 Reflection: \(reflection)")
        
        // Navigate to VerseDetailView
        DispatchQueue.main.async {
            print("📱 AppDelegate: Posting ShowVerseDetail notification")
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowVerseDetail"),
                object: nil,
                userInfo: [
                    "verse": verse,
                    "reflection": reflection
                ]
            )
        }
        
        completionHandler()
    }
    
    /// Called when a notification is received while the app is in the foreground
    /// Allows the app to handle notifications while active
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("📱 Foreground notification received: \(notification.request.content.title)")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
