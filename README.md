# Claude Code + DeepSeek 一键开发环境

三份脚本都会安装：Claude Code（stable 渠道）、DeepSeek 配置、uv、Node.js LTS、Git、ripgrep、SQLite CLI、VS Code、VS Code 的 Claude Code/Python 扩展，以及 `~/projects`（Windows 为 `%USERPROFILE%\Projects`）项目目录。

## 使用前

- 准备一个 DeepSeek API Key。脚本会隐藏输入，并写入当前用户的 `~/.claude/settings.json`（Windows: `%USERPROFILE%\.claude\settings.json`）。不要把该文件提交到 Git。
- Ubuntu/macOS 需要能输入当前管理员密码；Windows 需要 WinGet。
- 脚本不会安装 Docker、Java、PostgreSQL、Redis、项目业务依赖等；这些按项目单独安装。

## Ubuntu 20.04+

```bash
chmod +x bootstrap-ubuntu.sh
./bootstrap-ubuntu.sh
```

无需安装 VS Code 时：

```bash
INSTALL_VSCODE=0 ./bootstrap-ubuntu.sh
```

## macOS 13+

第一次运行若没有 Apple Command Line Tools，会出现系统安装窗口；安装完成后再次运行脚本即可。

```bash
chmod +x bootstrap-macos.sh
./bootstrap-macos.sh
```

## Windows 10 1809+ / Windows 11（原生 PowerShell）

在普通 PowerShell 中：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\bootstrap-windows.ps1
```

如 PowerShell 阻止脚本下载，请确认网络/企业策略允许访问官方安装源。

## 首个项目

```bash
mkdir -p ~/projects/my-project
cd ~/projects/my-project
claude
```

Windows PowerShell:

```powershell
mkdir $HOME\Projects\my-project
cd $HOME\Projects\my-project
claude
```

Python 项目：`uv init`、`uv add 包名`、`uv run main.py`。

## 安全与维护

- DeepSeek Key 以明文保存在当前用户的 Claude Code settings 文件中，以便 CLI 和 VS Code 扩展都能读取。不要共享该文件；泄露后立即去 DeepSeek 平台撤销并重建 Key。
- 运行 `claude -p "只回复：DeepSeek API 已接通。"` 会发起一次实际 API 请求并消耗少量额度。
- Windows 若追求最接近 Linux/macOS 的开发体验、或需要 Claude Code 沙盒能力，建议使用 WSL2 Ubuntu，然后运行 Ubuntu 脚本。
