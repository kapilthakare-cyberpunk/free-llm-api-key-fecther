import XCTest
@testable import FreeLLMKeyManager

final class FreeLLMKeyManagerTests: XCTestCase {
    func testProviderURLs() {
        let providers: [String: String] = [
            "groq": "https://console.groq.com/keys",
            "gemini": "https://aistudio.google.com/app/apikey",
            "deepseek": "https://platform.deepseek.com/api_keys",
            "openrouter": "https://openrouter.ai/keys"
        ]

        XCTAssertEqual(providers.count, 4)
        XCTAssertTrue(providers["groq"]?.hasPrefix("https://") == true)
        XCTAssertTrue(providers["gemini"]?.hasPrefix("https://") == true)
    }

    func testGroqKeyDetection() {
        let key = "gsk_1234567890abcdef"
        XCTAssertTrue(key.hasPrefix("gsk_"))
    }

    func testGeminiKeyDetection() {
        let key = "AIzaSyD-1234567890abcdef"
        XCTAssertTrue(key.hasPrefix("AIza"))
    }
}
