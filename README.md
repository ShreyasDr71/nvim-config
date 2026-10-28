# nvim-config

My AstroNvim v6 setup. I riced it to be beginner friendly, so it works well for someone learning the basics of programming in a terminal IDE.

## Features

- AstroNvim v6 base with a custom dashboard
- `F5` compiles and runs the current file (C, C++, Java, Python)
- `<Leader>rp` runs the current Python file in a terminal
- `<Leader>th` / `<Leader>tv` open a horizontal / vertical terminal in the file's directory
- Discord Rich Presence (cord.nvim), LSP signature hints

## Install (one step)

Each installer installs Neovim and all dependencies, backs up any existing config to `*.bak-<timestamp>`, clones this repo and syncs plugins.

### Linux (Kali / Debian / Ubuntu, Arch, Fedora)

```sh
curl -fsSL https://raw.githubusercontent.com/ShreyasDr71/nvim-config/master/install.sh | bash
```

On Kali, if `apt update` fails because the archive signing key was rotated (`NO_PUBKEY`, `EXPKEYSIG`, etc.), the script downloads the current keyring from `archive.kali.org` and retries.

### Windows 10/11 (PowerShell)

```powershell
irm https://raw.githubusercontent.com/ShreyasDr71/nvim-config/master/install.ps1 | iex
```

Requires `winget` (App Installer).

### After installing

Set your terminal font to **JetBrainsMono Nerd Font** (installed by the script), open a new terminal and run `nvim`.

Java is not installed automatically. Install a JDK if you want `F5` to work for `.java` files.
