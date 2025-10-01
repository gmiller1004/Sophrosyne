//
//  OnboardingView.swift
//  Sophrosyne
//
//  Created by Greg Miller on 9/29/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct OnboardingView: View {
    // MARK: - State Variables
    @State private var currentSlide: Int = 0
    @State private var struggle: String = ""
    @State private var faithWord: String = ""
    @State private var isSignedIn: Bool = false
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccessSheet: Bool = false
    @State private var generatedJourney: [String: Any] = [:]
    @State private var isGeneratingJourney: Bool = false
    @State private var navigateToDashboard: Bool = false
    
    // Struggle options
    private let struggles = ["Anxiety", "Grief", "Burnout", "Other"]
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress dots at top
                progressDots
                    .padding(.top, SophrosyneTheme.Spacing.xl)
                    .padding(.bottom, SophrosyneTheme.Spacing.lg)
                
                // TabView with page style for slides
                TabView(selection: $currentSlide) {
                    // Slide 1: Struggle Selection
                    slide1
                        .tag(0)
                    
                    // Slide 2: Faith Word (optional)
                    slide2
                        .tag(1)
                    
                    // Slide 3: Ready to Begin
                    slide3
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentSlide)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showSuccessSheet) {
            SuccessSheet(journey: generatedJourney, navigateToDashboard: $navigateToDashboard)
        }
        .fullScreenCover(isPresented: $navigateToDashboard) {
            DashboardView()
        }
        .sophrosyneTheme()
    }
    
    // MARK: - View Components
    
    /// Progress dots indicator showing which slide the user is on
    private var progressDots: some View {
        HStack(spacing: SophrosyneTheme.Spacing.sm) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == currentSlide ? Color.sophrosynePrimary : Color.sophrosyneTextTertiary.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .animation(.easeInOut, value: currentSlide)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(currentSlide + 1) of 3")
    }
    
    /// Slide 1: Main struggle selection
    private var slide1: some View {
        VStack(spacing: SophrosyneTheme.Spacing.xl) {
            Spacer()
            
            // Header
            VStack(spacing: SophrosyneTheme.Spacing.md) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.sophrosynePrimary)
                
                Text("What's your main struggle?")
                    .font(.sophrosyneTitle2)
                    .scaledFont(.sophrosyneTitle2)
                    .foregroundStyle(Color.sophrosyneTextPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.bottom, SophrosyneTheme.Spacing.lg)
            
            // Struggle picker
            SophrosyneCardView {
                VStack(spacing: SophrosyneTheme.Spacing.md) {
                    Picker("Struggle", selection: $struggle) {
                        Text("Select one").tag("")
                            .foregroundStyle(Color.sophrosyneTextTertiary)
                        ForEach(struggles, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    .accessibilityLabel("Main struggle selector")
                    .accessibilityHint("Choose the primary struggle you're facing: Anxiety, Grief, Burnout, or Other")
                }
            }
            .padding(.horizontal, SophrosyneTheme.Spacing.xl)
            
            Spacer()
            
            // Next button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if !struggle.isEmpty {
                    withAnimation {
                        currentSlide = 1
                    }
                }
            }) {
                Text("Next")
                    .font(.sophrosyneHeadline)
                    .scaledFont(.sophrosyneHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SophrosyneTheme.Spacing.md)
                    .background(struggle.isEmpty ? Color.sophrosyneTextTertiary : Color.sophrosynePrimary)
                    .cornerRadius(SophrosyneTheme.CornerRadius.md)
            }
            .disabled(struggle.isEmpty)
            .padding(.horizontal, SophrosyneTheme.Spacing.xl)
            .padding(.bottom, SophrosyneTheme.Spacing.xl)
            .accessibilityLabel("Continue to next step")
            .accessibilityHint("Tap to proceed after selecting your struggle")
        }
    }
    
    /// Slide 2: Faith word (optional)
    private var slide2: some View {
        VStack(spacing: SophrosyneTheme.Spacing.xl) {
            Spacer()
            
            // Header
            VStack(spacing: SophrosyneTheme.Spacing.md) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.sophrosyneAccent)
                
                Text("Briefly, what's one word describing your faith walk?")
                    .font(.sophrosyneTitle2)
                    .scaledFont(.sophrosyneTitle2)
                    .foregroundStyle(Color.sophrosyneTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SophrosyneTheme.Spacing.lg)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Optional - Skip if you prefer")
                    .font(.sophrosyneCaption)
                    .scaledFont(.sophrosyneCaption)
                    .foregroundStyle(Color.sophrosyneTextSecondary)
            }
            .padding(.bottom, SophrosyneTheme.Spacing.lg)
            
            // Faith word input
            SophrosyneCardView {
                TextField("e.g., seeking, growing, hopeful", text: $faithWord)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.sophrosyneBody)
                    .scaledFont(.sophrosyneBody)
                    .foregroundStyle(Color.sophrosyneTextPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("Faith walk description")
                    .accessibilityHint("Enter one word describing your current faith journey - this is optional")
            }
            .padding(.horizontal, SophrosyneTheme.Spacing.xl)
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: SophrosyneTheme.Spacing.md) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation {
                        currentSlide = 0
                    }
                }) {
                    Text("Back")
                        .font(.sophrosyneCallout)
                        .scaledFont(.sophrosyneCallout)
                        .foregroundStyle(Color.sophrosynePrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SophrosyneTheme.Spacing.md)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: SophrosyneTheme.CornerRadius.md)
                                .stroke(Color.sophrosynePrimary, lineWidth: 2)
                        )
                }
                .accessibilityLabel("Go back to previous step")
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    // Trigger auth if struggle is present (and optionally faith word)
                    if !struggle.isEmpty && !isSignedIn {
                        authenticateUser()
                    }
                    withAnimation {
                        currentSlide = 2
                    }
                }) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isLoading ? "Authenticating..." : "Next")
                            .font(.sophrosyneHeadline)
                            .scaledFont(.sophrosyneHeadline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SophrosyneTheme.Spacing.md)
                    .background(isLoading ? Color.sophrosyneTextTertiary : Color.sophrosynePrimary)
                    .cornerRadius(SophrosyneTheme.CornerRadius.md)
                }
                .disabled(isLoading)
                .accessibilityLabel(isLoading ? "Authenticating your session" : "Continue to next step")
            }
            .padding(.horizontal, SophrosyneTheme.Spacing.xl)
            .padding(.bottom, SophrosyneTheme.Spacing.xl)
        }
    }
    
    /// Slide 3: Ready to begin
    private var slide3: some View {
        VStack(spacing: SophrosyneTheme.Spacing.xl) {
            Spacer()
            
            // Header
            VStack(spacing: SophrosyneTheme.Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.sophrosyneAccent)
                
                Text("Ready to begin?")
                    .font(.sophrosyneTitle)
                    .scaledFont(.sophrosyneTitle)
                    .foregroundStyle(Color.sophrosyneTextPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Text("We'll create a personalized Bible journey just for you")
                    .font(.sophrosyneBody)
                    .scaledFont(.sophrosyneBody)
                    .foregroundStyle(Color.sophrosyneTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SophrosyneTheme.Spacing.xl)
            }
            .padding(.bottom, SophrosyneTheme.Spacing.lg)
            
            // Summary card
            SophrosyneCardView {
                VStack(alignment: .leading, spacing: SophrosyneTheme.Spacing.md) {
                    HStack {
                        Text("Your Struggle:")
                            .font(.sophrosyneCallout)
                            .scaledFont(.sophrosyneCallout)
                            .foregroundStyle(Color.sophrosyneTextSecondary)
                        Spacer()
                        Text(struggle)
                            .font(.sophrosyneHeadline)
                            .scaledFont(.sophrosyneHeadline)
                            .foregroundStyle(Color.sophrosynePrimary)
                    }
                    
                    if !faithWord.isEmpty {
                        Divider()
                        HStack {
                            Text("Faith Walk:")
                                .font(.sophrosyneCallout)
                                .scaledFont(.sophrosyneCallout)
                                .foregroundStyle(Color.sophrosyneTextSecondary)
                            Spacer()
                            Text(faithWord)
                                .font(.sophrosyneHeadline)
                                .scaledFont(.sophrosyneHeadline)
                                .foregroundStyle(Color.sophrosyneAccent)
                        }
                    }
                }
            }
            .padding(.horizontal, SophrosyneTheme.Spacing.xl)
            
            Spacer()
            
            // Navigation buttons
            VStack(spacing: SophrosyneTheme.Spacing.md) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    handleBeginJourney()
                }) {
                    HStack(spacing: 8) {
                        if isGeneratingJourney {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isGeneratingJourney ? "Creating Journey..." : "Begin My Journey")
                            .font(.sophrosyneHeadline)
                            .scaledFont(.sophrosyneHeadline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SophrosyneTheme.Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [Color.sophrosynePrimary, Color.sophrosyneAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(SophrosyneTheme.CornerRadius.md)
                    .sophrosyneShadow(opacity: 0.3, radius: 8, offset: CGSize(width: 0, height: 4))
                }
                .disabled(isGeneratingJourney)
                .accessibilityLabel(isGeneratingJourney ? "Creating your spiritual journey" : "Begin your journey")
                .accessibilityHint("Tap to authenticate and generate your personalized Bible journey")
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation {
                        currentSlide = 1
                    }
                }) {
                    Text("Back")
                        .font(.sophrosyneCallout)
                        .scaledFont(.sophrosyneCallout)
                        .foregroundStyle(Color.sophrosynePrimary)
                }
                .accessibilityLabel("Go back to previous step")
            }
            .padding(.horizontal, SophrosyneTheme.Spacing.xl)
            .padding(.bottom, SophrosyneTheme.Spacing.xl)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.sophrosynePrimary.opacity(0.1), .white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Firebase Auth Functions
    /// Authenticate user anonymously (called after Slide 2 if inputs present)
    /// Following Sophrosyne rules: Early auth for seamless journey creation
    private func authenticateUser() {
        guard !isSignedIn else { return }
        
        print("🔥 DEBUG: authenticateUser() called")
        isLoading = true
        
        Auth.auth().signInAnonymously { result, error in
            print("🔥 DEBUG: Auth callback received - result: \(String(describing: result)), error: \(String(describing: error))")
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Authentication failed: \(error.localizedDescription)"
                    showError = true
                    print("🔥 DEBUG: Authentication error: \(error.localizedDescription)")
                } else if result != nil {
                    isSignedIn = true
                    print("🔥 DEBUG: Authentication successful, setting isSignedIn = true")
                } else {
                    print("🔥 DEBUG: Unexpected: both result and error are nil")
                }
            }
        }
    }
    
    /// Legacy function - kept for backwards compatibility
    private func signInAnonymously() {
        authenticateUser()
    }
    
    // MARK: - Journey Creation
    /// Handles journey generation - auth should already be complete from Slide 2
    /// Following Sophrosyne rules: Streamlined journey creation with early auth
    private func handleBeginJourney() {
        // Guard against empty struggle
        guard !struggle.isEmpty else {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            errorMessage = "Please select a struggle to continue"
            showError = true
            return
        }
        
        // Ensure user is authenticated (should be from Slide 2, but double-check)
        if !isSignedIn {
            authenticateUser()
            // Wait a moment for auth to complete, then retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if isSignedIn {
                    handleBeginJourney()
                }
            }
            return
        }
        
        // Set loading state
        isGeneratingJourney = true
        
        // Print inputs for debugging
        print("User struggle: \(struggle)")
        if !faithWord.isEmpty {
            print("User faith walk: \(faithWord)")
        }
        
        // Construct Grok prompt with struggle and optional faith word
        let maturity = faithWord.isEmpty ? "Intermediate" : faithWord
        let grokPrompt = constructGrokPrompt(goal: struggle, maturity: maturity)
        print("Grok Prompt: \(grokPrompt)")
        
        // Generate journey using GrokService with API key (auth already complete)
        Task {
            do {
                let journey = try await GrokService.generateJourney(goal: struggle, maturity: maturity, apiKey: Config.grokAPIKey)
                print("✅ Live Journey: \(journey)")
                
                // Save journey to Firestore
                do {
                    try await saveJourneyToFirestore(goal: struggle, maturity: maturity, journeyDict: journey)
                    
                    // Update UI on main thread after successful save
                    await MainActor.run {
                        // Store the journey data
                        generatedJourney = journey
                        
                        // Stop loading state
                        isGeneratingJourney = false
                        
                        // Success haptic feedback
                        let successFeedback = UINotificationFeedbackGenerator()
                        successFeedback.notificationOccurred(.success)
                        
                        // Show success sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showSuccessSheet = true
                        }
                    }
                } catch {
                    print("❌ Error saving journey to Firestore: \(error)")
                    await MainActor.run {
                        // Stop loading state
                        isGeneratingJourney = false
                        
                        // Set error message and show alert
                        errorMessage = "Journey generated but failed to save. Please try again."
                        showError = true
                        
                        // Show error feedback
                        let errorFeedback = UINotificationFeedbackGenerator()
                        errorFeedback.notificationOccurred(.error)
                    }
                }
            } catch {
                print("❌ Error generating journey: \(error)")
                
                // Fallback to mock data with user notification
                print("🔄 Falling back to mock data...")
                let mockJourney = GrokService.generateMockJourney(goal: struggle, maturity: maturity)
                
                await MainActor.run {
                    // Store the mock journey data
                    generatedJourney = mockJourney
                    
                    // Stop loading state
                    isGeneratingJourney = false
                    
                    // Set fallback alert message
                    errorMessage = "Using sample journey—check your API key configuration?"
                    showError = true
                    
                    // Show warning feedback (not error since we have fallback)
                    let warningFeedback = UINotificationFeedbackGenerator()
                    warningFeedback.notificationOccurred(.warning)
                    
                    // Show success sheet with mock data
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showSuccessSheet = true
                    }
                }
            }
        }
    }
    
    // MARK: - Grok Prompt Construction
    /// Constructs a flexible-length Grok prompt based on struggle severity and faith context
    /// Following Sophrosyne rules: Balanced, adaptive journey generation
    private func constructGrokPrompt(goal: String, maturity: String) -> String {
        return """
        Generate a JSON Bible journey for struggle: \(goal), faithWord: \(maturity).
        
        IMPORTANT: Length should be 7-28 days based on severity:
        - Acute struggles (Grief): 7-14 days
        - Ongoing struggles (Anxiety, Burnout): 14-28 days
        
        REQUIRED JSON FORMAT (do NOT use weeks structure):
        {
          "path": {
            "days": [
              {
                "title": "Day 1: Title here",
                "verse": "Full ESV verse with reference",
                "devotional": {
                  "context": "Biblical background and setting",
                  "meaning": "Deeper theological interpretation",
                  "qaPrompt": "Thoughtful reflection question"
                }
              }
            ]
          }
        }
        
        Generate \(goal == "Grief" ? "7-10" : "14-21") days of content. Use ONLY the format above with a flat 'days' array directly under 'path'.
        """
    }
    
    // MARK: - Firestore Functions
    private func saveJourneyToFirestore(goal: String, maturity: String, journeyDict: [String: Any]) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "SophrosyneError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        
        let db = Firestore.firestore()
        let journeyData: [String: Any] = [
            "goal": goal,
            "maturity": maturity,
            "path": journeyDict,
            "createdAt": Timestamp()
        ]
        
        try await db.collection("users")
            .document(currentUser.uid)
            .collection("journeys")
            .addDocument(data: journeyData)
        
        print("✅ Journey saved to Firestore for user: \(currentUser.uid)")
    }
}

