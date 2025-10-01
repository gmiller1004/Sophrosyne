import Foundation
import Alamofire

// MARK: - Codable Journey Structures

/// Type-safe structure for Bible journey data
/// Following Sophrosyne rules: Balanced design with comprehensive type safety
struct JourneyPath: Codable {
    let path: JourneyStructure
}

struct JourneyStructure: Codable {
    let weeks: [Week]
}

struct Week: Codable {
    let title: String
    let days: [Day]
}

struct Day: Codable {
    let verse: String
    let reflection: String
}

/// Service class for integrating with xAI Grok API to generate personalized Bible journeys
/// As in Proverbs 4:7, "In all thy getting, get understanding" - this service seeks wisdom through AI
class GrokService {
    
    // MARK: - Constants
    private static let apiURL = "https://api.x.ai/v1/chat/completions"
    private static let grokModel = "grok-3-mini"
    private static let maxRetries = 3
    private static let retryDelay: TimeInterval = 1.0
    
    // MARK: - API Key Management
    /// API key retrieved from secure configuration
    /// Following Sophrosyne rules: Balanced integration with proper security
    private static var apiKey: String {
        return Config.grokAPIKey
    }
    
    // MARK: - Public API
    
    /// Generates a personalized 4-week Bible journey based on user's goal and spiritual maturity
    /// - Parameters:
    ///   - goal: User's healing goal (e.g., "overcoming anxiety")
    ///   - maturity: Spiritual maturity level ("Beginner", "Intermediate", "Advanced")
    ///   - apiKey: Optional API key override (uses Config.grokAPIKey if nil)
    /// - Returns: Dictionary containing the structured Bible journey
    /// - Throws: Network errors, JSON parsing errors, or API errors
    static func generateJourney(goal: String, maturity: String, apiKey: String? = nil) async throws -> [String: Any] {
        return try await generateJourneyWithRetry(goal: goal, maturity: maturity, apiKey: apiKey, attempt: 1)
    }
    
    /// Internal method with retry logic for rate limiting
    private static func generateJourneyWithRetry(goal: String, maturity: String, apiKey: String? = nil, attempt: Int) async throws -> [String: Any] {
        
        // Use provided API key or fall back to Config
        let effectiveAPIKey = apiKey ?? Config.grokAPIKey
        
        // Log configuration status for debugging
        if Config.isDevelopment {
            print("🔑 GrokService: API Key configured: \(Config.isAPIKeyConfigured)")
            print("🔑 GrokService: Using \(apiKey != nil ? "provided" : "config") key: \(effectiveAPIKey.prefix(8))...")
            print("🔄 GrokService: Attempt \(attempt)/\(maxRetries)")
        }
        
        // Construct the prompt for Grok API
        let prompt = """
        Generate a 4-week JSON Bible journey for goal: \(goal), maturity: \(maturity). 
        Verses from ESV only: {path: {weeks: [{title: String, days: [{verse: String, reflection: String}]}]}}
        """
        
        // Prepare the request body with response_format for JSON object
        let requestBody: [String: Any] = [
            "model": grokModel,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "response_format": [
                "type": "json_object"
            ]
        ]
        
        // Prepare headers
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(effectiveAPIKey)",
            "Content-Type": "application/json"
        ]
        
