# EasyVideoDL

![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Windows-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Tool](https://img.shields.io/badge/tool-yt--dlp-orange)
![Language](https://img.shields.io/badge/scripts-Bash%20%7C%20PowerShell-yellow)

**Authors:** Aco Vidovic  
**License:** MIT

---

## 📘 About EasyVideoDL

**EasyVideoDL** is a cross-platform (macOS + Windows) video downloader powered by **yt-dlp** and **ffmpeg**.  
It simplifies downloading videos — including login-protected course content — with cookie-based authentication, playlist handling, and auto-naming.

Includes:

- Step-by-step setup for **macOS** and **Windows**
- A **Bash helper** (`hf-dl.sh`) and **PowerShell helper** (`hf-dl-win.ps1`)
- Auto-merging of audio + video streams using **ffmpeg**
- Clear troubleshooting and example commands

> ⚠️ Use only for videos you are authorized to access. Respect site Terms and local law.

---

## 🚀 Quick Start

### macOS

```bash
# Install Homebrew (if needed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install yt-dlp ffmpeg

# Make the helper executable and run it
chmod +x ./hf-dl.sh
./hf-dl.sh
```

### Windows (PowerShell)

```powershell
# Install tools (Windows 10/11)
winget install yt-dlp.yt-dlp
winget install Gyan.FFmpeg

# Allow scripts if blocked
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# If you downloaded this file from the internet or a ZIP archive, unblock it first
Unblock-File -Path .\hf-dl-win.ps1

# Run the helper script
.\hf-dl-win.ps1
```

> Before running either script, export cookies with **Get cookies.txt LOCALLY** in Chrome and save as `cookies.txt` (e.g., in Downloads).

---

## 🧩 Key Features

- ✅ Works on **macOS** and **Windows**
- 🔑 Handles **login-protected** videos using exported cookies
- 🎞️ Merges separate video + audio streams (via **ffmpeg**)
- 📂 Organizes course playlists into titled folders with numbered lessons
- 🧠 Minimal commands — fully guided through prompts

---

## 1) Install yt-dlp and ffmpeg

### macOS (Homebrew recommended)

```bash
brew install yt-dlp ffmpeg
yt-dlp --version
ffmpeg -version
```

### Windows

```powershell
winget install yt-dlp.yt-dlp
winget install Gyan.FFmpeg
yt-dlp --version
ffmpeg -version
```

Alternative package managers: `choco install yt-dlp ffmpeg` (Chocolatey) or `pip install -U yt-dlp`.

---

## 2) Export Cookies (Chrome)

Install **Get cookies.txt LOCALLY** from the Chrome Web Store.

Steps:

1. Log in to the site (play the video).
2. Click the 🍪 extension → **Export/Download cookies**.
3. Save as `cookies.txt` (e.g., in Downloads). Keep it **private**; it contains session tokens.

> Safari uses a different cookie storage; Chrome or Firefox are simpler.

---

## 3) Example Commands

**Single video (best quality):**

```bash
yt-dlp --cookies cookies.txt -f "bestvideo+bestaudio/best"   -o "%(title)s.%(ext)s" "https://example.com/video-url"
```

**Entire playlist/course (auto folders + numbering):**

```bash
yt-dlp --cookies cookies.txt --yes-playlist -f "bestvideo+bestaudio/best"   -o "%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s"   "https://example.com/course-url"
```

---

## 4) Common Issue: Two Files (video-only + audio-only)

Once you downloaded a video, if you see two separate MP4s instead of just one and your video has no sound, it means `ffmpeg` is missing.  
Install it and re-run the command or helper script.

Force merge (optional):

```bash
yt-dlp -f "bestvideo+bestaudio/best" --merge-output-format mp4 "URL"
```

---

## 5) Helper Scripts

### macOS — `hf-dl.sh`

Interactive Bash script that prompts for URL, cookies path, output folder, and playlist mode.

### Windows — `hf-dl-win.ps1`

Equivalent PowerShell helper for Windows systems.

> Both scripts ensure optimal quality, correct naming, and automatic merging of video + audio.

---

## 📚 Official yt-dlp Documentation

- GitHub repository: [yt-dlp/yt-dlp](https://github.com/yt-dlp/yt-dlp)
- Full command-line reference in their README and Wiki.

---

## 🧾 License

Released under the **MIT License** with attribution to **Aco Vidovic** and **ChatGPT**.
