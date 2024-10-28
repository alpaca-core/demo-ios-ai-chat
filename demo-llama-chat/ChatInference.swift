// Copyright (c) Alpaca Core
// SPDX-License-Identifier: MIT
//
import AlpacaCoreSwift
import UIKit

func progress(_ tag: String, _ progress: Float) {
    print("[\(tag)]Progress: \(progress)")
}

class ChatInference {
    var instance: Instance?

    init() {
        initSDK();
    }

    public func createInstance(modelName: String, modelPath: String) async -> Bool {
        instance = nil

        var desc = ModelDesc()
        desc.inferenceType = "llama.cpp"
        desc.assets.append(AssetInfo(modelPath, modelName))

        var params = Dictionary<String, Any>()
        do {
            let model = try await withCheckedThrowingContinuation { continuation in
                do {
                    let model = try createModel(&desc, params)
                    continuation.resume(returning: model)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            params["ctx_size"] = 16
            instance = try await withCheckedThrowingContinuation { continuation in
                do {
                    let instance = try model.createInstance("general", params)
                    continuation.resume(returning: instance)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            print("Error creating instance: \(error)")
            return false
        }

        do {
            var inferenceParams = Dictionary<String, Any>()
            inferenceParams["setup"] = "Hi, how can I help you?"
            // Wrap the synchronous runOp call in an asynchronous task
            try await withCheckedThrowingContinuation { continuation in
                do {
                    let _ = try instance!.runOp("begin-chat", inferenceParams)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            print("Error running operation: \(error)")
        }

        return true
    }

    public func sendPrompt(_ prompt: String) async -> String {
        if (instance == nil) {
            return "Error: Instance not created"
        }

        var inferenceParams = Dictionary<String, Any>()
        inferenceParams["prompt"] = prompt

        do {
            try await withCheckedThrowingContinuation { continuation in
                do {
                    let _ = try instance!.runOp("add-chat-prompt", inferenceParams, progress)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            inferenceParams = Dictionary<String, Any>()
            var result: Dictionary<String, Any> = Dictionary<String, Any>()
            try await withCheckedThrowingContinuation { continuation in
                do {
                    result = try instance!.runOp("get-chat-response", inferenceParams, progress)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            return result["response"] as! String
        } catch {
            return "Error running operation: \(error)"
        }
    }
}