        // Make the API request using Alamofire
        do {
            return try await withCheckedThrowingContinuation { continuation in
                AF.request(
                    apiURL,
                    method: .post,
                    parameters: requestBody,
                    encoding: JSONEncoding.default,
                    headers: headers
                )
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        do {
                            // Parse the response with enhanced error handling
                            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                                print("❌ GrokService: Failed to parse JSON response")
                                print("❌ Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
                                continuation.resume(throwing: GrokServiceError.invalidResponse)
                                return
                            }
                            
                            print("✅ GrokService: Received JSON response: \(jsonResponse)")
                            
                            // Check for API errors in response
                            if let error = jsonResponse["error"] as? [String: Any],
                               let errorCode = error["code"] as? Int {
                                if errorCode == 429 && attempt < maxRetries {
                                    // Rate limit hit - retry after delay
                                    print("⏳ GrokService: Rate limit hit (429), retrying in \(retryDelay)s...")
                                    Task {
                                        try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                                        do {
                                            let retryResult = try await generateJourneyWithRetry(goal: goal, maturity: maturity, apiKey: apiKey, attempt: attempt + 1)
                                            continuation.resume(returning: retryResult)
                                        } catch {
                                            continuation.resume(throwing: error)
                                        }
                                    }
                                    return
                                } else {
                                    let errorMessage = error["message"] as? String ?? "Unknown API error"
                                    continuation.resume(throwing: GrokServiceError.apiError(errorMessage))
                                    return
                                }
                            }
                            
                            // Extract the content from the response with comprehensive guards
                            guard let choices = jsonResponse["choices"] as? [[String: Any]],
                                  !choices.isEmpty,
                                  let firstChoice = choices.first,
                                  let message = firstChoice["message"] as? [String: Any],
                                  let content = message["content"] as? String,
                                  !content.isEmpty else {
                                print("❌ GrokService: Invalid response structure")
                                print("❌ Choices: \(jsonResponse["choices"] ?? "nil")")
                                continuation.resume(throwing: GrokServiceError.invalidResponse)
                                return
                            }
                            
                            print("✅ GrokService: Content extracted: \(content.prefix(200))...")
                            
                            // Parse the content as JSON with enhanced validation
                            guard let contentData = content.data(using: .utf8),
                                  let journeyData = try JSONSerialization.jsonObject(with: contentData) as? [String: Any],
                                  !journeyData.isEmpty else {
                                continuation.resume(throwing: GrokServiceError.jsonParsingFailed)
                                return
                            }
                            
                            // Validate journey structure
                            guard let path = journeyData["path"] as? [String: Any],
                                  let weeks = path["weeks"] as? [[String: Any]],
                                  !weeks.isEmpty else {
                                continuation.resume(throwing: GrokServiceError.invalidResponse)
                                return
                            }
                            
                            continuation.resume(returning: journeyData)
                            
                        } catch {
                            continuation.resume(throwing: GrokServiceError.jsonParsingFailed)
                        }
                        
                    case .failure(let error):
                        // Check for rate limiting in HTTP status
                        if let statusCode = response.response?.statusCode,
                           statusCode == 429 && attempt < maxRetries {
                            print("⏳ GrokService: HTTP 429 rate limit, retrying in \(retryDelay)s...")
                            Task {
                                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                                do {
                                    let retryResult = try await generateJourneyWithRetry(goal: goal, maturity: maturity, apiKey: apiKey, attempt: attempt + 1)
                                    continuation.resume(returning: retryResult)
                                } catch {
                                    continuation.resume(throwing: error)
                                }
                            }
                        } else {
                            continuation.resume(throwing: GrokServiceError.networkError(error))
                        }
                    }
                }
            }
        } catch {
            // If we've exhausted retries, throw the error
            if attempt >= maxRetries {
                print("❌ GrokService: Max retries (\(maxRetries)) exceeded")
                throw error
            }
            throw error
        }
    }
    
    /// Selects a daily verse from a journey based on the day index
    /// - Parameters:
    ///   - journey: The journey dictionary containing the path structure
    ///   - dayIndex: The index of the day (0-based) to select
    /// - Returns: A tuple containing the verse and reflection, or nil if not found
    static func selectDailyVerse(journey: [String: Any], dayIndex: Int) -> (verse: String, reflection: String)? {
        // Enhanced parsing with comprehensive guards against nil values
        guard !journey.isEmpty,
              let path = journey["path"] as? [String: Any],
              !path.isEmpty,
              let weeks = path["weeks"] as? [[String: Any]],
              !weeks.isEmpty else {
            print("⚠️ GrokService: Invalid journey structure - missing path or weeks")
            return fallbackVerse()
        }
        
        // Find the appropriate week and day with bounds checking
        var currentDayIndex = dayIndex
        for weekIndex in 0..<weeks.count {
            guard let week = weeks[weekIndex] as? [String: Any],
                  let days = week["days"] as? [[String: Any]],
                  !days.isEmpty else {
                print("⚠️ GrokService: Invalid week structure at index \(weekIndex)")
                continue
            }
            
            if currentDayIndex < days.count {
                // Found the target day
                guard let day = days[currentDayIndex] as? [String: Any] else {
                    print("⚠️ GrokService: Invalid day structure at index \(currentDayIndex)")
                    return fallbackVerse()
                }
                
                // Extract verse and reflection with comprehensive validation
                guard let verse = day["verse"] as? String,
                      !verse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let reflection = day["reflection"] as? String,
                      !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    print("⚠️ GrokService: Empty verse or reflection at day \(currentDayIndex)")
                    return fallbackVerse()
                }
                
                return (verse: verse, reflection: reflection)
            }
            
            // Move to next week
            currentDayIndex -= days.count
        }
        
        // If we've exhausted all weeks, return fallback
        print("⚠️ GrokService: Day index \(dayIndex) exceeds available days")
        return fallbackVerse()
    }
    
    /// Provides a fallback verse when parsing fails
    private static func fallbackVerse() -> (verse: String, reflection: String) {
        return (
            verse: "Psalm 23:1 - The Lord is my shepherd; I shall not want.",
            reflection: "Even when the path is unclear, trust in His guidance and provision."
        )
    }
    
    // MARK: - Day Revision
    
    /// Revises a single day's devotional content based on user feedback
    /// Following Sophrosyne rules: Adaptive, feedback-driven content improvement
    /// - Parameters:
    ///   - context: The current day's context data (title, verse, devotional)
    ///   - feedback: User feedback explaining what needs improvement
    /// - Returns: Dictionary containing the revised day structure
    /// - Throws: GrokServiceError on API or parsing failures
    static func reviseDay(context: [String: Any], feedback: String) async throws -> [String: Any] {
        print("🔄 GrokService: Revising day based on feedback: \(feedback)")
        
        // Extract current day information
        let currentTitle = context["title"] as? String ?? "Untitled"
        let currentVerse = context["verse"] as? String ?? ""
        
        var devotionalInfo = ""
        if let devotional = context["devotional"] as? [String: Any] {
            let contextText = devotional["context"] as? String ?? ""
            let meaning = devotional["meaning"] as? String ?? ""
            let qaPrompt = devotional["qaPrompt"] as? String ?? ""
            
            devotionalInfo = """
            Current Context: \(contextText)
            Current Meaning: \(meaning)
            Current Q&A Prompt: \(qaPrompt)
            """
        }
        
        // Construct revision prompt
        let revisionPrompt = """
        Revise this devotional day based on user feedback.
        
        Current Day:
        Title: \(currentTitle)
        Verse: \(currentVerse)
        \(devotionalInfo)
        
        User Feedback: \(feedback)
        
        Generate an improved version that addresses the feedback while maintaining biblical accuracy.
        Return ONLY a single JSON object in this exact format:
        {
          "title": "Improved day title",
          "verse": "ESV Bible verse with reference",
          "devotional": {
            "context": "Biblical background and setting",
            "meaning": "Deeper theological interpretation",
            "qaPrompt": "Thoughtful reflection question"
          }
        }
        """
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": grokModel,
            "messages": [
                [
                    "role": "user",
                    "content": revisionPrompt
                ]
            ],
            "response_format": [
                "type": "json_object"
            ]
        ]
        
        // Prepare headers
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Config.grokAPIKey)",
            "Content-Type": "application/json"
        ]
        
        // Make the API request
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                apiURL,
                method: .post,
                parameters: requestBody,
                encoding: JSONEncoding.default,
                headers: headers
            )
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        // Parse response
                        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = jsonResponse["choices"] as? [[String: Any]],
                              !choices.isEmpty,
                              let firstChoice = choices.first,
                              let message = firstChoice["message"] as? [String: Any],
                              let content = message["content"] as? String,
                              !content.isEmpty else {
                            print("❌ GrokService: Invalid revision response structure")
                            continuation.resume(throwing: GrokServiceError.invalidResponse)
                            return
                        }
                        
                        print("✅ GrokService: Revision content: \(content.prefix(200))...")
                        
                        // Parse the content as the revised day JSON
                        guard let contentData = content.data(using: .utf8),
                              let revisedDay = try JSONSerialization.jsonObject(with: contentData) as? [String: Any],
                              !revisedDay.isEmpty else {
                            print("❌ GrokService: Failed to parse revised day JSON")
                            continuation.resume(throwing: GrokServiceError.jsonParsingFailed)
                            return
                        }
                        
                        // Validate revised day structure
                        guard let title = revisedDay["title"] as? String,
                              let verse = revisedDay["verse"] as? String,
                              !title.isEmpty,
                              !verse.isEmpty else {
                            print("❌ GrokService: Invalid revised day structure")
                            continuation.resume(throwing: GrokServiceError.invalidResponse)
                            return
                        }
                        
                        print("✅ GrokService: Day successfully revised - Title: \(title)")
                        continuation.resume(returning: revisedDay)
                        
                    } catch {
                        print("❌ GrokService: Error parsing revision response: \(error)")
                        continuation.resume(throwing: GrokServiceError.jsonParsingFailed)
                    }
                    
                case .failure(let error):
                    print("❌ GrokService: Network error during revision: \(error)")
                    continuation.resume(throwing: GrokServiceError.networkError(error))
                }
            }
        }
    }
    
    // MARK: - Q&A Reflection
    
    /// Ask Grok for personalized reflection based on Q&A chain
    /// Following Sophrosyne rules: Contextual, personalized spiritual guidance
    /// - Parameters:
    ///   - priorQA: Previous Q&A interactions from Firestore
    ///   - question: User's current reflection question
    /// - Returns: Personalized spiritual response from Grok
    static func askReflection(priorQA: [[String: Any]], question: String) async throws -> String {
        print("🔄 GrokService: Processing Q&A reflection request")
        
        // Build context from prior Q&A chain
        var contextString = "Previous spiritual reflections:\n"
        for (index, qa) in priorQA.enumerated() {
            if let q = qa["question"] as? String,
               let a = qa["answer"] as? String {
                contextString += "Q\(index + 1): \(q)\nA\(index + 1): \(a)\n\n"
            }
        }
        
        // Construct prompt for Grok
        let prompt = """
        You are a wise spiritual mentor helping someone deepen their faith through biblical reflection.
        
        \(contextString)
        
        Current question: \(question)
        
        Provide a thoughtful, encouraging response that:
        1. Builds on their previous reflections
        2. Offers biblical wisdom and insight
        3. Encourages deeper spiritual growth
        4. Is personal and supportive
        
        Keep response under 200 words and focus on spiritual encouragement.
        """
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": grokModel,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "response_format": [
                "type": "json_object"
            ]
        ]
        
        // Prepare headers
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Config.grokAPIKey)",
            "Content-Type": "application/json"
        ]
        
        // Make the API request
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                apiURL,
                method: .post,
                parameters: requestBody,
                encoding: JSONEncoding.default,
                headers: headers
            )
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        // Parse response
                        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = jsonResponse["choices"] as? [[String: Any]],
                              !choices.isEmpty,
                              let firstChoice = choices.first,
                              let message = firstChoice["message"] as? [String: Any],
                              let content = message["content"] as? String,
                              !content.isEmpty else {
                            print("❌ GrokService: Invalid Q&A response structure")
                            continuation.resume(throwing: GrokServiceError.invalidResponse)
                            return
                        }
                        
                        print("✅ GrokService: Q&A response received")
                        continuation.resume(returning: content)
                        
                    } catch {
                        print("❌ GrokService: Error parsing Q&A response: \(error)")
                        continuation.resume(throwing: GrokServiceError.jsonParsingFailed)
                    }
                    
                case .failure(let error):
                    print("❌ GrokService: Network error during Q&A: \(error)")
                    continuation.resume(throwing: GrokServiceError.networkError(error))
                }
            }
        }
    }
}

