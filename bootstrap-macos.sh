#!/usr/bin/env bash
# Claude Code + DeepSeek developer bootstrap for macOS 13+
# Run: chmod +x bootstrap-macos.sh && ./bootstrap-macos.sh
set -Eeuo pipefail

INSTALL_VSCODE="${INSTALL_VSCODE:-1}"   # set to 0 to skip VS Code
NVM_VERSION="${NVM_VERSION:-v0.40.4}"

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
ensure_line() {
  local file="$1" line="$2"
  touch "$file"
  grep -qxF "$line" "$file" 2>/dev/null || printf '\n%s\n' "$line" >> "$file"
}

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This script is for macOS." >&2
  exit 1
fi

say "Checking Apple Command Line Tools"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  echo "macOS has opened the Command Line Tools installer. Complete it, then run this script again." >&2
  exit 1
fi

say "Installing Homebrew if needed"
if ! command -v brew >/dev/null 2>&1; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$( /usr/local/bin/brew shellenv )"
fi

say "Installing common developer tools"
brew update
brew install git ripgrep sqlite jq
if [[ "$INSTALL_VSCODE" == "1" ]]; then
  brew install --cask visual-studio-code
fi

say "Configuring shell PATH"
ensure_line "$HOME/.zshrc" 'export PATH="$HOME/.local/bin:$PATH"'
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
ensure_line "$HOME/.zshrc" 'export NVM_DIR="$HOME/.nvm"'
ensure_line "$HOME/.zshrc" '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"'
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
  try { settings = JSON.parse(fs.readFileSync(file, 'utf8')); }
  catch {
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

CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
if [[ -x "$CODE_BIN" ]]; then
  ensure_line "$HOME/.zprofile" 'export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"'
  "$CODE_BIN" --install-extension anthropic.claude-code --force || true
  "$CODE_BIN" --install-extension ms-python.python --force || true
fi

say "Verification"
printf 'Claude Code: '; claude --version
printf 'uv: '; uv --version
printf 'Node: '; node --version
printf 'npm: '; npm --version
printf 'Git: '; git --version
printf '\nDone. Open a new terminal, then start a project with:\n  mkdir -p ~/projects/my-project && cd ~/projects/my-project && claude\n'
printf 'Optional DeepSeek smoke test (uses a small amount of API quota):\n  claude -p "只回复：DeepSeek API 已接通。"\n'
