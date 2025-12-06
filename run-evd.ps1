<#
===============================================================================
 EasyVideoDL Helper Script for Windows
 Feature-parity version matching the macOS/Linux run-evd.sh script
===============================================================================
 Supports:
   • Video downloads (best / 1080p / 720p / 480p)
   • Audio-only downloads:
        - MP3 (320 / 256 / 160 / 96 kbps)
        - Best available M4A (Apple-friendly, no filename suffix)
   • Playlist or single video
   • Overwrite or skip existing files
   • Automatic ffmpeg detection
   • Safe filename output with quality suffixes
===============================================================================
#>

# ---------------------- 1) Ask for URL ---------------------------------------
$URL = Read-Host "Video or playlist URL"
if ([string]::IsNullOrWhiteSpace($URL)) {
    Write-Host "Error: URL is required. Exiting." -ForegroundColor Red
    exit 1
}

# ---------------------- 2) cookies.txt path ----------------------------------
$DefaultCookies = Join-Path $HOME "Downloads\cookies.txt"
$Cookies = Read-Host "Path to cookies.txt [$DefaultCookies]"
if ([string]::IsNullOrWhiteSpace($Cookies)) { $Cookies = $DefaultCookies }

# ---------------------- 3) Output folder -------------------------------------
$DefaultOut = Join-Path $HOME "Downloads"
$OutDir = Read-Host "Output folder [$DefaultOut]"
if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = $DefaultOut }

# ---------------------- 4) Playlist or single? --------------------------------
$IsPl = Read-Host "Is this a playlist (course with multiple videos)? [y/N]"

# --------- 4.1) Overwrite or skip existing files ------------------------------
Write-Host ""
Write-Host "If a file with the same name already exists:"
Write-Host "  [s] Skip downloading (keep existing)"
Write-Host "  [o] Overwrite existing file"
$OVER_CHOICE = Read-Host "Choice [s/o, default s]"

$OverwriteFlag = ""
switch ($OVER_CHOICE.ToLower()) {
    "o" { $OverwriteFlag = "--force-overwrites"; Write-Host "Overwrite enabled." }
    default { $OverwriteFlag = ""; Write-Host "Existing files will be skipped." }
}
Write-Host ""

# ---------------------- 5) Quality selection ---------------------------------
Write-Host "Choose quality:"
Write-Host "  1) Best available (highest quality, may be large)"
Write-Host "  2) 1080p"
Write-Host "  3) 720p"
Write-Host "  4) 480p"
Write-Host "  5) Audio only"

$QUALITY_CHOICE = Read-Host "Enter choice [1-5, default 1]"
if ([string]::IsNullOrWhiteSpace($QUALITY_CHOICE)) { $QUALITY_CHOICE = "1" }

$Format = "bestvideo+bestaudio/best"
$AudioOnly = $false
$AudioMode = "none"
$QualityLabel = "best"
$AudioQualityFlags = @()

switch ($QUALITY_CHOICE) {

    "2" { $Format = "bestvideo[height<=1080]+bestaudio/best"; $QualityLabel = "1080p" }
    "3" { $Format = "bestvideo[height<=720]+bestaudio/best";  $QualityLabel = "720p" }
    "4" { $Format = "bestvideo[height<=480]+bestaudio/best";  $QualityLabel = "480p" }

    "5" {
        $AudioOnly = $true
        $Format = "bestaudio"

        Write-Host "Choose audio quality:"
        Write-Host "  1) 320 kbps MP3 (highest MP3 quality)"
        Write-Host "  2) 256 kbps MP3 (very high)"
        Write-Host "  3) 160 kbps MP3 (medium)"
        Write-Host "  4) 96 kbps MP3 (low)"
        Write-Host "  5) Best audio as m4a (Apple-friendly, no suffix)"
        $AQ = Read-Host "Enter choice [1-5, default 1]"
        if ([string]::IsNullOrWhiteSpace($AQ)) { $AQ = "1" }

        switch ($AQ) {

            "2" { $AudioMode="mp3"; $AudioQualityFlags=@("--audio-quality","2"); $QualityLabel="256kbps" }
            "3" { $AudioMode="mp3"; $AudioQualityFlags=@("--audio-quality","4"); $QualityLabel="160kbps" }
            "4" { $AudioMode="mp3"; $AudioQualityFlags=@("--audio-quality","7"); $QualityLabel="96kbps" }

            "5" { 
                $AudioMode="m4a"; 
                $AudioQualityFlags=@(); 
                $QualityLabel="m4a";   # no suffix in filename
                $Format="bestaudio"
            }

            default { $AudioMode="mp3"; $AudioQualityFlags=@("--audio-quality","0"); $QualityLabel="320kbps" }
        }
    }

    default { $Format = "bestvideo+bestaudio/best"; $QualityLabel = "best" }
}

