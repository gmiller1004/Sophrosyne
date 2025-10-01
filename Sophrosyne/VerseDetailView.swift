//
//  VerseDetailView.swift
//  Sophrosyne
//
//  Created by Greg Miller on 9/30/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// View for displaying full devotional with context, meaning, Q&A reflection, and Grok integration
/// Following Sophrosyne rules: Immersive, balanced spiritual learning experience
struct VerseDetailView: View {
    let verse: String
    let reflection: String
    let devotional: [String: Any]?
    let dayNumber: Int?
    
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isAskingGrok = false
    @State private var grokResponse: String?
    @State private var showGrokResponse = false
    @State private var completedAt: Date?
    @State private var canSeal: Bool = false
    @State private var userQuestion: String = ""
    @State private var qaResponse: String = ""
    @State private var qaChain: [[String: Any]] = []
    @State private var showSealSuccess: Bool = false
    
    // Legacy initializer for backwards compatibility
    init(verse: String, reflection: String) {
        self.verse = verse
        self.reflection = reflection
        self.devotional = nil
        self.dayNumber = nil
    }
    
    // New initializer with full devotional support
    init(verse: String, devotional: [String: Any]?, dayNumber: Int? = nil) {
        self.verse = verse
        self.reflection = (devotional?["meaning"] as? String) ?? ""
        self.devotional = devotional
        self.dayNumber = dayNumber
    }
    
