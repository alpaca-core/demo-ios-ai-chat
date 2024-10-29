// Copyright (c) Alpaca Core
// SPDX-License-Identifier: MIT
//
import Foundation

func fileSize(atPath path: String) -> Int64? {
    let fileManager = FileManager.default

    do {
        let attributes = try fileManager.attributesOfItem(atPath: path)
        if let fileSize = attributes[.size] as? Int64 {
            return fileSize
        }
    } catch {
        print("Error retrieving file size: \(error.localizedDescription)")
    }

    return nil
}

class DownloadManager: NSObject, URLSessionDownloadDelegate {
    var downloadTask: URLSessionDownloadTask?
    var session: URLSession?
    var originalFilename = "default.txt"
    var progressCb: Optional<(Int64, Int64)->()>
    var finishCb: Optional<(String)->()>
    var cache: URLCache?
    var downloadDst: URL?
    let downloadIntoSandBoxFolder = false

    override init() {
        self.progressCb = { (bytesWritten, totalBytes) -> Void in
            let dp: Float = Float(bytesWritten) / Float(totalBytes)
            print("Progress \(dp)")

        }
        self.finishCb = { (path) -> Void in
            print("Downlad finished for: \(path)")
        }

        let fileManager = FileManager.default
        let downloads = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        downloadDst = downloads!.appendingPathComponent("alpaca-ai")
        do {
            try fileManager.createDirectory(atPath: downloadDst!.path, withIntermediateDirectories: true)
        } catch {
            print("Create dir error: \(error.localizedDescription)")
        }
        print("AlpacaAI download folder is \(downloadDst!.path)")
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
        let requestedFileName = downloadTask.originalRequest?.url?.path().split(separator: "/").last
        let destURL = downloadDst!.appendingPathComponent(String(requestedFileName!))

        do {
            // Remove any existing file at the destination
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            // Move the file from the temporary location to the permanent location
            try fileManager.moveItem(at: location, to: destURL)

            print("File moved to: \(destURL.path)")
            if finishCb != nil {
                finishCb!(destURL.path)
            }
        } catch {
            print("Error moving file: \(error.localizedDescription)")
        }
    }

    /* Sent periodically to notify the delegate of download progress. */
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if progressCb != nil {
            progressCb!(totalBytesWritten, totalBytesExpectedToWrite)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download failed with error: \(error.localizedDescription)")
        } else {
            print("Download successful")
        }
    }
}
