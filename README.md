# EasyVideoDL

**Platform:** macOS | Windows  
**License:** MIT  
**Tool:** yt-dlp  
**Scripts:** Bash | PowerShell  

**Created by Aco Vidovic with AI assistance from ChatGPT**  


---

## 📖 **Table of Contents**

1. 🎬 What Is EasyVideoDL?  
2. ⚡ Quick Start Summary (for Experienced Users)  
3. ⚙️ Basic Installation  
   - 3.1 💡 Automatic Installation (Recommended)  
   - 3.2 🧰 Manual Installation (Alternative)  
4. 🍪 Installation Required for Login-Protected Sites: Browser Cookie Extension  
5. 📁 Project Directory Structure (CLI + GUI Architecture)  
6. ▶️ Running EasyVideoDL  
7. 🧹 Uninstalling EasyVideoDL  
8. 🎓 Example Commands (for Advanced Users)  
9. 🧩 Troubleshooting & Common Issues  
10. 📚 Official Resources  
11. 🧾 License  


---

## **1. 🎬 What Is EasyVideoDL?**

**EasyVideoDL** is a simple, cross-platform tool (for **macOS** and **Windows**) that helps you download videos — even from **login-protected websites** — using the powerful open-source engine [yt-dlp](https://github.com/yt-dlp/yt-dlp).  

It automates complex terminal commands into an easy guided process. Whether you're downloading a single lecture or an entire online course, EasyVideoDL ensures high-quality audio/video merging with minimal effort.

> ⚠️ Always use this tool responsibly and only for videos you are legally authorized to access.


---

## **2. ⚡ Quick Start Summary (for Experienced Users)**

Once you installed **EasyVideoDL**, you run it using the commands in your computer's terminal:

```bash
# macOS
chmod +x ./install-evd.sh && ./install-evd.sh
./run-evd.sh

# Windows (PowerShell)
.\install-evd.ps1
.\run-evd.ps1
```

> 💡 Full, detailed installation and usage instructions follow below.


---

## **3. ⚙️ Basic Installation**

Choose **one** installation method — do *not* run both on the same system.

---

### **3.1 💡 Automatic Installation (Recommended)**

This installs everything for you (yt-dlp, ffmpeg, permissions).

#### 🍎 macOS Installation

```bash
chmod +x ./install-evd.sh
./install-evd.sh
```

#### 💻 Windows Installation

```powershell
.\install-evd.ps1
```

---

### **3.2 🧰 Manual Installation (Alternative)**

Only for advanced users or when avoiding automated scripts.

#### macOS

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install yt-dlp ffmpeg
```

#### Windows

```powershell
winget install yt-dlp.yt-dlp
winget install Gyan.FFmpeg
```

Verify success:

```bash
yt-dlp --version
ffmpeg -version
```


---

## **4. 🍪 Installation Required for Login-Protected Sites**

Many platforms require your browser **session cookies** to access videos.

### ✔ Recommended browser extension  
**Get cookies.txt LOCALLY**

- Works locally (no cloud sync)  
- Chrome / Edge / Firefox versions available  
- Extracts cookies for the currently open website  

### ✔ How to use it

1. Log into the video site  
2. Open the video  
3. Click the extension icon  
4. Save cookies to a file named `cookies.txt`  
5. Provide that file to EasyVideoDL when prompted  

> 🔒 Never share your cookies file — it contains login tokens.


---

## **5. 📁 Project Directory Structure (CLI + GUI Architecture)**

EasyVideoDL now contains two subsystems:

- **CLI Mode** — stable, feature-complete  
- **GUI Mode** — React + Python (in development)

```
EasyVideoDL/
│
├── README.md
├── LICENSE
│
├── cli/
│   ├── run-evd.sh
│   ├── run-evd.command
│   ├── run-evd.ps1
│   ├── install-evd.sh
│   ├── install-evd.ps1
│   ├── uninstall-evd.sh
│   └── uninstall-evd.ps1
│
├── gui/
│   ├── frontend/
│   │   ├── package.json
│   │   ├── public/
│   │   └── src/
│   │       ├── components/
│   │       ├── pages/
│   │       ├── hooks/
│   │       ├── api/
│   │       ├── styles/
│   │       └── App.jsx
│   │
│   ├── backend/
│   │   ├── app.py
│   │   ├── yt_service.py
│   │   ├── cookies.py
│   │   ├── models.py
│   │   └── requirements.txt
│   │
│   └── electron/
│       ├── main.js
│       └── preload.js
│
├── downloads/          # optional sandbox folder for GUI dev
│
└── utils/
    ├── common_paths.py
    ├── validation.py
    └── platform_utils.py
```

### ✔ Folder Overview

#### **cli/**
Mature, ready-to-use command-line tools for macOS and Windows.

#### **gui/frontend/**
React application that will provide a user-friendly GUI.

#### **gui/backend/**
Python API service (Flask or FastAPI), wrapping yt-dlp.

#### **gui/electron/**
Optional packaging into a desktop .app or .exe.

#### **utils/**
Shared logic across CLI and GUI (path utilities, validation, helpers).


---

## **6. ▶️ Running EasyVideoDL**

EasyVideoDL can be used in **two ways**:

1. **Interactive mode** — download videos one-by-one by entering URLs manually  
2. **Batch mode** — download many videos automatically from a text file  

You choose the mode **when the program starts**.

---

### **6.1 Running on macOS**

```bash
chmod +x ./run-evd.sh
./run-evd.sh
```

---

### **6.2 Running on Windows (PowerShell)**

```powershell
.\run-evd.ps1
```

---

### **6.3 Mode Selection**

When EasyVideoDL starts, you will first be asked to choose how you want to provide URLs:

- **Interactive mode**  
  - You paste **one URL at a time**
  - After each download, you can choose whether to download another video
  - Press **ENTER without a URL** to exit

- **Batch mode (URL list file)**  
  - EasyVideoDL reads URLs from a **text file**
  - Each URL must be on its **own line**
  - Empty lines and lines starting with `#` are ignored
  - Ideal for downloading **courses, playlists, or many videos at once**

Example batch input file (`evd-urls.txt`):

```
# Online course – Week 1
https://example.com/video-1
https://example.com/video-2

# Another source
https://example.com/video-3
```

---

### **6.4 Questions Asked by EasyVideoDL**

Regardless of mode, EasyVideoDL will guide you through the following choices:

1. **Video or playlist URL** (or file path in batch mode)
2. **Cookies file** (`cookies.txt`) for login-protected sites
3. **Output folder** (default is `~/Downloads`)
4. **Playlist or single video**
5. **If a file already exists**
   - Skip existing files  
   - Overwrite existing files
6. **Download type**
   - Video (best / 1080p / 720p / 480p)
   - Audio only
7. **Audio quality (if audio-only)**
   - MP3: 320 / 256 / 160 / 96 kbps  
   - Best available M4A (Apple-friendly)

---

### **6.5 Output Location**

Downloaded files are organized automatically under:

```
~/Downloads/EasyVideoDL/
```

Examples:

```
EasyVideoDL/
├── Course Name/
│   ├── 001 - Introduction [1080p].mp4
│   ├── 002 - Lesson One [1080p].mp4
│   └── ...
└── Single Video Title [720p].mp4
```

A **human-readable log file** is also created:

```
~/Downloads/EasyVideoDL/evd-log.txt
```

This log records:
- Date and time
- Download mode (single / playlist)
- Type and quality
- Output location
- Original URL


---

## **7. 🧹 Uninstalling EasyVideoDL**

### macOS

```bash
chmod +x ./uninstall-evd.sh
./uninstall-evd.sh
```

### Windows

```powershell
.\uninstall-evd.ps1
```


---

## **8. 🎓 Example Commands (for Advanced Users)**

```bash
# Single video
yt-dlp --cookies cookies.txt -f "bestvideo+bestaudio/best" \
  -o "EasyVideoDL/%(title)s.%(ext)s" "URL"
```

```bash
# Playlist
yt-dlp --cookies cookies.txt --yes-playlist \
  -f "bestvideo+bestaudio/best" \
  -o "EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s" \
  "URL"
```


---

## **9. 🧩 Troubleshooting & Common Issues**

### ⚠️ Two files appear (video-only + audio-only)

Cause: `ffmpeg` missing.  
Fix: Reinstall `ffmpeg`.

---

### 🔐 PowerShell warning: “script not digitally signed”

Fix:

```powershell
Unblock-File -Path .\run-evd.ps1
```

---

### 🔄 Cookies expired

Re-export cookies using the browser extension.

---

### 🧩 ffmpeg not recognized (Windows)

Refresh PATH:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path','User')
```

---

## **10. 📚 Official Resources**

- yt-dlp → https://github.com/yt-dlp/yt-dlp  
- ffmpeg → https://ffmpeg.org/documentation.html  


---

## **11. 🧾 License**

Released under the **MIT License**.  
**Created by Aco Vidovic with AI assistance from ChatGPT.**  