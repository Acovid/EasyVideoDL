#!/usr/bin/env bash
# =============================================================================
# EasyVideoDL Installer (macOS)
# =============================================================================
# Purpose:
#   Installs the dependencies required by EasyVideoDL on macOS using Homebrew.
#
# What this script does:
#   1) Enables strict shell settings for safer execution.
#   2) Checks if Homebrew is installed; if not, installs it.
#   3) Ensures the current shell session is configured to use Homebrew (shellenv).
#   4) Installs yt-dlp (the downloader) and ffmpeg (for merging audio+video).
#   5) Marks the EasyVideoDL helper script (run-evd.sh) as executable.
#   6) Prints a friendly completion message.
#
# Safety / Transparency:
#   - This script only installs well-known open-source tools (Homebrew, yt-dlp, ffmpeg).
#   - No hidden downloads; all commands are visible below.
#   - You can re-run safely; Homebrew will skip already-installed packages.
#
# Usage:
#   chmod +x ./install-evd.sh
#   ./install-evd.sh
# =============================================================================

# -----------------------------------------------------------------------------
# 1) Enable strict mode:
#    -e : exit on any command failure
#    -u : error on use of unset variables
#    -o pipefail : fail a pipeline if any command errors
# -----------------------------------------------------------------------------
set -euo pipefail

# -----------------------------------------------------------------------------
# 2) Display a start banner so users know what's running.
# -----------------------------------------------------------------------------
echo "=== EasyVideoDL Installer (macOS) ==="

# -----------------------------------------------------------------------------
# 3) Ensure Homebrew is installed. If not, install it using the official script.
#    After installation, configure the current shell to use 'brew' by evaluating
#    its shellenv (handles both Apple Silicon (/opt/homebrew) and Intel (/usr/local)).
# -----------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Apple Silicon default path
  if [[ -x /opt/homebrew/bin/brew ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"

  # Intel default path
  elif [[ -x /usr/local/bin/brew ]]; then
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# -----------------------------------------------------------------------------
# 4) Install yt-dlp and ffmpeg via Homebrew.
#    - yt-dlp: main downloader
#    - ffmpeg: required by yt-dlp to merge separate audio/video streams
# -----------------------------------------------------------------------------
echo "Installing yt-dlp and ffmpeg..."
brew install yt-dlp ffmpeg

# -----------------------------------------------------------------------------
# 5) If the EasyVideoDL helper exists, make it executable so users can run it.
# -----------------------------------------------------------------------------
if [[ -f "./run-evd.sh" ]]; then
  chmod +x ./run-evd.sh
  echo "Made run-evd.sh executable."
fi

# -----------------------------------------------------------------------------
# 6) Friendly completion message with the next command to run.
# -----------------------------------------------------------------------------
echo "Done. You can run EasyVideDL with command: ./run-evd.sh"