# Seer Scripts

**A collection of CLI “spells” for power users, sysadmins, and curious hackers.**
Analyze files, inspect processes, query packages, and probe your LAN—right from your terminal.

---
![Seer Suite demo](seer-suit.gif)


## 🚀 What’s Inside

* **file-seer.sh** — Deep-dive file inspection: type, stat, ACLs, attributes, hexdump, hashes, metadata, and more.
* **proc-seer.sh** — Process sleuthing: find, filter, trace, and examine system processes.
* **pkg-seer.sh** — Explore and search installed packages (supports common Linux/BSD package managers).
* **lan-seer.sh** — Network and LAN explorer: interfaces, connections, targets, routes, and more.

*All scripts use a shared set of helpers in **dotlib.sh** (see below for usage).*

---

## 🛠️ Quick Start

1. Clone/download all scripts (and `dotlib.sh`) into a directory.
2. Make them executable:
   `chmod +x *.sh`

---

## Usage

Below are the basic usage patterns for each script.

### `file-seer.sh`

```sh
./file-seer.sh <command> <file>

# Commands:
#   inspect <file>   — Detailed info, metadata, stat, hashes, etc.
#   hex <file>       — Hexdump view (uses xxd/hexdump).
#   strings <file>   — Print printable strings in file.
#   perms <file>     — Show permissions, ACLs, and extended attributes.
#   help             — Show help.
```

---

### `proc-seer.sh`

```sh
./proc-seer.sh <command> [args]

# Commands:
#   search <pattern>         — Find processes by name/pattern.
#   info <pid>               — Show detailed info for PID.
#   tree                     — Show process tree.
#   ports                    — Show processes with open network ports.
#   help                     — Show help.
```

---

### `pkg-seer.sh`

```sh
./pkg-seer.sh <command> <pattern>

# Commands:
#   find <name>    — Search for package by name.
#   info <name>    — Show info/details for package.
#   list           — List all installed packages.
#   help           — Show help.
```

---

### `lan-seer.sh`

```sh
./lan-seer.sh [target]

# Targets:
#   (none)            — Show LAN overview (interfaces, DNS, routes, etc.)
#   <ip>              — Analyze a specific IP.
#   <hostname>        — Analyze a specific host.
#   :<port>           — Check a local/remote port.
#   --from <host>     — Run remotely via SSH.
#   help              — Show help.
```

---

## 🧰 Dotlib Integration

Seer scripts rely on `dotlib.sh` for shared helpers.
**The scripts automatically check:**

* If the `DOTFILES` environment variable is set, they use `$DOTFILES/bash/dotlib.sh`.
* Otherwise, they look for `dotlib.sh` in the current directory.

If you’re developing or running outside your dotfiles setup, just keep a copy of `dotlib.sh` with your scripts.

---

## Philosophy

Unix is beautiful.

This project was based on a forensics script I wrote for work called maxinfo. The idea was to bring together a number of commands into one detailed but friendly report format. I use these tools regularly now but I'm always polishing and refining them. Please let me know if you find any issues or can think of any improvements. 


---

## 📦 License

MIT License — see [LICENSE](./LICENSE) for details.
Copyright (c) 2025 forfaxx / Kevin Joiner

---

## 🙋‍♂️ Contributions & Feedback

Ideas, bugfixes, suggestions, and issue reports are always welcome!
Feel free to fork, PR, or [open an issue](https://github.com/forfaxx/seer-scripts/issues) 

---

## 🏴‍☠️ See also

* [More tools & guides](https://github.com/forfaxx/)

 **Happy hacking!**

