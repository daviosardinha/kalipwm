#!/bin/bash

# Colors
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

WALLPAPER_CHOICE=""
INSTALL_STAGE="preflight"
INSTALL_FAILURE_DETAIL=""
INSTALL_FINISHED=0

installer_command_error() {
    local rc="$1"
    local line="$2"
    local command="$3"

    INSTALL_FAILURE_DETAIL="line $line: $command (exit $rc)"
    exit "$rc"
}

installer_failure_summary() {
    local rc="$1"

    [ "$INSTALL_FINISHED" -eq 0 ] || return 0
    [ "$rc" -ne 0 ] || return 0

    printf '\n%s[-] KaliPWM installation stopped.%s\n' "$RED" "$RESET" >&2
    printf 'Stage: %s\n' "$INSTALL_STAGE" >&2
    if [ -n "$INSTALL_FAILURE_DETAIL" ]; then
        printf 'Failure: %s\n' "$INSTALL_FAILURE_DETAIL" >&2
    fi
    printf 'No automatic rollback was attempted; existing files were left as-is.\n' >&2
    printf 'Fix the reported problem, then rerun: bash %s\n' "$0" >&2
    if command -v kalipwm >/dev/null 2>&1; then
        printf 'Check the current managed state with: kalipwm doctor\n' >&2
        printf 'If managed configuration needs recovery, use an existing KaliPWM backup/rollback.\n' >&2
    fi
}

print_wallpaper_choices() {
    cat <<'EOF'
auto
city-16x9
city-ultrawide
nomad-monolith
nomad-monolith-16x9
nomad-emblem
nomad-emblem-16x9
EOF
}

validate_wallpaper_choice() {
    case "$1" in
        auto|city-16x9|city-ultrawide|nomad-monolith|nomad-monolith-16x9|nomad-emblem|nomad-emblem-16x9)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

show_usage() {
    cat <<'EOF'
Usage:
  bash kalipwm.sh
  bash kalipwm.sh --install-wallpaper NAME
  bash kalipwm.sh --wallpaper NAME
  bash kalipwm.sh --list-wallpapers

Options:
  --wallpaper NAME          Change only the wallpaper on an existing KaliPWM installation.
  --set-wallpaper NAME      Alias for --wallpaper.
  --install-wallpaper NAME  Select the wallpaper to apply during a full KaliPWM installation.
  --list-wallpapers         Print available wallpaper names and exit.
  -h, --help                Show this help.
EOF
}

ensure_git_repo() {
    local name="$1"
    local url="$2"
    local dir="$3"
    local depth="${4:-0}"
    local recursive="${5:-0}"
    local ref="${6:-}"
    local clone_args=()
    local current_ref=""

    if [ -d "$dir/.git" ]; then
        echo -e "${GREEN}[=] Reusing existing $name checkout: $dir${RESET}"
        if [ -n "$ref" ]; then
            current_ref="$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)"
            if [ -n "$current_ref" ] && [ "$current_ref" != "$ref" ]; then
                echo -e "${BLUE}[=] $name is at ${current_ref:0:12}; fresh installs are pinned to ${ref:0:12}. Existing checkout left unchanged.${RESET}"
            fi
        fi
        if [ "$recursive" = "1" ]; then
            git -C "$dir" submodule update --init --recursive
        fi
        return 0
    fi

    if [ -e "$dir" ]; then
        echo -e "${RED}[-] Cannot install $name: $dir exists but is not a Git checkout.${RESET}"
        echo -e "${RED}[-] Move or remove that path manually, then rerun the installer.${RESET}"
        return 1
    fi

    mkdir -p "$(dirname "$dir")"

    if [ -n "$ref" ]; then
        # A full clone guarantees the locked commit remains checkout-able even
        # after the upstream branch moves beyond it.
        git clone "$url" "$dir"
        git -C "$dir" checkout --detach "$ref"
        if [ "$recursive" = "1" ]; then
            git -C "$dir" submodule update --init --recursive
        fi
        echo -e "${GREEN}[=] Pinned $name to ${ref:0:12}.${RESET}"
        return 0
    fi

    [ "$depth" = "1" ] && clone_args+=(--depth=1)
    [ "$recursive" = "1" ] && clone_args+=(--recursive)
    git clone "${clone_args[@]}" "$url" "$dir"
}

