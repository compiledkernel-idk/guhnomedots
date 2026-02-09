#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
ACCENT="mauve"

info() { printf '\033[1;35m[*]\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m[+]\033[0m %s\n' "$1"; }
err()  { printf '\033[1;31m[-]\033[0m %s\n' "$1"; }

command -v dnf &>/dev/null || { err "This script requires Fedora (dnf)."; exit 1; }

info "Installing packages..."
sudo dnf install -y \
  zsh git curl unzip \
  eza bat fd-find ripgrep fzf zoxide delta fastfetch \
  alacritty micro ImageMagick \
  starship \
  gnome-tweaks papirus-icon-theme \
  2>/dev/null

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

[[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

[[ -d "$ZSH_CUSTOM/plugins/fzf-tab" ]] || \
  git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"

info "Installing JetBrainsMono Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
  TMP=$(mktemp -d)
  curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" -o "$TMP/jbm.tar.xz"
  tar -xf "$TMP/jbm.tar.xz" -C "$FONT_DIR"
  fc-cache -f
  rm -rf "$TMP"
fi

info "Linking dotfiles..."
ln -sf "$DOTFILES/zshrc" "$HOME/.zshrc"

mkdir -p "$HOME/.config/alacritty"
mkdir -p "$HOME/.config/gtk-4.0"
mkdir -p "$HOME/.config/gtk-3.0"
mkdir -p "$HOME/.config/bat/themes"
mkdir -p "$HOME/.config/micro"

ln -sf "$DOTFILES/config/starship/starship.toml" "$HOME/.config/starship.toml"
ln -sf "$DOTFILES/config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
ln -sf "$DOTFILES/config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
ln -sf "$DOTFILES/config/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"
ln -sf "$DOTFILES/config/bat/config" "$HOME/.config/bat/config"
ln -sf "$DOTFILES/config/bat/themes/Catppuccin Mocha.tmTheme" "$HOME/.config/bat/themes/Catppuccin Mocha.tmTheme"
ln -sf "$DOTFILES/config/micro/bindings.json" "$HOME/.config/micro/bindings.json"
ln -sf "$DOTFILES/config/gamemode/gamemode.ini" "$HOME/.config/gamemode.ini"

if [[ ! -f "$HOME/.gitconfig" ]] || ! grep -q "delta" "$HOME/.gitconfig" 2>/dev/null; then
  ln -sf "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
fi

bat cache --build 2>/dev/null || true

info "Installing Catppuccin GTK theme..."
THEME_DIR="$HOME/.local/share/themes"
mkdir -p "$THEME_DIR"
if ! ls "$THEME_DIR" 2>/dev/null | grep -qi catppuccin; then
  TMP=$(mktemp -d)
  RELEASE_URL="https://github.com/catppuccin/gtk/releases/latest"
  LATEST=$(curl -sI "$RELEASE_URL" | grep -i ^location | awk -F/ '{print $NF}' | tr -d '\r\n')
  curl -sL "https://github.com/catppuccin/gtk/releases/download/${LATEST}/catppuccin-mocha-${ACCENT}-standard+default.zip" -o "$TMP/theme.zip"
  unzip -qo "$TMP/theme.zip" -d "$THEME_DIR" 2>/dev/null || true
  rm -rf "$TMP"
fi

info "Installing Catppuccin cursors..."
ICON_DIR="$HOME/.local/share/icons"
mkdir -p "$ICON_DIR"
if [[ ! -d "$ICON_DIR/catppuccin-mocha-${ACCENT}-cursors" ]]; then
  TMP=$(mktemp -d)
  curl -sL "https://github.com/catppuccin/cursors/releases/latest/download/catppuccin-mocha-${ACCENT}-cursors.zip" -o "$TMP/cursors.zip"
  unzip -qo "$TMP/cursors.zip" -d "$ICON_DIR" 2>/dev/null || true
  rm -rf "$TMP"
fi

info "Installing Papirus Catppuccin folders..."
if ! command -v papirus-folders &>/dev/null; then
  TMP=$(mktemp -d)
  curl -sL "https://raw.githubusercontent.com/catppuccin/papirus-folders/main/install.sh" -o "$TMP/install.sh"
  if [[ -s "$TMP/install.sh" ]]; then
    [[ -d "$ICON_DIR/Papirus-Dark" ]] || cp -r /usr/share/icons/Papirus-Dark "$ICON_DIR/" 2>/dev/null || true
    bash "$TMP/install.sh" 2>/dev/null || true
  fi
  rm -rf "$TMP"
fi
papirus-folders -C cat-mocha-${ACCENT} --theme Papirus-Dark 2>/dev/null || true

info "Generating wallpaper..."
WALL="$HOME/.local/share/backgrounds/catppuccin-mocha.png"
mkdir -p "$(dirname "$WALL")"
if [[ ! -f "$WALL" ]] || ! file "$WALL" | grep -q PNG; then
  magick -size 3840x2160 xc:"#11111b" \
    \( -size 3840x2160 gradient:"#1e1e2e-#181825" \) -compose over -composite \
    \( -size 3840x2160 radial-gradient:"#313244-none" -gravity SouthEast \) -compose over -composite \
    \( -size 3840x2160 radial-gradient:"rgba(203,166,247,0.15)-none" -gravity NorthWest \) -compose over -composite \
    \( -size 3840x2160 radial-gradient:"rgba(137,180,250,0.08)-none" -gravity SouthEast \) -compose over -composite \
    "$WALL" 2>/dev/null || true
fi

info "Applying GNOME settings..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-format '24h'
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

CURSOR_THEME="catppuccin-mocha-${ACCENT}-cursors"
[[ -d "$ICON_DIR/$CURSOR_THEME" ]] && gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"

GTK_THEME=$(ls "$THEME_DIR" 2>/dev/null | grep -i "catppuccin.*mocha" | head -1 || true)
[[ -n "$GTK_THEME" ]] && gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"

if [[ -f "$WALL" ]] && file "$WALL" | grep -q PNG; then
  gsettings set org.gnome.desktop.background picture-uri "file://$WALL"
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALL"
  gsettings set org.gnome.desktop.background picture-options 'zoom'
  gsettings set org.gnome.desktop.screensaver picture-uri "file://$WALL" 2>/dev/null || true
fi

sudo flatpak override --filesystem=xdg-config/gtk-4.0:ro --filesystem=xdg-config/gtk-3.0:ro \
  --filesystem=xdg-data/themes:ro --filesystem=xdg-data/icons:ro 2>/dev/null || true

if [[ "$SHELL" != *zsh ]]; then
  info "Setting zsh as default shell..."
  chsh -s "$(which zsh)"
fi

ok "Done. Log out and back in for full effect."
