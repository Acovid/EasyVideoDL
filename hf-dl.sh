#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# yt-dlp macOS Helper Script
# Author: Aco Vidovic & ChatGPT
#
# Purpose:
# This script simplifies the process of downloading videos or entire playlists
# from websites (including login-protected ones) using yt-dlp on macOS.
#
# It automatically:
#  - prompts for the video or playlist URL,
#  - asks for the cookies.txt file path,
#  - requests an output folder,
#  - lets you specify whether it’s a playlist or single video,
#  - merges video + audio using ffmpeg (if installed).
###############################################################################

# --- Prompt user for the video or playlist URL ---
read -r -p "Video or playlist URL: " URL

# --- Ask for cookies file (default: ~/Downloads/cookies.txt) ---
DEFAULT_COOKIES="$HOME/Downloads/cookies.txt"
read -r -p "Path to cookies.txt [${DEFAULT_COOKIES}]: " COOKIES
COOKIES="${COOKIES:-$DEFAULT_COOKIES}"

# --- Ask for output folder (default: ~/Downloads) ---
DEFAULT_OUT="$HOME/Downloads"
read -r -p "Output folder [${DEFAULT_OUT}]: " OUTDIR
OUTDIR="${OUTDIR:-$DEFAULT_OUT}"

# --- Determine if this is a playlist or a single video ---
echo "Is this a playlist (course with multiple videos)? (y/n)"
read -r IS_PL

###############################################################################
# Execute yt-dlp depending on user's choice
# - For playlists: downloads all videos in the course
# - For single videos: downloads only one file
# The options ensure best quality video + audio and auto-merging into MP4
###############################################################################
if [[ "${IS_PL}" == "y" || "${IS_PL}" == "Y" ]]; then
  echo "Downloading playlist..."
  yt-dlp --cookies "$COOKIES" --yes-playlist -f "bestvideo+bestaudio/best"     -o "${OUTDIR}/%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s"     "$URL"
else
  echo "Downloading single video..."
  yt-dlp --cookies "$COOKIES" -f "bestvideo+bestaudio/best"     -o "${OUTDIR}/%(uploader)s/%(title)s.%(ext)s"     "$URL"
fi

###############################################################################
# Completion message
###############################################################################
echo "Download completed successfully."
echo "Files saved to: $OUTDIR"
