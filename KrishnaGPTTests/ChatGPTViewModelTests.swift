import Testing
@testable import KrishnaGPT

@Suite("ChatGPTViewModel Tests")
@MainActor
struct ChatGPTViewModelTests {
    private enum TestError: Error {
        case mocked
    }

    @Test func sendTappedStreamsResponseAndResetsInteractionState() async {
        let mock = MockChatService()
        mock.streamedResponses = [.success(["Hare", " Krishna"])]

        let viewModel = ChatGPTViewModel(service: mock)
        viewModel.selectedLanguage = .hindi
        viewModel.inputMessage = "  Explain dharma  "

        await viewModel.sendTapped()

        #expect(mock.sentRequests == [
            MockChatService.SendRequest(text: "Explain dharma", language: .hindi)
        ])
        #expect(viewModel.inputMessage == "")
        #expect(!viewModel.isInteractingWithChatGPT)
        #expect(viewModel.messages.count == 1)

        let message = viewModel.messages[0]
        #expect(message.sendText == "Explain dharma")
        #expect(message.responseText == "Hare Krishna")
        #expect(message.responseError == nil)
        #expect(!message.isInteractingWithChatGPT)
    }

    @Test func sendTappedWithWhitespaceInputDoesNothing() async {
        let mock = MockChatService()
        let viewModel = ChatGPTViewModel(service: mock)
        viewModel.inputMessage = "   \n\t  "

        await viewModel.sendTapped()

        #expect(mock.sentRequests.isEmpty)
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.inputMessage == "   \n\t  ")
    }

    @Test func clearMessagesCallsServiceAndClearsMessages() async {
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

        #expect(mock.clearHistoryCallCount == 1)
        #expect(viewModel.messages.isEmpty)
    }

    @Test func retryRemovesOldMessageAndSendsOriginalText() async {
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

        #expect(mock.sentRequests == [
            MockChatService.SendRequest(text: "What is karma?", language: .mandarin)
        ])
        #expect(viewModel.messages.count == 1)
        #expect(viewModel.messages[0].sendText == "What is karma?")
        #expect(viewModel.messages[0].responseText == "Retry response")
        #expect(viewModel.messages[0].responseError == nil)
        #expect(viewModel.messages[0].id != failedMessage.id)
    }

    @Test func sendTappedStoresErrorOnStreamFailure() async {
        let mock = MockChatService()
        mock.streamedResponses = [.failure(TestError.mocked)]

        let viewModel = ChatGPTViewModel(service: mock)
        viewModel.inputMessage = "error test"

        await viewModel.sendTapped()

        #expect(viewModel.messages.count == 1)
        #expect(viewModel.messages[0].responseError != nil)
        #expect(!viewModel.isInteractingWithChatGPT)
        #expect(!viewModel.messages[0].isInteractingWithChatGPT)
    }
}