    var body: some View {
        ZStack {
            // Immersive gradient background
            LinearGradient(
                colors: [.primary.opacity(0.05), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main scrollable content
            ScrollView {
                VStack(spacing: SophrosyneTheme.Spacing.xl) {
                    // Header
                    headerSection
                    
                    // Verse
                    verseSection
                    
                    // Full Devotional Content
                    if let devotional = devotional {
                        // Context
                        contextSection(devotional)
                        
                        // Meaning
                        meaningSection(devotional)
                        
                        // Q&A Reflection
                        qaReflectionSection(devotional)
                    } else {
                        // Legacy reflection fallback
                        reflectionSection
                    }
                }
                .padding(.horizontal, SophrosyneTheme.Spacing.lg)
                .padding(.top, SophrosyneTheme.Spacing.xxl)
                .padding(.bottom, SophrosyneTheme.Spacing.xl)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geo.frame(in: .named("scroll")).minY
                        )
                    }
                )
                .highPriorityGesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            if value.translation.height > 100 && value.velocity.height > 0 {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    dismiss()
                                }
                            }
                        }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            
            // Success banner overlay
            if showSealSuccess {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Sealed—tomorrow's whisper awaits")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .padding()
                    .background(.white.opacity(0.95))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, SophrosyneTheme.Spacing.lg)
                    .padding(.bottom, SophrosyneTheme.Spacing.xl)
                }
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .ignoresSafeArea()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareText])
        }
        .sheet(isPresented: $showGrokResponse) {
            grokResponseSheet
        }
        .onAppear {
            // Haptic feedback on appear
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Calculate if user can seal (24 hours after completion)
            canSeal = Date() > (completedAt?.addingTimeInterval(24*3600) ?? Date.distantPast)
            
            // Load Q&A chain from Firestore
            Task {
                await loadQAChain()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        HStack {
            VStack(spacing: 12) {
                Text("🙏")
                    .font(.system(size: 60))
                
                Text("Daily Grace")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            // Share button
            Button(action: {
                showShareSheet = true
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .padding(12)
                    .background(.white.opacity(0.9))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private var verseSection: some View {
        VStack(spacing: SophrosyneTheme.Spacing.lg) {
            // Enhanced verse display
            Text(verse)
                .font(.custom("Georgia", size: 24))
                .fontWeight(.semibold)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor, lineWidth: 1)
                )
            
            // Context section
            if let devotional = devotional,
               let context = devotional["context"] as? String {
                Section("Context") {
                    Text(context)
                        .font(.body)
                        .padding()
                }
            }
            
            // Meaning section
            if let devotional = devotional,
               let meaning = devotional["meaning"] as? String {
                Section("Meaning for You") {
                    Text(meaning)
                        .italic()
                        .font(.body)
                        .padding()
                }
            }
            
            // Q&A Reflection section
            if let devotional = devotional,
               let qaPrompt = devotional["qaPrompt"] as? String {
                Section("Q&A Reflection") {
                    VStack(spacing: SophrosyneTheme.Spacing.md) {
                        TextField("How does this verse speak to you?", text: $userQuestion)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Ask Grok") {
                            Task {
                                do {
                                    qaResponse = try await GrokService.askReflection(priorQA: qaChain, question: userQuestion)
                                } catch {
                                    qaResponse = "Unable to get response at this time."
                                }
                            }
                        }
                        .disabled(userQuestion.isEmpty)
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                        
                        if !qaResponse.isEmpty {
                            Text(qaResponse)
                                .font(.body)
                                .padding(.top)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                }
            }
            
            // Time-gated Reflect & Seal button
            Button(canSeal ? "Reflect & Seal" : "Return Tomorrow") {
                if canSeal {
                    saveNotesToFirestore()
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    // Set completedAt to current time
                    completedAt = Date()
                    canSeal = false
                    
                    // Show success banner
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSealSuccess = true
                    }
                    
                    // Auto-hide banner after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSealSuccess = false
                        }
                    }
                }
            }
            .disabled(!canSeal)
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .padding(.top, SophrosyneTheme.Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white.opacity(0.9))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reflection")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            ScrollView {
                HStack(alignment: .top, spacing: 8) {
                    // Opening quote mark
                    Image(systemName: "quote.opening")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    
                    Text(reflection)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                    
                    // Closing quote mark
                    Image(systemName: "quote.closing")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .frame(maxHeight: 200)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.9))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var dismissSection: some View {
        VStack(spacing: 8) {
            Text("Swipe down to dismiss")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Image(systemName: "chevron.down")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 40)
    }
    
    
    /// Context section from devotional
    private func contextSection(_ devotional: [String: Any]) -> some View {
        Group {
            if let context = devotional["context"] as? String {
                VStack(alignment: .leading, spacing: SophrosyneTheme.Spacing.md) {
                    Text("Context")
                        .font(.sophrosyneHeadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.sophrosyneTextSecondary)
                    
                    Text(context)
                        .font(.sophrosyneBody)
                        .foregroundStyle(Color.sophrosyneTextPrimary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SophrosyneTheme.Spacing.md)
                .background(.white.opacity(0.9))
                .cornerRadius(SophrosyneTheme.CornerRadius.md)
                .sophrosyneShadow()
            }
        }
    }
    
    /// Meaning section from devotional (displayed in italic)
    private func meaningSection(_ devotional: [String: Any]) -> some View {
        Group {
            if let meaning = devotional["meaning"] as? String {
                VStack(alignment: .leading, spacing: SophrosyneTheme.Spacing.md) {
                    Text("Deeper Meaning")
                        .font(.sophrosyneHeadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.sophrosyneTextSecondary)
                    
                    Text(meaning)
                        .font(.sophrosyneBody)
                        .italic()
                        .foregroundStyle(Color.sophrosyneTextPrimary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SophrosyneTheme.Spacing.md)
                .background(.white.opacity(0.9))
                .cornerRadius(SophrosyneTheme.CornerRadius.md)
                .sophrosyneShadow()
            }
        }
    }
    
    /// Q&A Reflection section with Grok integration
    private func qaReflectionSection(_ devotional: [String: Any]) -> some View {
        Group {
            if let qaPrompt = devotional["qaPrompt"] as? String {
                VStack(alignment: .leading, spacing: SophrosyneTheme.Spacing.md) {
                    Text("Q&A Reflection")
                        .font(.sophrosyneTitle3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.sophrosynePrimary)
                    
                    // Prompt text with special styling
                    Text(qaPrompt)
                        .font(.sophrosyneBody)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.sophrosyneAccent)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(SophrosyneTheme.Spacing.sm)
                        .background(Color.sophrosyneAccent.opacity(0.1))
                        .cornerRadius(SophrosyneTheme.CornerRadius.sm)
                    
                    // Ask Grok button
                    Button(action: {
                        askGrok(prompt: qaPrompt)
                    }) {
                        HStack(spacing: SophrosyneTheme.Spacing.sm) {
                            if isAskingGrok {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Image(systemName: "sparkles")
                                .font(.sophrosyneCallout)
                            
                            Text(isAskingGrok ? "Asking..." : "Ask Grok")
                                .font(.sophrosyneHeadline)
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
                    }
                    .disabled(isAskingGrok)
                    .accessibilityLabel("Ask Grok AI about this reflection")
                    .accessibilityHint("Get personalized spiritual guidance based on your journey")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SophrosyneTheme.Spacing.md)
                .background(.white.opacity(0.95))
                .cornerRadius(SophrosyneTheme.CornerRadius.md)
                .sophrosyneShadow(opacity: 0.15, radius: 8, offset: CGSize(width: 0, height: 4))
            }
        }
    }
    
    /// Grok response sheet
    private var grokResponseSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: SophrosyneTheme.Spacing.lg) {
                    Text("Spiritual Guidance")
                        .font(.sophrosyneTitle2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.sophrosynePrimary)
                    
                    if let response = grokResponse {
                        Text(response)
                            .font(.sophrosyneBody)
                            .foregroundStyle(Color.sophrosyneTextPrimary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(8)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        ProgressView("Receiving guidance...")
                    }
                }
                .padding(SophrosyneTheme.Spacing.lg)
            }
            .background(backgroundGradient)
            .navigationTitle("Grok Response")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showGrokResponse = false
                    }
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.sophrosynePrimary.opacity(0.1),
                Color.sophrosyneAccent.opacity(0.05),
                .white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Grok Integration
    
    /// Ask Grok with context chain from Firestore session history
    /// Following Sophrosyne rules: Contextual, personalized spiritual guidance
    private func askGrok(prompt: String) {
        isAskingGrok = true
        
        Task {
            do {
                // Build context chain from Firestore
                let sessionContext = await buildSessionContext()
                
                // Construct Grok prompt with prior context
                let fullPrompt = """
                Based on prior journey context: \(sessionContext)
                
                Answer this reflection question: \(prompt)
                
                Provide a thoughtful, biblical response that builds on the user's spiritual journey.
                """
                
                // Call Grok API
                let response = try await GrokService.generateJourney(
                    goal: "Spiritual Reflection",
                    maturity: fullPrompt,
                    apiKey: Config.grokAPIKey
                )
                
                // Extract response text (simplified for now)
                await MainActor.run {
                    if let path = response["path"] as? [String: Any],
                       let days = path["days"] as? [[String: Any]],
                       let firstDay = days.first,
                       let devotional = firstDay["devotional"] as? [String: Any],
                       let meaning = devotional["meaning"] as? String {
                        grokResponse = meaning
                    } else {
                        grokResponse = "Received guidance from Grok. Reflect on how this applies to your journey."
                    }
                    
                    isAskingGrok = false
                    showGrokResponse = true
                    
                    // Success haptic
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                print("❌ Error calling Grok: \(error)")
                await MainActor.run {
                    grokResponse = "Unable to receive guidance at this time. Please reflect on the question yourself."
                    isAskingGrok = false
                    showGrokResponse = true
                    
                    // Warning haptic
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            }
        }
    }
    
    /// Build session context from Firestore journey history
    private func buildSessionContext() async -> String {
        guard let currentUser = Auth.auth().currentUser else {
            return "Beginning spiritual journey"
        }
        
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("users")
                .document(currentUser.uid)
                .collection("journeys")
                .order(by: "createdAt", descending: true)
                .limit(to: 1)
                .getDocuments()
            
            if let journey = snapshot.documents.first?.data(),
               let goal = journey["goal"] as? String,
               let maturity = journey["maturity"] as? String {
                var context = "User is working on: \(goal). Faith context: \(maturity)."
                
                if let dayNumber = dayNumber {
                    context += " Currently on Day \(dayNumber) of their journey."
                }
                
                return context
            }
        } catch {
            print("❌ Error building context: \(error)")
        }
        
        return "Spiritual seeker on a journey of growth"
    }
    
    // MARK: - Q&A Chain Management
    
    /// Load Q&A chain from Firestore for contextual responses
    /// Following Sophrosyne rules: Balanced spiritual continuity
    private func loadQAChain() async {
        guard let currentUser = Auth.auth().currentUser,
              let dayNumber = dayNumber else {
            print("❌ VerseDetailView: No authenticated user or day number for Q&A chain")
            return
        }
        
        let db = Firestore.firestore()
        
        do {
            let snapshot = try await db.collection("users")
                .document(currentUser.uid)
                .collection("days")
                .document("day_\(dayNumber)")
                .collection("qa")
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            qaChain = snapshot.documents.compactMap { document in
                document.data()
            }
            
            print("✅ VerseDetailView: Loaded \(qaChain.count) Q&A interactions")
            
        } catch {
            print("❌ VerseDetailView: Error loading Q&A chain: \(error)")
        }
    }
    
    // MARK: - Firestore Integration
    
    /// Save notes to Firestore when user seals their reflection
    /// Following Sophrosyne rules: Balanced persistence with spiritual timing
    private func saveNotesToFirestore() {
        guard let currentUser = Auth.auth().currentUser,
              let dayNumber = dayNumber else {
            print("❌ VerseDetailView: No authenticated user or day number for saving notes")
            return
        }
        
        let db = Firestore.firestore()
        let notesData: [String: Any] = [
            "verse": verse,
            "reflection": reflection,
            "completedAt": Timestamp(),
            "userId": currentUser.uid,
            "dayNumber": dayNumber
        ]
        
        Task {
            do {
                try await db.collection("users")
                    .document(currentUser.uid)
                    .collection("reflections")
                    .document("day_\(dayNumber)")
                    .setData(notesData)
                
                print("✅ VerseDetailView: Notes saved to Firestore for day \(dayNumber)")
                
                // Schedule notification for next day at 8 AM
                await scheduleNextDayNotification()
                
            } catch {
                print("❌ VerseDetailView: Error saving notes to Firestore: \(error)")
            }
        }
    }
    
    /// Schedule notification for next day at 8 AM
    /// Following Sophrosyne rules: Gentle spiritual pacing
    private func scheduleNextDayNotification() async {
        guard let dayNumber = dayNumber else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Grace"
        content.body = "Your next reflection awaits. Return when you're ready."
        content.sound = .default
        
        // Schedule for next day at 8 AM
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowAt8AM = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: tomorrow) ?? Date()
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.hour, .minute], from: tomorrowAt8AM), repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "next_reflection_day_\(dayNumber + 1)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ VerseDetailView: Next day notification scheduled for 8 AM")
        } catch {
            print("❌ VerseDetailView: Error scheduling notification: \(error)")
        }
    }
    
    // MARK: - Share Functionality
    
    private var shareText: String {
        """
        📖 Today's Verse
        
        \(verse)
        
        💭 Reflection
        
        \(reflection)
        
        Shared from Sophrosyne - Biblical Wisdom for Balanced Healing
        """
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {}
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview("Legacy View") {
    VerseDetailView(
        verse: "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, to give you a future and a hope. - Jeremiah 29:11",
        reflection: "Begin your journey with trust in God's perfect plan for your life. Even in uncertainty, His love provides a firm foundation."
    )
}

#Preview("Full Devotional") {
    VerseDetailView(
        verse: "Psalm 46:10 (ESV) - Be still, and know that I am God.",
        devotional: [
            "context": "In times of chaos and uncertainty, God calls us to stillness and trust.",
            "meaning": "This verse reminds us that recognizing God's sovereignty begins with quieting our hearts and minds.",
            "qaPrompt": "How can you create moments of stillness in your daily life to know God better?"
        ],
        dayNumber: 3
    )
}
