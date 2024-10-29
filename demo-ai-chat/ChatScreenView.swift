// Copyright (c) Alpaca Core
// SPDX-License-Identifier: MIT
//
import SwiftUI

struct Message: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isSentByCurrentUser: Bool
}

struct ChatBubble: View {
    @Environment(\.colorScheme) var colorScheme
    var message: Message

    var body: some View {
        HStack {
            if message.isSentByCurrentUser {
                Spacer()
            }

            if message.text == "Waiting" {
                VStack {
                    TypingIndicator()
                }
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
            else {
                Text(message.text)
                    .padding()
                    .background(message.isSentByCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isSentByCurrentUser ? .white : .black)
                    .cornerRadius(12)
                    .frame(maxWidth: 250, alignment: message.isSentByCurrentUser ? .trailing : .leading)
            }

            if !message.isSentByCurrentUser {
                Spacer()
            }
        }
        .padding(message.isSentByCurrentUser ? .leading : .trailing, 60)
        .padding(.vertical, 5)
    }
}

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []

    func sendMessage(_ text: String, _ isUser: Bool) {
        let newMessage = Message(text: text, isSentByCurrentUser: isUser)
        messages.append(newMessage)
    }

    func clearMessages() {
        messages.removeAll()
    }

    func addWaitingMessage() {
        messages.append(Message(text: "Waiting", isSentByCurrentUser: false))
    }

    func removeWaitingMessage() {
        messages.removeLast()
    }
}

struct ChatScreen: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText: String = ""
    @State private var selectedModel: String? = ""
    private var manager: DownloadManager = DownloadManager()
    private var modelRegistry: ModelRegistry = ModelRegistry()
    private var chatInference: ChatInference = ChatInference()
    @State private var isLoading: Bool = false
    @State private var isWaitingResponse: Bool = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading the model...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .foregroundColor(.black)
            }

            ModelSelector(registry: modelRegistry, selectedModel: $selectedModel, manager: manager)
                .onChange(of: selectedModel, perform: { model in
                    if let model {
                        print("Loading model: \(model)")
                        let fullModelPath = modelRegistry.getModelLocalPath(modelName: model)
                        if fullModelPath != nil {
                            isLoading = true
                            Task {
                                let _ = await chatInference.createInstance(modelName: selectedModel!, modelPath: fullModelPath!)
                                isLoading = false
                                viewModel.clearMessages()
                                viewModel.sendMessage("Hi, how can I help you?", false)
                            }
                        }
                    }
                })

            ScrollViewReader { scrollView in
                ScrollView {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                    .padding(.horizontal)

                }
                .onChange(of: viewModel.messages) { _ in
                    if let lastIndex = viewModel.messages.last?.id {
                         withAnimation {
                             scrollView.scrollTo(lastIndex, anchor: .bottom)
                         }
                     }
                }
            }

            HStack {
                TextField("Type a message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 30)
                    .cornerRadius(8) // Additional corner radius

                Button(action: {
                    if !messageText.isEmpty {
                        viewModel.sendMessage(messageText, true)
                        isWaitingResponse = true
                        viewModel.addWaitingMessage()
                        let prompt = messageText
                        Task {
                            let resultText = await chatInference.sendPrompt(prompt)
                            viewModel.removeWaitingMessage()
                            viewModel.sendMessage(resultText, false)
                            isWaitingResponse = false
                        }
                        messageText = ""
                    }
                }) {
                    Text("Send")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Chat with AI")
    }
}

struct ChatScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChatScreen()
                .preferredColorScheme(.light) // Preview in light mode
            ChatScreen()
                .preferredColorScheme(.dark) // Preview in dark mode
        }
    }
}
