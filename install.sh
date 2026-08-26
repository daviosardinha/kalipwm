#!/usr/bin/env bash
set -Eeuo pipefail

# KaliPWM V1 rebuild — safe installer shell.
# Core upstream desktop behavior remains protected. Approved, regression-tested
# operator bindings are layered on top without changing BSPWM/Picom/Polybar/
# Kitty/Rofi behavior.

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DETECTOR="$REPO_ROOT/SCRIPTS/kalipwm-detect"
STATE_ROOT="$HOME/.local/state/kalipwm-rebuild"
BACKUP_ROOT="$STATE_ROOT/backups"
MODE="${1:-install}"

ENVIRONMENT=""
DETECTION=""

log()  { printf '[+] %s\n' "$*"; }
info() { printf '[*] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die()  { printf '[-] %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
KaliPWM V1 rebuild installer

Usage:
  bash kalipwm.sh                 interactive install
  bash kalipwm.sh --preflight     read-only host checks + detection
  bash kalipwm.sh --plan          read-only environment/package plan
  bash kalipwm.sh --help

Rebuild rule: BSPWM, Picom, Polybar, Kitty and Rofi remain inherited from the
known-good upstream baseline. sxhkd may contain only explicitly approved,
regression-tested operator bindings.
EOF
}

require_normal_user() {
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "Run KaliPWM as your normal user, not root."
  [[ -z ${SUDO_USER:-} ]] || die "Do not launch the whole installer with sudo."
}

load_detection() {
  [[ -x "$DETECTOR" || -f "$DETECTOR" ]] || die "Missing detector: $DETECTOR"
  DETECTION="$(bash "$DETECTOR")"
  ENVIRONMENT="$(awk -F= '$1=="environment" {print $2; exit}' <<<"$DETECTION")"
  [[ -n "$ENVIRONMENT" ]] || ENVIRONMENT=unknown
}

show_detection() {
  printf '%s\n' "$DETECTION"
}

preflight() {
  require_normal_user
  command -v apt >/dev/null || die "APT is required."
  command -v dpkg >/dev/null || die "dpkg is required."
  command -v systemd-detect-virt >/dev/null || die "systemd-detect-virt is required."
  command -v git >/dev/null || die "git is required."

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ ${ID:-} == kali ]] || warn "Host reports ${PRETTY_NAME:-unknown OS}; V1 is targeted at Kali Linux."
  fi

  local free_kb
  free_kb="$(df -Pk "$HOME" | awk 'NR==2 {print $4}')"
  (( free_kb >= 1500000 )) || die "At least 1.5 GB free under HOME is required."

  if dpkg --audit 2>/dev/null | grep -q .; then
    warn "dpkg reports unfinished package configuration. Resolve it before installing."
    dpkg --audit || true
    return 1
  fi

  load_detection
  log "Preflight passed"
}

confirm_environment() {
  local answer choice
  printf '\nDetected environment: %s\n' "$ENVIRONMENT"
  read -r -p "Use this environment? [Y/n] " answer || true
  if [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]]; then
    return 0
  fi

  cat <<'EOF'
  1) baremetal
  2) vmware
  3) virtualbox
  4) kvm
  5) other
EOF
  read -r -p "Environment [1-5]: " choice
  case "$choice" in
    1) ENVIRONMENT=baremetal ;;
    2) ENVIRONMENT=vmware ;;
    3) ENVIRONMENT=virtualbox ;;
    4) ENVIRONMENT=kvm ;;
    5) read -r -p "Environment name: " ENVIRONMENT ;;
    *) die "Invalid environment selection." ;;
  esac
}

common_packages() {
  cat <<'EOF'
git
curl
wget
unzip
bspwm
vim
feh
scrot
flameshot
brightnessctl
dunst
wireguard-tools
scrub
zsh
rofi
xclip
xsel
plocate
wmname
acpi
sxhkd
imagemagick
ranger
kitty
tmux
python3-pip
font-manager
lsd
bat
bpython
fastfetch
dirsearch
feroxbuster
gedit
fzf
polybar
picom
x11-xserver-utils
x11-utils
EOF
}

guest_packages() {
  case "$ENVIRONMENT" in
    vmware)
      printf '%s\n' open-vm-tools open-vm-tools-desktop
      ;;
    virtualbox)
      printf '%s\n' virtualbox-guest-utils virtualbox-guest-x11
      ;;
    kvm)
      printf '%s\n' spice-vdagent qemu-guest-agent
      ;;
  esac
}

