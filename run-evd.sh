#!/usr/bin/env bash
# =============================================================================
# EasyVideoDL Helper Script (macOS / Linux)
# =============================================================================
# Purpose:
#   Interactive helper for downloading videos or playlists using yt-dlp.
#   Supports:
#     - Video: best / 1080p / 720p / 480p
#     - Audio only: MP3 (320/256/160/96 kbps) or best M4A (Apple-friendly)
#
# Output naming:
#   Video: "Title [QUALITY].ext"
#   Audio MP3: "Title [320kbps].mp3" (etc.)
#   Audio M4A (best): "Title.m4a"   (no suffix)
# =============================================================================

set -euo pipefail

# 1) Ask for URL ---------------------------------------------------------------
read -r -p "Video or playlist URL: " URL
if [[ -z "${URL}" ]]; then
  echo "Error: URL is required. Exiting."
  exit 1
fi

# 2) cookies.txt path ---------------------------------------------------------
DEFAULT_COOKIES="$HOME/Downloads/cookies.txt"
read -r -p "Path to cookies.txt [${DEFAULT_COOKIES}]: " COOKIES
COOKIES="${COOKIES:-$DEFAULT_COOKIES}"

# 3) Output folder ------------------------------------------------------------
DEFAULT_OUT="$HOME/Downloads"
read -r -p "Output folder [${DEFAULT_OUT}]: " OUTDIR
OUTDIR="${OUTDIR:-$DEFAULT_OUT}"

# 4) Playlist or single video? -----------------------------------------------
echo "Is this a playlist (course with multiple videos)? [y/N]"
read -r IS_PL

# 4.1) Overwrite or skip existing files? --------------------------------------
echo
echo "If a file with the same name already exists:"
echo "  [s] Skip downloading (keep existing file)"
echo "  [o] Overwrite existing file"
read -r -p "Choice [s/o, default s]: " OVER_CHOICE

OVERWRITE_FLAG=""
case "$OVER_CHOICE" in
  o|O)
    OVERWRITE_FLAG="--force-overwrites"
    echo "Existing files will be overwritten if present."
    ;;
  *)
    OVERWRITE_FLAG=""
    echo "Existing files will be kept; yt-dlp will skip them if they already exist."
    ;;
esac
echo

# 5) Quality choice (video vs audio-only) ------------------------------------
echo "Choose quality:"
echo "  1) Best available (highest quality, may be large)"
echo "  2) 1080p"
echo "  3) 720p"
echo "  4) 480p"
echo "  5) Audio only"
read -r -p "Enter choice [1-5, default 1]: " QUALITY_CHOICE
QUALITY_CHOICE="${QUALITY_CHOICE:-1}"

FORMAT="bestvideo+bestaudio/best"
AUDIO_ONLY=0
AUDIO_MODE="none"   # "mp3" or "m4a"
QUALITY_LABEL="best"
AUDIO_QUALITY_FLAGS=()

case "$QUALITY_CHOICE" in
  2)
    FORMAT="bestvideo[height<=1080]+bestaudio/best"
    QUALITY_LABEL="1080p"
    ;;
  3)
    FORMAT="bestvideo[height<=720]+bestaudio/best"
    QUALITY_LABEL="720p"
    ;;
  4)
    FORMAT="bestvideo[height<=480]+bestaudio/best"
    QUALITY_LABEL="480p"
    ;;
  5)
    AUDIO_ONLY=1
    FORMAT="bestaudio"
    echo "Choose audio quality:"
    echo "  1) 320 kbps MP3 (highest MP3 quality)"
    echo "  2) 256 kbps MP3 (very high)"
    echo "  3) 160 kbps MP3 (medium)"
    echo "  4) 96 kbps MP3 (low)"
    echo "  5) Best audio as m4a (Apple-friendly, may re-encode)"
    read -r -p "Enter choice [1-5, default 1]: " AQ
    AQ="${AQ:-1}"

    case "$AQ" in
      2)
        AUDIO_MODE="mp3"
        AUDIO_QUALITY_FLAGS=(--audio-quality 2)
        QUALITY_LABEL="256kbps"
        ;;
      3)
        AUDIO_MODE="mp3"
        AUDIO_QUALITY_FLAGS=(--audio-quality 4)
        QUALITY_LABEL="160kbps"
        ;;
      4)
        AUDIO_MODE="mp3"
        AUDIO_QUALITY_FLAGS=(--audio-quality 7)
        QUALITY_LABEL="96kbps"
        ;;
      5)
        AUDIO_MODE="m4a"
        AUDIO_QUALITY_FLAGS=()
        QUALITY_LABEL="m4a"   # label not used in filename for m4a
        FORMAT="bestaudio"
        ;;
      *)
        AUDIO_MODE="mp3"
        AUDIO_QUALITY_FLAGS=(--audio-quality 0)
        QUALITY_LABEL="320kbps"
        ;;
    esac
    ;;
  *)
    FORMAT="bestvideo+bestaudio/best"
    QUALITY_LABEL="best"
    ;;
esac

# 6) Ensure base output folder exists ----------------------------------------
mkdir -p "${OUTDIR}/EasyVideoDL"

echo "Starting download..."
echo

# 7) Build yt-dlp command based on playlist/single & audio/video -------------
if [[ "${IS_PL}" == "y" || "${IS_PL}" == "Y" ]]; then
  echo "Mode: Playlist download"

  if [[ "$AUDIO_ONLY" -eq 1 ]]; then
    if [[ "$AUDIO_MODE" == "mp3" ]]; then
      yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" --yes-playlist \
        -f "$FORMAT" \
        --extract-audio --audio-format mp3 "${AUDIO_QUALITY_FLAGS[@]}" \
        -o "${OUTDIR}/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s [${QUALITY_LABEL}].%(ext)s" \
        "$URL"
    else
      # m4a mode (no suffix)
      yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" --yes-playlist \
        -f "$FORMAT" \
        --extract-audio --audio-format m4a \
        -o "${OUTDIR}/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s" \
        "$URL"
    fi
  else
    yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" --yes-playlist \
      -f "$FORMAT" \
      -o "${OUTDIR}/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s [${QUALITY_LABEL}].%(ext)s" \
      "$URL"
  fi
else
  echo "Mode: Single video download"

  if [[ "$AUDIO_ONLY" -eq 1 ]]; then
    if [[ "$AUDIO_MODE" == "mp3" ]]; then
      yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" \
        -f "$FORMAT" \
        --extract-audio --audio-format mp3 "${AUDIO_QUALITY_FLAGS[@]}" \
        -o "${OUTDIR}/EasyVideoDL/%(title)s [${QUALITY_LABEL}].%(ext)s" \
        "$URL"
    else
      # m4a mode (no suffix)
      yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" \
        -f "$FORMAT" \
        --extract-audio --audio-format m4a \
        -o "${OUTDIR}/EasyVideoDL/%(title)s.%(ext)s" \
        "$URL"
    fi
  else
    yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" \
      -f "$FORMAT" \
      -o "${OUTDIR}/EasyVideoDL/%(title)s [${QUALITY_LABEL}].%(ext)s" \
      "$URL"
  fi
fi

echo
echo "Download completed."
echo "Files saved to: $OUTDIR/EasyVideoDL"