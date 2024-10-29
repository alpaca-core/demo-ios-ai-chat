// Copyright (c) Alpaca Core
// SPDX-License-Identifier: MIT
//
import SwiftUI

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

struct TypingIndicator_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TypingIndicator()
                .preferredColorScheme(.light) // Preview in light mode
            TypingIndicator()
                .preferredColorScheme(.dark) // Preview in dark mode
        }
    }
}
