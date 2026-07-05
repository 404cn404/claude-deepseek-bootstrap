# Claude Code + DeepSeek 一键开发环境

三份脚本都会安装 Claude Code、DeepSeek 配置、uv、Node.js LTS、Git、ripgrep、SQLite、VS Code 以及 Claude Code / Python 扩展。

新增：脚本会同时把 DeepSeek 环境变量写入桌面会话环境，因此 VS Code 图形界面打开 Claude Code 扩展时也会自动使用 DeepSeek。

## Windows CMD

```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/404cn404/claude-deepseek-bootstrap/main/bootstrap-windows.ps1' | iex"
```

首次部署后，注销并重新登录 Windows（或重启）一次，确保从开始菜单启动的 VS Code 也能读取环境变量。通过当前 CMD 执行 `code` 打开的 VS Code 则立即可用。

## Ubuntu

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/404cn404/claude-deepseek-bootstrap/main/bootstrap-ubuntu.sh)"
```

通过当前终端执行 `code` 打开的 VS Code 可立即使用 DeepSeek；从桌面图标打开时，注销并重新登录一次或重启即可。

## macOS

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/404cn404/claude-deepseek-bootstrap/main/bootstrap-macos.sh)"
```

脚本会生成用户级 LaunchAgent；关闭再打开 VS Code 后，Finder 启动的图形界面也会读取 DeepSeek 配置。

## 安全提醒

API Key 会保存在 `~/.claude/settings.json`，同时为图形界面持久化到系统用户环境（Windows 注册表用户环境、Ubuntu environment.d、macOS LaunchAgent）。不要把这些文件提交到 Git；如果 Key 泄露，请立即在 DeepSeek 平台撤销并重建。
