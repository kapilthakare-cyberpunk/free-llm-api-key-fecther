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
  if (!fs.existsSync(KEYS_FILE)) return {};
  return JSON.parse(fs.readFileSync(KEYS_FILE, 'utf8'));
}

const args = process.argv.slice(2);

if (args[0] === '--list') {
  console.log('Available providers:', Object.keys(providers).join(', '));
} else if (args[0] === '--fetch' && providers[args[1]]) {
  console.log(`Opening ${args[1]}...`);
  exec(`open ${providers[args[1]]}`);
} else if (args[0] === '--save' && providers[args[1]] && args[2]) {
  const keys = loadKeys();
  keys[args[1]] = args[2];
  fs.writeFileSync(KEYS_FILE, JSON.stringify(keys, null, 2));
  console.log(`Key for ${args[1]} saved.`);
} else if (args[0] === '--get' && providers[args[1]]) {
  const keys = loadKeys();
  if (keys[args[1]]) {
    const proc = exec('pbcopy');
    proc.stdin.write(keys[args[1]]);
    proc.stdin.end();
    console.log(`Key for ${args[1]} copied to clipboard.`);
  } else {
    console.log('Key not found.');
  }
} else {
  console.log('Usage: node fetcher.js [--list|--fetch <provider>|--save <provider> <key>|--get <provider>]');
}
