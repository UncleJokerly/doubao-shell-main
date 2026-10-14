# doubao-shell 二进制分发分支

这个孤儿分支只存放编译产物，方便在访问 GitHub Releases 不便的网络下直接下载。源码在 `main` 分支。

| 文件 | 大小 | Gitee 直链 |
| --- | --- | --- |
| `doubao-shell_0.1.0_x64-setup.exe` | 1.13 MiB | https://gitee.com/UncleJokerly/doubao-shell-main/raw/binaries/doubao-shell_0.1.0_x64-setup.exe |
| `doubao-shell_0.1.0_windows_x64_portable.zip` | 1.36 MiB | https://gitee.com/UncleJokerly/doubao-shell-main/raw/binaries/doubao-shell_0.1.0_windows_x64_portable.zip |

安装包为 NSIS 安装程序，装到 `%LOCALAPPDATA%\doubao-shell`，免管理员权限；绿色版解压即用。两者都要求系统已装 WebView2 Runtime（Win10/11 随 Edge 自带）。未做代码签名，首次运行 SmartScreen 可能弹警告。
