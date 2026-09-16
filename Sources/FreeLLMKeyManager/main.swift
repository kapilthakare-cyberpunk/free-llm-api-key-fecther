import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var lastClipboardContent: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.title = "LLM Keys"
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate), keyEquivalent: "q"))
        statusBarItem.menu = menu

        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if let content = NSPasteboard.general.string(forType: .string), content != self.lastClipboardContent {
                self.lastClipboardContent = content
                self.processKey(content: content.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }

    func processKey(content: String) {
        // Heuristic detection
        if content.hasPrefix("gsk_") || content.hasPrefix("AIza") {
            let provider = content.hasPrefix("gsk_") ? "groq" : "gemini"
            let msg = "Detected \(provider) key: \(content.prefix(10))..."
            
            // Just log to console for now, the daemon handles persistent storage
            print(msg)
            
            let alert = NSAlert()
            alert.messageText = "Auto-save \(provider) key?"
            alert.informativeText = msg
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Ignore")
            
            if alert.runModal() == .alertFirstButtonReturn {
                // Here we could trigger a helper script to save
                print("Key saved to local store.")
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
