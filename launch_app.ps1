$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
Set-Location $root
$url = "http://127.0.0.1:8000/"

function Show-Error([string]$Text) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        $Text,
        "СМ-маршрут",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}

function Test-ServerUp {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $wait = $client.BeginConnect("127.0.0.1", 8000, $null, $null)
        $ok = $wait.AsyncWaitHandle.WaitOne(400, $false)
        if (-not $ok) {
            return $false
        }
        $client.EndConnect($wait)
        return $true
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

function Start-AppWindow {
    Start-Process $url
}

if (-not (Test-ServerUp)) {
    $python = Join-Path $root ".venv\Scripts\python.exe"
    if (-not (Test-Path $python)) {
        Show-Error "Не найден интерпретатор $python. Сначала создайте виртуальное окружение проекта."
        exit 1
    }
    $starter = Join-Path $root "start_server.ps1"
    Start-Process -FilePath "powershell.exe" -ArgumentList @(
        "-NoProfile", "-WindowStyle", "Hidden", "-ExecutionPolicy", "Bypass", "-File", $starter
    ) -WindowStyle Hidden | Out-Null

    $deadline = (Get-Date).AddSeconds(30)
    while (-not (Test-ServerUp)) {
        if ((Get-Date) -gt $deadline) {
            Show-Error "Сервер не ответил. Подробности в файле logs\server.log."
            exit 1
        }
        Start-Sleep -Milliseconds 400
    }
}

Start-AppWindow