font_available() {
    local family="$1"
    command -v fc-list >/dev/null 2>&1 && fc-list : family 2>/dev/null | grep -qi "$family"
}

ensure_nerd_font() {
    local family="$1"
    local archive="$2"
    local tmpdir

    if font_available "$family"; then
        echo -e "${GREEN}[=] $family is already installed; skipping download.${RESET}"
        return 0
    fi

    tmpdir="$(mktemp -d /tmp/kalipwm-fonts.XXXXXX)"
    wget -q --show-progress \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/${archive}.zip" \
        -O "$tmpdir/${archive}.zip" || {
            rm -rf "$tmpdir"
            return 1
        }

    unzip -q "$tmpdir/${archive}.zip" -d "$tmpdir/$archive" || {
        rm -rf "$tmpdir"
        return 1
    }

    mkdir -p "$HOME/.local/share/fonts"
    find "$tmpdir/$archive" -maxdepth 1 -type f -name '*.ttf' -exec cp -f {} "$HOME/.local/share/fonts/" \;
    rm -rf "$tmpdir"
    fc-cache -f
}

while [ $# -gt 0 ]; do
    case "$1" in
        --wallpaper|--set-wallpaper)
            if [ $# -lt 2 ]; then
                echo -e "${RED}[-] $1 requires a wallpaper name.${RESET}"
                exit 1
            fi
            WALLPAPER_CHOICE="$2"
            if ! validate_wallpaper_choice "$WALLPAPER_CHOICE"; then
                echo -e "${RED}[-] Unknown wallpaper: $WALLPAPER_CHOICE${RESET}"
                echo "Available wallpapers:"
                print_wallpaper_choices
                exit 1
            fi
            SELECTOR="$HOME/.config/bspwm/scripts/set-obsidian-wallpaper.sh"
            if [ ! -x "$SELECTOR" ]; then
                echo -e "${RED}[-] KaliPWM wallpaper selector is not installed yet.${RESET}"
                echo "Use --install-wallpaper NAME during the first installation."
                exit 1
            fi
            exec "$SELECTOR" "$WALLPAPER_CHOICE"
            ;;
        --install-wallpaper)
            if [ $# -lt 2 ]; then
                echo -e "${RED}[-] --install-wallpaper requires a name.${RESET}"
                exit 1
            fi
            WALLPAPER_CHOICE="$2"
            shift 2
            ;;
        --list-wallpapers)
            print_wallpaper_choices
            exit 0
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}[-] Unknown option: $1${RESET}"
            show_usage
            exit 1
            ;;
    esac
done

# A plain rerun preserves the user's saved wallpaper choice. Fresh installations
# with no saved state continue to use the automatic City wallpaper selection.
if [ -z "$WALLPAPER_CHOICE" ]; then
    SAVED_WALLPAPER_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/kalipwm/wallpaper-choice"
    if [ -s "$SAVED_WALLPAPER_FILE" ]; then
        SAVED_WALLPAPER_CHOICE="$(/usr/bin/cat "$SAVED_WALLPAPER_FILE" 2>/dev/null || true)"
        if validate_wallpaper_choice "$SAVED_WALLPAPER_CHOICE"; then
            WALLPAPER_CHOICE="$SAVED_WALLPAPER_CHOICE"
            echo -e "${GREEN}[=] Preserving saved wallpaper choice: $WALLPAPER_CHOICE${RESET}"
        else
            echo -e "${RED}[!] Ignoring invalid saved wallpaper choice: $SAVED_WALLPAPER_CHOICE${RESET}"
        fi
    fi

    if [ -z "$WALLPAPER_CHOICE" ]; then
        WALLPAPER_CHOICE="auto"
    fi
fi

if ! validate_wallpaper_choice "$WALLPAPER_CHOICE"; then
    echo -e "${RED}[-] Unknown wallpaper: $WALLPAPER_CHOICE${RESET}"
    echo "Available wallpapers:"
    print_wallpaper_choices
    exit 1
fi

# Do not run the installer as root or through sudo.
if [ "$UID" -eq 0 ]; then
    echo -e "${RED}[-] Do not run KaliPWM as root.${RESET}"
    exit 1
