$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
Set-Location $root

$logDir = Join-Path $root "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir "server.log"
$python = Join-Path $root ".venv\Scripts\python.exe"

$mutex = New-Object System.Threading.Mutex($false, "Local\SMMarshrutServer")
$owned = $false
try {
    $owned = $mutex.WaitOne(0)
} catch [System.Threading.AbandonedMutexException] {
    $owned = $true
}
if (-not $owned) {
    exit 0
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

try {
    while ($true) {
        if (Test-ServerUp) {
            Start-Sleep -Seconds 5
            continue
        }
        Add-Content -Path $log -Value ("{0} starting" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
        $command = 'cd /d "{0}" && "{1}" manage.py runserver 127.0.0.1:8000 --noreload >> "{2}" 2>&1' -f $root, $python, $log
        $proc = Start-Process -FilePath "cmd.exe" -ArgumentList @("/c", $command) -WorkingDirectory $root -WindowStyle Hidden -PassThru
        $proc.WaitForExit()
        Add-Content -Path $log -Value ("{0} stopped exit={1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $proc.ExitCode)
        Start-Sleep -Seconds 3
    }
} finally {
    $mutex.ReleaseMutex() | Out-Null
    $mutex.Dispose()
}
