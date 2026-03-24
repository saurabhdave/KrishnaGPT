import Foundation
@testable import KrishnaGPT

final class MockChatService: ChatNetworking, @unchecked Sendable {
    struct SendRequest: Equatable {
        let text: String
        let language: LanguageType
    }

    var streamedResponses: [Result<[String], Error>] = []
    private(set) var sentRequests: [SendRequest] = []
    private(set) var clearHistoryCallCount = 0

    func sendMessageStream(text: String, language: LanguageType) async throws -> AsyncThrowingStream<String, Error> {
        sentRequests.append(SendRequest(text: text, language: language))

        let result: Result<[String], Error>
        if streamedResponses.isEmpty {
            result = .success([])
        } else {
            result = streamedResponses.removeFirst()
        }

        return AsyncThrowingStream { continuation in
            switch result {
            case .success(let chunks):
                chunks.forEach { continuation.yield($0) }
                continuation.finish()
            case .failure(let error):
                continuation.finish(throwing: error)
            }
        }
    }

    func sendMessage(_ text: String, language: LanguageType) async throws -> String {
        sentRequests.append(SendRequest(text: text, language: language))
        return ""
    }

    func clearHistory() async {
        clearHistoryCallCount += 1
    }
}
