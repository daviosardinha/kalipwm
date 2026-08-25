#!/usr/bin/env bash
set -Eeuo pipefail

# KaliPWM V1 — Obsidian Tactical
# Adaptive installer for Kali Linux on bare metal and common hypervisors.

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_ROOT="$HOME/.local/state/kalipwm"
INSTALL_MARKER="$STATE_ROOT/install-in-progress"
PROFILE_DIR="$HOME/.config/kalipwm"
PROFILE_FILE="$PROFILE_DIR/profile.conf"
LOCAL_BIN="$HOME/.local/bin"
POWER_SUPPLY_ROOT="${KALIPWM_POWER_SUPPLY_ROOT:-/sys/class/power_supply}"

ENVIRONMENT=''
VENDOR=''
PRODUCT=''
BATTERY=''
ADAPTER=''
BACKLIGHT=''
WIFI_IFACE=''
WIRED_IFACE=''
INTERNAL_DISPLAY=''
CONNECTED_DISPLAYS=''
EXTERNAL_POSITION=''
INSTALL_ACTIVE=false

log()  { printf '%b[+]%b %s\n' "$GREEN" "$RESET" "$*"; }
info() { printf '%b[*]%b %s\n' "$BLUE" "$RESET" "$*"; }
warn() { printf '%b[!]%b %s\n' "$YELLOW" "$RESET" "$*"; }
die()  { printf '%b[-]%b %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
KaliPWM V1 — Obsidian Tactical

Usage:
  bash kalipwm.sh                 Interactive install
  bash kalipwm.sh --preflight     Detect environment/hardware without installing
  bash kalipwm.sh --checkpoint    Create a rollback transaction checkpoint
  bash kalipwm.sh --rollback      Restore the latest transaction checkpoint
  bash kalipwm.sh --uninstall     Restore the trusted pre-KaliPWM baseline
  bash kalipwm.sh --state-status  Show recovery-state status
  bash kalipwm.sh --detect-power
  bash kalipwm.sh --help

The installer must be launched as your normal user. It requests sudo only for
package/system operations. Recovery state is managed by SCRIPTS/kalipwm-state.
EOF
}

confirm() {
  local prompt="$1" default="${2:-Y}" answer=''
  if [[ "$default" == Y ]]; then
    read -r -p "$prompt [Y/n] " answer || true
    [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]]
  else
    read -r -p "$prompt [y/N] " answer || true
    [[ "$answer" =~ ^[Yy]$ ]]
  fi
}

require_normal_user() {
  [[ ${EUID:-$(id -u)} -ne 0 ]] || die "Do not run KaliPWM as root. Run it as your normal user."
  [[ -z ${SUDO_USER:-} ]] || die "Do not run the whole installer with sudo. The script requests sudo only when needed."
}

on_error() {
  local rc=$?
  if [[ "$INSTALL_ACTIVE" == true ]]; then
    printf '\n' >&2
    warn "Installation stopped before completion (exit $rc)."
    warn "Do not log into BSPWM yet. Fix the reported error, then rerun; use ./kalipwm.sh --rollback if configuration files were already changed."
  fi
  exit "$rc"
}
trap on_error ERR

detect_environment() {
  local virt
  virt="$(systemd-detect-virt 2>/dev/null || true)"
  case "$virt" in
    vmware) echo vmware ;;
    oracle) echo virtualbox ;;
    kvm|qemu) echo kvm ;;
    none|'') echo baremetal ;;
    *) echo "$virt" ;;
  esac
}

