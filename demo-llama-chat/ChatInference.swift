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

        var params = Dictionary<String, Any>()
        do {
            let model = try createModel(&desc, params);
            params["ctx_size"] = 2048
            instance = try model.createInstance("general", params)
        } catch {
            print("Error creating instance: \(error)")
            return false
        }

        do {
            var inferenceParams = Dictionary<String, Any>()
            inferenceParams["setup"] = "Hi, how can I help you?"
            let _ = try instance!.runOp("begin-chat", inferenceParams);
        } catch {
            print("Error running operation: \(error)")
        }

        return true
    }

    public func sendPrompt(_ prompt: String) -> String {
        if (instance == nil) {
            return "Error: Instance not created"
        }

        var inferenceParams = Dictionary<String, Any>()
        inferenceParams["prompt"] = prompt

        do {
            let _ = try instance!.runOp("add-chat-prompt", inferenceParams, progress)
            inferenceParams = Dictionary<String, Any>()
            let result = try instance!.runOp("get-chat-response", inferenceParams, progress)
            return result["response"] as! String
        } catch {
            return "Error running operation: \(error)"
        }
    }
}
