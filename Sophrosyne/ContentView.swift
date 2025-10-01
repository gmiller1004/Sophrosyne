//
//  ContentView.swift
//  Sophrosyne
//
//  Created by Greg Miller on 9/29/25.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen LinearGradient background
                SophrosyneGradient()
                
                // Centered VStack with welcome content
                VStack(spacing: SophrosyneTheme.Spacing.lg) {
                    // Animated prayer hands icon
                    Image(systemName: "heart.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.sophrosyneAccent)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                        .onAppear {
                            isAnimating = true
                        }
                    
                    // Large Sophrosyne title
                    Text("Sophrosyne")
                        .font(.sophrosyneLargeTitle)
                        .foregroundStyle(Color.sophrosyneTextPrimary)
                        .sophrosyneShadow()
                    
                    // Enhanced subtitle with line limit
                    Text("Biblical Wisdom for Balanced Healing")
                        .font(.sophrosyneHeadline)
                        .foregroundStyle(Color.sophrosyneTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Begin Journey button
                    NavigationLink(destination: OnboardingView()) {
                        SophrosyneButton(
                            title: "Begin Your Journey",
                            color: .sophrosynePrimary
                        )
                    }
                    
                    // Dashboard button (for testing)
                    NavigationLink(destination: DashboardView()) {
                        SophrosyneButton(
                            title: "View Dashboard",
                            color: .sophrosyneAccent
                        )
                    }
                }
                .padding(.horizontal, SophrosyneTheme.Spacing.xl)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Notification delegate is now set in AppDelegate
        }
        // Notification handling moved to DashboardView to avoid sheet conflicts
        .sophrosyneTheme()
    }
    
    // MARK: - Functions
}

// MARK: - Reusable Components
struct SophrosyneGradient: View {
    var body: some View {
        LinearGradient(
            colors: [.blue.opacity(0.1), .white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct SophrosyneButton: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.sophrosyneHeadline)
            .foregroundStyle(.white)
            .padding(.horizontal, SophrosyneTheme.Spacing.xl)
            .padding(.vertical, SophrosyneTheme.Spacing.md)
            .background(color)
            .cornerRadius(SophrosyneTheme.CornerRadius.md)
            .sophrosyneShadow(opacity: 0.3, radius: 8, offset: CGSize(width: 0, height: 4))
    }
}

#Preview("Serene Welcome - Light Mode") {
    ContentView()
        .previewDevice("iPhone 15 Pro")
}

#Preview("Serene Welcome - Dark Mode") {
    ContentView()
        .previewDevice("iPhone 15 Pro")
        .colorScheme(.dark)
}

