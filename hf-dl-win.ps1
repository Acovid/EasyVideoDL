<# 
yt-dlp Windows Helper Script
Author: Aco Vidovic & ChatGPT
License: MIT

###############################################################################
# PURPOSE
# --------
# This PowerShell script simplifies the process of downloading videos or
# entire playlists from websites (including login-protected ones) using yt-dlp
# on Windows systems.
#
# It automatically:
#  - prompts for the video or playlist URL,
#  - asks for the cookies.txt file path,
#  - requests an output folder,
#  - lets you specify whether it’s a playlist or single video,
#  - merges video + audio using ffmpeg (if installed).
#
# The script mirrors the macOS Bash version (hf-dl.sh) in logic and behavior.
###############################################################################
# REQUIREMENTS
# -------------
# - yt-dlp (installed via winget, Chocolatey, or pip)
# - ffmpeg (installed via winget, Chocolatey, or manual ZIP)
# - cookies.txt exported via "Get cookies.txt LOCALLY" Chrome extension
###############################################################################
# USAGE
# -----
# Run from PowerShell:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#   .\hf-dl-win.ps1
###############################################################################
# NOTES
# -----
# - Keep your cookies.txt private; it contains session tokens.
# - Works with both single videos and playlists.
# - DRM-protected content cannot be downloaded by yt-dlp.
###############################################################################
# VERSION
# -------
# v1.0  |  October 2025
###############################################################################
#>

# --- Prompt user for the video or playlist URL ---
$URL = Read-Host "Video or playlist URL"

# --- Ask for cookies file (default: Downloads\\cookies.txt) ---
$DefaultCookies = Join-Path $HOME "Downloads\\cookies.txt"
$Cookies = Read-Host "Path to cookies.txt [$DefaultCookies]"
if ([string]::IsNullOrWhiteSpace($Cookies)) { $Cookies = $DefaultCookies }

# --- Ask for output folder (default: Downloads) ---
$DefaultOut = Join-Path $HOME "Downloads"
$OutDir = Read-Host "Output folder [$DefaultOut]"
if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = $DefaultOut }

# --- Ask whether the URL is a playlist or a single video ---
$IsPl = Read-Host "Is this a playlist (course with multiple videos)? (y/n)"

###############################################################################
# EXECUTION
# ----------
# Depending on the user’s choice:
#  - Playlist mode downloads all videos in the course.
#  - Single video mode downloads only one file.
# yt-dlp automatically merges video + audio into a single MP4 file using ffmpeg.
###############################################################################
Write-Host "`nStarting download...`n"

if ($IsPl -match '^[yY]$') {
    Write-Host "Mode: Playlist download"
    yt-dlp --cookies "$Cookies" --yes-playlist -f "bestvideo+bestaudio/best" `
        -o "$OutDir/%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s" `
        "$URL"
}
else {
    Write-Host "Mode: Single video download"
    yt-dlp --cookies "$Cookies" -f "bestvideo+bestaudio/best" `
        -o "$OutDir/%(uploader)s/%(title)s.%(ext)s" `
        "$URL"
}

###############################################################################
# COMPLETION MESSAGE
# -------------------
# After completion, yt-dlp displays its own progress and merge logs.
# This final message confirms success.
###############################################################################
Write-Host "`nDownload completed successfully.`nFiles saved to: $OutDir`n"