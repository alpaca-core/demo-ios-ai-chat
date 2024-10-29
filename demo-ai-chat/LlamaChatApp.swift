// Copyright (c) Alpaca Core
// SPDX-License-Identifier: MIT
//
import SwiftUI

@main
struct LlamaChatApp: App {
    var body: some Scene {
        WindowGroup {
            ChatScreen()
                .background(Color.white) // Make the background white for the entire app
        }
    }
}
