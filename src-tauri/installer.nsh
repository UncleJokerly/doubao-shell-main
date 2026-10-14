; NSIS 安装钩子。必须在 tauri.conf.json 里用 bundle.windows.nsis.installerHooks 显式指向本文件，
; Tauri 2 才会把它编进安装包 —— 只把文件放在 src-tauri/ 下是不生效的。
;
; 宏名也是 Tauri 2 的新写法：NSIS_HOOK_PREINSTALL / NSIS_HOOK_POSTINSTALL /
; NSIS_HOOK_PREUNINSTALL / NSIS_HOOK_POSTUNINSTALL。
; Tauri 1 的 customInstall / customUnInstall 在 2.x 模板里已经不存在，
; 上游 deepseek-shell 的 installer.nsh 就是栽在这里（加上没配 installerHooks），
; 所以那份 autostart.flag 从来没被写出来过。
;
; 这里只做一件事：安装完成后在安装目录留一个一次性标志文件，
; 应用首次启动时由 src-tauri/src/lib.rs 的 apply_installer_autostart_flag() 消费并删除。
; 卸载不需要额外处理：Tauri 模板的卸载段本身就会
;   DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "${PRODUCTNAME}"
; 正好对应 tauri-plugin-autostart 写入的值名。
!macro NSIS_HOOK_POSTINSTALL
  FileOpen $9 "$INSTDIR\autostart.flag" w
  FileClose $9
!macroend