# Prefer the machine battery and ignore Battery-class peripherals such as
# phones/controllers that expose scope=Device.
detect_battery() {
  local p type scope present name
  local system_candidate='' capacity_candidate='' fallback=''

  for p in "$POWER_SUPPLY_ROOT"/*; do
    [[ -r "$p/type" ]] || continue
    read -r type < "$p/type"
    [[ "$type" == Battery ]] || continue

    scope="$(cat "$p/scope" 2>/dev/null || true)"
    [[ "$scope" == Device ]] && continue

    present="$(cat "$p/present" 2>/dev/null || printf '1')"
    [[ "$present" == 0 ]] && continue

    name="$(basename "$p")"
    if [[ "$scope" == System ]]; then
      [[ -n "$system_candidate" ]] || system_candidate="$name"
    elif [[ -r "$p/capacity" ]]; then
      [[ -n "$capacity_candidate" ]] || capacity_candidate="$name"
    else
      [[ -n "$fallback" ]] || fallback="$name"
    fi
  done

  if [[ -n "$system_candidate" ]]; then
    printf '%s\n' "$system_candidate"
  elif [[ -n "$capacity_candidate" ]]; then
    printf '%s\n' "$capacity_candidate"
  elif [[ -n "$fallback" ]]; then
    printf '%s\n' "$fallback"
  else
    return 1
  fi
}

# Prefer Mains. USB/USB-C is only a fallback and device-scoped peripherals are
# excluded.
detect_adapter() {
  local p type scope name
  local system_usb='' fallback_usb=''

  for p in "$POWER_SUPPLY_ROOT"/*; do
    [[ -r "$p/type" ]] || continue
    read -r type < "$p/type"
    if [[ "$type" == Mains ]]; then
      basename "$p"
      return 0
    fi
  done

  for p in "$POWER_SUPPLY_ROOT"/*; do
    [[ -r "$p/type" ]] || continue
    read -r type < "$p/type"
    case "$type" in USB|USB_C) ;; *) continue ;; esac

    scope="$(cat "$p/scope" 2>/dev/null || true)"
    [[ "$scope" == Device ]] && continue
    name="$(basename "$p")"

    if [[ "$scope" == System ]]; then
      [[ -n "$system_usb" ]] || system_usb="$name"
    else
      [[ -n "$fallback_usb" ]] || fallback_usb="$name"
    fi
  done

  if [[ -n "$system_usb" ]]; then
    printf '%s\n' "$system_usb"
  elif [[ -n "$fallback_usb" ]]; then
    printf '%s\n' "$fallback_usb"
  else
    return 1
  fi
}

detect_backlight() {
  local p
  for p in /sys/class/backlight/*; do
    [[ -e "$p" ]] && { basename "$p"; return 0; }
  done
  return 1
}

detect_wifi() {
  local p
  for p in /sys/class/net/*/wireless; do
    [[ -d "$p" ]] && { basename "$(dirname "$p")"; return 0; }
  done
  return 1
}

detect_wired() {
  local dev path
  while read -r dev; do
    [[ -n "$dev" ]] || continue
    case "$dev" in lo|tun*|tap*|wg*|docker*|br-*|virbr*|vmnet*|vboxnet*) continue ;; esac
    path="/sys/class/net/$dev"
    [[ -e "$path" ]] || continue
    [[ -d "$path/wireless" ]] && continue
    printf '%s\n' "$dev"
    return 0
  done < <(find /sys/class/net -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null | sort)
  return 1
}

detect_internal_display() {
  command -v xrandr >/dev/null 2>&1 || return 1
  [[ -n ${DISPLAY:-} ]] || return 1
  xrandr --query 2>/dev/null | awk '$2=="connected" && $1 ~ /^(eDP|LVDS)/ {print $1; exit}'
}

detect_connected_displays() {
  command -v xrandr >/dev/null 2>&1 || return 0
  [[ -n ${DISPLAY:-} ]] || return 0
  xrandr --query 2>/dev/null | awk '$2=="connected" {print $1}' | paste -sd, -
}

preflight() {
  info "Running pre-flight checks"
  command -v sudo >/dev/null || die "sudo is required."
  command -v apt >/dev/null || die "This installer requires an APT-based Kali system."
  command -v systemd-detect-virt >/dev/null || die "systemd-detect-virt is required."
  sudo -v || die "Unable to obtain sudo privileges."

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ ${ID:-} != kali ]]; then
      warn "Detected ${PRETTY_NAME:-unknown OS}, not Kali Linux."
      confirm "Continue anyway?" N || exit 1
    else
      log "Detected ${PRETTY_NAME:-Kali Linux}"
    fi
  fi

  local free_kb
  free_kb="$(df -Pk "$HOME" | awk 'NR==2 {print $4}')"
  (( free_kb >= 1500000 )) || die "At least 1.5 GB of free space is required."

  if sudo dpkg --audit 2>/dev/null | grep -q .; then
    warn "dpkg reports unfinished package configuration. Resolve it before installing."
    sudo dpkg --audit || true
    exit 1
  fi

  log "Pre-flight checks passed"
}

choose_environment() {
  local detected choice
  detected="$(detect_environment)"
  printf '\nDetected environment: %s\n' "$detected"

  if confirm "Is this correct?" Y; then
    ENVIRONMENT="$detected"
    return
  fi

  cat <<'EOF'
  1) Bare metal
  2) VMware guest
  3) VirtualBox guest
  4) KVM/QEMU guest
  5) Other
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

detect_hardware() {
  VENDOR="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
  PRODUCT="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
  BATTERY="$(detect_battery || true)"
  ADAPTER="$(detect_adapter || true)"
  BACKLIGHT="$(detect_backlight || true)"
  WIFI_IFACE="$(detect_wifi || true)"
  WIRED_IFACE="$(detect_wired || true)"
  INTERNAL_DISPLAY="$(detect_internal_display || true)"
  CONNECTED_DISPLAYS="$(detect_connected_displays || true)"
}

