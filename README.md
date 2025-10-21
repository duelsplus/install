# Duels+ Linux Installer

This repository contains the official **Linux installer for Duels+ Launcher**.

This script is a **quicker alternative** to manually downloading and running the AppImage -- and a convenient **alternative to the AUR package** for Arch users.

## Supported Distros

The installer was primarily tested on **Arch Linux**. However, it *should* work on any modern distribution such as:

* Arch / Artix (works as an AUR alternative)
* Ubuntu / Debian / Linux Mint
* Fedora / RHEL
* openSUSE
* Anything else with curl, jq, and unzip available

All installs are done under `~/.local/share/duelsplus`, so root access is **not** necessary.

## Usage

Run this command in your terminal:

```bash
curl -sSL https://get.duelsplus.com | bash
```

### That’s it.
The installer will:

* Download the latest Duels+ Launcher AppImage
* Add a desktop shortcut
* Create a `duelsplus` command in your PATH

After installation, you can launch Duels+ from your application menu or by running:

```bash
duelsplus
```

## Uninstalling
To remove Duels+, run this command in your terminal:
```bash
rm -rf ~/.local/share/duelsplus ~/.local/bin/duelsplus ~/.local/share/applications/duelsplus.desktop
```

## Contributing

**We're open to improvements!** If you’d like to implement or improve something, open a pull request.

---
*Maintained by the Duels+ Team and the rest of the community*