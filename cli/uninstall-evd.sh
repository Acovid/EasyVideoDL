#!/usr/bin/env bash
# =============================================================================
# EasyVideoDL Uninstaller (macOS / Linux)
# =============================================================================
# Purpose:
#   Safely removes EasyVideoDL and its related components from your macOS system.
#
# What this script does:
#   1) Optionally uninstalls yt-dlp and ffmpeg (if installed via Homebrew).
#   2) Optionally deletes EasyVideoDL scripts and documentation from
#      the current folder.
#   3) Optionally deletes your ~/Downloads/EasyVideoDL folder containing
#      previously downloaded videos.
#
# Safety / Transparency:
#   - Every action is confirmed before deletion — no automatic removals.
#   - No hidden processes or network calls.
#   - All deletions and uninstalls use visible, standard macOS commands.
#
# Usage:
#   chmod +x ./uninstall-evd.sh
#   ./uninstall-evd.sh
# =============================================================================

# -----------------------------------------------------------------------------
# 1) Enable strict shell mode for safety:
#    -e : exit immediately on any error
#    -u : treat unset variables as errors
#    -o pipefail : fail entire pipeline if any command fails
# -----------------------------------------------------------------------------
set -euo pipefail

# -----------------------------------------------------------------------------
# 2) Display header so the user knows what script is running.
# -----------------------------------------------------------------------------
echo "=== EasyVideoDL Uninstaller (macOS) ==="

# -----------------------------------------------------------------------------
# 3) Ask whether to uninstall yt-dlp and ffmpeg using Homebrew.
#    If the user agrees, use `brew uninstall` for each package.
# -----------------------------------------------------------------------------
read -r -p "Remove yt-dlp and ffmpeg if installed via Homebrew? (y/n) " ans_tools
if [[ "$ans_tools" =~ ^[yY]$ ]]; then
  # Only proceed if Homebrew is installed
  if command -v brew >/dev/null 2>&1; then
    echo "Uninstalling yt-dlp and ffmpeg via Homebrew..."
    brew uninstall yt-dlp || true
    brew uninstall ffmpeg || true
  else
    echo "Homebrew not found; skipping Homebrew uninstalls."
  fi
else
  echo "Keeping yt-dlp and ffmpeg."
fi

# -----------------------------------------------------------------------------
# 4) Ask whether to delete local EasyVideoDL project files.
#    Includes helper scripts, installers, uninstallers, README, LICENSE, etc.
# -----------------------------------------------------------------------------
read -r -p "Remove local EasyVideoDL scripts and docs in the current folder (README, LICENSE, install/uninstall scripts, helpers)? (y/n) " ans_files
if [[ "$ans_files" =~ ^[yY]$ ]]; then
  # Remove all project-related files safely, ignoring errors if they’re missing.
  rm -f ./run-evd.sh ./run-evd.ps1 || true
  rm -f ./install-evd.sh ./uninstall-evd.sh || true
  rm -f ./install-evd.ps1 ./uninstall-evd.ps1 || true
  rm -f ./README.md ./LICENSE || true
  rm -rf ./images || true
  echo "Removed EasyVideoDL scripts and documentation files in the current folder (if present)."
else
  echo "Keeping local scripts and documentation."
fi

# -----------------------------------------------------------------------------
# 5) Ask whether to remove the EasyVideoDL download folder in ~/Downloads.
# -----------------------------------------------------------------------------
download_dir="$HOME/Downloads/EasyVideoDL"
if [[ -d "$download_dir" ]]; then
  read -r -p "Delete downloaded videos folder at '$download_dir'? (y/n) " ans_dl
  if [[ "$ans_dl" =~ ^[yY]$ ]]; then
    rm -rf "$download_dir"
    echo "Removed $download_dir"
  else
    echo "Kept $download_dir"
  fi
fi

# -----------------------------------------------------------------------------
# 6) Print final success message.
# -----------------------------------------------------------------------------
echo "Uninstall complete."