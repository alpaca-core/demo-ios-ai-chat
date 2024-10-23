// Copyright (c) Alpaca Core
// SPDX-License-Identifier: MIT
//
import Foundation
import UIKit
import MobileCoreServices

func readFileFromLocalFolder() -> String {
    let fileManager = FileManager.default
    let downloads = try! fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
    let downloadDst = downloads.appendingPathComponent("alpaca-ai")

    // Define the file name and create a file URL in the shared container
    let fileName = "default.txt"
    let fileURL = downloadDst.appendingPathComponent(fileName)

    print("Reading file from: \(fileURL.path)")

    return getContentFromFile(fileURL: fileURL)
}

func readFileFromBookmarked() -> String {
    let originalFilename = "default.txt"
    let bookmarkURL = getSavedBookmarkURL()
    let file = bookmarkURL.appendingPathComponent(originalFilename)

    print("Reading file from: \(file.path)")

    return getContentFromFile(fileURL: file)
}

func readFileContentString() -> String{
    let shouldReadFromGlobal = true

    if shouldReadFromGlobal {
        return readFileFromBookmarked()
    } else {
        return readFileFromLocalFolder()
    }
}

func getContentFromFile(fileURL: URL) -> String {
    do {
        // read only the first 16 bytes of the file since it might be too big (100-200 mb)
        let handle = try FileHandle(forReadingFrom: fileURL)
        let first16Bytes: Data? = try handle.read(upToCount: 16)
        try handle.close()
        guard let bytes = first16Bytes else {
            print("Cannot read dataa - 16 bytes!")
            return ""
        }
        let content = String(data: bytes, encoding: .utf8)
        print("File read from App Group container: \(content)")
        return content! + "\n"
    } catch {
        print("Error reading file from App Group container: \(error.localizedDescription)")
    }
    return ""
}
func getMyURLForBookmark() -> URL {
    let fileManager = FileManager.default
    let docs = try! fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)

    return docs.appendingPathComponent("alpaca-ai-bookmark.txt")
}

func getSavedBookmarkURL() -> URL {
    let bookmarkData = try! Data(contentsOf: getMyURLForBookmark())
    var isStale = false
    let url = try! URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
    return url!
}

class ExportViewController: UIViewController, UIDocumentPickerDelegate {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        exportFile()  // Trigger the file export after the view has appeared
    }

    func exportFile() {
        let fileManager = FileManager.default
        let downloads = try! fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
        let dirURL = downloads.appendingPathComponent("alpaca-ai")

        try? fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)

        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.directoryURL = dirURL
        documentPicker.delegate = self

        print("Doc picker: Alpaca folder is \(dirURL.path)")

        present(documentPicker, animated: true, completion: nil)
    }

    func createSampleFile() -> URL {
        let fileManager = FileManager.default
        let downloads = try! fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
        let downloadDst = downloads.appendingPathComponent("alpaca-ai")

        return downloadDst.appendingPathComponent("default.txt")
    }

    // UIDocumentPickerDelegate methods
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // From apple docs:
        // =========================
        // Start accessing a security-scoped resource.
        guard urls.first!.startAccessingSecurityScopedResource() else {
            // Handle the failure here.
            return
        }


        // Make sure you release the security-scoped resource when you finish.
        defer { urls.first!.stopAccessingSecurityScopedResource() }
        // =========================

        guard let destinationURL = urls.first else { return }
        var dst = destinationURL

        print("Picked dest is \(destinationURL)")
        dst = dst.appendingPathComponent("alpaca-ai")

        writeAsBookmark(url: dst)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled.")
    }

    func writeAsBookmark(url: URL) {
        do {
            // Start accessing a security-scoped resource.
            guard url.startAccessingSecurityScopedResource() else {
                // Handle the failure here.
                return
            }

            // Make sure you release the security-scoped resource when you finish.
            defer { url.stopAccessingSecurityScopedResource() }

            let bookmarkData = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)

            try bookmarkData.write(to: getMyURLForBookmark())
        }
        catch let error {
            // Handle the error here.
        }
    }
}

class DownloadManager: NSObject, URLSessionDownloadDelegate {

    var downloadTask: URLSessionDownloadTask?
    var session: URLSession?
    var originalFilename = "default.txt"
    var progressCb: (Int64, Int64)->()?
    var cache: URLCache?
    var downloadDst: URL?
    let downloadIntoSandBoxFolder = false

    override init() {
        self.progressCb = { (bytesWritten, totalBytes) -> Void in
            let dp: Float = Float(bytesWritten) / Float(totalBytes)
            print("Progress \(dp)")

        }

        let fileManager = FileManager.default
        let downloads = try! fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        downloadDst = downloads!.appendingPathComponent("alpaca-ai")
        do {
            try fileManager.createDirectory(atPath: downloadDst!.path, withIntermediateDirectories: true)
        } catch {
            print("Create dir error: \(error.localizedDescription)")
        }
        print("Alpaca folder is \(downloadDst!.path)")
    }

    func startDownload(from url: URL) {
        let sessionConfig = URLSessionConfiguration.default
        session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        downloadTask = session?.downloadTask(with: url)
        downloadTask?.resume()
    }

    func cancelDownloadTask() {
        if let task = downloadTask, task.state == .running {
            task.cancel()
            print("Download task is canceled")
        }
        downloadTask = nil
    }

    // URLSessionDownloadDelegate method
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("File downloaded to: \(location.path)")

        print("current dir: \(FileManager.default.currentDirectoryPath)")
        let fileManager = FileManager.default

        do {
            var destURL = location
            if downloadIntoSandBoxFolder {
                destURL = downloadDst!.appendingPathComponent(originalFilename)
            } else {
                let bookmarkURL = getSavedBookmarkURL()
                destURL = bookmarkURL.appendingPathComponent(originalFilename)
            }

            do {
                // Remove any existing file at the destination
                if fileManager.fileExists(atPath: destURL.path) {
                    try fileManager.removeItem(at: destURL)
                }
                // Move the file from the temporary location to the permanent location
                try fileManager.moveItem(at: location, to: destURL)

                print("File moved to: \(destURL.path)")
            } catch {
                print("Error moving file: \(error.localizedDescription)")
            }
        }
        catch let error {
            print("Bookmark: \(error)")
        }
    }

    /* Sent periodically to notify the delegate of download progress. */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        progressCb(totalBytesWritten, totalBytesExpectedToWrite)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download failed with error: \(error.localizedDescription)")
        } else {
            print("Download successful")
        }
    }
}

func downloadFile(manager: DownloadManager) {
    guard let url = URL(string: "https://ed03-78-130-168-52.ngrok-free.app/default_small.txt") else {
        return
    }

    manager.startDownload(from: url)
}
