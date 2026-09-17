package com.freellmkeymanager

import org.junit.Assert.assertEquals
import org.junit.Test

class ExampleUnitTest {
    @Test
    fun keyPrefixDetection() {
        val groqKey = "gsk_1234567890abcdef"
        val geminiKey = "AIzaSyD-1234567890abcdef"

        assertEquals(true, groqKey.startsWith("gsk_"))
        assertEquals(true, geminiKey.startsWith("AIza"))
    }

    @Test
    fun providerCount() {
        val providers = mapOf(
            "groq" to "https://console.groq.com/keys",
            "gemini" to "https://aistudio.google.com/app/apikey",
            "deepseek" to "https://platform.deepseek.com/api_keys",
            "openrouter" to "https://openrouter.ai/keys"
        )

        assertEquals(4, providers.size)
    }
}
