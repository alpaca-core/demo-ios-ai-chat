// Copyright (c) Alpaca Core
// SPDX-License-Identifier: MIT
//
import Foundation

class ModelRegistry {
    private var modelPaths: [String] = []
    public var remotedModelPaths: [String: String] = [:]

    init() {
        remotedModelPaths["capybarahermes-2.5-mistral-7b.Q4_0"] = "https://huggingface.co/TheBloke/CapybaraHermes-2.5-Mistral-7B-GGUF/resolve/main/capybarahermes-2.5-mistral-7b.Q4_0.gguf"

        let fileExtension = "gguf"
        // get all files in the bundle
        guard let resourcePaths = Bundle.main.paths(forResourcesOfType: fileExtension, inDirectory: nil) as [String]? else {
            print("No resources found with extension \(fileExtension)")
        }

        modelPaths += resourcePaths

        for resourcePath in resourcePaths {
            print(fileSize(atPath: resourcePath) ?? 0)
        }

        // get all files in download dir
        do {
            let downloads = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let downloadDst = downloads!.appendingPathComponent("alpaca-ai")

            let files = try FileManager.default.contentsOfDirectory(at: downloadDst, includingPropertiesForKeys: nil, options: [])
            let matchingFiles = files.filter { $0.pathExtension == fileExtension }
            modelPaths += matchingFiles.map({ fileUrl in
                return fileUrl.path()
            })
        }
        catch {
            print("Error reading directory: \(error.localizedDescription)")
        }

        print("Total models: \(modelPaths.count): \(modelPaths.joined(separator: ", "))")
    }

    public func register(modelPath: String) {
        modelPaths.append(modelPath)
    }

    public func models() -> [String] {
        var supportedModels: [String] = modelPaths.map({ path in
            var fileName = path.split(separator: "/").last
            fileName!.removeLast(5)
            return String(fileName!)
        })

        supportedModels += remotedModelPaths.map({ elem in
            return elem.key
        })

        return Array(Set(supportedModels))
    }

    public func exists(modelName: String) -> Bool {
        for path in modelPaths {
            if (path.contains(modelName)) {
                print("Does it exist: \(modelName) -> True")
                return true
            }
        }
        print("Does it exist: \(modelName) -> False")
        return false
    }

    public func getModelLocalPath(modelName: String) -> String? {
        for path in modelPaths {
            if (path.contains(modelName)) {
                print("Found model: \(modelName) -> \(path)")
                return path
            }
        }
        print("Could not find model: \(modelName)")
        return nil
    }
}
