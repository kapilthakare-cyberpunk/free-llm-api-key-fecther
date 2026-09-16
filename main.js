const { app, BrowserWindow, clipboard, ipcMain } = require('electron');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const KEYS_FILE = path.join(__dirname, 'keys.json');

const providers = {
  groq: 'https://console.groq.com/keys',
  gemini: 'https://aistudio.google.com/app/apikey',
  deepseek: 'https://platform.deepseek.com/api_keys',
  openrouter: 'https://openrouter.ai/keys'
};

function loadKeys() {
  return fs.existsSync(KEYS_FILE) ? JSON.parse(fs.readFileSync(KEYS_FILE, 'utf8')) : {};
}

function createWindow() {
  const win = new BrowserWindow({
    width: 500, height: 600,
    webPreferences: { nodeIntegration: true, contextIsolation: false }
  });
  win.loadURL(`data:text/html,
    <html>
      <body style="font-family:sans-serif; padding:20px;">
        <h2>LLM Key Fetcher</h2>
        ${Object.keys(providers).map(p => `
          <div style="margin:10px 0; padding:10px; border:1px solid #ccc;">
            <strong>${p.toUpperCase()}</strong><br>
            <button onclick="fetch('${p}')">Login</button>
            <button onclick="copy('${p}')">Copy</button>
          </div>
        `).join('')}
        <script>
          const { ipcRenderer } = require('electron');
          function fetch(p) { ipcRenderer.send('fetch', p); }
          function copy(p) { ipcRenderer.send('copy', p); }
        </script>
      </body>
    </html>
  `);
}

ipcMain.on('fetch', (e, p) => exec(`open ${providers[p]}`));
ipcMain.on('copy', (e, p) => {
  const keys = loadKeys();
  if (keys[p]) clipboard.writeText(keys[p]);
});

app.whenReady().then(createWindow);
