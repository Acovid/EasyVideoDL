<#
===============================================================================
 EasyVideoDL Helper Script for Windows
 Feature-parity version matching the macOS/Linux run-evd.sh script
===============================================================================
 Supports:
   • Mode 1: Interactive (one URL at a time, with multi-download loop)
   • Mode 2: Batch from file (many URLs listed in a text file)

   • Video downloads (best / 1080p / 720p / 480p)
   • Audio-only downloads:
        - MP3 (320 / 256 / 160 / 96 kbps)
        - Best available M4A (Apple-friendly, no filename suffix)
   • Playlist or single video
   • Overwrite or skip existing files
   • Logging to evd-log.txt:
        - Newest entries at TOP
        - Date banners, once per day
        - Multi-line entries: TS, MODE, TYPE, OUT, URL
===============================================================================
#>

# ---------------------- Logging helper ---------------------------------------
function Write-EvdLog {
    param(
        [string]$Url,
        [string]$IsPl,
        [bool]  $AudioOnly,
        [string]$AudioMode,
        [string]$QualityLabel,
        [string]$OutDir
    )

    $baseDir = Join-Path $OutDir "EasyVideoDL"
    if (-not (Test-Path $baseDir)) {
        New-Item -ItemType Directory -Path $baseDir | Out-Null
    }
    $logFile = Join-Path $baseDir "evd-log.txt"

    $ts      = Get-Date
    $tsStr   = $ts.ToString("yyyy-MM-dd HH:mm:ss")
    $todayHuman = $ts.ToString("MMMM d, yyyy")

    if ($IsPl -match '^[yY]$') { $mode = "playlist" } else { $mode = "single" }

    if ($AudioOnly) {
        if ($AudioMode -eq "m4a") {
            $type = "audio:m4a"
        } else {
            $type = "audio:mp3:$QualityLabel"
        }
    } else {
        $type = "video:$QualityLabel"
    }

    $entryBlock = @(
        "[$tsStr]"
        "MODE=$mode"
        "TYPE=$type"
        "OUT=$baseDir"
        "URL=$Url"
    )

    # If log does not exist or is empty, create fresh with today's header
    if (-not (Test-Path $logFile) -or (Get-Item $logFile).Length -eq 0) {
        $newLines = @(
            "# ================="
            "# $todayHuman"
            "# ================="
            ""
        ) + $entryBlock + @("")
        $newLines | Set-Content -Encoding UTF8 $logFile
        return
    }

    $lines = Get-Content $logFile

    # If file is weird (no header), prepend fresh header + entry
    if ($lines.Count -lt 3 -or -not $lines[0].StartsWith("#")) {
        $newLines = @(
            "# ================="
            "# $todayHuman"
            "# ================="
            ""
        ) + $entryBlock + @("") + $lines
        $newLines | Set-Content -Encoding UTF8 $logFile
        return
    }

    $topDateLine = $lines[1]
    $topDate = $topDateLine.TrimStart("# ").Trim()

    if ($topDate -ne $todayHuman) {
        # New calendar day: put new header and entry ABOVE everything
        $newLines = @(
            "# ================="
            "# $todayHuman"
            "# ================="
            ""
        ) + $entryBlock + @("") + $lines
        $newLines | Set-Content -Encoding UTF8 $logFile
        return
    }

    # Same day: keep header (lines 0–3) and insert entry under it
    $header = $lines[0..3]
    if ($lines.Count -gt 4) {
        $rest = $lines[4..($lines.Count - 1)]
    } else {
        $rest = @()
    }

    $newLines = $header + $entryBlock + @("") + $rest
    $newLines | Set-Content -Encoding UTF8 $logFile
}

