# 验证 doubao-shell 的窗口显隐状态：列出进程所有带标题或可见的顶层窗口。
# 用法：powershell -ExecutionPolicy Bypass -File scripts/verify-window.ps1
#
# 注意不要直接用 Get-Process 的 MainWindowHandle —— 主窗口隐藏后它会改指到进程里
# 另一个顶层窗口，看起来像“还可见”，实际是换了句柄。

Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class WinEnum {
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr h);

  public delegate bool EnumProc(IntPtr h, IntPtr l);

  public static List<string> Scan(uint target) {
    List<string> hits = new List<string>();
    EnumProc proc = delegate(IntPtr h, IntPtr l) {
      uint pid;
      GetWindowThreadProcessId(h, out pid);
      if (pid == target) {
        StringBuilder sb = new StringBuilder(256);
        GetWindowText(h, sb, 256);
        if (GetWindowTextLength(h) > 0 || IsWindowVisible(h)) {
          hits.Add(string.Format("hwnd={0} visible={1} title=[{2}]", h, IsWindowVisible(h), sb));
        }
      }
      return true;
    };
    EnumWindows(proc, IntPtr.Zero);
    return hits;
  }
}
"@

$procs = Get-Process doubao-shell -ErrorAction SilentlyContinue
if (-not $procs) {
  Write-Output "NO_PROCESS"
  exit
}
foreach ($p in $procs) {
  Write-Output ("pid=" + $p.Id)
  foreach ($line in [WinEnum]::Scan([uint32]$p.Id)) {
    Write-Output ("  " + $line)
  }
}
