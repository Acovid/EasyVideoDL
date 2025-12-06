<# 
===============================================================================
 EasyVideoDL Helper Script for Windows
===============================================================================

 Purpose:
   This script is the main user-facing helper for downloading videos or playlists
   using the EasyVideoDL tool on Windows. It guides the user through prompts,
   automatically builds the correct yt-dlp command, and runs it.

 What this script does:
   • Prompts the user for:
       - Video or playlist URL
       - Path to cookies.txt (used for login-protected videos)
       - Output folder where downloads will be saved
       - Whether the link is a playlist or single video
       - Desired quality (best, 1080p, 720p, 480p, audio-only)
   • Detects whether ffmpeg is installed and passes its path to yt-dlp if needed.
   • Creates a folder structure in ~/Downloads/EasyVideoDL for organized saving.
   • Executes yt-dlp to download and merge audio + video files.
   • Displays clear status messages throughout.

 Safety / Transparency:
   - This script does not download or install any additional software.
   - It only uses yt-dlp and ffmpeg already installed on your machine.
   - All operations run locally and visibly in this terminal window.

 Run in PowerShell as:
   .\run-evd.ps1
===============================================================================
#>

# -----------------------------------------------------------------------------
# 1) Prompt user for the video or playlist URL.
# -----------------------------------------------------------------------------
$URL = Read-Host "Video or playlist URL"

# -----------------------------------------------------------------------------
# 2) Ask for cookies.txt path (required for login-protected sites).
#    Default location: C:\Users\<User>\Downloads\cookies.txt
# -----------------------------------------------------------------------------
$DefaultCookies = Join-Path $HOME "Downloads\cookies.txt"
$Cookies = Read-Host "Path to cookies.txt [$DefaultCookies]"
if ([string]::IsNullOrWhiteSpace($Cookies)) { $Cookies = $DefaultCookies }

# -----------------------------------------------------------------------------
# 3) Ask for output folder where videos will be saved.
#    Default: C:\Users\<User>\Downloads
# -----------------------------------------------------------------------------
$DefaultOut = Join-Path $HOME "Downloads"
$OutDir = Read-Host "Output folder [$DefaultOut]"
if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = $DefaultOut }

# -----------------------------------------------------------------------------
# 4) Ask whether this is a playlist or single video.
# -----------------------------------------------------------------------------
$IsPl = Read-Host "Is this a playlist (course with multiple videos)? (y/n)"

# -----------------------------------------------------------------------------
# 5) Ask for desired quality (format selection for yt-dlp).
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Choose quality:" -ForegroundColor Cyan
Write-Host "  1) Best available (highest quality, may be large)"
Write-Host "  2) 1080p"
Write-Host "  3) 720p"
Write-Host "  4) 480p"
Write-Host "  5) Audio only (MP3)"
$Quality = Read-Host "Enter choice [1-5, default 1]"
if ([string]::IsNullOrWhiteSpace($Quality)) { $Quality = "1" }

# Default format and extra args
$format    = "bestvideo+bestaudio/best"
$extraArgs = @()

switch ($Quality) {
  "2" {
    $format = "bestvideo[height<=1080]+bestaudio/best"
  }
  "3" {
    $format = "bestvideo[height<=720]+bestaudio/best"
  }
  "4" {
    $format = "bestvideo[height<=480]+bestaudio/best"
  }
  "5" {
    # Audio-only MP3
    $format    = "bestaudio"
    $extraArgs = @("--extract-audio", "--audio-format", "mp3")
  }
  default {
    $format = "bestvideo+bestaudio/best"
  }
}

# -----------------------------------------------------------------------------
# 6) Try to detect ffmpeg automatically.
#    - If ffmpeg is on PATH, nothing special needed.
#    - If not, search in typical WinGet install locations and build a flag for yt-dlp.
# -----------------------------------------------------------------------------
$ffmpegCmd  = Get-Command ffmpeg -ErrorAction SilentlyContinue
$ffmpegFlag = ""
if (-not $ffmpegCmd) {
  # Look for ffmpeg.exe in WinGet installation folders
  $ffexe = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue |
    Select-Object -First 1 -Expand FullName
  if ($ffexe) {
    $ffbin      = Split-Path -Parent $ffexe
    $ffmpegFlag = "--ffmpeg-location `"$ffbin`""
    Write-Host "Using ffmpeg at: $ffbin"
  } else {
    Write-Warning "ffmpeg not found on PATH. yt-dlp may fail to merge audio+video."
  }
}

# -----------------------------------------------------------------------------
# 7) Start download process with user feedback.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Starting download..." -ForegroundColor Cyan
Write-Host ""

# -----------------------------------------------------------------------------
# 8) Ensure base output folder exists.
# -----------------------------------------------------------------------------
$evdBase = Join-Path $OutDir "EasyVideoDL"
if (-not (Test-Path $evdBase)) { 
  New-Item -ItemType Directory -Path $evdBase | Out-Null 
}

# -----------------------------------------------------------------------------
# 9) Construct yt-dlp command depending on whether it's a playlist or single video.
#    Build a list of arguments and then join them into a string.
# -----------------------------------------------------------------------------
if ($IsPl -match '^[yY]$') {
  Write-Host "Mode: Playlist download"

  $cmdParts = @(
    "yt-dlp", $ffmpegFlag,
    "--cookies", "`"$Cookies`"",
    "--yes-playlist",
    "-f", "`"$format`""
  )

  if ($extraArgs.Count -gt 0) {
    $cmdParts += $extraArgs
  }

  $cmdParts += @(
    "-o", "`"$OutDir/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s`"",
    "`"$URL`""
  )

  $cmd = $cmdParts -join " "
  iex $cmd
}
else {
  Write-Host "Mode: Single video download"

  $cmdParts = @(
    "yt-dlp", $ffmpegFlag,
    "--cookies", "`"$Cookies`"",
    "-f", "`"$format`""
  )

  if ($extraArgs.Count -gt 0) {
    $cmdParts += $extraArgs
  }

  $cmdParts += @(
    "-o", "`"$OutDir/EasyVideoDL/%(title)s.%(ext)s`"",
    "`"$URL`""
  )

  $cmd = $cmdParts -join " "
  iex $cmd
}

# -----------------------------------------------------------------------------
# 10) Final completion message showing where files were saved.
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Done. Files saved to: $OutDir\EasyVideoDL" -ForegroundColor Green