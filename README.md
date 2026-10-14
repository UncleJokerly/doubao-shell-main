# 豆包桌面壳（doubao-shell）

极简、极小体积（安装包约 8MB）的豆包（Doubao）桌面端。基于 [Tauri 2](https://tauri.app/) + Rust，不内置浏览器内核，直接调用系统 WebView2，安装后按 **Alt+D** 随时唤出 / 收起小窗，关窗自动收进系统托盘。

派生自 [deepseek-shell](https://github.com/benhack20/deepseek-shell)，本项目做了三处改动：加载豆包而非 DeepSeek、快捷键由 `Alt+Space` 改为 `Alt+D`、修掉了原版遗留的开机自启半成品逻辑（详见下文）。

## 下载

最新版本见 [GitHub Releases](https://github.com/UncleJokerly/doubao-shell-main/releases/tag/v0.1.0)：

| 文件 | 说明 |
| --- | --- |
| [`doubao-shell_0.1.0_x64-setup.exe`](https://github.com/UncleJokerly/doubao-shell-main/releases/download/v0.1.0/doubao-shell_0.1.0_x64-setup.exe) | NSIS 安装包，1.13 MiB，装到 `%LOCALAPPDATA%\doubao-shell`，免管理员权限 |
| [`doubao-shell_0.1.0_windows_x64_portable.zip`](https://github.com/UncleJokerly/doubao-shell-main/releases/download/v0.1.0/doubao-shell_0.1.0_windows_x64_portable.zip) | 免安装绿色版，1.36 MiB，解压即用 |

两者都要求系统装有 WebView2 Runtime（Win10/11 随 Edge 自带）。未做代码签名，首次运行 SmartScreen 可能弹警告，点「仍要运行」即可。

访问 GitHub Releases 不便时，走 Gitee 的 `binaries` 孤儿分支直链（与 Release 附件同一文件，MD5 `0cfc59ca...`）：

- 安装包：<https://gitee.com/UncleJokerly/doubao-shell-main/raw/binaries/doubao-shell_0.1.0_x64-setup.exe>
- 绿色版：<https://gitee.com/UncleJokerly/doubao-shell-main/raw/binaries/doubao-shell_0.1.0_windows_x64_portable.zip>

## 与原版 deepseek-shell 的差异

| 项目 | deepseek-shell | doubao-shell |
| --- | --- | --- |
| 加载地址 | `https://chat.deepseek.com/` | `https://www.doubao.com/` |
| 唤出快捷键 | `Alt+Space` | `Alt+D` |
| bundle 标识 | `com.lenovo.deepseek-shell` | `com.doubao.shell`（两者可共存，互不覆盖） |
| 窗口 | 400×700 | 420×720，最小 340×480，居中 |
| 开机自启 | `installer.nsh` 里写 `customInstall` 生成 `autostart.flag`，但无人读取；JS 里读取的代码是死代码（`frontendDist` 指向远端，本地 `src/` 根本不参与打包） | 安装写入 `autostart.flag` → Rust 首启读取并调用 `tauri-plugin-autostart` 写注册表 → 删除标志文件 |
| NSIS 安装页 | 用 `Page custom` + nsDialogs 画勾选框（`customInstall` 宏位于 `Section` 内，`Page` 指令在此处非法，实际不生效） | 去掉自定义页面，改为“安装即默认开启自启”，之后在托盘菜单随时取消 |

> **Tauri 2 的 NSIS 钩子和 1.x 不一样**，这里是上游那份 `installer.nsh` 完全失效的真正原因，两处都要改对：
>
> 1. 宏名：`customInstall` / `customUnInstall` 在 2.x 模板里已经不存在，改用 `NSIS_HOOK_PREINSTALL` / `NSIS_HOOK_POSTINSTALL` / `NSIS_HOOK_PREUNINSTALL` / `NSIS_HOOK_POSTUNINSTALL`。
> 2. 引入方式：把 `installer.nsh` 放在 `src-tauri/` 下**不会**被自动包含，必须配 `bundle.windows.nsis.installerHooks`。
>
> 判别办法：打包后看 `src-tauri/target/release/nsis/x64/installer.nsi` 里有没有 `!include "...installer.nsh"` 这一行。卸载不需要自己清自启项，Tauri 模板的卸载段已经会 `DeleteRegValue HKCU ...\Run "${PRODUCTNAME}"`。

## 功能

- **Alt+D 全局快捷键**：任何应用里按下即可唤出/收起豆包小窗。
- **托盘常驻**：关闭窗口只是隐藏，进程继续留在托盘；左键单击托盘图标同样切换显示。
- **托盘菜单**：主窗口（Alt+D）、开机自启 / 取消开机自启（文案随状态变化）、退出。
- **极小体积**：安装包约 8MB，内存占用远低于 Electron 方案。

## 环境要求

构建端需要三样，缺一不可：

1. **Node.js**（本机 v24.19 已具备）
2. **Rust 工具链**，必须是 `x86_64-pc-windows-msvc`（GNU 工具链不被 Tauri 官方支持，托盘与 WebView2 容易出问题）
   ```powershell
   winget install Rustlang.Rustup
   # 或
   rustup default stable-x86_64-pc-windows-msvc
   ```
3. **Visual Studio Build Tools**，勾选「使用 C++ 的桌面开发」工作流（提供 `link.exe` 与 Windows SDK）
   ```powershell
   winget install Microsoft.VisualStudio.2022.BuildTools --override "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
   ```

运行端只需要 **WebView2 Runtime**（Windows 10/11 一般随 Edge 自带）。

## 开发与打包

```bash
npm install              # 装 @tauri-apps/cli 等依赖
npm run tauri dev        # 开发模式，直接打开豆包网页，Rust 改动会热编译
npm run build:exe        # = tauri build -- --bundles nsis，只出 Windows 安装包
```

`npm run build:exe` 的产物：

```
src-tauri/target/release/bundle/nsis/doubao-shell_0.1.0_x64-setup.exe   ← 安装包
src-tauri/target/release/doubao-shell.exe                                ← 免安装绿色版
```

首次构建要编译 400 多个 Rust crate，5～15 分钟属正常，不是卡死。国内网络建议给 cargo 换镜像：

```toml
# %USERPROFILE%\.cargo\config.toml
[source.crates-io]
replace-with = "rsproxy-sparse"

[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
```

## 图标

`src-tauri/icons/` 下的 `icon.ico` 等由下面命令从 `assets/icon-source.png` 一键生成，换图标只需替换源图后重跑：

```bash
npm run tauri icon assets/icon-source.png
```

## 本机安装结果

安装包 1.13 MiB（`opt-level = "s"` + `strip` + 不打包本地前端，比上游的 8MB 更小），`installMode` 用默认的 `currentUser`，无需管理员：

```
安装目录  C:\Users\Administrator\AppData\Local\doubao-shell\doubao-shell.exe
开始菜单  %APPDATA%\Microsoft\Windows\Start Menu\Programs\doubao-shell.lnk
自启项    HKCU\Software\Microsoft\Windows\CurrentVersion\Run  doubao-shell
```

静默安装/卸载（**不要在 Git Bash 里直接传 `/S`**，MSYS 会把它当路径改写，结果弹出图形安装界面像卡死）：

```powershell
Start-Process -FilePath "$env:LOCALAPPDATA\doubao-shell\uninstall.exe" -ArgumentList "/S" -Wait
Start-Process -FilePath "<bundle>\doubao-shell_0.1.0_x64-setup.exe" -ArgumentList "/S" -Wait
```

已实测通过：窗口正常渲染豆包对话页；前台是别的程序时按 `Alt+D` 能把窗口收起、再按唤回（同一 HWND 的 `IsWindowVisible` False→True）；关窗后进程常驻；`autostart.flag` 安装时生成、首启后被消费删除且注册表自启项写入。可用 `scripts/verify-window.ps1` 复查窗口状态——注意别用 `Get-Process.MainWindowHandle` 判断显隐，主窗口隐藏后它会改指到进程里另一个顶层窗口。

## 快捷键说明

`Alt+D` 是全局热键，会**抢占**该组合：热键生效期间，浏览器/资源管理器里 `Alt+D` 不再定位到地址栏。想换键只改 `src-tauri/src/lib.rs` 顶部的两个常量：

```rust
const SHORTCUT: &str = "alt+d";
const SHORTCUT_LABEL: &str = "Alt+D";
```

## 说明与限制

- 这是豆包网页版的**外壳**，账号、会话、模型能力全部由 `www.doubao.com` 提供；离线或豆包改版会直接影响显示。
- 未配置代码签名，首次运行 Windows SmartScreen 可能弹警告，点「仍要运行」即可。
- 未引入 single-instance 插件，重复启动会出现两个托盘图标；需要时加 `tauri-plugin-single-instance` 即可。
