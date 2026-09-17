package com.freellmkeymanager

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    private val providers = mapOf(
        "groq" to "https://console.groq.com/keys",
        "gemini" to "https://aistudio.google.com/app/apikey",
        "deepseek" to "https://platform.deepseek.com/api_keys",
        "openrouter" to "https://openrouter.ai/keys"
    )

    private val prefs by lazy {
        getSharedPreferences("llm_keys", Context.MODE_PRIVATE)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val keysContainer = findViewById<LinearLayout>(R.id.keysContainer)
        val addKeyButton = findViewById<Button>(R.id.addKeyButton)

        renderKeys()

        addKeyButton.setOnClickListener {
            showAddKeyDialog()
        }
    }

    private fun renderKeys() {
        val keysContainer = findViewById<LinearLayout>(R.id.keysContainer)
        keysContainer.removeAllViews()

        providers.forEach { (name, url) ->
            val key = prefs.getString(name, null)

            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = 8
                    bottomMargin = 8
                }
            }

            val providerText = TextView(this).apply {
                text = name.replaceFirstChar { it.uppercase() }
                textSize = 16f
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }

            val keyText = TextView(this).apply {
                text = key ?: "No key"
                textSize = 14f
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 2f)
            }

            val actions = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            }

            val loginBtn = Button(this).apply {
                text = "Login"
                setOnClickListener { openUrl(url) }
            }

            val copyBtn = Button(this).apply {
                text = "Copy"
                setOnClickListener {
                    if (key != null) {
                        copyToClipboard(key)
                        Toast.makeText(this@MainActivity, "Key copied", Toast.LENGTH_SHORT).show()
                    } else {
                        Toast.makeText(this@MainActivity, "No key saved", Toast.LENGTH_SHORT).show()
                    }
                }
            }

            actions.addView(loginBtn)
            actions.addView(copyBtn)

            row.addView(providerText)
            row.addView(keyText)
            row.addView(actions)
            keysContainer.addView(row)
        }
    }

    private fun showAddKeyDialog() {
        val providersList = providers.keys.toTypedArray()
        val builder = android.app.AlertDialog.Builder(this)
        builder.setTitle("Select Provider")
        builder.setItems(providersList) { _, which ->
            val provider = providersList[which]
            showSaveKeyDialog(provider)
        }
        builder.show()
    }

    private fun showSaveKeyDialog(provider: String) {
        val input = TextView(this)
        input.hint = "Paste API key for $provider"
        input.setPadding(50, 50, 50, 50)

        val builder = android.app.AlertDialog.Builder(this)
        builder.setTitle("Save $provider key")
        builder.setView(input)
        builder.setPositiveButton("Save") { _, _ ->
            val key = input.text.toString().trim()
            if (key.isNotEmpty()) {
                prefs.edit().putString(provider, key).apply()
                renderKeys()
                Toast.makeText(this, "Key saved", Toast.LENGTH_SHORT).show()
            }
        }
        builder.setNegativeButton("Cancel", null)
        builder.show()
    }

    private fun copyToClipboard(text: String) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("API Key", text)
        clipboard.setPrimaryClip(clip)
    }

    private fun openUrl(url: String) {
        val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url))
        startActivity(intent)
    }
}
