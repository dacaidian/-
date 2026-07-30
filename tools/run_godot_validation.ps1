[CmdletBinding()]
param(
    [string]$ScriptPath = "",
    [string]$SuccessMarker = "",
    [int]$TimeoutSeconds = 120,
    [string]$LogFile = "",
    [switch]$ImportAssets
)

$ErrorActionPreference = "Stop"

if ($TimeoutSeconds -le 0) {
    throw "TimeoutSeconds must be greater than zero."
}
if ($ImportAssets -and -not [string]::IsNullOrWhiteSpace($ScriptPath)) {
    throw "ImportAssets and ScriptPath cannot be used together."
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotOverride = [Environment]::GetEnvironmentVariable("GODOT_BIN")
if ([string]::IsNullOrWhiteSpace($godotOverride)) {
    $godotCommand = Get-Command godot -ErrorAction Stop
    $godotPath = $godotCommand.Source
} else {
    $godotPath = (Resolve-Path $godotOverride).Path
}

if ([string]::IsNullOrWhiteSpace($LogFile)) {
    $logName = if ($ImportAssets) {
        "safe_asset_import.log"
    } elseif ([string]::IsNullOrWhiteSpace($ScriptPath)) {
        "safe_project_check.log"
    } else {
        "safe_$([IO.Path]::GetFileNameWithoutExtension($ScriptPath)).log"
    }
    $LogFile = Join-Path $projectRoot ".godot\$logName"
} elseif (-not [IO.Path]::IsPathRooted($LogFile)) {
    $LogFile = Join-Path $projectRoot $LogFile
}

$logDirectory = Split-Path -Parent $LogFile
if (-not (Test-Path -LiteralPath $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
}
if (Test-Path -LiteralPath $LogFile) {
    Remove-Item -LiteralPath $LogFile -Force
}

$godotArguments = @(
    "--headless",
    "--path", $projectRoot,
    "--log-file", $LogFile
)
if ($ImportAssets) {
    $godotArguments += @("--import")
} elseif ([string]::IsNullOrWhiteSpace($ScriptPath)) {
    # Project-mode --check-only does not terminate reliably on Windows.
    $godotArguments += @("--quit-after", "1")
} else {
    $godotArguments += @("--script", $ScriptPath)
}

$existingGodotIds = @(
    Get-Process -Name godot -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Id }
)
$launchedProcess = $null
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
$stableExitPolls = 0

function Get-NewGodotProcesses {
    return @(
        Get-Process -Name godot -ErrorAction SilentlyContinue |
            Where-Object { $existingGodotIds -notcontains $_.Id }
    )
}

function Stop-NewGodotProcesses {
    Get-NewGodotProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
}

try {
    $launchedProcess = Start-Process `
        -FilePath $godotPath `
        -ArgumentList $godotArguments `
        -WorkingDirectory $projectRoot `
        -NoNewWindow `
        -PassThru

    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $newGodotProcesses = Get-NewGodotProcesses
        if ($launchedProcess.HasExited -and $newGodotProcesses.Count -eq 0) {
            $stableExitPolls += 1
            if ($stableExitPolls -ge 3) {
                break
            }
        } else {
            $stableExitPolls = 0
        }
        Start-Sleep -Milliseconds 100
    }

    if (-not $launchedProcess.HasExited -or (Get-NewGodotProcesses).Count -gt 0) {
        Stop-NewGodotProcesses
        throw "Godot validation timed out after $TimeoutSeconds seconds; processes from this run were stopped."
    }
} catch {
    Stop-NewGodotProcesses
    throw
} finally {
    $stopwatch.Stop()
}

if (-not (Test-Path -LiteralPath $LogFile)) {
    throw "Godot exited without creating the expected log: $LogFile"
}

$fatalLogLines = @(
    Select-String -Path $LogFile -Pattern @(
        "SCRIPT ERROR:",
        "Parse Error:",
        "Failed loading resource:",
        "Can't load script:",
        "Assertion failed"
    ) -SimpleMatch
)
if ($fatalLogLines.Count -gt 0) {
    $details = ($fatalLogLines | ForEach-Object { $_.Line }) -join [Environment]::NewLine
    throw "Godot validation reported fatal errors:$([Environment]::NewLine)$details"
}

if (-not [string]::IsNullOrWhiteSpace($SuccessMarker)) {
    $markerMatch = Select-String -Path $LogFile -Pattern $SuccessMarker -SimpleMatch
    if ($null -eq $markerMatch) {
        throw "Godot validation did not emit success marker '$SuccessMarker'."
    }
}

$elapsedSeconds = [math]::Round($stopwatch.Elapsed.TotalSeconds, 2)
Write-Output "Godot validation passed in ${elapsedSeconds}s."
Write-Output "Log: $LogFile"
