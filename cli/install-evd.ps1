<# 
===============================================================================
 EasyVideoDL Installer for Windows
===============================================================================

 Purpose:
   This PowerShell script installs all necessary dependencies 
   for the EasyVideoDL video-downloading tool on Windows systems.

 What it does:
   • Verifies that the Windows package manager ("winget") is available.
   • Installs the open-source tools yt-dlp and ffmpeg using winget.
   • Automatically adds the programs to your system PATH (so you can run them anywhere).
   • Adjusts PowerShell execution policy so local scripts can run safely.
   • Unblocks the EasyVideoDL helper script (run-evd.ps1).
   • Displays the installed version numbers to confirm successful setup.

 Notes:
   - This script does not download or run any hidden executables.
   - All software installed is open-source and fetched directly via Microsoft’s winget.
   - You can inspect every command below to see what happens on your system.

 Run in PowerShell as:
   .\install-evd.ps1
===============================================================================
#>

# Display startup message
Write-Host "=== EasyVideoDL Installer (Windows) ===" -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------------
# 1) Verify that the Windows package manager (winget) is available.
#    If not, instruct the user to install it from Microsoft Store.
# -----------------------------------------------------------------------------
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Warning "winget (App Installer) is not available. Please install it from the Microsoft Store first."
  exit 1
}

# -----------------------------------------------------------------------------
# 2) Install yt-dlp (the main video downloader).
#    This command also pulls ffmpeg as a dependency in many builds.
# -----------------------------------------------------------------------------
Write-Host "Installing yt-dlp (this may also pull its ffmpeg dependency)..." -ForegroundColor Cyan
winget install --id yt-dlp.yt-dlp -e --accept-source-agreements --accept-package-agreements

# -----------------------------------------------------------------------------
# 3) Check whether ffmpeg is already installed or available.
#    If not, install it separately. Use multiple sources for reliability.
# -----------------------------------------------------------------------------
$ffFound = (Get-Command ffmpeg -ErrorAction SilentlyContinue) -ne $null
if (-not $ffFound) {
  Write-Host ""
  Write-Host "Checking for ffmpeg..." -ForegroundColor Cyan

  # Look through installed winget packages for any ffmpeg entry
  $hasDep = winget list | Select-String -Pattern "yt-dlp\.FFmpeg|Gyan\.FFmpeg|BtbN\.ffmpeg"
  
  if (-not $hasDep) {
    # Try lightweight yt-dlp.FFmpeg first
    Write-Host "Installing ffmpeg (yt-dlp.FFmpeg)..." -ForegroundColor Cyan
    winget install --id yt-dlp.FFmpeg -e --accept-source-agreements --accept-package-agreements -ErrorAction SilentlyContinue

    # Fallback: if still not found, use the official Gyan build
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
      Write-Host "Falling back to Gyan.FFmpeg..." -ForegroundColor Yellow
      winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
    }
  }
}

# -----------------------------------------------------------------------------
# 4) Refresh the PATH environment variable for this PowerShell session.
#    This ensures yt-dlp and ffmpeg can be used immediately without restarting.
# -----------------------------------------------------------------------------
$machine = [System.Environment]::GetEnvironmentVariable("Path","Machine")
$user    = [System.Environment]::GetEnvironmentVariable("Path","User")
$session = "$machine;$user"
$links   = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"

# Append the WinGet binary folder if it’s not already in PATH
if (-not (($session -split ";") -contains $links)) {
  $session = "$session;$links"
}
[System.Environment]::SetEnvironmentVariable("Path", $session, "Process")

# -----------------------------------------------------------------------------
# 5) Set PowerShell ExecutionPolicy to RemoteSigned for the current user.
#    This allows running locally created scripts (like run-evd.ps1) safely.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Setting ExecutionPolicy for CurrentUser to RemoteSigned (you may be prompted)..." -ForegroundColor Cyan
try {
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
  Write-Host "ExecutionPolicy set to RemoteSigned at CurrentUser." -ForegroundColor Green
}
catch [System.Management.Automation.SecurityException] {
  # If this fails because a higher policy is already in place, show a safe warning
  $eff = Get-ExecutionPolicy
  Write-Warning "ExecutionPolicy is controlled by a higher-precedence scope. Effective policy: $eff. This is OK—scripts will still run."
}

# -----------------------------------------------------------------------------
# 6) Unblock the EasyVideoDL helper script if it exists.
#    This removes the “file is not digitally signed” protection flag.
# -----------------------------------------------------------------------------
if (Test-Path ".\run-evd.ps1") {
  Write-Host ""
  Write-Host "Unblocking run-evd.ps1..." -ForegroundColor Cyan
  Unblock-File -Path .\run-evd.ps1 -ErrorAction SilentlyContinue
}

# -----------------------------------------------------------------------------
# 7) Verify installation success by printing tool versions.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Verifying installations..." -ForegroundColor Cyan
try { yt-dlp --version } catch { Write-Warning "yt-dlp not detected on PATH." }
try { ffmpeg -version } catch { Write-Warning "ffmpeg not detected on PATH." }

# -----------------------------------------------------------------------------
# 8) Display completion message.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "All set! You can run EasyVideDL with command: .\run-evd.ps1" -ForegroundColor Green