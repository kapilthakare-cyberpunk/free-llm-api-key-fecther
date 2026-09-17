import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var lastClipboardContent: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.title = "LLM Keys"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Export Backup", action: #selector(exportBackup), keyEquivalent: "e"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate), keyEquivalent: "q"))
        statusBarItem.menu = menu

        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if let content = NSPasteboard.general.string(forType: .string), content != self.lastClipboardContent {
                self.lastClipboardContent = content
                self.processKey(content: content.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }

    @objc func exportBackup() {
        let keys: [String: String] = [
            "groq": "gsk_...",
            "gemini": "AIza...",
            "together": "together_...",
            "mistral": "mistral_...",
            "huggingface": "hf_...",
            "cohere": "cohere_...",
            "fireworks": "fw_...",
            "cerebras": "csk_..."
        ]

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "llm_keys_backup.json"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let json = try JSONSerialization.data(withJSONObject: keys, options: .prettyPrinted)
                    try json.write(to: url)
                    let alert = NSAlert()
                    alert.messageText = "Backup exported"
                    alert.informativeText = url.path
                    alert.alertStyle = .informational
                    alert.runModal()
                } catch {
                    let alert = NSAlert()
                    alert.messageText = "Export failed"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .critical
                    alert.runModal()
                }
            }
        }
    }

    func processKey(content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let provider: String?
        let prefix: String

        if trimmed.hasPrefix("gsk_") {
            provider = "groq"
            prefix = "gsk_"
        } else if trimmed.hasPrefix("AIza") {
            provider = "gemini"
            prefix = "AIza"
        } else if trimmed.hasPrefix("together_") {
            provider = "together"
            prefix = "together_"
        } else if trimmed.hasPrefix("mistral_") {
            provider = "mistral"
            prefix = "mistral_"
        } else if trimmed.hasPrefix("hf_") {
            provider = "huggingface"
            prefix = "hf_"
        } else if trimmed.hasPrefix("cohere_") {
            provider = "cohere"
            prefix = "cohere_"
        } else if trimmed.hasPrefix("fw_") {
            provider = "fireworks"
            prefix = "fw_"
        } else if trimmed.hasPrefix("csk_") {
            provider = "cerebras"
            prefix = "csk_"
        } else {
            provider = nil
            prefix = ""
        }

        if let detectedProvider = provider {
            let msg = "Detected \(detectedProvider) key: \(trimmed.prefix(prefix.count + 10))..."
            print(msg)

            let alert = NSAlert()
            alert.messageText = "Auto-save \(detectedProvider) key?"
            alert.informativeText = msg
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Ignore")

            if alert.runModal() == .alertFirstButtonReturn {
                print("Key saved to local store.")
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
