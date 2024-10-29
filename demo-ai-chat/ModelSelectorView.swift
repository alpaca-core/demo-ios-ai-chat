// Copyright (c) Alpaca Core
// SPDX-License-Identifier: MIT
//
import SwiftUI

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

            if selectedModel! != "" && !registry.exists(modelName: selectedModel!) && !isDownloading {
                Text("Model must be downloaded first.")
                    .foregroundStyle(.black)
                Button("Download", action: {
                    manager!.progressCb = { (bytesWritten, totalBytes) -> Void in
                        let dp: Float = Float((Float(bytesWritten) / Float(totalBytes)) * 100).rounded()
                        downloadProgressText = "Progress: \(dp)%"
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
                Text("Please don't switch the model while downloading.")
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                Text(downloadProgressText)
                    .padding()
                    .foregroundColor(.black)
            }

        }
        .padding()
        .background(.white) // Light background for contrast
        .cornerRadius(12)
        .shadow(radius: 5) // Add shadow for depth
        .padding()
    }
}
