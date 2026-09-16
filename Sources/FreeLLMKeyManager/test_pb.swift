import Cocoa

let pb = NSPasteboard.general
if let content = pb.string(forType: .string) {
    print("Clipboard content: " + content)
} else {
    print("No text in clipboard")
}