choose_display_preferences() {
  local pos

  if [[ "$ENVIRONMENT" != baremetal ]]; then
    EXTERNAL_POSITION=''
    return 0
  fi

  EXTERNAL_POSITION=right
  if confirm "Place external displays to the right of the laptop by default?" Y; then
    return 0
  fi

  printf 'Position: 1) left  2) above  3) below  4) mirror\n'
  read -r -p "Selection [1-4]: " pos
  case "${pos:-1}" in
    1) EXTERNAL_POSITION=left ;;
    2) EXTERNAL_POSITION=above ;;
    3) EXTERNAL_POSITION=below ;;
    4) EXTERNAL_POSITION=mirror ;;
    *) EXTERNAL_POSITION=right ;;
  esac
}

show_detection() {
  cat <<EOF

Environment / hardware detection
────────────────────────────────────────
Virtualization     : ${ENVIRONMENT:-unknown}
Platform           : ${VENDOR:-unknown} ${PRODUCT:-}
Battery            : ${BATTERY:-not detected}
AC adapter         : ${ADAPTER:-not detected}
Backlight          : ${BACKLIGHT:-not detected}
Wi-Fi              : ${WIFI_IFACE:-not detected}
Ethernet           : ${WIRED_IFACE:-not detected}
Internal display   : ${INTERNAL_DISPLAY:-not detected}
Connected displays : ${CONNECTED_DISPLAYS:-not detected}
External position  : ${EXTERNAL_POSITION:-n/a}
────────────────────────────────────────
EOF
}

package_has_candidate() {
  local pkg="$1" candidate
  candidate="$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2; exit}')"
  [[ -n "$candidate" && "$candidate" != '(none)' ]]
}

install_packages() {
  local -a common guest available
  local pkg

  # Use current Kali/Debian binary package names. In particular,
  # network-manager-gnome and policykit-1-gnome may remain visible in APT
  # metadata while having no install candidate, so never use apt-cache show as
  # the availability test.
  common=(
    git curl wget unzip bspwm vim feh zsh rofi xclip xsel plocate suckless-tools acpi sxhkd
    imagemagick ranger kitty tmux python3-pip font-manager lsd bat bpython fastfetch
    dirsearch feroxbuster gedit fzf polybar picom flameshot brightnessctl pulseaudio-utils
    network-manager-applet nm-connection-editor mate-polkit dunst xfce4-power-manager
    x11-xserver-utils x11-utils
  )
  guest=()
  available=()

  case "$ENVIRONMENT" in
    vmware) guest=(open-vm-tools open-vm-tools-desktop) ;;
    virtualbox) guest=(virtualbox-guest-x11 virtualbox-guest-utils) ;;
    kvm) guest=(spice-vdagent qemu-guest-agent) ;;
  esac

  info "Updating APT metadata"
  sudo apt update

  for pkg in "${common[@]}" "${guest[@]}"; do
    if package_has_candidate "$pkg"; then
      available+=("$pkg")
    else
      warn "No install candidate on this Kali snapshot, skipping: $pkg"
    fi
  done

  ((${#available[@]})) || die "No requested packages have install candidates. Check your APT sources."
  info "Installing ${#available[@]} packages with valid candidates"
  sudo apt install -y "${available[@]}"
}

install_fonts() {
  local tmp="$HOME/.cache/kalipwm-fonts" version=v3.0.2 font zip
  mkdir -p "$tmp" "$HOME/.local/share/fonts"

  for font in Hack JetBrainsMono; do
    zip="$tmp/$font.zip"
    wget -q --show-progress "https://github.com/ryanoasis/nerd-fonts/releases/download/$version/$font.zip" -O "$zip"
    unzip -oq "$zip" -d "$tmp/$font"
    find "$tmp/$font" -type f -name '*.ttf' -exec cp -f {} "$HOME/.local/share/fonts/" \;
  done

  fc-cache -f >/dev/null
  rm -rf "$tmp"
}

git_clone_or_update() {
  local url="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --ff-only || warn "Could not fast-forward $dest; preserving the existing checkout."
  else
    rm -rf "$dest"
    git clone --depth=1 "$url" "$dest"
  fi
}

install_shell_stack() {
  info "Installing ZSH environment"
  git_clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  mkdir -p "$HOME/.oh-my-zsh/custom/themes" "$HOME/.oh-my-zsh/custom/plugins"
  git_clone_or_update https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
  git_clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  git_clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

  cp -f "$REPO_ROOT/CONFIGS/zshrc" "$HOME/.zshrc"
  cp -f "$REPO_ROOT/CONFIGS/p10k.zsh" "$HOME/.p10k.zsh"

  info "Installing tmux configuration"
  git_clone_or_update https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
  ln -sfn "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
  cp -f "$REPO_ROOT/CONFIGS/tmux.conf.local" "$HOME/.tmux.conf.local"

  if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]] && confirm "Make ZSH your default shell?" Y; then
    sudo chsh -s "$(command -v zsh)" "$USER"
  fi
}