// MARK: - Confetti Particle View
struct ParticleView: View {
    @State private var isAnimating = false
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    let colors = [Color.sophrosynePrimary, Color.sophrosyneAccent, Color.blue, Color.purple, Color.green]
    let symbols = ["✨", "🌟", "💫", "⭐", "🎉"]
    
    var body: some View {
        Text(symbols.randomElement() ?? "✨")
            .font(.system(size: CGFloat.random(in: 12...20)))
            .foregroundColor(colors.randomElement() ?? Color.sophrosynePrimary)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .offset(
                x: CGFloat.random(in: -100...100),
                y: CGFloat.random(in: -200...200)
            )
            .animation(
                .easeInOut(duration: Double.random(in: 1.0...3.0))
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                rotation = Double.random(in: 0...360)
                scale = CGFloat.random(in: 0.5...1.5)
                isAnimating = true
            }
    }
}

// MARK: - Success Sheet
struct SuccessSheet: View {
    @Environment(\.dismiss) private var dismiss
    let journey: [String: Any]
    @Binding var navigateToDashboard: Bool
    
    var body: some View {
        ZStack {
            // Confetti particles background
            ForEach(0..<10, id: \.self) { _ in
                ParticleView()
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Prayer emoji
                    Text("🙏")
                        .font(.system(size: 60))
                
                // Success message
                Text("Your Journey is Ready!")
                    .font(.title2)
                    .scaledFont(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Your personalized Bible journey has been crafted with wisdom and care.")
                    .font(.body)
                    .scaledFont(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .accessibilityLabel("Success message: Your personalized Bible journey has been crafted with wisdom and care")
                
                // Display journey preview (supports both old and new formats)
                if let path = journey["path"] as? [String: Any] {
                    VStack(alignment: .leading, spacing: 16) {
                        // New format: Direct days array
                        if let days = path["days"] as? [[String: Any]] {
                            Text("Your \(days.count)-Day Journey Preview:")
                                .font(.headline)
                                .scaledFont(.headline)
                                .foregroundStyle(.primary)
                            
                            ForEach(Array(days.prefix(3).enumerated()), id: \.offset) { index, day in
                                HStack {
                                    Text("Day \(index + 1):")
                                        .font(.subheadline)
                                        .scaledFont(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(Color.sophrosynePrimary)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    Text(day["title"] as? String ?? "Untitled")
                                        .font(.subheadline)
                                        .scaledFont(.subheadline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                            }
                            
                            if days.count > 3 {
                                Text("...and \(days.count - 3) more days")
                                    .font(.caption)
                                    .scaledFont(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        // Old format: Weeks with days
                        else if let weeks = path["weeks"] as? [[String: Any]] {
                            Text("Your 4-Week Journey Preview:")
                                .font(.headline)
                                .scaledFont(.headline)
                                .foregroundStyle(.primary)
                                .accessibilityAddTraits(.isHeader)
                            
                            List {
                                ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Week \(index + 1)")
                                            .font(.headline)
                                            .foregroundStyle(.blue)
                                        
                                        Text(week["title"] as? String ?? "Untitled")
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        
                                        if let days = week["days"] as? [[String: Any]] {
                                            Text("\(days.count) days of reflection")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .frame(height: 200)
                            .listStyle(PlainListStyle())
                        }
                    }
                    .padding()
                    .background(.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                // Close button
                Button("Begin Your Journey") {
                    dismiss()
                    // Add a small delay to ensure the sheet is fully dismissed before presenting the dashboard
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigateToDashboard = true
                    }
                }
                .font(.sophrosyneHeadline)
                .scaledFont(.sophrosyneHeadline)
                .foregroundStyle(.white)
                .padding(.horizontal, SophrosyneTheme.Spacing.xl)
                .padding(.vertical, SophrosyneTheme.Spacing.md)
                .background(Color.sophrosynePrimary)
                .cornerRadius(SophrosyneTheme.CornerRadius.md)
                .shadow(color: Color.sophrosynePrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                .accessibilityLabel("Begin your spiritual journey")
                .accessibilityHint("Tap to start your personalized Bible journey and view your dashboard")
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.sophrosynePrimary.opacity(0.1), .white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

#Preview {
    OnboardingView()
        .previewDevice("iPhone 15 Pro")
        .previewDisplayName("Onboarding Journey")
}