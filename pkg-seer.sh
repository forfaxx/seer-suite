#!/usr/bin/env bash
# package_seer.sh — Inspect installed packages and related files 📦

# === SETUP ===
set -euo pipefail
trap 'echo -e "\n💥 Script failed at line $LINENO." >&2' ERR

DOTLIB="$HOME/codelab/dotfiles/bash/dotlib.sh"
if [[ -f "$DOTLIB" ]]; then
  source "$DOTLIB"
else
  echo "⚠️  Missing dotlib: $DOTLIB" >&2
  exit 1
fi

platform="$(get_platform)"
package="${1:-}"

if [[ -z "$package" && ! -t 0 ]]; then
  log_warn "⚠️  Input was piped but no argument was given. Ignoring STDIN."
fi

echo -e "🧙‍♂️ Package Seer Activated"
divider

# === HOLISTIC VIEW MODE (NO ARGUMENTS) ===
if [[ -z "$package" ]]; then
  echo -e "🧾 No package specified — showing system package overview..."
  newline

  if is_linux && check_tool dpkg; then
    pkg_count=$(dpkg -l | grep '^ii' | wc -l || true)
    arch=$(dpkg --print-architecture || true)
    apt_version=$(apt --version | head -n1 || true)
    cache_size=$(du -sh /var/cache/apt/archives 2>/dev/null | awk '{print $1}' || true)

    echo -e "📦 Installed packages: ${DOT_COLOR_GREEN}$pkg_count${DOT_COLOR_RESET}"
    echo -e "🧱 Architecture: $arch"
    echo -e "🛠️  APT version: $apt_version"
    echo -e "💾 APT cache size: $cache_size"
    newline

    echo -e "⬇️  Packages pending upgrade:"
    if apt list --upgradeable &>/dev/null; then
      pending=$(apt list --upgradeable 2>/dev/null | grep -c 'upgradable' || true)
      if [[ "$pending" -eq 0 ]]; then
        echo " • System is up to date"
      else
        apt list --upgradeable 2>/dev/null | grep -v "^Listing" | head -n 5 | sed 's/^/ • /'
        [[ "$pending" -gt 5 ]] && echo " • ...and $((pending - 5)) more"
      fi
    else
      echo " • Unable to fetch upgrade list"
    fi
    newline

    # ──────────────────────────────────────────
    # APT HISTORY: Recently installed packages
    echo -e "🧠 Recently installed (explicitly via apt install):"

    log_files=(/var/log/apt/history.log /var/log/apt/history.log.* /var/log/apt/history.log.*.gz)

    available_logs=()
    for f in "${log_files[@]}"; do
      [[ -f "$f" ]] && available_logs+=("$f")
    done

    if [[ ${#available_logs[@]} -eq 0 ]]; then
      echo " • No APT history logs found"
    else
      zgrep -h 'Commandline: apt install' "${available_logs[@]}" 2>/dev/null | \
        grep -oP 'install\s+\K[^:]*' | \
        awk '{print $1}' | \
        sort | uniq | tail -n 10 | sed 's/^/ • /' || echo " • No recent installs found"
    fi

    divider
    exit 0

  elif is_macos && check_tool brew; then
    pkg_count=$(brew list --formula | wc -l || true)
    brew_ver=$(brew --version | head -n1 || true)
    cache_size=$(du -sh "$(brew --cache)" 2>/dev/null | awk '{print $1}' || true)

    echo -e "🍺 Brew packages: ${DOT_COLOR_GREEN}$pkg_count${DOT_COLOR_RESET}"
    echo -e "🛠️  Brew version: $brew_ver"
    echo -e "💾 Cache size: $cache_size"
    newline

    echo -e "⬇️  Packages pending upgrade:"
    outdated=$(brew outdated --formula || true)
    if [[ -z "$outdated" ]]; then
      echo " • Everything is current"
    else
      echo "$outdated" | head -n 5 | sed 's/^/ • /'
      echo "$outdated" | wc -l | awk '{ if ($1 > 5) print " • ...and " $1 - 5 " more" }'
    fi
    newline

    echo -e "🧠 Recently installed formulae:"
    ls -lt /usr/local/Cellar 2>/dev/null | grep '^d' | head -n 10 | awk '{print " • " $9}'

    divider
    exit 0

  else
    log_error "Unsupported system or missing package manager"
    exit 1
  fi
fi

# === INDIVIDUAL PACKAGE VIEW (ARGUMENT GIVEN) ===
echo -e "🔍 Searching for: ${DOT_COLOR_CYAN}$package${DOT_COLOR_RESET}"

if is_linux && check_tool dpkg && check_tool apt; then
  if dpkg -s "$package" &>/dev/null; then
    echo -e "✅ Package '$package' is installed"
    newline

    apt_info="$(apt show "$package" 2>/dev/null)"

    version=$(echo "$apt_info" | awk -F': ' '/^Version:/ {print $2}')
    section=$(echo "$apt_info" | awk -F': ' '/^Section:/ {print $2}')
    priority=$(echo "$apt_info" | awk -F': ' '/^Priority:/ {print $2}')
    maintainer=$(echo "$apt_info" | awk -F': ' '/^Maintainer:/ {print $2}')
    homepage=$(echo "$apt_info" | awk -F': ' '/^Homepage:/ {print $2}')
    installed_size_kb=$(echo "$apt_info" | awk -F': ' '/^Installed-Size:/ {print $2}')
    depends=$(echo "$apt_info" | awk -F': ' '/^Depends:/ {print $2}')
    suggests=$(echo "$apt_info" | awk -F': ' '/^Suggests:/ {print $2}')
    source=$(echo "$apt_info" | awk -F': ' '/^APT-Sources:/ {print $2}')
    size_mb=""

    if [[ "$installed_size_kb" =~ ^[0-9]+$ ]]; then
      size_mb=$(awk "BEGIN { printf \"%.1f\", $installed_size_kb / 1024 }")
    fi

    echo -e "🧾 Summary:"
    echo -e " • Version:      ${DOT_COLOR_GREEN}$version${DOT_COLOR_RESET}"
    echo -e " • Section:      $section"
    echo -e " • Priority:     $priority"
    echo -e " • Maintainer:   $maintainer"
    [[ -n "$homepage" ]] && echo -e " • Homepage:     $homepage"
    [[ -n "$source" ]] && echo -e " • Source:       $source"
    [[ -n "$size_mb" ]] && echo -e " • Size:         ${DOT_COLOR_GREEN}${size_mb} MB${DOT_COLOR_RESET}"
    newline 
    [[ -n "$depends" ]] && echo -e " • Depends:      $depends"
    newline
    [[ -n "$installed_size_kb" ]] && echo -e " • Installed Size: ${DOT_COLOR_GREEN}${installed_size_kb} KB${DOT_COLOR_RESET}"
    [[ -n "$suggests" ]] && echo -e " • Suggests:     $suggests"
    newline

    echo "$apt_info" | awk '
      /^Description:/ {
      gsub(/^Description: /, "")
      printf "📘 Description: %s\n", $0
      desc = 1
      next
    }
      /^[A-Z][^:]*:/ { desc = 0 }
      desc { print }
    '

    newline

    echo -e "🔗 Executables installed by '$package':"
    dpkg -L "$package" | grep -E '^(/usr|/bin|/sbin|/lib)' | while read -r path; do
      if [[ -x "$path" && ! -d "$path" ]]; then
        echo " • $path"
      fi
    done
    newline

    echo -e "🧭 Resolved Commands on PATH:"
    {
      dpkg -L "$package" | while read -r path; do
        if [[ -x "$path" && ! -d "$path" ]]; then
          cmd="$(basename "$path")"
          resolved=$(command -v "$cmd" 2>/dev/null || true)
          [[ -n "$resolved" ]] && echo " • $resolved"
        fi
      done
    } | sort -u

  else
    log_warn "Package '$package' not installed — searching..."
    apt-cache search "$package" | grep -i "$package" | head -n 10 || true
    exit 1
  fi

elif is_macos && check_tool brew; then
  if brew list --formula | grep -qx "$package"; then
    echo -e "✅ Package '$package' is installed via Homebrew"
    newline

    echo -e "🧾 Package summary:"
    brew info "$package"
    newline

    echo -e "🔗 Installed files:"
    brew list --verbose "$package"
    newline

    echo -e "🧭 Resolved Commands on PATH:"
    {
      brew list "$package" | while read -r path; do
        if [[ -x "$path" && ! -d "$path" ]]; then
          cmd="$(basename "$path")"
          resolved=$(command -v "$cmd" 2>/dev/null || true)
          [[ -n "$resolved" ]] && echo " • $resolved"
        fi
      done
    } | sort -u

  else
    log_warn "Package '$package' not installed — searching..."
    brew search "$package" | head -n 10 || true
    exit 1
  fi

else
  log_error "Unsupported platform or missing tools"
  exit 1
fi

divider