package_has_candidate() {
  local pkg="$1" candidate
  candidate="$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
  [[ -n "$candidate" && "$candidate" != '(none)' ]]
}

show_plan() {
  local pkg guest_summary
  local -a available=() missing=()

  info "Environment-specific installation plan"
  printf 'environment=%s\n' "$ENVIRONMENT"
  printf 'timezone=preserve-current\n'
  printf 'desktop-config=upstream-plus-approved-bindings\n'
  case "$ENVIRONMENT" in
    baremetal) guest_summary=none ;;
    vmware) guest_summary=vmware ;;
    virtualbox) guest_summary=virtualbox ;;
    kvm) guest_summary=kvm ;;
    *) guest_summary=none ;;
  esac
  printf 'vm-guest-tools=%s\n' "$guest_summary"
  printf 'polybar=distro-package\n'
  printf 'picom=distro-package\n'
  printf 'kitty=user-local-upstream-installer-for-binding-compatibility\n'
  printf 'gpu-provider-routing=untouched\n'

  while read -r pkg; do
    [[ -n "$pkg" ]] || continue
    if package_has_candidate "$pkg"; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done < <({ common_packages; guest_packages; } | awk 'NF && !seen[$0]++')

  printf '\nPackages with candidates (%d):\n' "${#available[@]}"
  printf '  %s\n' "${available[@]}"

  if ((${#missing[@]})); then
    printf '\nPackages without candidates (%d, will be skipped):\n' "${#missing[@]}"
    printf '  %s\n' "${missing[@]}"
  fi
}

backup_user_state() {
  local stamp dest rel
  local -a paths=(
    .config/bspwm .config/sxhkd .config/polybar .config/kitty .config/picom .config/rofi .config/flameshot
    .config/kalipwm .zshrc .p10k.zsh .tmux .tmux.conf .tmux.conf.local .oh-my-zsh .fzf
  )

  stamp="$(date +%Y%m%d-%H%M%S)-$$"
  dest="$BACKUP_ROOT/$stamp"
  mkdir -p "$dest"

  printf 'created=%s\nenvironment=%s\n' "$(date --iso-8601=seconds)" "$ENVIRONMENT" > "$dest/metadata"
  getent passwd "$USER" | cut -d: -f7 > "$dest/login-shell.txt" || true

  : > "$dest/paths.txt"
  for rel in "${paths[@]}"; do
    if [[ -e "$HOME/$rel" || -L "$HOME/$rel" ]]; then
      printf '%s\n' "$rel" >> "$dest/paths.txt"
    fi
  done

  if [[ -s "$dest/paths.txt" ]]; then
    tar -czf "$dest/home-configs.tar.gz" -C "$HOME" -T "$dest/paths.txt"
  else
    tar -czf "$dest/home-configs.tar.gz" --files-from /dev/null
  fi

  printf '%s\n' "$dest"
}

install_packages() {
  local pkg
  local -a available=()

  sudo apt update
  while read -r pkg; do
    [[ -n "$pkg" ]] || continue
    if package_has_candidate "$pkg"; then
      available+=("$pkg")
    else
      warn "Skipping package with no candidate: $pkg"
    fi
  done < <({ common_packages; guest_packages; } | awk 'NF && !seen[$0]++')

  ((${#available[@]})) || die "No installable packages found."
  sudo apt install -y "${available[@]}"
}

clone_or_update() {
  local url="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --ff-only || warn "Could not fast-forward $dest; preserving current checkout."
  else
    rm -rf "$dest"
    git clone --depth=1 "$url" "$dest"
  fi
}

install_fonts() {
  local tmp="$HOME/.cache/kalipwm-fonts" version=v3.0.2 font zip
  mkdir -p "$tmp" "$HOME/.local/share/fonts"

  for font in Hack JetBrainsMono; do
    zip="$tmp/$font.zip"
    wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/download/$version/$font.zip" -O "$zip"
    rm -rf "$tmp/$font"
    mkdir -p "$tmp/$font"
    unzip -oq "$zip" -d "$tmp/$font"
    find "$tmp/$font" -type f -name '*.ttf' -exec cp -f {} "$HOME/.local/share/fonts/" \;
  done

  fc-cache -f >/dev/null
}

install_shell_stack() {
  clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  mkdir -p "$HOME/.oh-my-zsh/custom/themes" "$HOME/.oh-my-zsh/custom/plugins"
  clone_or_update https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
  clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
  clone_or_update https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
  ln -sfn "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
}

install_upstream_kitty_path() {
  # The upstream terminal binding launches ~/.local/kitty.app/bin/kitty.
  if [[ ! -x "$HOME/.local/kitty.app/bin/kitty" ]]; then
    info "Installing Kitty in the upstream-compatible user-local path"
    bash "$REPO_ROOT/kitty-installer.sh"
  fi
}

copy_known_good_desktop() {
  local dir
  mkdir -p "$HOME/.config"

  # Core directories remain upstream-derived. sxhkd is separately regression-
  # guarded so only approved operator bindings may diverge from the baseline.
  for dir in bspwm sxhkd polybar kitty picom rofi; do
    rm -rf "$HOME/.config/$dir"
    cp -a "$REPO_ROOT/CONFIGS/config/$dir" "$HOME/.config/$dir"
  done

  # Flameshot 14 needs the known-good native X11 capture path in BSPWM. This
  # configuration is intentionally additive and does not alter the upstream WM.
  rm -rf "$HOME/.config/flameshot"
  cp -a "$REPO_ROOT/CONFIGS/config/flameshot" "$HOME/.config/flameshot"

  cp -f "$REPO_ROOT/CONFIGS/zshrc" "$HOME/.zshrc"
  cp -f "$REPO_ROOT/CONFIGS/p10k.zsh" "$HOME/.p10k.zsh"
  cp -f "$REPO_ROOT/CONFIGS/tmux.conf.local" "$HOME/.tmux.conf.local"

  mkdir -p "$HOME/.config/polybar/forest/scripts"
  cp -af "$REPO_ROOT"/SCRIPTS/* "$HOME/.config/polybar/forest/scripts/"

  mkdir -p "$HOME/Wallpapers" "$HOME/screenshots" "$HOME/.local/bin"
  cp -af "$REPO_ROOT"/WALLPAPERS/* "$HOME/Wallpapers/"

  ln -sfn "$HOME/.config/polybar/forest/scripts/target.sh" "$HOME/.local/bin/target"
  ln -sfn "$HOME/.config/polybar/forest/scripts/screenshot.sh" "$HOME/.local/bin/screenshot"
  ln -sfn "$HOME/.config/polybar/forest/scripts/screenshot.sh" "$HOME/.local/bin/screenshot.sh"

  chmod +x "$HOME/.config/bspwm/bspwmrc"
  chmod +x "$HOME/.config/bspwm/scripts/bspwm_resize"
  chmod +x "$HOME/.config/polybar/launch.sh"
  chmod +x "$HOME/.config/polybar/forest/scripts/target.sh"
  chmod +x "$HOME/.config/polybar/forest/scripts/screenshot.sh"
}

perform_install() {
  local backup

  preflight
  show_detection
  confirm_environment
  show_plan

  printf '\nNo timezone, GPU-provider, NVIDIA, VMware-host, or display-routing settings will be changed.\n'
  read -r -p "Continue with installation? [y/N] " answer || true
  [[ "$answer" =~ ^[Yy]$ ]] || { info "Installation cancelled."; return 0; }

  sudo -v
  backup="$(backup_user_state)"
  log "User configuration backup: $backup"

  install_packages
  install_fonts
  install_shell_stack
  install_upstream_kitty_path
  copy_known_good_desktop
  bash "$REPO_ROOT/SCRIPTS/kalipwm-profile-init" --write

  if [[ "$(getent passwd "$USER" | cut -d: -f7)" != */zsh ]] && command -v zsh >/dev/null 2>&1; then
    sudo chsh -s "$(command -v zsh)" "$USER" || warn "Could not change login shell automatically."
  fi

  cat <<EOF

KaliPWM V1 rebuild install complete
----------------------------------------
environment=$ENVIRONMENT
backup=$backup
desktop-config=upstream-plus-approved-bindings
timezone=preserved
gpu-routing=untouched
----------------------------------------
Log out or reboot, select BSPWM, and run the baseline regression checks before
adding any further operator or visual features.
EOF
}

case "$MODE" in
  --help|-h|help)
    usage
    ;;
  --preflight|preflight)
    preflight
    show_detection
    ;;
  --plan|plan)
    preflight
    show_detection
    show_plan
    ;;
  install|'')
    perform_install
    ;;
  *)
    die "Unknown option: $MODE (use --help)"
    ;;
esac
