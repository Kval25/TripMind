import Foundation

class AIPackingService {
    static let shared = AIPackingService()
    
    private let apiKey = Secrets.geminiAPIKey
    
    func suggestPackingItems(for prompt: String) async throws -> [String] {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(Secrets.geminiAPIKey)"
        
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let fullPrompt = """
        You are a smart travel packing assistant.
        The user is describing their trip: \(prompt)
        Return ONLY a JSON array of packing item strings.
        Example: ["Sunscreen", "Swimsuit", "Flip flops", "Beach towel"]
        Return 8 to 12 items. No explanation, no markdown, just the JSON array.
        """
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": fullPrompt]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let raw = String(data: data, encoding: .utf8) ?? "no response"
        print("🔍 Gemini response: \(raw)")
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Parse Gemini response
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let content = decoded.candidates.first?.content.parts.first?.text ?? "[]"
        
        // Clean response and parse JSON array
        let cleaned = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleaned.data(using: .utf8),
              let items = try? JSONDecoder().decode([String].self, from: jsonData) else {
            return []
        }
        
        return items
    }
}

// MARK: - Gemini Response Models
struct GeminiResponse: Decodable {
    let candidates: [Candidate]
    
    struct Candidate: Decodable {
        let content: Content
    }
    
    struct Content: Decodable {
        let parts: [Part]
    }
    
    struct Part: Decodable {
        let text: String
    }
}
