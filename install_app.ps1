$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$icon = Join-Path $root "assets\sm-marshrut.ico"
$launcher = Join-Path $root "launch_app.vbs"
$wscript = Join-Path $env:SystemRoot "System32\wscript.exe"

if (-not (Test-Path $icon)) {
    throw "Не найдена иконка $icon"
}
if (-not (Test-Path $launcher)) {
    throw "Не найден запускатель $launcher"
}

$desktop = [Environment]::GetFolderPath("Desktop")
$programs = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$targets = @(
    (Join-Path $desktop "СМ-маршрут.lnk"),
    (Join-Path $programs "СМ-маршрут.lnk")
)

$shell = New-Object -ComObject WScript.Shell
foreach ($path in $targets) {
    $shortcut = $shell.CreateShortcut($path)
    $shortcut.TargetPath = $wscript
    $shortcut.Arguments = "//B `"$launcher`""
    $shortcut.WorkingDirectory = $root
    $shortcut.IconLocation = $icon
    $shortcut.Description = "СМ-маршрут"
    $shortcut.WindowStyle = 7
    $shortcut.Save()
    Write-Output $path
}