# ---------------------- Download helper --------------------------------------
function Invoke-EvdDownload {
    param(
        [string]$Url,
        [string]$Cookies,
        [string]$OutDir,
        [string]$IsPl,
        [string]$OverwriteFlag,
        [string]$Format,
        [bool]  $AudioOnly,
        [string]$AudioMode,
        [string]$QualityLabel,
        [string[]]$AudioQualityFlags
    )

    $evdBase = Join-Path $OutDir "EasyVideoDL"
    if (-not (Test-Path $evdBase)) {
        New-Item -ItemType Directory -Path $evdBase | Out-Null
    }

    Write-Host ""
    Write-Host "Starting download..." -ForegroundColor Cyan
    Write-Host ""

    $args = @("yt-dlp")

    if ($OverwriteFlag) {
        $args += $OverwriteFlag
    }

    $args += @("--cookies", "`"$Cookies`"", "-f", "`"$Format`"")

    if ($IsPl -match '^[yY]$') {
        Write-Host "Mode: Playlist download" -ForegroundColor Cyan
        $args += "--yes-playlist"

        if ($AudioOnly) {
            if ($AudioMode -eq "mp3") {
                $args = $args + @(
                    "--extract-audio",
                    "--audio-format", "mp3"
                ) + $AudioQualityFlags + @(
                    "-o", "`"$OutDir/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s [$QualityLabel].%(ext)s`"",
                    "`"$Url`""
                )
            }
            else {
                $args = $args + @(
                    "--extract-audio",
                    "--audio-format", "m4a",
                    "-o", "`"$OutDir/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s`"",
                    "`"$Url`""
                )
            }
        }
        else {
            $args = $args + @(
                "-o", "`"$OutDir/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s [$QualityLabel].%(ext)s`"",
                "`"$Url`""
            )
        }
    }
    else {
        Write-Host "Mode: Single video download" -ForegroundColor Cyan

        if ($AudioOnly) {
            if ($AudioMode -eq "mp3") {
                $args = $args + @(
                    "--extract-audio",
                    "--audio-format", "mp3"
                ) + $AudioQualityFlags + @(
                    "-o", "`"$OutDir/EasyVideoDL/%(title)s [$QualityLabel].%(ext)s`"",
                    "`"$Url`""
                )
            }
            else {
                $args = $args + @(
                    "--extract-audio",
                    "--audio-format", "m4a",
                    "-o", "`"$OutDir/EasyVideoDL/%(title)s.%(ext)s`"",
                    "`"$Url`""
                )
            }
        }
        else {
            $args = $args + @(
                "-o", "`"$OutDir/EasyVideoDL/%(title)s [$QualityLabel].%(ext)s`"",
                "`"$Url`""
            )
        }
    }

    $cmd = $args -join " "
    Write-Host "Executing:" -ForegroundColor DarkGray
    Write-Host $cmd -ForegroundColor Gray
    iex $cmd

    Write-Host ""
    Write-Host "Download completed." -ForegroundColor Green
    Write-Host "Files saved to: $OutDir\EasyVideoDL"

    Write-EvdLog -Url $Url -IsPl $IsPl -AudioOnly:$AudioOnly -AudioMode $AudioMode -QualityLabel $QualityLabel -OutDir $OutDir
}

# ---------------------- Mode selection banner --------------------------------
Write-Host "==============================================="
Write-Host " EasyVideoDL – Interactive Download Helper"
Write-Host "==============================================="
Write-Host ""
Write-Host "Choose mode:"
Write-Host "  1) Interactive (one URL at a time, with prompts)"
Write-Host "  2) Batch from file (many URLs listed in a text file)"
$ModeChoice = Read-Host "Enter choice [1-2, default 1]"
if ([string]::IsNullOrWhiteSpace($ModeChoice)) { $ModeChoice = "1" }
Write-Host ""

# =============================================================================
# MODE 2: BATCH FROM FILE
# =============================================================================
if ($ModeChoice -eq "2") {

    $DefaultUrlFile = Join-Path $HOME "Downloads\evd-urls.txt"
    $UrlFile = Read-Host "Path to URL list file [$DefaultUrlFile]"
    if ([string]::IsNullOrWhiteSpace($UrlFile)) { $UrlFile = $DefaultUrlFile }

    if (-not (Test-Path $UrlFile)) {
        Write-Host "Error: URL list file not found: $UrlFile" -ForegroundColor Red
        exit 1
    }

    # Cookies (once)
    $DefaultCookies = Join-Path $HOME "Downloads\cookies.txt"
    $Cookies = Read-Host "Path to cookies.txt [$DefaultCookies]"
    if ([string]::IsNullOrWhiteSpace($Cookies)) { $Cookies = $DefaultCookies }

    # Output folder (once)
    $DefaultOut = Join-Path $HOME "Downloads"
    $OutDir = Read-Host "Output folder [$DefaultOut]"
    if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = $DefaultOut }

    # Playlist flag (applies to all URLs in this batch)
    $IsPl = Read-Host "Are these URLs playlists (courses with multiple videos)? [y/N]"

    # Overwrite / skip
    Write-Host ""
    Write-Host "If a file with the same name already exists:"
    Write-Host "  [s] Skip downloading (keep existing file)"
    Write-Host "  [o] Overwrite existing file"
    $OVER_CHOICE = Read-Host "Choice [s/o, default s]"

    $OverwriteFlag = ""
    switch ($OVER_CHOICE.ToLower()) {
        "o" { $OverwriteFlag = "--force-overwrites"; Write-Host "Existing files will be overwritten if present." }
        default { $OverwriteFlag = ""; Write-Host "Existing files will be kept; yt-dlp will skip them if they already exist." }
    }
    Write-Host ""

    # Quality (once for whole batch)
    Write-Host "Choose quality for ALL URLs in this file:"
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

            Write-Host "Choose audio quality (applies to all URLs):"
            Write-Host "  1) 320 kbps MP3 (highest MP3 quality)"
            Write-Host "  2) 256 kbps MP3 (very high)"
            Write-Host "  3) 160 kbps MP3 (medium)"
            Write-Host "  4) 96 kbps MP3 (low)"
            Write-Host "  5) Best audio as m4a (Apple-friendly, may re-encode)"
            $AQ = Read-Host "Enter choice [1-5, default 1]"
            if ([string]::IsNullOrWhiteSpace($AQ)) { $AQ = "1" }

            switch ($AQ) {
                "2" { $AudioMode="mp3"; $AudioQualityFlags=@("--audio-quality","2"); $QualityLabel="256kbps" }
                "3" { $AudioMode="mp3"; $AudioQualityFlags=@("--audio-quality","4"); $QualityLabel="160kbps" }
                "4" { $AudioMode="mp3"; $AudioQualityFlags=@("--audio-quality","7"); $QualityLabel="96kbps" }
                "5" {
                    $AudioMode="m4a"
                    $AudioQualityFlags=@()
                    $QualityLabel="m4a"   # label not used in filename
                    $Format="bestaudio"
                }
                default {
                    $AudioMode="mp3"
                    $AudioQualityFlags=@("--audio-quality","0")
                    $QualityLabel="320kbps"
                }
            }
        }

        default {
            $Format = "bestvideo+bestaudio/best"
            $QualityLabel = "best"
        }
    }

    Write-Host ""
    Write-Host "Reading URLs from: $UrlFile"
    Write-Host ""

    # Read URLs (skip empty lines and comments)
    $UrlList = Get-Content $UrlFile |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith("#") }

    $Total = $UrlList.Count
    if ($Total -eq 0) {
        Write-Host "No valid URLs found in file (empty or only comments). Exiting." -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Found $Total URL(s) in the file."
    Write-Host ""

    $index = 1
    foreach ($u in $UrlList) {
        $URL = $u
        Write-Host "-----------------------------------------------"
        Write-Host " Downloading ($index/$Total):"
        Write-Host "  $URL"
        Write-Host "-----------------------------------------------"

        Invoke-EvdDownload `
            -Url $URL `
            -Cookies $Cookies `
            -OutDir $OutDir `
            -IsPl $IsPl `
            -OverwriteFlag $OverwriteFlag `
            -Format $Format `
            -AudioOnly:$AudioOnly `
            -AudioMode $AudioMode `
            -QualityLabel $QualityLabel `
            -AudioQualityFlags $AudioQualityFlags

        $index++
    }

    Write-Host "All batch downloads finished."
    exit 0
}