install_configs() {
  info "Installing BSPWM desktop configuration"
  mkdir -p "$HOME/.config" "$LOCAL_BIN" "$PROFILE_DIR" "$HOME/Pictures/Screenshots" "$HOME/Wallpapers"
  cp -a "$REPO_ROOT/CONFIGS/config/." "$HOME/.config/"
  cp -a "$REPO_ROOT/WALLPAPERS/." "$HOME/Wallpapers/"

  for script in "$REPO_ROOT"/SCRIPTS/*; do
    [[ -f "$script" ]] || continue
    install -m 0755 "$script" "$LOCAL_BIN/$(basename "$script")"
  done

  if [[ -x "$LOCAL_BIN/target.sh" ]]; then
    ln -sfn "$LOCAL_BIN/target.sh" "$LOCAL_BIN/target"
  fi

  find "$HOME/.config/bspwm" "$HOME/.config/polybar" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  chmod +x "$HOME/.config/bspwm/bspwmrc" 2>/dev/null || true
}

write_profile() {
  mkdir -p "$PROFILE_DIR"
  cat > "$PROFILE_FILE" <<EOF
# Generated by KaliPWM V1. Safe to edit.
environment=$(printf '%q' "$ENVIRONMENT")
vendor=$(printf '%q' "$VENDOR")
product=$(printf '%q' "$PRODUCT")
battery=$(printf '%q' "$BATTERY")
adapter=$(printf '%q' "$ADAPTER")
backlight=$(printf '%q' "$BACKLIGHT")
wifi_interface=$(printf '%q' "$WIFI_IFACE")
wired_interface=$(printf '%q' "$WIRED_IFACE")
internal_display=$(printf '%q' "$INTERNAL_DISPLAY")
connected_displays=$(printf '%q' "$CONNECTED_DISPLAYS")
external_position=$(printf '%q' "$EXTERNAL_POSITION")
editor=vim
cat_override=false
screenshots=flameshot
telemetry=true
plymouth=false
EOF
}

print_summary() {
  cat <<EOF

KaliPWM V1 installation summary
────────────────────────────────────────
Environment       : $ENVIRONMENT
Platform          : ${VENDOR:-unknown} ${PRODUCT:-}
Battery           : ${BATTERY:-not detected}
AC adapter        : ${ADAPTER:-not detected}
Backlight         : ${BACKLIGHT:-not detected}
Wi-Fi             : ${WIFI_IFACE:-not detected}
Ethernet          : ${WIRED_IFACE:-not detected}
Displays          : ${CONNECTED_DISPLAYS:-not detected}
External position : ${EXTERNAL_POSITION:-n/a}
Editor            : Vim
cat               : standard /usr/bin/cat
Screenshots       : Flameshot
Profile           : $PROFILE_FILE
Recovery          : trusted baseline + transaction checkpoint state
────────────────────────────────────────
EOF
  log "Installation complete. Log out, select BSPWM from the session chooser, and log back in."
}

main() {
  local mode="${1:-}"

  case "$mode" in
    --help|-h)
      usage
      exit 0
      ;;
    --detect-power)
      printf 'battery=%s\n' "$(detect_battery || true)"
      printf 'adapter=%s\n' "$(detect_adapter || true)"
      exit 0
      ;;
    --preflight|'') ;;
    *) usage; die "Unknown option: $mode" ;;
  esac

  require_normal_user
  printf '%b\nKaliPWM V1 — Obsidian Tactical%b\n' "$GREEN" "$RESET"
  preflight
  choose_environment
  detect_hardware
  choose_display_preferences
  show_detection

  if [[ "$mode" == --preflight ]]; then
    log "Pre-flight only: no configuration was changed."
    exit 0
  fi

  confirm "Apply this configuration?" Y || exit 0

  mkdir -p "$STATE_ROOT"
  printf 'prepared=%s\n' "$(date --iso-8601=seconds)" > "$INSTALL_MARKER"
  INSTALL_ACTIVE=true

  install_packages
  install_fonts
  install_shell_stack
  install_configs
  write_profile

  # Existing sessions can pick up the new key bindings immediately. BSPWM
  # itself is selected from the login/session chooser after logout.
  pkill -USR1 -x sxhkd 2>/dev/null || true

  INSTALL_ACTIVE=false
  rm -f "$INSTALL_MARKER"
  print_summary
}

main "$@"
