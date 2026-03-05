import XCTest
@testable import KrishnaGPT

@MainActor
final class ChatGPTViewModelTests: XCTestCase {
    private enum TestError: Error {
        case mocked
    }

    func testSendTappedStreamsResponseAndResetsInteractionState() async {
        let mock = MockChatService()
        mock.streamedResponses = [.success(["Hare", " Krishna"])]

        let viewModel = ChatGPTViewModel(service: mock)
        viewModel.selectedLanguage = .hindi
        viewModel.inputMessage = "  Explain dharma  "

        await viewModel.sendTapped()

        XCTAssertEqual(mock.sentRequests, [
            MockChatService.SendRequest(text: "Explain dharma", language: .hindi)
        ])
        XCTAssertEqual(viewModel.inputMessage, "")
        XCTAssertFalse(viewModel.isInteractingWithChatGPT)
        XCTAssertEqual(viewModel.messages.count, 1)

        let message = viewModel.messages[0]
        XCTAssertEqual(message.sendText, "Explain dharma")
        XCTAssertEqual(message.responseText, "Hare Krishna")
        XCTAssertNil(message.responseError)
        XCTAssertFalse(message.isInteractingWithChatGPT)
    }

    func testSendTappedWithWhitespaceInputDoesNothing() async {
        let mock = MockChatService()
        let viewModel = ChatGPTViewModel(service: mock)
        viewModel.inputMessage = "   \n\t  "

        await viewModel.sendTapped()

        XCTAssertTrue(mock.sentRequests.isEmpty)
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertEqual(viewModel.inputMessage, "   \n\t  ")
    }

    func testClearMessagesCallsServiceAndClearsMessages() async {
        let mock = MockChatService()
        let viewModel = ChatGPTViewModel(service: mock)

        viewModel.messages = [
            MessageRow(
                isInteractingWithChatGPT: false,
                sendImage: "profile",
                sendText: "Question",
                responseImage: "krishnaai",
                responseText: "Answer",
                responseError: nil
            )
        ]

        await viewModel.clearMessages()

        XCTAssertEqual(mock.clearHistoryCallCount, 1)
        XCTAssertTrue(viewModel.messages.isEmpty)
    }

    func testRetryRemovesOldMessageAndSendsOriginalText() async {
        let mock = MockChatService()
        mock.streamedResponses = [.success(["Retry response"])]

        let viewModel = ChatGPTViewModel(service: mock)
        viewModel.selectedLanguage = .mandarin

        let failedMessage = MessageRow(
            isInteractingWithChatGPT: false,
            sendImage: "profile",
            sendText: "What is karma?",
            responseImage: "krishnaai",
            responseText: "",
            responseError: "Network error"
        )
        viewModel.messages = [failedMessage]

        await viewModel.retry(message: failedMessage)

        XCTAssertEqual(mock.sentRequests, [
            MockChatService.SendRequest(text: "What is karma?", language: .mandarin)
        ])
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages[0].sendText, "What is karma?")
        XCTAssertEqual(viewModel.messages[0].responseText, "Retry response")
        XCTAssertNil(viewModel.messages[0].responseError)
        XCTAssertNotEqual(viewModel.messages[0].id, failedMessage.id)
    }

    func testSendTappedStoresErrorOnStreamFailure() async {
        let mock = MockChatService()
        mock.streamedResponses = [.failure(TestError.mocked)]

        let viewModel = ChatGPTViewModel(service: mock)
        viewModel.inputMessage = "error test"

        await viewModel.sendTapped()

        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertNotNil(viewModel.messages[0].responseError)
        XCTAssertFalse(viewModel.isInteractingWithChatGPT)
        XCTAssertFalse(viewModel.messages[0].isInteractingWithChatGPT)
    }
}