else
    if [ -n "$SUDO_USER" ]; then
        echo -e "${RED}[-] Do not run KaliPWM with sudo.${RESET}"
        exit 1
    fi
fi

# From this point onward a command failure is fatal. The ERR trap stops the
# installer immediately and the EXIT trap reports the stage and recovery path.
set -E
trap 'installer_command_error "$?" "$LINENO" "$BASH_COMMAND"' ERR
trap 'installer_failure_summary "$?"' EXIT

# CI-only failure injection. This is inert unless explicitly set by a test.
if [ -n "${KALIPWM_TEST_FAIL_STAGE:-}" ]; then
    INSTALL_STAGE="$KALIPWM_TEST_FAIL_STAGE"
    false
fi

echo -e "${GREEN}
@@@  @@@   @@@@@@   @@@       @@@  @@@@@@@   @@@  @@@  @@@  @@@@@@@@@@
@@@  @@@  @@@@@@@@  @@@       @@@  @@@@@@@@  @@@  @@@  @@@  @@@@@@@@@@@
@@!  !@@  @@!  @@@  @@!       @@!  @@!  @@@  @@!  @@!  @@!  @@! @@! @@!
!@!  @!!  !@!  @!@  !@!       !@!  !@!  @!@  !@!  !@!  !@!  !@! !@! !@!
@!@@!@!   @!@!@!@!  @!!       !!@  @!@@!@!   @!!  !!@  @!@  @!! !!@ @!@
!!@!!!    !!!@!!!!  !!!       !!!  !!@!!!    !@!  !!!  !@!  !@!   ! !@!
!!: :!!   !!:  !!!  !!:       !!:  !!:       !!:  !!:  !!:  !!:     !!:
:!:  !:!  :!:  !:!   :!:      :!:  :!:       :!:  :!:  :!:  :!:     :!:
 ::  :::  ::   :::   :: ::::   ::   ::        :::: :: :::   :::     ::
 :   :::   :   : :  : :: : :  :     :          :: :  : :     :      :
"

sleep 2
echo -e "[+] KaliPWM Obsidian — maintained by @daviosardinha.${RESET}"
sleep 1
echo -e "[+] Based on afsh4ck/kalipwm — original project by @afsh4ck.${RESET}"
sleep 1
echo -e "[+] Existing managed components will be reused where possible.${RESET}"
sleep 1
echo -e "\n${BLUE}[*] Preparing installation..${RESET}\n"

RPATH="$(pwd)"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
DEPENDENCY_LOCK="$RPATH/DEPENDENCIES.lock"

INSTALL_STAGE="dependency lock"
if [ ! -r "$DEPENDENCY_LOCK" ]; then
    echo -e "${RED}[-] Missing dependency lock: $DEPENDENCY_LOCK${RESET}"
    exit 1
fi
# shellcheck source=DEPENDENCIES.lock
. "$DEPENDENCY_LOCK"

echo -e "${GREEN}[=] External dependency revisions loaded from DEPENDENCIES.lock.${RESET}"

INSTALL_STAGE="package metadata"
echo -e "\n${BLUE}[*] Updating package metadata..${RESET}\n"
sudo apt update

INSTALL_STAGE="required packages"
echo -e "\n${BLUE}[*] Ensuring required packages are installed..${RESET}\n"
sudo apt install -y git bspwm vim feh flameshot scrub zsh rofi xclip xsel locate wmname acpi sxhkd \
    imagemagick ranger kitty tmux python3-pip font-manager lsd bat bpython open-vm-tools-desktop open-vm-tools fastfetch \
    dirsearch feroxbuster gedit curl wget unzip papirus-icon-theme lm-sensors pavucontrol network-manager i3lock jq

INSTALL_STAGE="desktop dependencies"
echo -e "\n${BLUE}[*] Ensuring desktop environment dependencies are installed..${RESET}\n"
sudo apt install -y build-essential libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev \
    libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev libasound2-dev libxcb-xtest0-dev libxcb-shape0-dev

