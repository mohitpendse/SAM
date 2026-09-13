//
//  GeminiService.swift
//  ASM
//

import Foundation

struct GeminiTutorRequest {
    var action: TutorAction
    var prompt: String
    var selection: SelectionState
    var profile: StudentLearningProfile
    var recentMessages: [TutorMessage]
}

enum GeminiServiceError: LocalizedError {
    case missingAPIKey
    case badResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add GEMINI_API_KEY to the scheme environment or app Info.plist."
        case .badResponse:
            return "Gemini did not return a usable tutor response."
        case .requestFailed(let message):
            return message
        }
    }
}

final class GeminiService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func generateTutorResponse(for tutorRequest: GeminiTutorRequest) async throws -> String {
        guard let apiKey = Self.configValue(for: ["GEMINI_API_KEY", "GeminiAPIKey"]), !apiKey.isEmpty else {
            throw GeminiServiceError.missingAPIKey
        }

        let model = Self.configValue(for: ["GEMINI_MODEL", "GeminiModel"]) ?? "gemini-3.8-flash"
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent") else {
            throw GeminiServiceError.badResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(Self.payload(for: tutorRequest))

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GeminiServiceError.badResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let apiError = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data)
            throw GeminiServiceError.requestFailed(apiError?.error.message ?? "Gemini request failed with HTTP \(http.statusCode).")
        }

        let decoded = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)
        let text = decoded.candidates?
            .flatMap { $0.content?.parts ?? [] }
            .compactMap(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let text, !text.isEmpty else {
            throw GeminiServiceError.badResponse
        }

        return text
    }

    private static func configValue(for keys: [String]) -> String? {
        for key in keys {
            if let value = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
               Self.isUsableConfigValue(value) {
                return value
            }
            if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if Self.isUsableConfigValue(trimmed) { return trimmed }
            }
        }
        return nil
    }

    private static func isUsableConfigValue(_ value: String) -> Bool {
        !value.isEmpty && !value.contains("$(")
    }

    private static func payload(for request: GeminiTutorRequest) -> GeminiGenerateContentRequest {
        GeminiGenerateContentRequest(
            systemInstruction: GeminiContent(
                role: nil,
                parts: [
                    GeminiPart(text: """
                    You are ASM Tutor, an AI study partner inside a canvas app. Be concise, concrete, and student-friendly. Use the learner profile. Prefer steps, checks, mini-quizzes, and next actions over generic encouragement. Do not claim to see handwritten content that was not provided; treat the selection label as the available context.
                    """)
                ]
            ),
            contents: [
                GeminiContent(
                    role: "user",
                    parts: [GeminiPart(text: promptText(for: request))]
                )
            ],
            generationConfig: GeminiGenerationConfig(
                temperature: 0.65,
                maxOutputTokens: 700
            )
        )
    }

    private static func promptText(for request: GeminiTutorRequest) -> String {
        let recent = request.recentMessages.suffix(6).map { message in
            "\(message.role): \(message.body)"
        }.joined(separator: "\n")

        return """
        Tutor action: \(request.action.rawValue)
        Student prompt: \(request.prompt)
        Selected canvas context: \(request.selection.label)

        Learner profile:
        Name: \(request.profile.name.isEmpty ? "Student" : request.profile.name)
        Goal: \(request.profile.goal)
        Exam/track: \(request.profile.exam)
        Subjects: \(request.profile.subjects.sorted().joined(separator: ", "))
        Learning modes: \(request.profile.learningModes.sorted().joined(separator: ", "))
        Explanation depth: \(request.profile.explanationDepth)
        Study block: \(Int(request.profile.studyBlock)) minutes
        Common blocker: \(request.profile.friction)
        Language preference: \(request.profile.language)
        Confidence: \(Int(request.profile.confidence * 100))%

        Recent conversation:
        \(recent.isEmpty ? "None" : recent)

        Respond as ASM Tutor. Keep it useful on a study canvas.
        """
    }
}

private struct GeminiGenerateContentRequest: Encodable {
    var systemInstruction: GeminiContent
    var contents: [GeminiContent]
    var generationConfig: GeminiGenerationConfig

    enum CodingKeys: String, CodingKey {
        case systemInstruction = "system_instruction"
        case contents
        case generationConfig
    }
}

private struct GeminiContent: Codable {
    var role: String?
    var parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    var text: String?
}

private struct GeminiGenerationConfig: Encodable {
    var temperature: Double
    var maxOutputTokens: Int
}

private struct GeminiGenerateContentResponse: Decodable {
    var candidates: [GeminiCandidate]?
}

private struct GeminiCandidate: Decodable {
    var content: GeminiContent?
}

private struct GeminiErrorResponse: Decodable {
    var error: GeminiAPIError
}

private struct GeminiAPIError: Decodable {
    var message: String
}
