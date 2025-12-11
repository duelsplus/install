#!/usr/bin/env bash
set -euo pipefail

action=${1:-install}

if [ "$(id -u)" -eq 0 ]; then
    echo "Run me as normal user, not root!"
    exit 1
fi

if grep -q "CHROMEOS_RELEASE_NAME" /etc/lsb-release 2>/dev/null; then
    echo "ChromeOS is not supported!"
    exit 1
fi

command -v curl >/dev/null || { echo "curl is required"; exit 1; }
command -v jq >/dev/null || { echo "jq is required"; exit 1; }
command -v sha256sum >/dev/null || { echo "sha256sum is required"; exit 1; }
command -v tar >/dev/null || command -v unzip >/dev/null || { echo "tar or unzip is required"; exit 1; }

BIN="$HOME/.local/bin/duelsplus"
INSTALL_DIR="$HOME/.local/share/duelsplus"
TMP="$INSTALL_DIR/tmp"

if [ "$action" = uninstall ]; then
    if [ -f "$BIN" ]; then
        rm -f "$BIN"
        rm -rf "$INSTALL_DIR"
        echo "Duels+ CLI uninstalled."
    else
        echo "Duels+ CLI is not installed."
    fi
    exit 0
fi

if command -v duelsplus >/dev/null 2>&1 || alias duelsplus >/dev/null 2>&1; then
    echo "'duelsplus' already exists in your PATH."
    echo "Proceeding anyway..."
    #read -p "Do you want to continue and overwrite? (y/N) " confirm
    #case "$confirm" in
    #    [yY]*) echo "Proceeding..." ;;
    #    *) echo "Installation cancelled!"; exit 0 ;;
    #esac
fi

platform="$(uname -s) $(uname -m)"
case "$platform" in
  'Darwin x86_64') target=darwin-x64 ;;
  'Darwin arm64') target=darwin-arm64 ;;
  'Linux aarch64'|'Linux arm64') target=linux-arm64 ;;
  'Linux x86_64'*) target=linux-x64 ;;
  *) echo "Unsupported platform: $platform"; exit 1 ;;
esac

release_json=$(curl -sSL https://api.github.com/repos/duelsplus/cli/releases/latest)
version=$(echo "$release_json" | jq -r --arg t "$target" '.tag_name')
url=$(echo "$release_json" | jq -r --arg t "$target" '.assets[] | select(.name | test($t)) | .browser_download_url')
digest=$(echo "$release_json" | jq -r --arg t "$target" '.assets[] | select(.name | test($t)) | .digest')

[ -z "$url" ] && { echo "No release available for $target"; exit 1; }

mkdir -p "$HOME/.local/bin" "$TMP"
echo "Downloading Duels+ CLI $version..."
archive="$TMP/duelsplus.tar.gz"
curl --fail --location --progress-bar --output "$archive" "$url" || {
    echo "Failed to download CLI from $url"
    exit 1
}

echo "Validating checksum..."
computed=$(sha256sum "$archive" | awk '{print $1}')
expected=${digest#sha256:}

if [ "$computed" != "$expected" ]; then
    echo "Checksum mismatch!"
    exit 1
fi

rm -f "$BIN"
tar -xf "$archive" -C "$TMP" || { echo "Failed to extract"; exit 1; }
binary=$(find "$TMP" -type f -name "duelsplus-*" \( -perm -u=x -o -perm -g=x -o -perm -o=x \) | head -n1)
[ -z "$binary" ] && { echo "Failed to locate binary"; exit 1; }

mv "$binary" "$BIN" || { echo "Failed to move binary"; exit 1; }
chmod +x "$BIN"
rm -rf "$TMP"

if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo "Add $HOME/.local/bin to your PATH by adding this line to your shell config:"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
fi

echo "Duels+ CLI installed to $BIN"