INSTALL_STAGE="Polybar build dependencies"
echo -e "\n${BLUE}[*] Ensuring Polybar build requirements are installed..${RESET}\n"
sudo apt install -y cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev \
    libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev \
    libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev \
    libmpdclient-dev libuv1-dev libnl-genl-3-dev

INSTALL_STAGE="Picom build dependencies"
echo -e "\n${BLUE}[*] Ensuring Picom dependencies are installed..${RESET}\n"
sudo apt install -y meson libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev \
    libxcb-render-util0-dev libxcb-render0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev \
    libxcb-xinerama0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev libevdev-dev \
    uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev libpcre3 libpcre3-dev

INSTALL_STAGE="Nerd Fonts"
echo -e "\n${BLUE}[*] Ensuring Nerd Fonts are installed..${RESET}\n"
ensure_nerd_font "Hack Nerd Font" "Hack" || exit 1
ensure_nerd_font "JetBrainsMono Nerd Font" "JetBrainsMono" || exit 1

INSTALL_STAGE="Oh My Zsh"
echo -e "\n${BLUE}[*] Ensuring Oh My Zsh is installed..${RESET}\n"
if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    echo -e "${GREEN}[=] Oh My Zsh is already installed; reusing it.${RESET}"
    if [ -d "$HOME/.oh-my-zsh/.git" ]; then
        omz_current_ref="$(git -C "$HOME/.oh-my-zsh" rev-parse HEAD 2>/dev/null || true)"
        if [ -n "$omz_current_ref" ] && [ "$omz_current_ref" != "$OH_MY_ZSH_REF" ]; then
            echo -e "${BLUE}[=] Oh My Zsh is at ${omz_current_ref:0:12}; fresh installs are pinned to ${OH_MY_ZSH_REF:0:12}. Existing checkout left unchanged.${RESET}"
        fi
    fi
elif [ -e "$HOME/.oh-my-zsh" ]; then
    echo -e "${RED}[-] $HOME/.oh-my-zsh exists but does not look like a complete Oh My Zsh installation.${RESET}"
    echo -e "${RED}[-] Move or repair that directory manually before rerunning KaliPWM.${RESET}"
    exit 1
else
    ensure_git_repo "Oh My Zsh" "https://github.com/ohmyzsh/ohmyzsh.git" "$HOME/.oh-my-zsh" 0 0 "$OH_MY_ZSH_REF" || exit 1
fi

INSTALL_STAGE="Powerlevel10k"
echo -e "\n${BLUE}[*] Ensuring the Powerlevel10k theme is installed..${RESET}\n"
ensure_git_repo "Powerlevel10k" "https://github.com/romkatv/powerlevel10k.git" "$ZSH_CUSTOM_DIR/themes/powerlevel10k" 0 0 "$POWERLEVEL10K_REF" || exit 1
cp -v "$RPATH/CONFIGS/p10k.zsh" "$HOME/.p10k.zsh"

INSTALL_STAGE="Zsh plugins"
echo -e "\n${BLUE}[*] Ensuring Zsh plugins are installed..${RESET}\n"
ensure_git_repo "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions" "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" 0 0 "$ZSH_AUTOSUGGESTIONS_REF" || exit 1
ensure_git_repo "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" 0 0 "$ZSH_SYNTAX_HIGHLIGHTING_REF" || exit 1
cp -v "$RPATH/CONFIGS/zshrc" "$HOME/.zshrc"

INSTALL_STAGE="fzf"
echo -e "\n${BLUE}[*] Ensuring fzf is installed..${RESET}\n"
ensure_git_repo "fzf" "https://github.com/junegunn/fzf.git" "$HOME/.fzf" 0 0 "$FZF_REF" || exit 1
if [ ! -x "$HOME/.fzf/bin/fzf" ] || [ ! -f "$HOME/.fzf.zsh" ]; then
    yes | "$HOME/.fzf/install"
else
    echo -e "${GREEN}[=] fzf shell integration is already installed; reusing it.${RESET}"
fi

INSTALL_STAGE="tmux"
echo -e "\n${BLUE}[*] Ensuring tmux configuration is installed..${RESET}\n"
ensure_git_repo "gpakosz/.tmux" "https://github.com/gpakosz/.tmux.git" "$HOME/.tmux" 0 0 "$TMUX_REF" || exit 1
ln -s -f "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"
cp -v "$RPATH/CONFIGS/tmux.conf.local" "$HOME/.tmux.conf.local"

