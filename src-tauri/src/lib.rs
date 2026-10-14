// 豆包桌面壳的全部运行时逻辑都在这里：托盘、Alt+D 全局快捷键、关窗收托盘、开机自启。
use tauri::menu::MenuBuilder;
use tauri::tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent};
use tauri::{AppHandle, Manager, WindowEvent};
use tauri_plugin_autostart::ManagerExt;
use tauri_plugin_global_shortcut::{Code, Modifiers, ShortcutState};

/// 安装包（NSIS）在安装目录留下的一次性标志文件。
/// 存在即代表“用户安装时同意开机自启”，应用首启消费它后删除。
const AUTOSTART_FLAG: &str = "autostart.flag";

/// 快捷键与托盘菜单文案的唯一来源，改键只改这两行。
const SHORTCUT: &str = "alt+d";
const SHORTCUT_LABEL: &str = "Alt+D";

fn is_autostart_enabled(app: &AppHandle) -> bool {
    app.autolaunch().is_enabled().unwrap_or(false)
}

/// 首启时消费安装包的 autostart.flag：开自启，然后删掉标志文件，
/// 这样用户之后在托盘菜单里的选择不会被反复覆盖。
fn apply_installer_autostart_flag(app: &AppHandle) {
    let Ok(exe_path) = std::env::current_exe() else {
        return;
    };
    let Some(install_dir) = exe_path.parent() else {
        return;
    };
    let flag = install_dir.join(AUTOSTART_FLAG);
    if flag.is_file() {
        let _ = app.autolaunch().enable();
        let _ = std::fs::remove_file(&flag);
    }
}

/// 托盘菜单内容随自启状态变化，切换后要整体重建。
fn build_tray_menu(app: &AppHandle) -> tauri::Result<tauri::menu::Menu<tauri::Wry>> {
    let autostart_text = if is_autostart_enabled(app) {
        "取消开机自启"
    } else {
        "开机自启"
    };

    MenuBuilder::new(app)
        .text("show", format!("主窗口（{SHORTCUT_LABEL}）"))
        .text("autostart", autostart_text)
        .text("quit", "退出")
        .build()
}

fn refresh_tray_menu(app: &AppHandle) {
    if let Ok(menu) = build_tray_menu(app) {
        if let Some(tray) = app.tray_by_id("tray") {
            let _ = tray.set_menu(Some(menu));
        }
    }
}

/// 显示并聚焦主窗口，或已可见时收起。
fn toggle_main_window(app: &AppHandle) {
    let Some(window) = app.get_webview_window("main") else {
        return;
    };
    if matches!(window.is_visible(), Ok(true)) {
        let _ = window.hide();
    } else {
        let _ = window.show();
        let _ = window.set_focus();
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_autostart::init(
            tauri_plugin_autostart::MacosLauncher::LaunchAgent,
            None,
        ))
        .setup(|app| {
            let handle = app.handle().clone();

            apply_installer_autostart_flag(&handle);

            let tray = TrayIconBuilder::with_id("tray")
                .icon(app.default_window_icon().unwrap().clone())
                .tooltip(format!("豆包 · {SHORTCUT_LABEL} 唤出"))
                .menu(&build_tray_menu(&handle)?)
                .on_menu_event(move |app, event| match event.id().0.as_str() {
                    "show" => {
                        if let Some(window) = app.get_webview_window("main") {
                            let _ = window.show();
                            let _ = window.set_focus();
                        }
                    }
                    "autostart" => {
                        if is_autostart_enabled(app) {
                            let _ = app.autolaunch().disable();
                        } else {
                            let _ = app.autolaunch().enable();
                        }
                        refresh_tray_menu(app);
                    }
                    "quit" => {
                        app.exit(0);
                    }
                    _ => {}
                })
                .on_tray_icon_event(|tray, event| {
                    if let TrayIconEvent::Click {
                        button: MouseButton::Left,
                        button_state: MouseButtonState::Up,
                        ..
                    } = event
                    {
                        toggle_main_window(tray.app_handle());
                    }
                })
                .build(app)?;

            // 不显示任务栏按钮之外的重复图标：Windows 上保持默认即可。
            let _ = tray;

            if let Some(window) = app.get_webview_window("main") {
                let _ = window.center();
            }

            // 全局快捷键：alt+d 唤起 / 收起小窗
            app.handle().plugin(
                tauri_plugin_global_shortcut::Builder::new()
                    .with_shortcuts([SHORTCUT])?
                    .with_handler(|app, shortcut, event| {
                        if event.state == ShortcutState::Pressed
                            && shortcut.matches(Modifiers::ALT, Code::KeyD)
                        {
                            toggle_main_window(app);
                        }
                    })
                    .build(),
            )?;

            Ok(())
        })
        .on_window_event(|window, event| {
            // 点关闭只收进托盘，不退出进程
            if let WindowEvent::CloseRequested { api, .. } = event {
                let _ = window.hide();
                api.prevent_close();
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running doubao-shell");
}
