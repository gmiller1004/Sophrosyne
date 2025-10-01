//
//  DashboardView.swift
//  Sophrosyne
//
//  Created by Greg Miller on 9/30/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

struct DashboardView: View {
    @State private var userJourneys: [Journey] = []
    @State private var isLoading: Bool = true
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var token: String? = nil
    @State private var isButtonAnimating: Bool = false
    @State private var upcomingVerses: [UpcomingVerse] = []
    @State private var showBanner: Bool = false
    @State private var bannerVerse: String = ""
    @State private var bannerReflection: String = ""
    @State private var enableDailyDrops: Bool = true
    @State private var showVerseDetail: Bool = false
    @State private var verseDetailData: (verse: String, reflection: String)?
    
    // Day completion tracking
    @State private var completedDays: Set<String> = []
    
    // Debug regeneration state
    @State private var isRegenerating: Bool = false
    @State private var showRegenerationSuccess: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    headerSection
                    
                    // FCM Token Banner (subtle debugging info)
                    if let token = token {
                        Text("Connected: \(token.prefix(10))...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                    
                    // Debug: Show journey count
                    Text("DEBUG: \(userJourneys.count) journey(s) loaded")
                        .font(.caption)
                        .foregroundStyle(.red)
                    
                    if isLoading {
                        loadingSection
                    } else if userJourneys.isEmpty {
                        emptyStateSection
                    } else {
                        journeysSection
                    }
                }
                .padding()
            }
            .background(backgroundGradient)
            .navigationTitle("Your Journey")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(false)
        }
        .overlay(alignment: .top) {
            if showBanner {
                verseBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showBanner)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Small delay to ensure Firestore sync completes for new journeys
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadUserJourneys()
            }
            
            // Request push notification permission
            requestNotificationPermission()
            
            // Retrieve FCM token for debugging
            Task {
                token = await MessagingService.getToken()
                print(token ?? "No token")
            }
            
            // Schedule daily notifications if enabled
            if enableDailyDrops {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    scheduleDailyNotifications()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowVerseDetail"))) { notification in
            print("📱 DashboardView: Received ShowVerseDetail notification")
            print("📱 DashboardView: UserInfo: \(notification.userInfo ?? [:])")
            
            if let userInfo = notification.userInfo,
               let verse = userInfo["verse"] as? String,
               let reflection = userInfo["reflection"] as? String {
                print("📱 DashboardView: Setting verse detail data and showing view")
                verseDetailData = (verse: verse, reflection: reflection)
                showVerseDetail = true
            } else {
                print("❌ DashboardView: Failed to parse notification data")
            }
        }
        .fullScreenCover(isPresented: $showVerseDetail) {
            if let data = verseDetailData {
                VerseDetailView(verse: data.verse, reflection: data.reflection)
            } else {
                Text("Error: No verse data available")
                    .foregroundStyle(.red)
            }
        }
        .onChange(of: showVerseDetail) { newValue in
            if newValue {
                if let data = verseDetailData {
                    print("📱 DashboardView: Presenting VerseDetailView with data:")
                    print("📱 DashboardView: verse = '\(data.verse)'")
                    print("📱 DashboardView: reflection = '\(data.reflection)'")
                } else {
                    print("❌ DashboardView: verseDetailData is nil!")
                }
            }
        }
        .sophrosyneTheme()
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: SophrosyneTheme.Spacing.md) {
            Text("🙏")
                .font(.system(size: 50))
            
            Text("Your Journey Awaits")
                .font(.sophrosyneTitle2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.sophrosyneTextPrimary)
                .multilineTextAlignment(.center)
            
            Text("Continue your path of healing and growth")
                .font(.sophrosyneBody)
                .foregroundStyle(Color.sophrosyneTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    private var loadingSection: some View {
        VStack(spacing: SophrosyneTheme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.sophrosynePrimary)
            
            Text("Loading your journeys...")
                .font(.sophrosyneBody)
                .foregroundStyle(Color.sophrosyneTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SophrosyneTheme.Spacing.xxl)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: SophrosyneTheme.Spacing.lg) {
            Text("📖")
                .font(.system(size: 60))
            
            Text("No Journeys Yet")
                .font(.sophrosyneTitle2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.sophrosyneTextPrimary)
            
            Text("Create your first personalized Bible journey to begin your spiritual growth.")
                .font(.sophrosyneBody)
                .foregroundStyle(Color.sophrosyneTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Create New Journey") {
                // TODO: Navigate back to onboarding or create new journey flow
            }
            .font(.sophrosyneHeadline)
            .foregroundStyle(.white)
            .padding(.horizontal, SophrosyneTheme.Spacing.xl)
            .padding(.vertical, SophrosyneTheme.Spacing.md)
            .background(Color.sophrosynePrimary)
            .cornerRadius(SophrosyneTheme.CornerRadius.md)
            .shadow(color: Color.sophrosynePrimary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SophrosyneTheme.Spacing.xxl)
    }
    
    private var journeysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Journey Day Cards with flexible length (7-28 days)
            List {
                Section {
                    ForEach(userJourneys, id: \.id) { journey in
                        let _ = print("🔍 Processing journey: \(journey.id)")
                        let _ = print("🔍 Journey path keys: \(journey.path.keys)")
                        
                        // Parse days from flexible journey structure (new format)
                        if let path = journey.path["path"] as? [String: Any],
                           let days = path["days"] as? [[String: Any]] {
                            let _ = print("✅ Found NEW format with \(days.count) days")
                            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                                DayCard(
                                    journeyId: journey.id,
                                    day: day,
                                    dayNumber: index + 1,
                                    isCompleted: isDayCompleted(journeyId: journey.id, dayNumber: index + 1),
                                    onMarkComplete: {
                                        markDayComplete(journeyId: journey.id, dayNumber: index + 1)
                                    }
                                )
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                        // Fallback: Support old week-based structure
                        else if let path = journey.path["path"] as? [String: Any],
                                let weeks = path["weeks"] as? [[String: Any]] {
                            let _ = print("✅ Found OLD format with \(weeks.count) weeks")
                            // Convert old format to day cards
                            ForEach(Array(weeks.enumerated()), id: \.offset) { weekIndex, week in
                                let _ = print("  Week \(weekIndex + 1): \(week["title"] ?? "No title")")
                                if let days = week["days"] as? [[String: Any]] {
                                    let _ = print("  Found \(days.count) days in week \(weekIndex + 1)")
                                    ForEach(Array(days.enumerated()), id: \.offset) { dayIndex, day in
                                        let absoluteDayNumber = (weekIndex * 7) + dayIndex + 1
                                        let _ = print("    Creating DayCard for day \(absoluteDayNumber)")
                                        DayCard(
                                            journeyId: journey.id,
                                            day: day,
                                            dayNumber: absoluteDayNumber,
                                            isCompleted: isDayCompleted(journeyId: journey.id, dayNumber: absoluteDayNumber),
                                            onMarkComplete: {
                                                markDayComplete(journeyId: journey.id, dayNumber: absoluteDayNumber)
                                            }
                                        )
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                    }
                                } else {
                                    let _ = print("  ❌ No days found in week \(weekIndex + 1)")
                                }
                            }
                        } else {
                            let _ = print("❌ Could not parse journey format")
                            let _ = print("❌ Path structure: \(journey.path)")
                        }
                    }
                } header: {
                    HStack {
                        Text("Your Journey")
                            .font(.sophrosyneTitle3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.sophrosyneTextPrimary)
                        Spacer()
                        if let journey = userJourneys.first,
                           let path = journey.path["path"] as? [String: Any] {
                            // New format: direct days array
                            if let days = path["days"] as? [[String: Any]] {
                                Text("\(days.count) Days")
                                    .font(.sophrosyneCaption)
                                    .foregroundStyle(Color.sophrosyneTextSecondary)
                            }
                            // Old format: weeks with days
                            else if let weeks = path["weeks"] as? [[String: Any]] {
                                let totalDays = weeks.reduce(0) { count, week in
                                    count + ((week["days"] as? [[String: Any]])?.count ?? 0)
                                }
                                Text("\(totalDays) Days")
                                    .font(.sophrosyneCaption)
                                    .foregroundStyle(Color.sophrosyneTextSecondary)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                await refreshJourneys()
            }
            
            // Daily Notifications Toggle
            if !userJourneys.isEmpty {
                dailyNotificationsToggle
            }
        }
    }
    
    private var dailyNotificationsToggle: some View {
        SophrosyneToggle(
            "Receive Verse Whispers",
            subtitle: "Daily notifications at 8:00 AM",
            isOn: $enableDailyDrops
        )
        .onChange(of: enableDailyDrops) { newValue in
            if newValue {
                scheduleDailyNotifications()
            } else {
                cancelAllDailyNotifications()
            }
        }
    }
    
    
    private var verseBanner: some View {
        HStack(spacing: SophrosyneTheme.Spacing.md) {
            Text(bannerVerse)
                .font(.sophrosyneBody)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button("Reflect") {
                // Show verse detail view with current banner content
                showVerseDetailView(verse: bannerVerse, reflection: bannerReflection)
                dismissBanner()
            }
            .font(.sophrosyneCallout)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, SophrosyneTheme.Spacing.md)
            .padding(.vertical, SophrosyneTheme.Spacing.sm)
            .background(.white.opacity(0.2))
            .cornerRadius(SophrosyneTheme.CornerRadius.sm)
        }
        .padding(.horizontal, SophrosyneTheme.Spacing.lg)
        .padding(.vertical, SophrosyneTheme.Spacing.md)
        .background(Color.sophrosynePrimary.opacity(0.9))
        .cornerRadius(SophrosyneTheme.CornerRadius.md)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, SophrosyneTheme.Spacing.md)
        .padding(.top, SophrosyneTheme.Spacing.sm)
        .onTapGesture {
            // Tap anywhere on banner to dismiss
            dismissBanner()
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [.indigo.opacity(0.1), .white],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Functions
    
    private func loadUserJourneys() {
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                isLoading = false
                errorMessage = "No authenticated user found"
                showError = true
            }
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users")
            .document(currentUser.uid)
            .collection("journeys")
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        print("❌ Error fetching journeys: \(error)")
                        errorMessage = "Failed to load journeys: \(error.localizedDescription)"
                        showError = true
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("📝 No journey documents found")
                        userJourneys = []
                        return
                    }
                    
                    userJourneys = documents.compactMap { document in
                        let data = document.data()
                        
                        guard let goal = data["goal"] as? String,
                              let maturity = data["maturity"] as? String,
                              let path = data["path"] as? [String: Any],
                              let createdAt = data["createdAt"] as? Timestamp else {
                            print("⚠️ Invalid journey data for document: \(document.documentID)")
                            return nil
                        }
                        
                        return Journey(
                            id: document.documentID,
                            goal: goal,
                            maturity: maturity,
                            createdAt: createdAt.dateValue(),
                            path: path
                        )
                    }
                    
                    print("✅ Loaded \(userJourneys.count) journey(s)")
                    
                    // Load upcoming verses after journeys are loaded
                    loadUpcomingVerses()
                    
                    // Load completed days for journey tracking
                    loadCompletedDays()
                }
            }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            // TODO: Navigate back to onboarding
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Push notification permission granted")
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("❌ Push notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func scheduleFirstVerse() {
        // Animate button
        withAnimation(.easeInOut(duration: 0.1)) {
            isButtonAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isButtonAnimating = false
            }
        }
        
        // Get the first journey's path data
        guard let firstJourney = userJourneys.first else {
            print("❌ No journeys available for verse scheduling")
            return
        }
        
        // Select the first day's verse
        let verse = GrokService.selectDailyVerse(journey: firstJourney.path, dayIndex: 0)
        
        guard let verseData = verse else {
            print("❌ Failed to select daily verse")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Daily Grace"
        content.body = verseData.verse
        content.userInfo = ["reflection": verseData.reflection]
        
        // Create trigger (5 seconds from now for testing)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        // Create notification request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification scheduling error: \(error.localizedDescription)")
            } else {
                print("✅ Daily verse notification scheduled successfully")
                print("📖 Verse: \(verseData.verse)")
                print("💭 Reflection: \(verseData.reflection)")
            }
        }
    }
    
    private func showVerseBanner(verse: String, reflection: String) {
        print("📱 DashboardView: showVerseBanner called with verse: \(verse)")
        print("📱 DashboardView: showVerseBanner called with reflection: \(reflection)")
        
        bannerVerse = verse
        bannerReflection = reflection
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showBanner = true
        }
        
        print("📱 DashboardView: Banner should now be visible")
        
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            dismissBanner()
        }
    }
    
    private func dismissBanner() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showBanner = false
        }
    }
    
    private func loadUpcomingVerses() {
        guard let firstJourney = userJourneys.first else {
            upcomingVerses = []
            return
        }
        
        // Extract upcoming verses from the journey path
        guard let path = firstJourney.path["path"] as? [String: Any],
              let weeks = path["weeks"] as? [[String: Any]] else {
            upcomingVerses = []
            return
        }
        
        var verses: [UpcomingVerse] = []
        
        for (weekIndex, week) in weeks.enumerated() {
            guard let days = week["days"] as? [[String: Any]] else { continue }
            
            for (dayIndex, day) in days.enumerated() {
                guard let verse = day["verse"] as? String,
                      let reflection = day["reflection"] as? String else { continue }
                
                verses.append(UpcomingVerse(
                    id: "\(weekIndex)-\(dayIndex)",
                    verse: verse,
                    reflection: reflection,
                    weekNumber: weekIndex + 1,
                    dayNumber: dayIndex + 1
                ))
            }
        }
        
        // Limit to next 7 verses for preview
        upcomingVerses = Array(verses.prefix(7))
    }
    
    private func scheduleDailyNotifications() {
        guard let firstJourney = userJourneys.first else {
            print("❌ No journey available for daily notifications")
            return
        }
        
        // Extract verses from journey path
        guard let path = firstJourney.path["path"] as? [String: Any],
              let weeks = path["weeks"] as? [[String: Any]] else {
            print("❌ Invalid journey path structure")
            return
        }
        
        var allVerses: [(verse: String, reflection: String)] = []
        
        for week in weeks {
            guard let days = week["days"] as? [[String: Any]] else { continue }
            
            for day in days {
                guard let verse = day["verse"] as? String,
                      let reflection = day["reflection"] as? String else { continue }
                
                allVerses.append((verse: verse, reflection: reflection))
            }
        }
        
        // Schedule first 7 verses as daily notifications
        let versesToSchedule = Array(allVerses.prefix(7))
        
        for (index, verseData) in versesToSchedule.enumerated() {
            let identifier = "daily-verse-\(index + 1)"
            
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Daily Grace"
            content.body = verseData.verse
            content.userInfo = ["reflection": verseData.reflection]
            content.sound = .default
            
            // Create calendar trigger for 8:00 AM daily
            var dateComponents = DateComponents()
            dateComponents.hour = 8
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            // Create notification request
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling daily notification \(index + 1): \(error.localizedDescription)")
                } else {
                    print("✅ Daily notification \(index + 1) scheduled for 8:00 AM")
                }
            }
        }
        
        print("✅ Scheduled \(versesToSchedule.count) daily notifications")
    }
    
    private func cancelAllDailyNotifications() {
        // Get all pending notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let dailyNotificationIdentifiers = requests
                .filter { $0.identifier.hasPrefix("daily-verse-") }
                .map { $0.identifier }
            
            // Remove daily verse notifications
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: dailyNotificationIdentifiers
            )
            
            print("✅ Cancelled \(dailyNotificationIdentifiers.count) daily notifications")
        }
    }
    
    private func showVerseDetailView(verse: String, reflection: String) {
        // Post notification to show verse detail view
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowVerseDetail"),
            object: nil,
            userInfo: [
                "verse": verse,
                "reflection": reflection
            ]
        )
    }
    
    private func refreshJourneys() async {
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Reload journeys
        await MainActor.run {
            loadUserJourneys()
        }
    }
    
    // MARK: - Day Completion Functions
    /// Check if a specific day is completed
    /// Following Sophrosyne rules: Progressive unlocking for balanced pacing
    private func isDayCompleted(journeyId: String, dayNumber: Int) -> Bool {
        let key = "\(journeyId)_day_\(dayNumber)"
        return completedDays.contains(key)
    }
    
    /// Mark a day as complete and update Firestore
    /// Following Sophrosyne rules: Success haptics and persistent tracking
    private func markDayComplete(journeyId: String, dayNumber: Int) {
        let key = "\(journeyId)_day_\(dayNumber)"
        
        // Add to completed days set
        completedDays.insert(key)
        
        // Success haptic feedback
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
        
        // Update Firestore
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users")
            .document(currentUser.uid)
            .collection("journeys")
            .document(journeyId)
            .updateData([
                "completedDays.\(dayNumber)": true
            ]) { error in
                if let error = error {
                    print("❌ Error updating completed day: \(error)")
                } else {
                    print("✅ Day \(dayNumber) marked complete in Firestore")
                }
            }
    }
    
    /// Load completed days from Firestore on journey load
    private func loadCompletedDays() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        for journey in userJourneys {
            db.collection("users")
                .document(currentUser.uid)
                .collection("journeys")
                .document(journey.id)
                .getDocument { snapshot, error in
                    if let data = snapshot?.data(),
                       let completedDaysData = data["completedDays"] as? [String: Bool] {
                        for (dayNumberString, isCompleted) in completedDaysData {
                            if isCompleted, let dayNumber = Int(dayNumberString) {
                                let key = "\(journey.id)_day_\(dayNumber)"
                                completedDays.insert(key)
                            }
                        }
                    }
                }
        }
    }
}