// MARK: - Error Handling
enum GrokServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case jsonParsingFailed
    case jsonSerializationFailed
    case networkError(AFError)
    case apiError(String)
    case rateLimitExceeded
    case maxRetriesExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response format from Grok API"
        case .jsonParsingFailed:
            return "Failed to parse JSON response from Grok API"
        case .jsonSerializationFailed:
            return "Failed to serialize request data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded - too many requests"
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        }
    }
}

// MARK: - Preview Mock Data
#if DEBUG
extension GrokService {
    /// Mock data for SwiftUI previews and testing
    /// Generates a mock journey for testing/fallback purposes
    /// Following Sophrosyne rules: Realistic mock data matching new flexible format
    static func generateMockJourney(goal: String, maturity: String) -> [String: Any] {
        return [
            "path": [
                "days": [
                    [
                        "title": "Day 1: Beginning with Hope",
                        "verse": "Jeremiah 29:11 (ESV) - For I know the plans I have for you, declares the Lord, plans for welfare and not for evil, to give you a future and a hope.",
                        "devotional": [
                            "context": "Jeremiah spoke these words to the Israelites in Babylonian exile, reminding them that God had not forgotten them despite their circumstances.",
                            "meaning": "Even in the midst of struggle with \(goal), God's plans for you are good. This verse reassures us that our current difficulties are not the end of our story.",
                            "qaPrompt": "How can you trust God's good plans for you even when facing \(goal)?"
                        ]
                    ],
                    [
                        "title": "Day 2: Casting Your Cares",
                        "verse": "1 Peter 5:7 (ESV) - Casting all your anxieties on him, because he cares for you.",
                        "devotional": [
                            "context": "Peter wrote to believers facing persecution, encouraging them to humble themselves and trust God's care.",
                            "meaning": "God invites you to actively cast your burdens—including \(goal)—onto Him. This isn't passive; it's a deliberate choice to trust His care.",
                            "qaPrompt": "What specific anxieties related to \(goal) can you cast on God today?"
                        ]
                    ],
                    [
                        "title": "Day 3: Trusting Beyond Understanding",
                        "verse": "Proverbs 3:5-6 (ESV) - Trust in the Lord with all your heart, and do not lean on your own understanding. In all your ways acknowledge him, and he will make straight your paths.",
                        "devotional": [
                            "context": "This wisdom from Solomon emphasizes complete reliance on God rather than our limited human perspective.",
                            "meaning": "When facing \(goal), your own understanding may feel insufficient. God calls you to trust Him fully, and He promises to guide your path.",
                            "qaPrompt": "Where are you leaning on your own understanding instead of trusting God with \(goal)?"
                        ]
                    ],
                    [
                        "title": "Day 4: Finding Rest",
                        "verse": "Matthew 11:28-30 (ESV) - Come to me, all who labor and are heavy laden, and I will give you rest. Take my yoke upon you, and learn from me, for I am gentle and lowly in heart, and you will find rest for your souls.",
                        "devotional": [
                            "context": "Jesus spoke these words to crowds burdened by religious legalism and life's hardships.",
                            "meaning": "Your struggle with \(goal) is heavy, but Jesus offers genuine rest—not just physical, but soul-deep peace.",
                            "qaPrompt": "How can you practically 'come to Jesus' for rest from \(goal) today?"
                        ]
                    ],
                    [
                        "title": "Day 5: Renewed Strength",
                        "verse": "Isaiah 40:31 (ESV) - But they who wait for the Lord shall renew their strength; they shall mount up with wings like eagles; they shall run and not be weary; they shall walk and not faint.",
                        "devotional": [
                            "context": "Isaiah prophesied comfort to exiles, reminding them of God's power to restore and strengthen.",
                            "meaning": "Waiting on the Lord isn't passive—it's active trust. As you persevere through \(goal), God promises renewed strength.",
                            "qaPrompt": "What does 'waiting on the Lord' look like for you in the midst of \(goal)?"
                        ]
                    ],
                    [
                        "title": "Day 6: God's Presence",
                        "verse": "Psalm 46:1 (ESV) - God is our refuge and strength, a very present help in trouble.",
                        "devotional": [
                            "context": "This psalm celebrates God as a secure fortress amid chaos and fear.",
                            "meaning": "God is not distant. He is 'very present'—actively helping you navigate \(goal) right now.",
                            "qaPrompt": "How have you experienced God's presence as a refuge during \(goal)?"
                        ]
                    ],
                    [
                        "title": "Day 7: Moving Forward in Faith",
                        "verse": "Philippians 4:13 (ESV) - I can do all things through him who strengthens me.",
                        "devotional": [
                            "context": "Paul wrote this from prison, testifying to Christ's sufficiency in every circumstance.",
                            "meaning": "Your journey with \(maturity) faith and overcoming \(goal) is possible—not in your own strength, but through Christ who empowers you.",
                            "qaPrompt": "What specific step can you take today, trusting Christ's strength to help you with \(goal)?"
                        ]
                    ]
                ]
            ]
        ]
    }
}
#endif
