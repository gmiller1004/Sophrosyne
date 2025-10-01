//
//  FeedbackService.swift
//  Sophrosyne
//
//  Created by Greg Miller on 10/1/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for handling user feedback on daily devotionals
/// Following Sophrosyne rules: Balanced feedback loop with AI-powered revisions
class FeedbackService {
    
    // MARK: - Feedback Submission
    
    /// Submit user feedback for a specific day
    /// If rating is low (< 3), triggers Grok revision for improved content
    /// - Parameters:
    ///   - journeyId: The journey document ID
    ///   - dayId: The day identifier (e.g., "day_1")
    ///   - rating: Star rating 1-5
    ///   - text: Optional feedback text from user
    static func submitFeedback(journeyId: String, dayId: String, rating: Int, text: String?) async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ FeedbackService: No authenticated user")
            return
        }
        
        let db = Firestore.firestore()
        
        // Prepare feedback data
        let feedbackData: [String: Any] = [
            "rating": rating,
            "text": text ?? "",
            "submittedAt": Timestamp(),
            "userId": currentUser.uid
        ]
        
        // Update Firestore with feedback
        do {
            try await db.collection("users")
                .document(currentUser.uid)
                .collection("journeys")
                .document(journeyId)
                .updateData([
                    "feedback.\(dayId)": feedbackData
                ])
            
            print("✅ FeedbackService: Submitted feedback for \(dayId) - Rating: \(rating)")
            
            // If rating is low, trigger Grok revision
            if rating < 3 {
                print("⚠️ FeedbackService: Low rating detected, triggering Grok revision...")
                await triggerGrokRevision(journeyId: journeyId, dayId: dayId, feedbackText: text, rating: rating)
            }
            
        } catch {
            print("❌ FeedbackService: Error submitting feedback: \(error)")
        }
    }
    
    // MARK: - Grok Revision
    
    /// Trigger Grok AI to revise a day based on user feedback
    /// Following Sophrosyne rules: Adaptive content improvement
    /// - Parameters:
    ///   - journeyId: The journey document ID
    ///   - dayId: The day identifier
    ///   - feedbackText: User's feedback text (if provided)
    ///   - rating: The star rating given
    private static func triggerGrokRevision(journeyId: String, dayId: String, feedbackText: String?, rating: Int) async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        
        do {
            // Get the current day data
            let journeyDoc = try await db.collection("users")
                .document(currentUser.uid)
                .collection("journeys")
                .document(journeyId)
                .getDocument()
            
            guard let journeyData = journeyDoc.data(),
                  let path = journeyData["path"] as? [String: Any],
                  let days = path["days"] as? [[String: Any]] else {
                print("❌ FeedbackService: Could not parse journey data")
                return
            }
            
            // Find the specific day (extract day number from dayId like "day_1")
            let dayNumberString = dayId.replacingOccurrences(of: "day_", with: "")
            guard let dayNumber = Int(dayNumberString),
                  dayNumber > 0 && dayNumber <= days.count else {
                print("❌ FeedbackService: Invalid day number")
                return
            }
            
            let currentDay = days[dayNumber - 1]
            
            // Prepare feedback text for revision
            let revisionReason = feedbackText ?? "Low rating (\(rating) stars)"
            
            print("🔄 FeedbackService: Requesting Grok revision for \(dayId)")
            
            // Call GrokService.reviseDay with current day context and feedback
            let revisedDay = try await GrokService.reviseDay(
                context: currentDay,
                feedback: revisionReason
            )
            
            // Update the day in Firestore with revised content
            var updatedDays = days
            updatedDays[dayNumber - 1] = revisedDay
            
            try await db.collection("users")
                .document(currentUser.uid)
                .collection("journeys")
                .document(journeyId)
                .updateData([
                    "path.days": updatedDays,
                    "lastRevised": Timestamp(),
                    "revisionReason": revisionReason
                ])
            
            print("✅ FeedbackService: Successfully revised \(dayId) based on feedback")
            print("✅ FeedbackService: New title: \(revisedDay["title"] as? String ?? "N/A")")
            
        } catch {
            print("❌ FeedbackService: Error during Grok revision: \(error)")
        }
    }
}

