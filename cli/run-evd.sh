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
#
# Features:
#   - Mode 1: Interactive (one URL at a time, with multi-download loop).
#   - Mode 2: Batch from file (many URLs listed in a text file).
#   - Exit interactive mode by pressing ENTER at URL prompt.
#
# Logging:
#   - Every completed download writes one entry into:
#       <OUTDIR>/EasyVideoDL/evd-log.txt
#   - Log format:
#       * Newest entries at the TOP of the file
#       * Blank line between entries
#       * Date sections with header, once per day:
#            # =================
#            # December  7, 2025
#            # =================
#         (blank line after the header)
# =============================================================================

set -euo pipefail

echo "==============================================="
echo " EasyVideoDL – Interactive Download Helper"
echo "==============================================="
echo
echo "Choose mode:"
echo "  1) Interactive (one URL at a time, with prompts)"
echo "  2) Batch from file (many URLs listed in a text file)"
read -r -p "Enter choice [1-2, default 1]: " MODE_CHOICE
MODE_CHOICE="${MODE_CHOICE:-1}"
echo

# -----------------------------------------------------------------------------
# Helper function: log one completed download
#   Uses global variables:
#     URL, OUTDIR, IS_PL, AUDIO_ONLY, AUDIO_MODE, QUALITY_LABEL
# -----------------------------------------------------------------------------
log_download() {
  local url="$URL"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"

  local mode type
  if [[ "${IS_PL}" == "y" || "${IS_PL}" == "Y" ]]; then
    mode="playlist"
  else
    mode="single"
  fi

  if [[ "$AUDIO_ONLY" -eq 1 ]]; then
    if [[ "$AUDIO_MODE" == "m4a" ]]; then
      type="audio:m4a"
    else
      type="audio:mp3:${QUALITY_LABEL}"
    fi
  else
    type="video:${QUALITY_LABEL}"
  fi

  local base_dir="${OUTDIR}/EasyVideoDL"
  mkdir -p "$base_dir"
  local log_file="${base_dir}/evd-log.txt"

  # Human-readable date, e.g. "December  7, 2025"
  local today_human
  today_human="$(date +"%B %e, %Y")"

  # Multi-line entry block for this download
  local entry_block
  printf -v entry_block '%s\nMODE=%s\nTYPE=%s\nOUT=%s\nURL=%s\n' \
    "[$ts]" "$mode" "$type" "$base_dir" "$url"

  # If log does not exist or is empty, create it with today's header and entry
  if [[ ! -s "$log_file" ]]; then
    {
      echo "# ================="
      echo "# ${today_human}"
      echo "# ================="
      echo
      echo "$entry_block"
      echo
    } > "$log_file"
    return
  fi

  # Log exists and is non-empty.
  # Invariant after every write:
  #   - Top date banner (today or latest day)
  #   - Its entries directly under it, newest first
  #   - Older days below, untouched

  local first_line
  first_line="$(sed -n '1p' "$log_file" 2>/dev/null || true)"

  local tmp
  tmp="$(mktemp)"

  # If the file somehow doesn't start with a header, just treat all as "old"
  # and prepend a fresh header + entry.
  if [[ "$first_line" != \#* ]]; then
    {
      echo "# ================="
      echo "# ${today_human}"
      echo "# ================="
      echo
      echo "$entry_block"
      echo
      cat "$log_file"
    } > "$tmp"
    mv "$tmp" "$log_file"
    return
  fi

  # Normal case: header is at the top
  local top_date_line top_date
  top_date_line="$(sed -n '2p' "$log_file" 2>/dev/null || true)"
  top_date="${top_date_line#\# }"   # strip leading "# " if present

  if [[ "$top_date" != "$today_human" ]]; then
    # New calendar day:
    # Put today's header + entry ABOVE the entire existing log.
    {
      echo "# ================="
      echo "# ${today_human}"
      echo "# ================="
      echo
      echo "$entry_block"
      echo
      cat "$log_file"
    } > "$tmp"
  else
    # Same day as current top section:
    #   - Keep header block (lines 1–4)
    #   - Insert new entry block + blank line
    #   - Append the rest (from line 5 onwards)
    {
      sed -n '1,4p' "$log_file"
      echo "$entry_block"
      echo
      sed -n '5,$p' "$log_file"
    } > "$tmp"
  fi

  mv "$tmp" "$log_file"
}

# -----------------------------------------------------------------------------
# Helper function: run one download based on already-set variables:
#   URL, COOKIES, OUTDIR, IS_PL, OVERWRITE_FLAG,
#   AUDIO_ONLY, AUDIO_MODE, FORMAT, QUALITY_LABEL, AUDIO_QUALITY_FLAGS
# -----------------------------------------------------------------------------
run_one_download() {
  local url="$URL"

  # Ensure base output folder exists
  mkdir -p "${OUTDIR}/EasyVideoDL"

  echo
  echo "Starting download..."
  echo

  if [[ "${IS_PL}" == "y" || "${IS_PL}" == "Y" ]]; then
    echo "Mode: Playlist download"

    if [[ "$AUDIO_ONLY" -eq 1 ]]; then
      if [[ "$AUDIO_MODE" == "mp3" ]]; then
        yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" --yes-playlist \
          -f "$FORMAT" \
          --extract-audio --audio-format mp3 "${AUDIO_QUALITY_FLAGS[@]}" \
          -o "${OUTDIR}/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s [${QUALITY_LABEL}].%(ext)s" \
          "$url"
      else
        # m4a mode (no suffix)
        yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" --yes-playlist \
          -f "$FORMAT" \
          --extract-audio --audio-format m4a \
          -o "${OUTDIR}/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s" \
          "$url"
      fi
    else
      yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" --yes-playlist \
        -f "$FORMAT" \
        -o "${OUTDIR}/EasyVideoDL/%(playlist_title)s/%(playlist_index)03d - %(title)s [${QUALITY_LABEL}].%(ext)s" \
        "$url"
    fi
  else
    echo "Mode: Single video download"

    if [[ "$AUDIO_ONLY" -eq 1 ]]; then
      if [[ "$AUDIO_MODE" == "mp3" ]]; then
        yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" \
          -f "$FORMAT" \
          --extract-audio --audio-format mp3 "${AUDIO_QUALITY_FLAGS[@]}" \
          -o "${OUTDIR}/EasyVideoDL/%(title)s [${QUALITY_LABEL}].%(ext)s" \
          "$url"
      else
        # m4a mode (no suffix)
        yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" \
          -f "$FORMAT" \
          --extract-audio --audio-format m4a \
          -o "${OUTDIR}/EasyVideoDL/%(title)s.%(ext)s" \
          "$url"
      fi
    else
      yt-dlp $OVERWRITE_FLAG --cookies "$COOKIES" \
        -f "$FORMAT" \
        -o "${OUTDIR}/EasyVideoDL/%(title)s [${QUALITY_LABEL}].%(ext)s" \
        "$url"
    fi
  fi

  echo
  echo "Download completed for URL:"
  echo "  $url"
  echo "Files saved to: $OUTDIR/EasyVideoDL"
  echo

  # --- Log this completed download in human-friendly format -----------------
  log_download
}

# =============================================================================
# MODE 2: BATCH FROM FILE
# =============================================================================
if [[ "$MODE_CHOICE" == "2" ]]; then
  DEFAULT_URL_FILE="$HOME/Downloads/evd-urls.txt"
  read -r -p "Path to URL list file [${DEFAULT_URL_FILE}]: " URL_FILE
  URL_FILE="${URL_FILE:-$DEFAULT_URL_FILE}"

  if [[ ! -f "$URL_FILE" ]]; then
    echo "Error: URL list file not found: $URL_FILE"
    exit 1
  fi

  # Cookies (once)
  DEFAULT_COOKIES="$HOME/Downloads/cookies.txt"
  read -r -p "Path to cookies.txt [${DEFAULT_COOKIES}]: " COOKIES
  COOKIES="${COOKIES:-$DEFAULT_COOKIES}"

  # Output folder (once)
  DEFAULT_OUT="$HOME/Downloads"
  read -r -p "Output folder [${DEFAULT_OUT}]: " OUTDIR
  OUTDIR="${OUTDIR:-$DEFAULT_OUT}"

  # Playlist flag for all URLs in this batch
  echo "Are these URLs playlists (courses with multiple videos)? [y/N]"
  read -r IS_PL

  # Overwrite / skip (once)
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

  # Quality choice (video vs audio-only) – once for whole batch
  echo "Choose quality for ALL URLs in this file:"
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
      echo "Choose audio quality (applies to all URLs):"
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

  echo
  echo "Reading URLs from: $URL_FILE"
  echo

  # Read URLs from file into an array (robust, macOS-friendly)
  URL_LIST=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    # Strip possible Windows-style carriage return at end of line
    line="${line%$'\r'}"

    # Skip empty / whitespace-only lines
    if [[ "$line" =~ ^[[:space:]]*$ ]]; then
      continue
    fi

    # Skip comment lines (starting with #, possibly after spaces)
    if [[ "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    URL_LIST+=("$line")
  done < "$URL_FILE"

  TOTAL=${#URL_LIST[@]}
  if [[ "$TOTAL" -eq 0 ]]; then
    echo "No valid URLs found in file (empty or only comments). Exiting."
    exit 1
  fi

  echo "Found $TOTAL URL(s) in the file."
  echo

  INDEX=1
  for u in "${URL_LIST[@]}"; do
    URL="$u"

    echo "-----------------------------------------------"
    echo " Downloading ($INDEX/$TOTAL):"
    echo "  $URL"
    echo "-----------------------------------------------"

    run_one_download
    INDEX=$((INDEX+1))
  done

  echo "All batch downloads finished."
  exit 0
fi

# =============================================================================
# MODE 1: INTERACTIVE (DEFAULT)
# =============================================================================

while true; do
  # 1) Ask for URL -----------------------------------------------------------
  read -r -p "Video or playlist URL (or press ENTER to quit): " URL
  if [[ -z "${URL}" ]]; then
    echo "No URL entered. Exiting EasyVideoDL."
    break
  fi

  # 2) cookies.txt path ------------------------------------------------------
  DEFAULT_COOKIES="$HOME/Downloads/cookies.txt"
  read -r -p "Path to cookies.txt [${DEFAULT_COOKIES}]: " COOKIES
  COOKIES="${COOKIES:-$DEFAULT_COOKIES}"

  # 3) Output folder ---------------------------------------------------------
  DEFAULT_OUT="$HOME/Downloads"
  read -r -p "Output folder [${DEFAULT_OUT}]: " OUTDIR
  OUTDIR="${OUTDIR:-$DEFAULT_OUT}"

  # 4) Playlist or single video? --------------------------------------------
  echo "Is this a playlist (course with multiple videos)? [y/N]"
  read -r IS_PL

  # 4.1) Overwrite or skip existing files? -----------------------------------
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

  # 5) Quality choice (video vs audio-only) ---------------------------------
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

  # Run one download with the current settings
  run_one_download

  # Ask if user wants another download
  read -r -p "Do you want to download another video? [y/N]: " AGAIN
  case "$AGAIN" in
    y|Y)
      echo
      echo "-----------------------------------------------"
      echo "Starting another download..."
      echo "-----------------------------------------------"
      echo
      ;;
    *)
      echo "Exiting EasyVideoDL. Goodbye."
      break
      ;;
  esac

done

echo
read -r -p "Press ENTER to close this window..." _