import SwiftUI
import AppKit

struct ContentView: View {
    @State private var blur: Double = 0

    var body: some View {
        VStack {
            Image(systemName: "photo")
                .resizable()
                .frame(width: 200, height: 200)
                .blur(radius: blur)

            Slider(value: $blur, in: 0...40)
            Text("Blur: \(blur)")
        }
        .frame(width: 400, height: 400)
    }
}

let app = NSApplication.shared
let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
                      styleMask: [.titled, .closable],
                      backing: .buffered, defer: false)
window.contentView = NSHostingView(rootView: ContentView())
window.makeKeyAndOrderFront(nil)
// NSApp.run()
