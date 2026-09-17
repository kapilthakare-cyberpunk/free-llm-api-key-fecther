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
            "openrouter" to "https://openrouter.ai/keys",
            "together" to "https://api.together.xyz/settings/api-keys",
            "mistral" to "https://console.mistral.ai/api-keys/",
            "huggingface" to "https://huggingface.co/settings/tokens",
            "cohere" to "https://dashboard.cohere.com/api-keys",
            "fireworks" to "https://fireworks.ai/account/api-keys",
            "cerebras" to "https://cloud.cerebras.ai/account/api-keys"
        )

        assertEquals(10, providers.size)
    }
}
