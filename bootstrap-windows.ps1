# Claude Code + DeepSeek developer bootstrap for native Windows 10 1809+ / Windows 11
# Run in PowerShell:
# Set-ExecutionPolicy -Scope Process Bypass -Force; .\bootstrap-windows.ps1
$ErrorActionPreference = 'Stop'

function Say($Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Refresh-Path {
  $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user = [Environment]::GetEnvironmentVariable('Path', 'User')
  $env:Path = "$machine;$user"
}
function Install-WingetPackage([string]$Id) {
  Say "Installing $Id"
  winget install --id $Id -e --accept-package-agreements --accept-source-agreements --silent
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  throw "WinGet is required. Update/install App Installer from Microsoft Store, then rerun this script."
}

Install-WingetPackage 'Git.Git'
Install-WingetPackage 'Microsoft.VisualStudioCode'
Install-WingetPackage 'OpenJS.NodeJS.LTS'
Install-WingetPackage 'astral-sh.uv'
Install-WingetPackage 'BurntSushi.ripgrep.MSVC'
Install-WingetPackage 'SQLite.SQLite'
Refresh-Path

Say 'Installing Claude Code (stable channel)'
& ([scriptblock]::Create((irm https://claude.ai/install.ps1))) stable
$localBin = Join-Path $env:USERPROFILE '.local\bin'
if (Test-Path $localBin) { $env:Path = "$localBin;$env:Path" }

Say 'Configuring DeepSeek for Claude Code'
$secureKey = Read-Host 'Paste your DeepSeek API key (hidden)' -AsSecureString
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
try { $plainKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
if ([string]::IsNullOrWhiteSpace($plainKey)) { throw 'No API key entered; stopping before creating configuration.' }

$configDir = Join-Path $env:USERPROFILE '.claude'
$settingsPath = Join-Path $configDir 'settings.json'
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
$settings = $null
if (Test-Path $settingsPath) {
  try { $settings = Get-Content -Raw -Path $settingsPath | ConvertFrom-Json }
  catch {
    $backup = "$settingsPath.invalid-$([DateTimeOffset]::Now.ToUnixTimeSeconds()).bak"
    Copy-Item $settingsPath $backup
    Write-Warning "Existing invalid settings backed up to: $backup"
  }
}
if ($null -eq $settings) { $settings = [PSCustomObject]@{} }
if ($null -eq $settings.PSObject.Properties['env']) {
  $settings | Add-Member -MemberType NoteProperty -Name env -Value ([PSCustomObject]@{})
}
$deepSeekEnv = [ordered]@{
  ANTHROPIC_BASE_URL = 'https://api.deepseek.com/anthropic'
  ANTHROPIC_AUTH_TOKEN = $plainKey
  ANTHROPIC_MODEL = 'deepseek-v4-pro'
  ANTHROPIC_DEFAULT_OPUS_MODEL = 'deepseek-v4-pro'
  ANTHROPIC_DEFAULT_SONNET_MODEL = 'deepseek-v4-pro'
  ANTHROPIC_DEFAULT_HAIKU_MODEL = 'deepseek-v4-flash'
  CLAUDE_CODE_SUBAGENT_MODEL = 'deepseek-v4-flash'
  CLAUDE_CODE_EFFORT_LEVEL = 'max'
}
foreach ($item in $deepSeekEnv.GetEnumerator()) {
  if ($settings.env.PSObject.Properties[$item.Key]) { $settings.env.$($item.Key) = $item.Value }
  else { $settings.env | Add-Member -MemberType NoteProperty -Name $item.Key -Value $item.Value }
}
$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
$plainKey = $null

New-Item -ItemType Directory -Force -Path (Join-Path $env:USERPROFILE 'Projects') | Out-Null

$codeCandidates = @(
  "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
  "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
)
$codeBin = $codeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($codeBin) {
  Say 'Installing VS Code extensions'
  & $codeBin --install-extension anthropic.claude-code --force
  & $codeBin --install-extension ms-python.python --force
}

Say 'Verification'
$claudeExe = Join-Path $localBin 'claude.exe'
if (Test-Path $claudeExe) { & $claudeExe --version } else { claude --version }
uv --version
node --version
npm --version
git --version
Write-Host "`nDone. Start a project with:" -ForegroundColor Green
Write-Host "  mkdir $env:USERPROFILE\Projects\my-project; cd $env:USERPROFILE\Projects\my-project; claude"
Write-Host "Optional DeepSeek smoke test (uses a small amount of API quota):" -ForegroundColor Yellow
Write-Host '  claude -p "只回复：DeepSeek API 已接通。"'
