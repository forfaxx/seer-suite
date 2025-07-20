#!/usr/bin/env bash
# proc_seer.sh — Inspect running processes or view holistic system process state 🔎

# === SETUP LOGIC ===
set -euo pipefail
trap 'echo -e "\n💥 Script failed at line $LINENO." >&2' ERR

DOTLIB="$HOME/codelab/dotfiles/bash/dotlib.sh"
[[ -f "$DOTLIB" ]] && source "$DOTLIB" || {
  echo "⚠️  Missing dotlib: $DOTLIB" >&2
  exit 1
}

# === ARGUMENT PARSING & HELP ===

show_help() {
  cat <<EOF
Usage: $(basename "$0") [PID]

Examples:
  $(basename "$0")         # Show overview of top processes and system usage
  $(basename "$0") 1234    # Show detailed info for process with PID 1234

Options:
  -h, --help               Show this help message

EOF
  exit 0
}

# Handle --help
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && show_help


# === MAIN LOGIC ===

platform="$(get_platform)"
target="${1:-}"

echo -e "🧙 Process Seer Activated"
divider

# === HOLISTIC SYSTEM VIEW (no argument) ===
if [[ -z "$target" ]]; then
  echo -e "🧾 No target specified — showing system process overview..."
  newline

  echo -e "📊 Load and process stats:"
  uptime
  newline

  echo -e "🔝 Top 5 CPU-consuming processes:"
  ps -eo pid,ppid,user,%cpu,%mem,etime,args --sort=-%cpu | head -n 6
  newline

  echo -e "🧠 Top 5 memory-consuming processes:"
  ps -eo pid,ppid,user,%mem,%cpu,etime,args --sort=-%mem | head -n 6
  newline

  echo -e "🧟 Zombie processes:"
  ps -eo pid,ppid,state,args | grep '[Zz]' || echo " • None detected"
  newline

  echo -e "🧍 Active user processes:"
  who | awk '{print " • " $1 " logged in since " $3 " " $4}'
  newline

  divider
  exit 0
fi

# === FOCUSED PROCESS INSPECTION (by PID or name) ===
if [[ "$target" =~ ^[0-9]+$ ]]; then
  pid="$target"
else
  pid=$(pgrep -n "$target" 2>/dev/null || true)
  if [[ -z "$pid" ]]; then
    log_error "No process found matching: $target"
    exit 1
  fi
fi

log_info "🔎 Inspecting process: PID $pid"
newline

# === SECTION: Basic Info ===
print_section "🧬 Basic info (ps):"
if ps -p "$pid" -o pid,ppid,user,%cpu,%mem,lstart,etime,args; then
  true
else
  echo " • Process not found (may have exited)"
  exit 1
fi
newline

# === SECTION: Open Files ===
print_section "📂 Open files (lsof):"
if command_exists lsof; then
  if lsof -p "$pid" 2>/dev/null | head -n 15; then
    true
  else
    echo " • No open files or access denied"
  fi
else
  echo " • lsof not available"
fi
newline

# === SECTION: Threads ===
print_section "🧵 Threads:"
if ps -L -p "$pid" &>/dev/null; then
  ps -L -p "$pid"
else
  echo " • Thread info unavailable"
fi
newline

# === SECTION: Network Connections (optional) ===
if command_exists ss; then
  print_section "🌐 Network Sockets:"
  ss -p | grep "$pid" || echo " • No network sockets associated with PID $pid"
  newline
fi

divider