# ---------------------- 6) Ensure base output folder --------------------------
$evdBase = Join-Path $OutDir "EasyVideoDL"
if (-not (Test-Path $evdBase)) { New-Item -ItemType Directory -Path $evdBase | Out-Null }

Write-Host ""
Write-Host "Starting download..." -ForegroundColor Cyan
Write-Host ""

# ---------------------- 7) Build yt-dlp command -------------------------------
function Run-YTDLP($cmdArray) {
    $cmd = $cmdArray -join " "
    Write-Host "Executing:" -ForegroundColor DarkGray
    Write-Host $cmd -ForegroundColor Gray
    iex $cmd
}

# ---------------------- 8) Playlist mode -------------------------------------
if ($IsPl -match '^[yY]$') {
    Write-Host "Mode: Playlist download" -ForegroundColor Cyan

    if ($AudioOnly) {

        if ($AudioMode -eq "mp3") {

            Run-YTDLP @(
                "yt-dlp",
                $OverwriteFlag,
                "--cookies `"$Cookies`"",
                "--yes-playlist",
                "-f `"$Format`"",
                "--extract-audio",
                "--audio-format mp3",
                $AudioQualityFlags,
                "-o `"$OutDir/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s [$QualityLabel].%(ext)s`"",
                "`"$URL`""
            )

        } else {
            Run-YTDLP @(
                "yt-dlp",
                $OverwriteFlag,
                "--cookies `"$Cookies`"",
                "--yes-playlist",
                "-f `"$Format`"",
                "--extract-audio",
                "--audio-format m4a",
                "-o `"$OutDir/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s`"",
                "`"$URL`""
            )
        }

    } else {
        Run-YTDLP @(
            "yt-dlp",
            $OverwriteFlag,
            "--cookies `"$Cookies`"",
            "--yes-playlist",
            "-f `"$Format`"",
            "-o `"$OutDir/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s [$QualityLabel].%(ext)s`"",
            "`"$URL`""
        )
    }

}

# ---------------------- 9) Single video mode ----------------------------------
else {
    Write-Host "Mode: Single video download" -ForegroundColor Cyan

    if ($AudioOnly) {

        if ($AudioMode -eq "mp3") {
            Run-YTDLP @(
                "yt-dlp",
                $OverwriteFlag,
                "--cookies `"$Cookies`"",
                "-f `"$Format`"",
                "--extract-audio",
                "--audio-format mp3",
                $AudioQualityFlags,
                "-o `"$OutDir/EasyVideoDL/%(title)s [$QualityLabel].%(ext)s`"",
                "`"$URL`""
            )

        } else {
            Run-YTDLP @(
                "yt-dlp",
                $OverwriteFlag,
                "--cookies `"$Cookies`"",
                "-f `"$Format`"",
                "--extract-audio",
                "--audio-format m4a",
                "-o `"$OutDir/EasyVideoDL/%(title)s.%(ext)s`"",
                "`"$URL`""
            )
        }

    } else {
        Run-YTDLP @(
            "yt-dlp",
            $OverwriteFlag,
            "--cookies `"$Cookies`"",
            "-f `"$Format`"",
            "-o `"$OutDir/EasyVideoDL/%(title)s [$QualityLabel].%(ext)s`"",
            "`"$URL`""
        )
    }
}

Write-Host ""
Write-Host "Download completed." -ForegroundColor Green
Write-Host "Files saved to: $OutDir\EasyVideoDL"