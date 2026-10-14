# 生成 doubao-shell 的应用图标（1024x1024 PNG，透明背景 + 圆角渐变方块 + 白色对话气泡）。
# 不依赖任何外部资源，产出后交给 `npm run tauri icon assets/icon-source.png` 切成各平台尺寸。
#
# 用法：powershell -ExecutionPolicy Bypass -File assets/make-icon.ps1
#
# 之所以不用 AI 生图：生成图右下角带水印，缩到 16x16 托盘图标后很脏。

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Size = 1024
$Out = Join-Path $PSScriptRoot 'icon-source.png'

function New-RoundedPath([double]$X, [double]$Y, [double]$W, [double]$H, [double]$R) {
    $d = $R * 2
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc($X, $Y, $d, $d, 180, 90)               # 左上
    $p.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)     # 右上
    $p.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)  # 右下
    $p.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)      # 左下
    $p.CloseFigure()
    return $p
}

$Bmp = New-Object System.Drawing.Bitmap($Size, $Size)
$G = [System.Drawing.Graphics]::FromImage($Bmp)
$G.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$G.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$G.Clear([System.Drawing.Color]::Transparent)

# 1) 蓝→青渐变圆角底
$Rect = New-Object System.Drawing.RectangleF(0, 0, $Size, $Size)
$Brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $Rect,
    [System.Drawing.Color]::FromArgb(255, 43, 107, 255),
    [System.Drawing.Color]::FromArgb(255, 23, 195, 230),
    [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)
$Base = New-RoundedPath 0 0 $Size $Size 232
$G.FillPath($Brush, $Base)

# 2) 气泡投影，让白色气泡在渐变上有一点浮起感
$Shadow = New-RoundedPath 262 322 500 320 92
$ShadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(46, 0, 30, 70))
$G.FillPath($ShadowBrush, $Shadow)

# 3) 白色对话气泡 + 左下尾巴
$Bubble = New-RoundedPath 250 300 500 320 92
$White = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$G.FillPath($White, $Bubble)

$Tail = @(
    (New-Object System.Drawing.PointF(352, 600)),
    (New-Object System.Drawing.PointF(352, 736)),
    (New-Object System.Drawing.PointF(486, 600))
)
$G.FillPolygon($White, [System.Drawing.PointF[]]$Tail)

$G.Dispose()
$Bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$Bmp.Dispose()

Write-Host "icon written: $Out"
