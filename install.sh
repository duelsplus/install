#!/usr/bin/env bash
# https://github.com/duelsplus/install

set -euo pipefail

INSTALL_DIR="$HOME/.local/share/duelsplus"
BIN_DIR="$HOME/.local/bin"
BIN_PATH="$BIN_DIR/duelsplus"
DESKTOP_FILE="$HOME/.local/share/applications/duelsplus.desktop"
VERSION_API="https://duelsplus.com/api/launcher/version"
LOG_FILE="$HOME/.cache/duelsplus-install.log"
# --- colors ---
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
DARK_GRAY="\033[90m"
NC="\033[0m"
# --- very wonderful ASCII banner ---
if [ "$(tput colors 2>/dev/null || echo 0)" -ge 256 ]; then
    BRAND_RED="\033[38;2;255;85;85m"  ##FF5555
else
    BRAND_RED="\033[0;31m"            #light red
fi
echo -e "${BRAND_RED}"
cat <<'EOF'
 _______                       __                     
|       \                     |  \              __    
| $$$$$$$\ __    __   ______  | $$  _______    |  \   
| $$  | $$|  \  |  \ /      \ | $$ /       \ __| $$__ 
| $$  | $$| $$  | $$|  $$$$$$\| $$|  $$$$$$$|    $$  \
| $$  | $$| $$  | $$| $$    $$| $$ \$$    \  \$$$$$$$$
| $$__/ $$| $$__/ $$| $$$$$$$$| $$ _\$$$$$$\   | $$   
| $$    $$ \$$    $$ \$$     \| $$|       $$    \$$   
 \$$$$$$$   \$$$$$$   \$$$$$$$ \$$ \$$$$$$$                               
EOF
echo -e "${NC}"
echo -e "${DARK_GRAY}Logs saved to: $LOG_FILE${NC}"
mkdir -p "$(dirname "$LOG_FILE")"
# --- check for root ---
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${RED}⚠️  Do not run this installer as root.${NC}"
    echo "This script installs Duels+ under your user account."
    echo "Please re-run it as a normal user."
    exit 1
fi
# --- check for existing installation ---
if command -v duelsplus >/dev/null 2>&1; then
    EXISTING_PATH=$(command -v duelsplus)
    if [[ "$EXISTING_PATH" == "/usr/bin/"* ]] || [[ "$EXISTING_PATH" == "/usr/local/bin/"* ]]; then
        echo -e "${YELLOW}⚠️  A system-wide installation of Duels+ was found at:${NC} $EXISTING_PATH"
        echo "It's likely installed via a package manager."
        read -rp "Do you still want to proceed? (y/N): " choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    elif [[ "$EXISTING_PATH" == "$BIN_PATH" ]]; then
        echo -e "${YELLOW}⚠️  Duels+ is already installed in your user directory.${NC}"
        read -rp "Do you still want to proceed? (y/N): " choice
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi
fi
# --- check dependencnies ---
for cmd in curl jq unzip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing missing dependency: $cmd${NC}"
        if command -v apt >/dev/null 2>&1; then
            sudo apt update -y && sudo apt install -y "$cmd"
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "$cmd"
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -Sy --noconfirm "$cmd"
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper install -y "$cmd"
        else
            echo -e "${RED}Unsupported package manager. Please install curl, jq, and unzip manually.${NC}"
            exit 1
        fi
    fi
done
# --- check fuse2 ---
#if ! ldconfig -p 2>/dev/null | grep -q "libfuse.so.2"; then
#    if command -v apt >/dev/null 2>&1; then
#        sudo apt install -y libfuse2
#    elif command -v dnf >/dev/null 2>&1; then
#        sudo dnf install -y fuse
#    elif command -v pacman >/dev/null 2>&1; then
#        sudo pacman -Sy --noconfirm fuse2
#    elif command -v zypper >/dev/null 2>&1; then
#        sudo zypper install -y fuse
#    else
#        echo -e "${RED}Could not automatically install FUSE2. Please install libfuse2 (or fuse2, depending on your distribution) manually.${NC}"
#        exit 1
#    fi
#fi
# --- fetch versioning ---
VERSION_JSON=$(curl -sSL "$VERSION_API")
LATEST_VERSION=$(echo "$VERSION_JSON" | jq -r '.version')
DOWNLOAD_URL=$(echo "$VERSION_JSON" | jq -r '.platforms[] | select(.platform=="Linux") | .downloadUrl')
FILENAME=$(basename "$DOWNLOAD_URL" | sed 's/%2B/+/g')
if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
    echo -e "${RED}No Linux release available right now.${NC}"
    exit 1
fi
# --- download + install ---
mkdir -p "$INSTALL_DIR"
echo -e "${YELLOW}Downloading Duels+ Launcher v$LATEST_VERSION...${NC}"
curl -# -L "$DOWNLOAD_URL" -o "$INSTALL_DIR/$FILENAME" 2>&1 | tee -a "$LOG_FILE"
echo
chmod +x "$INSTALL_DIR/$FILENAME"
# --- create binary wrapper ---
mkdir -p "$BIN_DIR"
cat > "$BIN_PATH" <<EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/$FILENAME" "\$@"
EOF
chmod +x "$BIN_PATH"
# --- check for ~/.local/bin in PATH ---
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo -e "${YELLOW}⚠️  ~/.local/bin is not in your PATH.${NC}"
    echo "Add this line to your shell config to enable 'duelsplus' globally:"
    echo -e "${CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo
fi
# --- create desktop entry ---
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Duels+
Exec=$BIN_PATH
Icon=$INSTALL_DIR/$FILENAME
Terminal=false
Type=Application
Categories=Game;Utility;
Comment=Lightweight, custom Minecraft Proxy designed to enhance your experience on Hypixel Duels.
EOF
# --- update desktop database (!) ---
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi
echo -e "${GREEN}✔ Duels+ Launcher v$LATEST_VERSION installed successfully.${NC}"
echo -e "Launch it from your application menu or run: ${CYAN}duelsplus${NC}"
echo