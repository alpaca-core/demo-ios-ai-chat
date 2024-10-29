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


struct ModelSelector: View {
    // Options for the dropdown
    static var modelNames = [""]
    @Binding var selectedModel: String?

    @State private var registry: ModelRegistry
    private var manager: DownloadManager?
    @State private var downloadProgressText = ""
    @State private var isDownloading = false

    init(registry: ModelRegistry, selectedModel: Binding<String?>, manager: DownloadManager?) {
        self.registry = registry
        ModelSelector.modelNames = registry.models()

        self._selectedModel = selectedModel
        self.manager = manager
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Select a model:")
                .font(.headline)
                .foregroundColor(.gray)

            // Custom styled Picker
            Menu {
                ForEach(ModelSelector.modelNames, id: \.self) { model in
                    Button(action: {
                        selectedModel = model
                    }) {
                        Text(model)
                            .padding()
                            .foregroundColor(.primary)
                    }
                }
            } label: {
                HStack {
                    Text(selectedModel!)
                        .foregroundColor(.white)
                        .padding()
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white)
                        .padding()
                }
                .background(Color.blue) // Messenger app color
                .cornerRadius(10)
            }

            if selectedModel! != "" && !registry.exists(modelName: selectedModel!) {
                Text("Model must be downloaded first.")
                    .foregroundStyle(.black)
                Button("Download", action: {
                    manager!.progressCb = { (bytesWritten, totalBytes) -> Void in
                        let dp: Float = Float((Float(bytesWritten) / Float(totalBytes)) * 100).rounded()

//                        print("Progress \(dp)")
                        downloadProgressText = "Progress \(dp)"
                    }

                    manager!.finishCb = { (filePath) -> Void in
                        print("Finished downloading")
                        isDownloading = false
                        registry.register(modelPath: filePath)
                    }

                    guard let url = URL(string: registry.remotedModelPaths[selectedModel!] ?? "") else {
                        print("Invalid URL")
                        return
                    }

                    manager!.startDownload(from: url)

                    isDownloading = true
                })
            }

            if (isDownloading) {
                Text(downloadProgressText)
                    .padding()
                    .foregroundColor(.secondary)
            }

        }
        .padding()
        .background(.white) // Light background for contrast
        .cornerRadius(12)
        .shadow(radius: 5) // Add shadow for depth
        .padding()
    }
}

struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(.gray)
                    .scaleEffect(animate ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(0.2 * Double(index))
                    )
            }
        }
        .onAppear {
            animate = true
        }
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
                        Task {
                            let resultText = await chatInference.sendPrompt(messageText)
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
            TypingIndicator()
                .preferredColorScheme(.light) // Preview in light mode
            TypingIndicator()
                .preferredColorScheme(.dark) // Preview in dark mode
        }
    }
}
