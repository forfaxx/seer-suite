# ─────────────────────────────────────────────
# 📎 dotlib.sh – Shared utilities for dotlib scripts
# ─────────────────────────────────────────────

# Convenient color codes. make sure to terminate strings with DOT_COLOR_RESET to avoid borking the shell. 
# ❌ Don't use this in PS1 — lacks required escape sequences. fine in scripts.

# Control codes 
DOT_COLOR_RESET="\033[0m"
DOT_COLOR_BOLD="\033[1m"
DOT_COLOR_DIM="\033[2m"

# Color codes
DOT_COLOR_RED="\033[1;31m"
DOT_COLOR_GREEN="\033[1;32m"
DOT_COLOR_YELLOW="\033[1;33m"
DOT_COLOR_BLUE="\033[1;34m"
DOT_COLOR_MAGENTA="\033[1;35m"
DOT_COLOR_CYAN="\033[1;36m"
DOT_COLOR_GRAY="\033[1;90m"




# Sanity / error checking
# ────────────────────────────────────────────────────────────────
# call when a tool must exist before continuing. require exiftool || exit 1
require() {
  command -v "$1" >/dev/null || {
    echo "⚠️  Missing required tool: $1" >&2
    return 1
  }
}


# checks if a command is available without existing. if command_exists logger; then ... 
command_exists() {
  command -v "$1" >/dev/null 2>&1
}


# use when multiple tools are available and you want the first one found
first_available() {
  for cmd in "$@"; do
    if command_exists "$cmd"; then
      echo "$cmd"
      return 0
    fi
  done
  return 1
}


# Output & UX
# ────────────────────────────────────────────────────────────────

# Draw a visual divider
divider() {
  echo -e "\n\033[1;90m────────────────────────────────────────────\033[0m\n"
}

# Print a visual break (just a blank line)
newline() {
  echo ""
}

print_section() {
  local title="$1"
  echo -e "\n\033[1;94m$title\033[0m"
}

# Check if a tool exists, with optional fallback message
check_tool() {
  local tool="$1"
  local fallback="${2:-}"
  if command_exists "$tool"; then
    return 0
  else
    echo -e "❌ ${DOT_COLOR_YELLOW}$tool${DOT_COLOR_RESET} not available${fallback:+ — $fallback}"
    return 1
  fi
}

# Cross platform notification routine. 
# Usage: notify "title" "message" 
notify() {
  local title="${1:-"Notification"}"
  local message="${2:-}"
  # macOS
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$message\" with title \"$title\""
  # WSL: Detect *first* before generic Linux!
  elif grep -qi microsoft /proc/version 2>/dev/null && command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "Import-Module BurntToast; New-BurntToastNotification -Text \"${title}\", \"${message}\""
  # Linux/Unix with notify-send
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$message"
  # Windows native Git Bash, msg.exe
  elif command -v msg.exe >/dev/null 2>&1; then
    msg.exe * "$title: $message"
  # Fallback to wall
  elif command -v wall >/dev/null 2>&1; then
    echo "$title: $message" | wall
  else
    echo "$title: $message"
  fi
}


# Logging functions
# ────────────────────────────────────────────────────────────────

# debug messages will only print if DOTLIB_DEBUG=1
log_debug() { [[ "${DOTLIB_DEBUG:-0}" == 1 ]] && echo "🔧 DEBUG: $*"; }
# info, warn and error messages always print 
log_info()  { echo -e "ℹ️  $*"; }
log_warn()  { echo -e "⚠️  $*" >&2; }
log_error() { echo -e "❌ $*" >&2; }

# log to system journal if available
log_to_journal() {
  local tag="${1:-dotlib}"
  local msg="$2"
  if command_exists logger; then
    logger -t "$tag" "$msg"
  fi
}


# Platform checks
# ────────────────────────────────────────────────────────────────

# Detect current platform as lowercase string
get_platform() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

# True if running on macOS
is_macos() {
  [[ "$(uname -s)" == "Darwin" ]]
}

# True if running on Linux
is_linux() {
  [[ "$(uname -s)" == "Linux" ]]
}

# Misc utilities

# Check if running in an interactive shell
is_interactive() {
  [[ -t 0 && -t 1 ]]
}

# Check if running in a non-interactive shell
is_ssh_session() {
  [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" ]]
}

# check if running as a cron job. no prompt, no ssh tty, no display and not a terminal. 
is_cron_job() {
  [[ -z "${PS1:-}" && -z "${SSH_TTY:-}" && -z "${DISPLAY:-}" && ! -t 0 ]]
}

has_tty() {
  [[ -t 0 || -t 1 || -t 2 ]]
}


#
is_vowel() {
  [[ "$1" =~ [aeiouAEIOU] ]]
}

