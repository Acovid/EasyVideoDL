#!/bin/bash

# =============================================================================
# EasyVideoDL macOS Launcher (.command)
# -----------------------------------------------------------------------------
# - Can be double-clicked from Finder
# - Works even if moved or symlinked (path-agnostic)
# - Sets a custom Terminal title and shows a friendly banner
# - Runs run-evd.sh in the correct project folder
# =============================================================================

# 1) Resolve alias/symlink to find the real script folder
SCRIPT_PATH="$0"
while [ -L "$SCRIPT_PATH" ]; do
  TARGET="$(readlink "$SCRIPT_PATH")"
  if [[ "$TARGET" == /* ]]; then
    SCRIPT_PATH="$TARGET"
  else
    SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
    SCRIPT_PATH="$SCRIPT_DIR/$TARGET"
  fi
done

PROJECT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# 2) Set a custom Terminal window title (tab title)
printf '\033]0;EasyVideoDL\007'

# 3) Welcome banner
echo
echo "=============================================="
echo "            EasyVideoDL Launcher"
echo "=============================================="
echo " Project directory:"
echo "   $PROJECT_DIR"
echo
echo " This tool will:"
echo "   - Ask you for a video or playlist URL"
echo "   - Use cookies.txt for login-protected sites"
echo "   - Let you pick video or audio quality"
echo "   - Save everything under:"
echo "       ~/Downloads/EasyVideoDL/"
echo "=============================================="
echo

# 4) Switch to project directory
cd "$PROJECT_DIR" || {
  echo "Error: Could not cd to project directory: $PROJECT_DIR"
  echo
  read -r -p "Press ENTER to close this window..." _
  exit 1
}

# 5) Ensure run-evd.sh is executable
if [ ! -x "./run-evd.sh" ]; then
  if [ -f "./run-evd.sh" ]; then
    chmod +x ./run-evd.sh
  else
    echo "Error: run-evd.sh not found in:"
    echo "  $PROJECT_DIR"
    echo
    read -r -p "Press ENTER to close this window..." _
    exit 1
  fi
fi

# 6) Hand over completely to run-evd.sh in THIS SAME WINDOW
#    `exec` replaces this shell with run-evd.sh, so there is only one process.
exec ./run-evd.sh

# If exec fails for some reason, we end up here:
STATUS=$?
echo
echo "=============================================="
echo " EasyVideoDL finished with exit status: $STATUS"
echo "=============================================="
echo
read -r -p "Press ENTER to close this window..." _