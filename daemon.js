const { clipboard } = require('clipboardy');
const fs = require('fs');
const path = require('path');

const KEYS_FILE = path.join(__dirname, 'keys.json');

function saveKey(key) {
    const keys = fs.existsSync(KEYS_FILE) ? JSON.parse(fs.readFileSync(KEYS_FILE, 'utf8')) : {};
    // Basic heuristic: check if key looks like a standard LLM key
    if (key.startsWith('gsk_') || key.startsWith('AIza')) {
        const provider = key.startsWith('gsk_') ? 'groq' : 'gemini';
        keys[provider] = key;
        fs.writeFileSync(KEYS_FILE, JSON.stringify(keys, null, 2));
        console.log(`Saved ${provider} key automatically.`);
    }
}

let lastContent = '';

console.log('Daemon running. Copy an API key and it will be saved.');

setInterval(() => {
    try {
        const content = clipboard.readSync().trim();
        if (content !== lastContent && content.length > 20) {
            lastContent = content;
            console.log('Detected potential key, checking...');
            saveKey(content);
        }
    } catch (e) {}
}, 2000);
