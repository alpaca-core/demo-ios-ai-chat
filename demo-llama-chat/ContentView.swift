// Copyright (c) Alpaca Core
// SPDX-License-Identifier: MIT
//
import SwiftUI

// Wrapper for ExportViewController
struct ExportViewControllerWrapper: UIViewControllerRepresentable {
    @Binding var isExporting: Bool  // A binding to control when to trigger the export action

    func makeUIViewController(context: Context) -> ExportViewController {
        return ExportViewController()  // Create an instance of ExportViewController
    }

    func updateUIViewController(_ uiViewController: ExportViewController, context: Context) {
    }

    func dismantleUIViewController(_ uiViewController: ExportViewController, coordinator: Coordinator) {
        isExporting = false
    }

}

struct ContentView: View {
    @State private var showText: Bool = false
    @State private var textContent: String = ""
    @State private var downloadProgressText: String = ""
    @State private var manager: DownloadManager = DownloadManager()
    @State private var isExporting = false

    var body: some View {
        VStack {
            Button(action: self.downloadFileToAppGroup, label: {
                Text("Download file")
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            })
            Button(action: self.readFileContent, label: {
                Text("Read Content")
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            })

            Button(action: {
                print("Exporting \(isExporting)")
                isExporting = true  // Set this to true to trigger the export action
                print("Exporting \(isExporting)")

            }, label: {
                Text("Export File")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            })
            .sheet(isPresented: $isExporting) {
                ExportViewControllerWrapper(isExporting: $isExporting)  // Embed the view controller wrapper
            }


            Text(downloadProgressText)
                .foregroundColor(.green)
                .frame(alignment: .topLeading)
            ScrollView {
                Text(textContent)
                    .foregroundColor(.green)
                    .frame(alignment: .topLeading)
            }
        }
        .padding()
    }

    func readFileContent() {
        textContent += ">" + readFileContentString()
    }

    func downloadFileToAppGroup() {
        manager.progressCb = { (bytesWritten, totalBytes) -> Void in
            let dp: Float = Float((Float(bytesWritten) / Float(totalBytes)) * 100).rounded()
            print("Progress \(dp)")
            downloadProgressText = "Progress \(dp)"

        }
        downloadFile(manager: self.manager)
    }

}

#Preview {
    ContentView()
}
