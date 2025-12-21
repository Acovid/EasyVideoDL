<# 
===============================================================================
 EasyVideoDL Uninstaller for Windows
===============================================================================

 Purpose:
   Safely removes EasyVideoDL components from your Windows system.

 What this script does:
   • Optionally uninstalls yt-dlp and ffmpeg (if they were installed via winget).
   • Optionally deletes local EasyVideoDL files (scripts, docs, images, etc.).
   • Optionally deletes your EasyVideoDL downloads folder (~/Downloads/EasyVideoDL).
   • Provides confirmation prompts before every major action.

 Safety / Transparency:
   - No hidden processes or background tasks.
   - Each uninstall or delete operation is clearly prompted.
   - You can choose to keep the programs, local scripts, or downloads.
   - The script only affects EasyVideoDL-related items in your current folder.

 Run in PowerShell as:
   .\uninstall-evd.ps1
===============================================================================
#>

# -----------------------------------------------------------------------------
# 1) Display header and explain what’s about to happen.
# -----------------------------------------------------------------------------
Write-Host "=== EasyVideoDL Uninstaller (Windows) ===`n" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 2) Ask user whether to uninstall yt-dlp and ffmpeg.
#    Uses 'winget uninstall' to remove packages cleanly if installed that way.
# -----------------------------------------------------------------------------
$ansTools = Read-Host "Uninstall yt-dlp and ffmpeg installed via winget? (y/n)"
if ($ansTools -match '^[yY]$') {
  # Attempt to uninstall from multiple known sources
  winget uninstall --id yt-dlp.yt-dlp -e
  winget uninstall --id yt-dlp.FFmpeg -e
  winget uninstall --id Gyan.FFmpeg -e
  winget uninstall --id BtbN.ffmpeg -e
} else {
  Write-Host "Keeping yt-dlp/ffmpeg." -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# 3) Ask user whether to remove EasyVideoDL project files in the current folder.
#    Includes helper scripts, installers, uninstallers, README, and LICENSE.
# -----------------------------------------------------------------------------
$ansFiles = Read-Host "Remove local EasyVideoDL scripts and docs in the current folder (install/uninstall scripts, helpers, README, LICENSE)? (y/n)"
if ($ansFiles -match '^[yY]$') {
  # Define list of items to delete
  $paths = @(
    ".\run-evd.ps1", ".\run-evd.sh",
    ".\install-evd.ps1", ".\install-evd.sh",
    ".\uninstall-evd.ps1", ".\uninstall-evd.sh",
    ".\README.md", ".\LICENSE", ".\images"
  )

  # Loop through and remove each if it exists
  foreach ($p in $paths) {
    if (Test-Path $p) {
      if ((Get-Item $p).PSIsContainer) { 
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue 
      }
      else { 
        Remove-Item $p -Force -ErrorAction SilentlyContinue 
      }
    }
  }

  Write-Host "Removed EasyVideoDL scripts and docs in the current folder (if present)."
} else {
  Write-Host "Keeping local scripts/docs." -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# 4) Ask user whether to remove the EasyVideoDL downloads folder (~/Downloads/EasyVideoDL).
# -----------------------------------------------------------------------------
$downloadDir = Join-Path $HOME "Downloads\EasyVideoDL"
if (Test-Path $downloadDir) {
  $ansDl = Read-Host "Delete downloaded videos folder at '$downloadDir'? (y/n)"
  if ($ansDl -match '^[yY]$') {
    Remove-Item $downloadDir -Recurse -Force
    Write-Host "Removed $downloadDir"
  } else {
    Write-Host "Kept $downloadDir"
  }
}

# -----------------------------------------------------------------------------
# 5) Final message confirming completion.
# -----------------------------------------------------------------------------
Write-Host "`nUninstall complete." -ForegroundColor Green