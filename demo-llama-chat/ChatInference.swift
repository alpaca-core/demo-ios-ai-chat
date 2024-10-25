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

    public func createInstance(modelName: String, modelPath: String) -> Bool {
        instance = nil

        var desc = ModelDesc()
        desc.inferenceType = "llama.cpp"
        desc.assets.append(AssetInfo(modelPath, modelName))

        // Attempt to open the file using fopen
        let filePointer = fopen(modelPath, "r") // Open for reading

        if filePointer != nil {
             print("File opened successfully: \(modelPath)")
             // Close the file when done
             fclose(filePointer)
         } else {
             print("Failed to open file: \(String(cString: strerror(errno)))")
         }

        var params = Dictionary<String, Any>()
        do {
            let model = try createModel(&desc, params, progress);
            params["ctx_size"] = 2048
            instance = try model.createInstance("general", params)
        } catch {
            print("Error creating instance: \(error)")
            return false
        }

        do {
            var inferenceParams = Dictionary<String, Any>()
            inferenceParams["setup"] = "Hi, how can I help you?"
            let _ = try instance!.runOp("begin-chat", inferenceParams, progress);
        } catch {
            print("Error running operation: \(error)")
        }

        return true
    }

    public func sendPrompt(_ prompt: String) -> String {
        if (instance == nil) {
            return "Instance not created"
        }

        var inferenceParams = Dictionary<String, Any>()
        inferenceParams["prompt"] = prompt

        do {
            try instance!.runOp("add-chat-prompt", inferenceParams, progress)
            inferenceParams = Dictionary<String, Any>()
            let result = try instance!.runOp("get-chat-response", inferenceParams, progress)
            return result["response"] as! String
        } catch {
            return "Error running operation: \(error)"
        }
    }
}
