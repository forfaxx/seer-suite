#!/usr/bin/env bash
# lan_seer.sh — Inspect and analyze network targets 🛰

set -euo pipefail
trap 'echo -e "\n💥 Script failed at line $LINENO." >&2' ERR

# ─── Load dotlib for helpers ───────────────────────────────────────────────
if [[ -n "${DOTFILES:-}" && -f "$DOTFILES/bash/dotlib.sh" ]]; then
  source "$DOTFILES/bash/dotlib.sh"
elif [[ -f ./dotlib.sh ]]; then
  source ./dotlib.sh
else
  echo "⚠️  Could not find dotlib.sh (tried \$DOTFILES/bash/dotlib.sh and ./dotlib.sh)" >&2
  exit 1
fi


# ─── Platform & Arg Setup ───────────────────────────────────────────────────
platform="$(get_platform)"
target="${1:-}"
shift || true

echo -e "🧙 LAN Seer Activated"
divider

# ─── Remote execution stub (via SSH) ────────────────────────────────────────
if [[ "$target" == "--from" && -n "${1:-}" ]]; then
  remote_host="$1"
  shift
  echo "🔗 Executing lan_seer remotely on $remote_host..."
  ssh "$remote_host" "~/bin/lan_seer.sh $*"
  exit $?
fi

# ─── No argument: local overview ────────────────────────────────────────────
if [[ -z "$target" ]]; then
  echo "📡 No target provided — showing LAN overview (local perspective)"
  newline

  # Show interfaces
  print_section "📶 Interfaces:"
  if [[ "$platform" == "darwin" ]]; then
    ifconfig | grep -E "^(en|lo)" | cut -d: -f1 | xargs -I{} ifconfig {} | grep -E "^(en|lo)|inet "
  else
    ip -brief address show || echo "(no interface info)"
  fi
  newline

  # Show active connections
  print_section "🔌 Active Connections:"
  if command_exists ss; then
    ss -tunap | head -n 10
  elif command_exists netstat; then
    netstat -tunap | head -n 10
  else
    echo "(no socket tool found)"
  fi
  newline

  # Show DNS
  print_section "📨 Resolvers:"
  grep nameserver /etc/resolv.conf || echo "(no resolv.conf)"
  newline

  # Show gateway
  print_section "🚦 Default Route:"
  ip route | grep default || echo "(no default route)"
  newline

  divider
  exit 0
fi

# ─── IP address target ──────────────────────────────────────────────────────
if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  print_section "🛰 Analyzing IP: $target"

  echo -e "🌐 Ping test:"
  ping -c 1 -W 1 "$target" && ok "Ping successful" || fail "No ping response"
  newline

  echo -e "🔁 Reverse DNS:"
  host "$target" || echo "(no PTR record)"
  newline

  echo -e "🔍 Who owns this IP? (optional whois):"
  if command_exists whois; then
    whois "$target" | head -n 10
  else
    echo "(whois not available)"
  fi
  divider
  exit 0
fi

# ─── Port target (like :22) ─────────────────────────────────────────────────
if [[ "$target" =~ ^:[0-9]+$ ]]; then
  port="${target#:}"
  print_section "🔌 Port Analysis: $port"

  echo -e "🔍 Locally listening?"
  if command_exists ss; then
    ss -tunlp | grep ":$port " || echo " • No local listener"
  elif command_exists lsof; then
    sudo lsof -iTCP -sTCP:LISTEN -n -P | grep ":$port" || echo " • Not found"
  fi
  newline

  echo -e "🌐 Remote scan via nc:"
  nc -zv 127.0.0.1 "$port" 2>&1 || echo " • Port closed"
  divider
  exit 0
fi

# ─── Hostname or service name ───────────────────────────────────────────────
print_section "🌍 Target: $target"

# DNS Resolution
echo -e "📡 DNS lookup:"
host "$target" || echo "(unresolved)"
newline

# Traceroute (optional)
if command_exists traceroute; then
  print_section "🧭 Traceroute:"
  traceroute "$target" | head -n 10
  newline
fi

# Web headers if applicable
if [[ "$target" =~ \. ]]; then
  print_section "📬 HTTP HEAD request (if reachable):"
  curl -Is "http://$target" | head -n 10 || echo "(HTTP not reachable)"
  newline
fi

divider
