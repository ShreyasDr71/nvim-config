#!/usr/bin/env bash
# One-step installer for this Neovim config on Linux (Kali / Debian / Ubuntu, with Arch and Fedora fallbacks).
#   curl -fsSL https://raw.githubusercontent.com/ShreyasDr71/nvim-config/master/install.sh | bash
set -euo pipefail

REPO="https://github.com/ShreyasDr71/nvim-config.git"
NVIM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
BIN_DIR="$HOME/.local/bin"
KALI_KEYRING_URL="https://archive.kali.org/archive-keyring.gpg"
KALI_KEYRING="/usr/share/keyrings/kali-archive-keyring.gpg"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"
if [ -n "$SUDO" ] && ! command -v sudo >/dev/null; then die "sudo is required (or run as root)"; fi

is_kali() { grep -qi '^ID=kali' /etc/os-release 2>/dev/null; }

fetch() { # fetch URL DEST
  if command -v curl >/dev/null; then curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null; then wget -qO "$2" "$1"
  else die "need curl or wget"; fi
}

# Kali rotates its archive signing key; an outdated kali-archive-keyring makes `apt update` fail with
# NO_PUBKEY / EXPKEYSIG / "not signed". Pull the current keyring straight from archive.kali.org and retry.
fix_kali_keyring() {
  warn "apt signature check failed - refreshing the Kali archive keyring"
  local tmp; tmp="$(mktemp)"
  fetch "$KALI_KEYRING_URL" "$tmp" || die "could not download $KALI_KEYRING_URL"
  $SUDO install -m 0644 "$tmp" "$KALI_KEYRING"
  rm -f "$tmp"
  # Older installs may also reference the legacy trusted.gpg.d location.
  [ -d /etc/apt/trusted.gpg.d ] && $SUDO install -m 0644 "$KALI_KEYRING" /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg
}

apt_update() {
  local log; log="$(mktemp)"
  if $SUDO apt-get update 2>&1 | tee "$log" && ! grep -qE 'NO_PUBKEY|EXPKEYSIG|KEYEXPIRED|is not signed|invalid signature|BADSIG' "$log"; then
    rm -f "$log"; return 0
  fi
  if is_kali && grep -qE 'NO_PUBKEY|EXPKEYSIG|KEYEXPIRED|is not signed|invalid signature|BADSIG' "$log"; then
    rm -f "$log"
    fix_kali_keyring
    $SUDO apt-get update || die "apt-get update still failing after keyring refresh"
    # Pull the packaged keyring too so future key rotations are handled by apt itself.
    $SUDO apt-get install -y kali-archive-keyring || true
    return 0
  fi
  rm -f "$log"
  die "apt-get update failed"
}

install_deps() {
  info "Installing dependencies"
  if command -v apt-get >/dev/null; then
    apt_update
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y \
      git curl wget unzip tar gzip build-essential ripgrep fd-find xclip \
      python3 python3-pip python3-venv nodejs npm fontconfig
    # Debian ships fd as fdfind
    if ! command -v fd >/dev/null && command -v fdfind >/dev/null; then
      mkdir -p "$BIN_DIR"; ln -sf "$(command -v fdfind)" "$BIN_DIR/fd"
    fi
  elif command -v pacman >/dev/null; then
    $SUDO pacman -Sy --needed --noconfirm git curl wget unzip tar gzip base-devel ripgrep fd xclip python python-pip nodejs npm fontconfig
  elif command -v dnf >/dev/null; then
    $SUDO dnf install -y git curl wget unzip tar gzip gcc gcc-c++ make ripgrep fd-find xclip python3 python3-pip nodejs npm fontconfig
  else
    die "unsupported package manager - install git, gcc, ripgrep, fd, node and python3 manually"
  fi
}

arch_name() {
  case "$(uname -m)" in
    x86_64|amd64) echo x86_64 ;;
    aarch64|arm64) echo arm64 ;;
    *) die "unsupported CPU architecture: $(uname -m)" ;;
  esac
}

# Distro packages lag behind; AstroNvim v6 needs a recent Neovim, so use the official release build.
install_neovim() {
  local arch; arch="$(arch_name)"
  info "Installing latest stable Neovim ($arch) to /opt/nvim"
  local tmp; tmp="$(mktemp -d)"
  fetch "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch}.tar.gz" "$tmp/nvim.tar.gz"
  tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
  $SUDO rm -rf /opt/nvim
  $SUDO mv "$tmp/nvim-linux-${arch}" /opt/nvim
  $SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  rm -rf "$tmp"
}

# nvim-treesitter (main branch) compiles parsers with the tree-sitter CLI.
install_tree_sitter() {
  local arch; case "$(arch_name)" in x86_64) arch=x64 ;; arm64) arch=arm64 ;; esac
  info "Installing tree-sitter CLI to $BIN_DIR"
  mkdir -p "$BIN_DIR"
  local tmp; tmp="$(mktemp)"
  fetch "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-${arch}.gz" "$tmp"
  gunzip -c "$tmp" > "$BIN_DIR/tree-sitter"
  chmod +x "$BIN_DIR/tree-sitter"
  rm -f "$tmp"
}

install_font() {
  if fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd'; then return 0; fi
  info "Installing JetBrainsMono Nerd Font"
  local dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
  local tmp; tmp="$(mktemp)"
  mkdir -p "$dir"
  fetch "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" "$tmp"
  unzip -oq "$tmp" -d "$dir"
  rm -f "$tmp"
  fc-cache -f >/dev/null 2>&1 || true
}

backup_existing() {
  local ts; ts="$(date +%Y%m%d-%H%M%S)"
  local paths=("$NVIM_DIR" "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim")
  for p in "${paths[@]}"; do
    if [ -e "$p" ]; then
      warn "Backing up $p -> $p.bak-$ts"
      mv "$p" "$p.bak-$ts"
    fi
  done
}

ensure_path() {
  case ":$PATH:" in *":$BIN_DIR:"*) ;; *)
    export PATH="$BIN_DIR:$PATH"
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      if [ -f "$rc" ] && ! grep -q '.local/bin' "$rc"; then echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"; fi
    done ;;
  esac
}

main() {
  install_deps
  install_neovim
  install_tree_sitter
  install_font
  ensure_path

  backup_existing
  info "Cloning config into $NVIM_DIR"
  git clone --depth 1 "$REPO" "$NVIM_DIR"

  info "Installing plugins (first run can take a few minutes)"
  nvim --headless "+Lazy! sync" +qa || warn "plugin sync reported errors - open nvim and run :Lazy sync"

  info "Done. Set your terminal font to 'JetBrainsMono Nerd Font', then run: nvim"
}

main "$@"