INSTALL_STAGE="Kitty"
echo -e "\n${BLUE}[*] Ensuring Kitty terminal is installed..${RESET}\n"
if [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
    echo -e "${GREEN}[=] Kitty application bundle is already installed; reusing it.${RESET}"
else
    case "$(uname -m)" in
        amd64|x86_64) kitty_bundle_sha256="$KITTY_SHA256_X86_64" ;;
        aarch64*|armv8*) kitty_bundle_sha256="$KITTY_SHA256_ARM64" ;;
        *)
            echo -e "${RED}[-] No pinned Kitty bundle is defined for architecture: $(uname -m)${RESET}"
            exit 1
            ;;
    esac
    KITTY_VERSION="$KITTY_VERSION" KITTY_SHA256="$kitty_bundle_sha256" sh "$RPATH/kitty-installer.sh"
fi

mkdir -p "$HOME/github"

INSTALL_STAGE="Polybar"
if command -v polybar >/dev/null 2>&1; then
    echo -e "\n${GREEN}[=] Polybar is already installed; skipping source rebuild.${RESET}\n"
else
    echo -e "\n${BLUE}[*] Installing Polybar..${RESET}\n"
    ensure_git_repo "Polybar" "https://github.com/polybar/polybar" "$HOME/github/polybar" 0 1 "$POLYBAR_REF" || exit 1
    cmake -S "$HOME/github/polybar" -B "$HOME/github/polybar/build"
    cmake --build "$HOME/github/polybar/build" -j "$(nproc)"
    sudo cmake --install "$HOME/github/polybar/build"
fi

INSTALL_STAGE="Polybar themes"
if [ -d "$HOME/github/polybar-themes/.git" ]; then
    echo -e "\n${GREEN}[=] Polybar themes checkout already exists; skipping theme bootstrap.${RESET}\n"
    themes_current_ref="$(git -C "$HOME/github/polybar-themes" rev-parse HEAD 2>/dev/null || true)"
    if [ -n "$themes_current_ref" ] && [ "$themes_current_ref" != "$POLYBAR_THEMES_REF" ]; then
        echo -e "${BLUE}[=] Polybar themes is at ${themes_current_ref:0:12}; fresh installs are pinned to ${POLYBAR_THEMES_REF:0:12}. Existing checkout left unchanged.${RESET}"
    fi
else
    echo -e "\n${BLUE}[*] Installing Polybar themes..${RESET}\n"
    ensure_git_repo "Polybar themes" "https://github.com/adi1090x/polybar-themes.git" "$HOME/github/polybar-themes" 0 0 "$POLYBAR_THEMES_REF" || exit 1
    chmod +x "$HOME/github/polybar-themes/setup.sh"
    (
        cd "$HOME/github/polybar-themes" || exit 1
        echo 1 | ./setup.sh
    ) || exit 1
fi

INSTALL_STAGE="Picom"
if command -v picom >/dev/null 2>&1; then
    echo -e "\n${GREEN}[=] Picom is already installed; skipping source rebuild.${RESET}\n"
else
    echo -e "\n${BLUE}[*] Installing Picom..${RESET}\n"
    ensure_git_repo "Picom" "https://github.com/ibhagwan/picom.git" "$HOME/github/picom" 0 1 "$PICOM_REF" || exit 1
    if [ -d "$HOME/github/picom/build/meson-private" ]; then
        meson setup --reconfigure --buildtype=release "$HOME/github/picom/build" "$HOME/github/picom"
    else
        meson setup --buildtype=release "$HOME/github/picom/build" "$HOME/github/picom"
    fi
    ninja -C "$HOME/github/picom/build"
    sudo ninja -C "$HOME/github/picom/build" install
fi

INSTALL_STAGE="managed configuration"
echo -e "\n${BLUE}[*] Installing KaliPWM managed configuration..${RESET}\n"
sudo timedatectl set-timezone "Europe/Lisbon"

mkdir -p "$HOME/screenshots"
mkdir -p "$HOME/.config"

