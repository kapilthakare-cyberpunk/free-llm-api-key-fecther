import Cocoa

struct Provider: Identifiable {
    let id: String
    let name: String
    let prefix: String
    let url: String
}

struct StoredKey: Codable {
    let provider: String
    let key: String
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var lastClipboardContent: String?
    var window: NSWindow?
    var tableView: NSTableView?
    var tableScrollView: NSScrollView?
    var keys: [String: String] = [:] {
        didSet {
            tableView?.reloadData()
        }
    }

    let providers: [Provider] = [
        Provider(id: "groq", name: "Groq", prefix: "gsk_", url: "https://console.groq.com/keys"),
        Provider(id: "gemini", name: "Gemini", prefix: "AIza", url: "https://aistudio.google.com/app/apikey"),
        Provider(id: "deepseek", name: "DeepSeek", prefix: "sk-", url: "https://platform.deepseek.com/api_keys"),
        Provider(id: "openrouter", name: "OpenRouter", prefix: "sk-or-", url: "https://openrouter.ai/keys"),
        Provider(id: "together", name: "Together", prefix: "together_", url: "https://api.together.xyz/settings/api-keys"),
        Provider(id: "mistral", name: "Mistral", prefix: "mistral_", url: "https://console.mistral.ai/api-keys/"),
        Provider(id: "huggingface", name: "Hugging Face", prefix: "hf_", url: "https://huggingface.co/settings/tokens"),
        Provider(id: "cohere", name: "Cohere", prefix: "cohere_", url: "https://dashboard.cohere.com/api-keys"),
        Provider(id: "fireworks", name: "Fireworks", prefix: "fw_", url: "https://fireworks.ai/account/api-keys"),
        Provider(id: "cerebras", name: "Cerebras", prefix: "csk_", url: "https://cloud.cerebras.ai/account/api-keys")
    ]

