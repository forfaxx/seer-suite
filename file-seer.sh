#!/usr/bin/env bash
# file_seer.sh — A file analysis spellbook for CLI wizards 🔍

set -euo pipefail

if [[ -n "${DOTFILES:-}" && -f "$DOTFILES/bash/dotlib.sh" ]]; then
  source "$DOTFILES/bash/dotlib.sh"
elif [[ -f ./dotlib.sh ]]; then
  source ./dotlib.sh
else
  echo "⚠️  Could not find dotlib.sh (tried \$DOTFILES/bash/dotlib.sh and ./dotlib.sh)" >&2
  exit 1
fi


# ─────────────────────────────────────────────
# 📘 USAGE
usage() {
  cat <<EOF
Usage: file_seer.sh <mode> <file>

Modes:
  inspect     Basic file info, stat, ACLs, and xattrs
  hex         Hexdump (via xxd or hexdump)
  hash        MD5/SHA-256 checksums
  strings     Print ASCII strings
  elf         ELF binary details (readelf, nm, ldd)
  meta        Metadata (exiftool, mediainfo, or mdls)
  binwalk     Run binwalk if available
  open        Show open file handles
  all         Run all analyses

EOF
  exit 1
}

# ─────────────────────────────────────────────
# 📦 PLATFORM + ARGS
platform="$(get_platform)"

[[ $# -lt 2 ]] && usage

mode="$1"
file="$2"

[[ ! -e "$file" ]] && echo "❌ File not found: $file" && exit 1

# ─────────────────────────────────────────────
# 🧙 BANNER (only on top-level call)
: "${FILE_SEER_MODE:=normal}"
if [[ "$FILE_SEER_MODE" == "normal" ]]; then
  echo -e "🧙‍♂️ File Seer Activated"
  divider
fi

# ─────────────────────────────────────────────
# 🧪 MODE HANDLER
case "$mode" in
  inspect)
    echo "📂 File Type:"
    file "$file"
    divider

    echo "🧾 File Stat:"
    stat "$file"
    divider

    echo "🔒 ACLs:"
    if [[ "$platform" == "darwin" ]]; then
      ls -led@ "$file"
    else
      if command_exists getfacl; then
        getfacl "$file"
      else
        echo "(getfacl not available — try: sudo apt install attr)"
      fi
    fi
    divider

    echo "📛 Extended Attributes:"
    if [[ "$platform" == "darwin" ]]; then
      xattr "$file" || echo "(no xattrs)"
    else
      if command_exists getfattr; then
        getfattr -d "$file" || echo "(no xattrs)"
      else
        echo "(getfattr not available — try: sudo apt install attr)"
      fi
    fi
    divider
    ;;

  hex)
    echo "🔢 Hexdump:"
    if command_exists xxd; then
      xxd "$file"
    elif command_exists hexdump; then
      hexdump -C "$file"
    else
      echo "❌ No hex tool available (xxd or hexdump)"
    fi
    divider
    ;;

  hash)
    echo "🔐 Hashes:"
    if command_exists md5sum; then
      md5sum "$file"
    elif command_exists md5; then
      md5 "$file"
    fi

    if command_exists sha256sum; then
      sha256sum "$file"
    elif command_exists shasum; then
      shasum -a 256 "$file"
    else
      echo "❌ No SHA tool available"
    fi
    divider
    ;;

  strings)
    require strings && echo "🧵 Strings:"
    strings "$file" | head -n 40
    divider
    ;;

  elf)
    echo "🔧 ELF/Binary Analysis:"
    if command_exists readelf; then
      readelf -h "$file"
    else
      echo "readelf not available"
    fi

    if command_exists nm; then
      nm "$file"
    else
      echo "nm not available"
    fi

    if command_exists ldd; then
      ldd "$file"
    else
      echo "ldd not available"
    fi
    divider
    ;;

  meta)
    echo "🧠 Metadata:"
    if [[ "$platform" == "darwin" ]]; then
      mdls "$file"
    else
      if command_exists exiftool; then
        exiftool "$file"
      elif command_exists mediainfo; then
        mediainfo "$file"
      else
        echo "No metadata tool found (exiftool or mediainfo)"
      fi
    fi
    divider
    ;;

  binwalk)
    if require binwalk; then
      echo "🧨 Binwalk:"
      binwalk "$file"
    fi
    divider
    ;;

  open)
    echo "🔎 Open File Handles:"
    if command_exists lsof; then
      timeout 2s lsof "$file" || echo "(no open handles or lsof timed out)"
    elif command_exists fuser; then
      fuser -v "$file" || echo "(no open handles)"
    else
      echo "(no open handle tool found — install lsof or fuser)"
    fi
    divider
    ;;

  all)
    FILE_SEER_MODE=sub "$0" inspect "$file"
    FILE_SEER_MODE=sub "$0" open "$file"
    FILE_SEER_MODE=sub "$0" hash "$file"
    FILE_SEER_MODE=sub "$0" strings "$file"
    FILE_SEER_MODE=sub "$0" hex "$file" | head -n 40
    [[ "$platform" != "darwin" ]] && FILE_SEER_MODE=sub "$0" elf "$file"
    FILE_SEER_MODE=sub "$0" meta "$file"
    ;;

  *)
    usage
    ;;
esac