cp -rv "$RPATH/CONFIGS/config/." "$HOME/.config/"
mkdir -p "$HOME/.config/polybar/forest/scripts"
cp -rv "$RPATH/SCRIPTS/." "$HOME/.config/polybar/forest/scripts/"
cp -v "$RPATH/SCRIPTS/screenshot.sh" "$HOME/.config/polybar/obsidian/scripts/screenshot.sh"
sudo ln -sf "$HOME/.config/polybar/obsidian/scripts/target.sh" /usr/bin/target
sudo ln -sf "$HOME/.config/polybar/obsidian/scripts/screenshot.sh" /usr/bin/screenshot
sudo ln -sf "$HOME/.config/bspwm/scripts/set-obsidian-wallpaper.sh" /usr/bin/wallpaper
sudo install -m 0755 "$RPATH/SCRIPTS/kalipwm" /usr/local/bin/kalipwm

mkdir -p "$HOME/Wallpapers"
cp -rv "$RPATH/WALLPAPERS/." "$HOME/Wallpapers/"

INSTALL_STAGE="wallpaper validation"
for wallpaper in \
    "$HOME/Wallpapers/obsidian/obsidian-city-16x9.jpg" \
    "$HOME/Wallpapers/obsidian/obsidian-city-ultrawide.jpg" \
    "$HOME/Wallpapers/obsidian/obsidian-nomad-monolith-standard.png" \
    "$HOME/Wallpapers/obsidian/obsidian-nomad-monolith-16x9.png" \
    "$HOME/Wallpapers/obsidian/obsidian-nomad-emblem-standard.png" \
    "$HOME/Wallpapers/obsidian/obsidian-nomad-emblem-16x9.png"; do
    if [ ! -s "$wallpaper" ] || ! identify "$wallpaper" >/dev/null 2>&1; then
        echo -e "${RED}[-] Invalid Obsidian wallpaper: $wallpaper${RESET}"
        exit 1
    fi
done

INSTALL_STAGE="managed permissions"
chmod +x "$HOME/.config/bspwm/bspwmrc"
chmod +x "$HOME/.config/bspwm/scripts/bspwm_resize"
chmod +x "$HOME/.config/bspwm/scripts/set-obsidian-wallpaper.sh"
chmod +x "$HOME/.config/polybar/obsidian/launch.sh"
chmod +x "$HOME/.config/polybar/obsidian/scripts/"*.sh
chmod +x "$HOME/.config/polybar/obsidian-v2/launch.sh"
chmod +x "$HOME/.config/polybar/obsidian-v2/scripts/"*.sh
chmod +x "$HOME/.config/polybar/forest/scripts/target.sh"
chmod +x "$HOME/.config/polybar/forest/scripts/screenshot.sh"

# Apply the selected bundled Obsidian wallpaper immediately when installing from a graphical session.
if [ -n "${DISPLAY:-}" ] && command -v xrandr >/dev/null 2>&1 && command -v feh >/dev/null 2>&1; then
    "$HOME/.config/bspwm/scripts/set-obsidian-wallpaper.sh" "$WALLPAPER_CHOICE" || \
        echo -e "${RED}[!] Wallpaper was installed but could not be applied in the current session.${RESET}"
fi

INSTALL_FINISHED=1
trap - ERR EXIT

echo -e "\n${BLUE}[+] KaliPWM environment deployed. Happy hacking ;)${RESET}\n"
echo -e "${BLUE}[+] Existing installations can rerun this installer without destructive source re-clones.${RESET}\n"
echo -e "${BLUE}[+] Obsidian v2 is enabled by default.${RESET}\n"
echo -e "${BLUE}[+] Obsidian wallpapers installed. Selected: $WALLPAPER_CHOICE.${RESET}\n"
echo -e "${BLUE}[+] Flameshot is enabled as the primary screenshot tool.${RESET}\n"
echo -e "${BLUE}[+] KaliPWM diagnostics are available through: kalipwm doctor${RESET}\n"
echo -e "${BLUE}[+] cat uses /usr/bin/cat and vim uses /usr/bin/vim.${RESET}\n"
echo -e "${BLUE}[+] Please reboot the system (sudo reboot).${RESET}\n"