// MARK: - Journey Model
struct Journey: Identifiable {
    let id: String
    let goal: String
    let maturity: String
    let createdAt: Date
    let path: [String: Any]
}

// MARK: - Day Card
/// Individual day card with title, verse preview, lock/unlock, and feedback functionality
/// Following Sophrosyne rules: Progressive unlocking, feedback loop, AI-powered revisions
struct DayCard: View {
    let journeyId: String
    let day: [String: Any]
    let dayNumber: Int
    let isCompleted: Bool
    let onMarkComplete: () -> Void
    
    @State private var rating: Int = 0
    @State private var feedbackText: String = ""
    @State private var isSubmittingFeedback: Bool = false
    @State private var feedbackSubmitted: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: SophrosyneTheme.Spacing.md) {
            // Day header with number and title
            HStack {
                Text("Day \(dayNumber)")
                    .font(.sophrosyneCallout)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.sophrosynePrimary)
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.green)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundStyle(Color.sophrosyneTextTertiary)
                }
            }
            
            // Title (new format) or Verse preview (old format as title)
            if let title = day["title"] as? String {
                Text(title)
                    .font(.sophrosyneHeadline)
                    .foregroundStyle(Color.sophrosyneTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            } else if let verse = day["verse"] as? String {
                // For old format without title, use verse as preview
                Text(verse)
                    .font(.sophrosyneHeadline)
                    .foregroundStyle(Color.sophrosyneTextPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            
            // Reflection preview (old format) or Verse preview (new format)
            if let _ = day["title"] as? String, let verse = day["verse"] as? String {
                // New format: Show verse as secondary content
                Text(verse)
                    .font(.sophrosyneBody)
                    .foregroundStyle(Color.sophrosyneTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            } else if let reflection = day["reflection"] as? String {
                // Old format: Show reflection as secondary content
                Text(reflection)
                    .font(.sophrosyneBody)
                    .foregroundStyle(Color.sophrosyneTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            
            // Mark Complete button (only if not completed)
            if !isCompleted {
                Button(action: {
                    onMarkComplete()
                }) {
                    Text("Mark Complete")
                        .font(.sophrosyneCallout)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SophrosyneTheme.Spacing.sm)
                        .background(Color.sophrosynePrimary)
                        .cornerRadius(SophrosyneTheme.CornerRadius.sm)
                }
                .accessibilityLabel("Mark day \(dayNumber) as complete")
                .accessibilityHint("Tap to unlock the next day in your journey")
            }
            
            // Post-unlock feedback section (only if completed and not yet submitted)
            if isCompleted && !feedbackSubmitted {
                Divider()
                    .padding(.vertical, SophrosyneTheme.Spacing.xs)
                
                VStack(alignment: .leading, spacing: SophrosyneTheme.Spacing.sm) {
                    Text("How was this day?")
                        .font(.sophrosyneCaption)
                        .foregroundStyle(Color.sophrosyneTextSecondary)
                    
                    // Star rating view
                    HStack(spacing: SophrosyneTheme.Spacing.xs) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                rating = star
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundStyle(star <= rating ? Color.sophrosyneAccent : Color.sophrosyneTextTertiary)
                            }
                        }
                    }
                    
                    // Optional feedback text
                    TextField("Feedback? (optional)", text: $feedbackText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.sophrosyneCaption)
                    
                    // Submit button
                    Button(action: {
                        submitFeedback()
                    }) {
                        HStack(spacing: SophrosyneTheme.Spacing.xs) {
                            if isSubmittingFeedback {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            }
                            Text(isSubmittingFeedback ? "Submitting..." : "Submit")
                                .font(.sophrosyneCaption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, SophrosyneTheme.Spacing.xs)
                        .background(rating > 0 ? Color.sophrosyneAccent : Color.sophrosyneTextTertiary)
                        .cornerRadius(SophrosyneTheme.CornerRadius.sm)
                    }
                    .disabled(rating == 0 || isSubmittingFeedback)
                    .accessibilityLabel("Submit feedback for day \(dayNumber)")
                    .accessibilityHint("Rate this day and optionally provide feedback to improve future content")
                }
                .padding(.top, SophrosyneTheme.Spacing.xs)
            }
            
            // Feedback submitted confirmation
            if feedbackSubmitted {
                HStack(spacing: SophrosyneTheme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.green)
                    Text("Thank you for your feedback!")
                        .font(.sophrosyneCaption)
                        .foregroundStyle(Color.sophrosyneTextSecondary)
                }
                .padding(.top, SophrosyneTheme.Spacing.xs)
            }
        }
        .padding(SophrosyneTheme.Spacing.md)
        .background(.white)
        .cornerRadius(SophrosyneTheme.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: SophrosyneTheme.CornerRadius.md)
                .stroke(isCompleted ? Color.green.opacity(0.3) : Color.secondary.opacity(0.3), lineWidth: 2)
        )
        .overlay(
            Group {
                // Locked overlay with frosted glass effect
                if !isCompleted {
                    RoundedRectangle(cornerRadius: SophrosyneTheme.CornerRadius.md)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: SophrosyneTheme.CornerRadius.md)
                                .stroke(Color.secondary, lineWidth: 2)
                        )
                }
            }
        )
        .sophrosyneShadow(opacity: isCompleted ? 0.1 : 0.05, radius: 4, offset: CGSize(width: 0, height: 2))
    }
    
    // MARK: - Feedback Submission
    
    /// Submit feedback for this day
    /// Following Sophrosyne rules: Async feedback with AI revision on low ratings
    private func submitFeedback() {
        guard rating > 0 else { return }
        
        isSubmittingFeedback = true
        
        Task {
            let dayId = "day_\(dayNumber)"
            await FeedbackService.submitFeedback(
                journeyId: journeyId,
                dayId: dayId,
                rating: rating,
                text: feedbackText.isEmpty ? nil : feedbackText
            )
            
            await MainActor.run {
                isSubmittingFeedback = false
                feedbackSubmitted = true
                
                // Success haptic
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Journey Card
struct JourneyCard: View {
    let journey: Journey
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Journey Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(journey.goal)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text("\(journey.maturity) Level")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("📖")
                    .font(.title2)
            }
            
            // Mock Weeks Display
            if let path = journey.path["path"] as? [String: Any],
               let weeks = path["weeks"] as? [[String: Any]] {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your 4-Week Journey:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                        HStack {
                            Text("Week \(index + 1)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                                .frame(width: 50, alignment: .leading)
                            
                            Text(week["title"] as? String ?? "Untitled")
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if let days = week["days"] as? [[String: Any]] {
                                Text("\(days.count) days")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.top, 8)
            }
            
            Text("Created \(journey.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Upcoming Verse Model
struct UpcomingVerse: Identifiable {
    let id: String
    let verse: String
    let reflection: String
    let weekNumber: Int
    let dayNumber: Int
}

// MARK: - Upcoming Verse Row
struct UpcomingVerseRow: View {
    let verse: UpcomingVerse
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            print("📱 UpcomingVerseRow: Button tapped for verse: \(verse.verse)")
            onTap()
        }) {
            HStack(spacing: SophrosyneTheme.Spacing.md) {
                // Book icon
                Image(systemName: "book.closed")
                    .font(.title3)
                    .foregroundStyle(Color.sophrosynePrimary)
                
                // Verse text
                Text(verse.verse)
                    .font(.sophrosyneBody)
                    .foregroundStyle(Color.sophrosyneTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Week/Day badge
                Text("W\(verse.weekNumber) D\(verse.dayNumber)")
                    .font(.sophrosyneCaption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, SophrosyneTheme.Spacing.sm)
                    .padding(.vertical, SophrosyneTheme.Spacing.xs)
                    .background(Color.sophrosyneAccent)
                    .cornerRadius(SophrosyneTheme.CornerRadius.sm)
            }
            .padding(.horizontal, SophrosyneTheme.Spacing.md)
            .padding(.vertical, SophrosyneTheme.Spacing.sm)
            .background(.white)
            .cornerRadius(SophrosyneTheme.CornerRadius.md)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    
}

#Preview {
    DashboardView()
        .previewDevice("iPhone 15 Pro")
        .previewDisplayName("Dashboard")
}
