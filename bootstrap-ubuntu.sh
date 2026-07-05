#!/usr/bin/env bash
# Claude Code + DeepSeek developer bootstrap for Ubuntu 20.04+
# Run: chmod +x bootstrap-ubuntu.sh && ./bootstrap-ubuntu.sh
set -Eeuo pipefail

INSTALL_VSCODE="${INSTALL_VSCODE:-1}"   # set to 0 to skip VS Code
NVM_VERSION="${NVM_VERSION:-v0.40.4}"

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ensure_line() {
  local file="$1" line="$2"
  touch "$file"
  grep -qxF "$line" "$file" 2>/dev/null || printf '\n%s\n' "$line" >> "$file"
}

if ! command -v apt >/dev/null 2>&1; then
  echo "This script is for Ubuntu/Debian systems with apt." >&2
  exit 1
fi

say "Requesting sudo once for system packages"
sudo -v

say "Installing system tools"
sudo apt update
sudo apt install -y \
  ca-certificates curl wget gpg git build-essential \
  python3 python3-venv python3-dev sqlite3 ripgrep \
  jq unzip zip

if [[ "$INSTALL_VSCODE" == "1" ]] && ! command -v code >/dev/null 2>&1; then
  say "Installing VS Code from Microsoft's apt repository"
  sudo install -d -m 0755 /etc/apt/keyrings
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/microsoft.gpg
  sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'REPO'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /etc/apt/keyrings/microsoft.gpg
REPO
  sudo apt update
  sudo apt install -y code
fi

say "Configuring user PATH"
ensure_line "$HOME/.bashrc" 'export PATH="$HOME/.local/bin:$PATH"'
export PATH="$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin" "$HOME/projects"

say "Installing uv"
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh \
    | env UV_INSTALL_DIR="$HOME/.local/bin" sh
fi
export PATH="$HOME/.local/bin:$PATH"

say "Installing nvm and the current Node.js LTS"
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi
ensure_line "$HOME/.bashrc" 'export NVM_DIR="$HOME/.nvm"'
ensure_line "$HOME/.bashrc" '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
# shellcheck disable=SC1090
. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts
nvm alias default "$(nvm version)"

say "Installing Claude Code (stable channel)"
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash -s stable
fi
export PATH="$HOME/.local/bin:$PATH"

say "Configuring DeepSeek for Claude Code"
read -r -s -p "Paste your DeepSeek API key (hidden): " DS_KEY
echo
if [[ -z "$DS_KEY" ]]; then
  echo "No API key entered; stopping before creating configuration." >&2
  exit 1
fi
export DS_KEY
node <<'NODE'
const fs = require('fs');
const path = require('path');
const os = require('os');
const dir = path.join(os.homedir(), '.claude');
const file = path.join(dir, 'settings.json');
fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
let settings = {};
if (fs.existsSync(file)) {
  try {
    settings = JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    const backup = `${file}.invalid-${Date.now()}.bak`;
    fs.copyFileSync(file, backup);
    console.error(`Existing invalid settings backed up to: ${backup}`);
  }
}
settings.env = {
  ...(settings.env || {}),
  ANTHROPIC_BASE_URL: 'https://api.deepseek.com/anthropic',
  ANTHROPIC_AUTH_TOKEN: process.env.DS_KEY,
  ANTHROPIC_MODEL: 'deepseek-v4-pro',
  ANTHROPIC_DEFAULT_OPUS_MODEL: 'deepseek-v4-pro',
  ANTHROPIC_DEFAULT_SONNET_MODEL: 'deepseek-v4-pro',
  ANTHROPIC_DEFAULT_HAIKU_MODEL: 'deepseek-v4-flash',
  CLAUDE_CODE_SUBAGENT_MODEL: 'deepseek-v4-flash',
  CLAUDE_CODE_EFFORT_LEVEL: 'max'
};
fs.writeFileSync(file, JSON.stringify(settings, null, 2) + '\n', { mode: 0o600 });
NODE
unset DS_KEY
chmod 600 "$HOME/.claude/settings.json"

if command -v code >/dev/null 2>&1; then
  say "Installing VS Code extensions"
  code --install-extension anthropic.claude-code --force || true
  code --install-extension ms-python.python --force || true
fi

say "Verification"
printf 'Claude Code: '; claude --version
printf 'uv: '; uv --version
printf 'Node: '; node --version
printf 'npm: '; npm --version
printf 'Git: '; git --version
printf '\nDone. Start a project with:\n  mkdir -p ~/projects/my-project && cd ~/projects/my-project && claude\n'
printf 'Optional DeepSeek smoke test (uses a small amount of API quota):\n  claude -p "只回复：DeepSeek API 已接通。"\n'