    private var storageURL: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let folder = urls.first!.appendingPathComponent("FreeLLMKeyManager")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("keys.json")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        loadKeys()

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem.button?.title = "LLM Keys"
        statusBarItem.menu = buildMenu()

        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let content = NSPasteboard.general.string(forType: .string),
                  content != self?.lastClipboardContent else { return }
            self?.lastClipboardContent = content
            self?.pasteAndSaveKey(content.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Keys", action: nil, keyEquivalent: ""))
        providers.forEach { provider in
            let key = keys[provider.id]
            let title = key != nil ? "\(provider.name): \(key!.prefix(6))..." : "\(provider.name): <missing>"
            let item = NSMenuItem(title: title, action: #selector(openProviderMenu(_:)), keyEquivalent: "")
            item.representedObject = provider
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open Manager", action: #selector(openManager), keyEquivalent: "m"))
        menu.addItem(NSMenuItem(title: "Paste and Save", action: #selector(pasteAndSave), keyEquivalent: "v"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Export Backup", action: #selector(exportBackup), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate), keyEquivalent: "q"))
        return menu
    }

    @objc func openProviderMenu(_ sender: NSMenuItem) {
        guard let provider = sender.representedObject as? Provider else { return }
        let storedKey = keys[provider.id]

        let menu = NSMenu()
        if storedKey != nil {
            menu.addItem(NSMenuItem(title: "Copy Key", action: #selector(copyProviderKey(_:)), keyEquivalent: "c"))
            menu.addItem(NSMenuItem(title: "Open Provider Page", action: #selector(openProviderUrl(_:)), keyEquivalent: "o"))
            menu.addItem(NSMenuItem(title: "Delete Key", action: #selector(deleteProviderKey(_:)), keyEquivalent: ""))
        } else {
            menu.addItem(NSMenuItem(title: "Save Key", action: #selector(saveProviderKey(_:)), keyEquivalent: "s"))
            menu.addItem(NSMenuItem(title: "Open Provider Page", action: #selector(openProviderUrl(_:)), keyEquivalent: "o"))
        }

        NSMenu.popUpContextMenu(menu, with: NSApp.currentEvent!, for: statusBarItem.button!)
    }

    @objc func copyProviderKey(_ sender: NSMenuItem) {
        guard let provider = sender.representedObject as? Provider,
              let key = keys[provider.id] else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(key, forType: .string)
    }

    @objc func openProviderUrl(_ sender: NSMenuItem) {
        guard let provider = sender.representedObject as? Provider else { return }
        NSWorkspace.shared.open(URL(string: provider.url)!)
    }

    @objc func deleteProviderKey(_ sender: NSMenuItem) {
        guard let provider = sender.representedObject as? Provider else { return }
        keys[provider.id] = nil
        saveKeys()
    }

    @objc func saveProviderKey(_ sender: NSMenuItem) {
        guard let provider = sender.representedObject as? Provider else { return }
        let alert = NSAlert()
        alert.messageText = "Save \(provider.name) key"
        alert.informativeText = "Paste or type the API key below."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        input.placeholderString = "API key"
        alert.accessoryView = input
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let value = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty {
                keys[provider.id] = value
                saveKeys()
            }
        }
    }

    @objc func openManager() {
        if window == nil {
            createManagerWindow()
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createManagerWindow() {
        let rect = NSRect(x: 0, y: 0, width: 560, height: 420)
        let win = NSWindow(contentRect: rect, styleMask: [.titled, .closable, .resizable, .miniaturizable], backing: .buffered, defer: false)
        win.title = "LLM Key Manager"
        win.center()
        window = win

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .left
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)

        let header = NSStackView()
        header.orientation = .horizontal
        header.alignment = .centerY
        header.distribution = .fill
        header.spacing = 8

        let title = NSTextField(labelWithString: "Saved Keys")
        title.font = NSFont.boldSystemFont(ofSize: 14)
        header.addView(title, in: .center)

        header.addView(NSView(), in: .leading)
        header.addView(NSView(), in: .trailing)
        root.addView(header, in: .top)

        let columns = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("provider"))
        columns.title = "Provider"
        columns.width = 160
        let keyColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("key"))
        keyColumn.title = "Key"
        keyColumn.width = 240
        let actionsColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("actions"))
        actionsColumn.title = "Actions"
        actionsColumn.width = 140

        let table = NSTableView()
        table.addTableColumn(columns)
        table.addTableColumn(keyColumn)
        table.addTableColumn(actionsColumn)
        table.headerView = NSTableHeaderView()
        table.delegate = self
        table.dataSource = self
        table.rowHeight = 28
        tableView = table

        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: rect.width - 28, height: rect.height - 140))
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        tableScrollView = scroll
        root.addView(scroll, in: .center)

        let actionsRow = NSStackView()
        actionsRow.orientation = .horizontal
        actionsRow.alignment = .centerY
        actionsRow.distribution = .fillEqually
        actionsRow.spacing = 10

        let addBtn = NSButton(title: "Add Key", target: self, action: #selector(addKey))
        let pasteBtn = NSButton(title: "Paste and Save", target: self, action: #selector(pasteAndSave))
        let exportBtn = NSButton(title: "Export Backup", target: self, action: #selector(exportBackup))
        actionsRow.addView(addBtn, in: .leading)
        actionsRow.addView(pasteBtn, in: .center)
        actionsRow.addView(exportBtn, in: .trailing)
        root.addView(actionsRow, in: .bottom)

        win.contentView = root
    }

    @objc func addKey() {
        let alert = NSAlert()
        alert.messageText = "Add LLM API Key"
        alert.informativeText = "Paste or type the API key. Provider will be detected automatically."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 340, height: 24))
        input.placeholderString = "Paste API key"
        alert.accessoryView = input
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let value = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty {
                pasteAndSaveKey(value)
            }
        }
    }

    @objc func pasteAndSave() {
        guard let content = NSPasteboard.general.string(forType: .string), !content.isEmpty else {
            showInfo("Clipboard is empty")
            return
        }
        pasteAndSaveKey(content.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func pasteAndSaveKey(_ content: String) {
        guard let provider = detectProvider(content) else {
            showInfo("No supported key detected")
            return
        }
        keys[provider.id] = content
        saveKeys()
        showInfo("Saved \(provider.name) key")
    }

    private func detectProvider(_ key: String) -> Provider? {
        providers.first { key.hasPrefix($0.prefix) }
    }

    @objc func exportBackup() {
        if keys.isEmpty {
            showInfo("No keys to export")
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "llm_keys_backup.json"
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let data = try JSONEncoder().encode(self?.keys ?? [:])
                try data.write(to: url)
                self?.showInfo("Backup exported")
            } catch {
                self?.showError("Export failed: \(error.localizedDescription)")
            }
        }
    }

    private func loadKeys() {
        guard let data = try? Data(contentsOf: storageURL), let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            keys = [:]
            return
        }
        keys = decoded
    }

    private func saveKeys() {
        guard let data = try? JSONEncoder().encode(keys) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func showInfo(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.runModal()
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.runModal()
    }
}

extension AppDelegate: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        providers.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let provider = providers[row]
        let key = keys[provider.id]

        if tableColumn?.identifier.rawValue == "provider" {
            let text = NSTextField(labelWithString: provider.name)
            text.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            return text
        } else if tableColumn?.identifier.rawValue == "key" {
            let text = NSTextField(labelWithString: key ?? "<missing>")
            text.font = NSFont.systemFont(ofSize: 12)
            text.textColor = key != nil ? .labelColor : .secondaryLabelColor
            return text
        } else {
            let stack = NSStackView()
            stack.orientation = .horizontal
            stack.spacing = 8

            if key != nil {
                let copyBtn = NSButton(title: "Copy", target: self, action: #selector(copyProviderKey(_:)))
                copyBtn.tag = row
                stack.addView(copyBtn, in: .leading)
            } else {
                let saveBtn = NSButton(title: "Save", target: self, action: #selector(saveProviderKeyFromTable(_:)))
                saveBtn.tag = row
                stack.addView(saveBtn, in: .leading)
            }

            let loginBtn = NSButton(title: "Open", target: self, action: #selector(openProviderFromTable(_:)))
            loginBtn.tag = row
            stack.addView(loginBtn, in: .trailing)
            return stack
        }
    }

    @objc func saveProviderKeyFromTable(_ sender: NSButton) {
        let provider = providers[sender.tag]
        let alert = NSAlert()
        alert.messageText = "Save \(provider.name) key"
        alert.informativeText = "Paste or type the API key below."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 340, height: 24))
        input.placeholderString = "API key"
        alert.accessoryView = input
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let value = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty {
                keys[provider.id] = value
                saveKeys()
            }
        }
    }

    @objc func openProviderFromTable(_ sender: NSButton) {
        let provider = providers[sender.tag]
        NSWorkspace.shared.open(URL(string: provider.url)!)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
