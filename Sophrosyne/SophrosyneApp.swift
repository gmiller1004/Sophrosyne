//
//  SophrosyneApp.swift
//  Sophrosyne
//
//  Created by Greg Miller on 9/29/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseAnalytics
import FirebaseMessaging

@main
struct SophrosyneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Firebase settings programmatically
        configureFirebaseForDevelopment()
    }
    
    private func configureFirebaseForDevelopment() {
        // Disable Analytics collection in development
        #if DEBUG
        Analytics.setAnalyticsCollectionEnabled(false)
        #endif
        
        // Disable Firebase Messaging auto-initialization after a brief delay
        // to ensure Firebase is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Messaging.messaging().isAutoInitEnabled = false
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