# =============================================================================
# MODE 1: INTERACTIVE (DEFAULT)
# =============================================================================

while ($true) {

    $URL = Read-Host "Video or playlist URL (or press ENTER to quit)"
    if ([string]::IsNullOrWhiteSpace($URL)) {
        Write-Host "No URL entered. Exiting EasyVideoDL."
        break
    }

    $DefaultCookies = Join-Path $HOME "Downloads\cookies.txt"
    $Cookies = Read-Host "Path to cookies.txt [$DefaultCookies]"
    if ([string]::IsNullOrWhiteSpace($Cookies)) { $Cookies = $DefaultCookies }

    $DefaultOut = Join-Path $HOME "Downloads"
    $OutDir = Read-Host "Output folder [$DefaultOut]"
    if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = $DefaultOut }

    $IsPl = Read-Host "Is this a playlist (course with multiple videos)? [y/N]"

    Write-Host ""
    Write-Host "If a file with the same name already exists:"
    Write-Host "  [s] Skip downloading (keep existing file)"
    Write-Host "  [o] Overwrite existing file"
    $OVER_CHOICE = Read-Host "Choice [s/o, default s]"

    $OverwriteFlag = ""
    switch ($OVER_CHOICE.ToLower()) {
        "o" { $OverwriteFlag = "--force-overwrites"; Write-Host "Existing files will be overwritten if present." }
        default { $OverwriteFlag = ""; Write-Host "Existing files will be kept; yt-dlp will skip them if they already exist." }
    }
    Write-Host ""

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
            Write-Host "  5) Best audio as m4a (Apple-friendly, may re-encode)"
            $AQ = Read-Host "Enter choice [1-5, default 1]"
            if ([string]::IsNullOrWhiteSpace($AQ)) { $AQ = "1" }

            switch ($AQ) {
                "2" { $AudioMode="mp3"; $AudioQualityFlags=@("--audio-quality","2"); $QualityLabel="256kbps" }
                "3" { $AudioMode="mp3"; $AudioQualityFlags=@("--audio-quality","4"); $QualityLabel="160kbps" }
                "4" { $AudioMode="mp3"; $AudioQualityFlags=@("--audio-quality","7"); $QualityLabel="96kbps" }
                "5" {
                    $AudioMode="m4a"
                    $AudioQualityFlags=@()
                    $QualityLabel="m4a"
                    $Format="bestaudio"
                }
                default {
                    $AudioMode="mp3"
                    $AudioQualityFlags=@("--audio-quality","0")
                    $QualityLabel="320kbps"
                }
            }
        }

        default {
            $Format = "bestvideo+bestaudio/best"
            $QualityLabel = "best"
        }
    }

    Invoke-EvdDownload `
        -Url $URL `
        -Cookies $Cookies `
        -OutDir $OutDir `
        -IsPl $IsPl `
        -OverwriteFlag $OverwriteFlag `
        -Format $Format `
        -AudioOnly:$AudioOnly `
        -AudioMode $AudioMode `
        -QualityLabel $QualityLabel `
        -AudioQualityFlags $AudioQualityFlags

    $again = Read-Host "Do you want to download another video? [y/N]"
    if ($again -notmatch '^[yY]$') {
        Write-Host "Exiting EasyVideoDL. Goodbye."
        break
    }

    Write-Host ""
    Write-Host "-----------------------------------------------"
    Write-Host "Starting another download..."
    Write-Host "-----------------------------------------------"
    Write-Host ""
}