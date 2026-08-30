# Unofficial Grok Bot Arch Installer

Unofficial Arch / Manjaro installer for the **Grok Bot** desktop agent. It turns the official Linux `.deb` into a native `pacman` package.

**Not affiliated with, endorsed by, or associated with xAI, SpaceXAI, or Cursor.** Grok Bot itself is proprietary; this repo only contains packaging scripts.

debtap is a poor fit here. The `.deb` is an Electron app with Debian-only dependency names, `update-alternatives`, AppArmor, and apt keyrings. This installer extracts the payload and installs it the Arch way.

## Install

Needs `base-devel` (`makepkg`, `fakeroot`, `sudo`).

```bash
git clone https://github.com/ATLTuck/unofficial-grok-bot-arch-installer.git
cd unofficial-grok-bot-arch-installer
./install.sh
```

If you already have the official `.deb`:

```bash
./install.sh /path/to/grok-bot_0.30.0_amd64.deb
```

Or build from the PKGBUILD yourself:

```bash
makepkg -si
```

After install, launch **Grok Bot** from the app menu or run `grok-bot`.

### Release packages

GitHub Releases attach a ready-made `.pkg.tar.zst`. Download it first, then install locally — do not pass the URL to `pacman -U` (default `SigLevel = Required` looks for a `.sig` that these unsigned packages do not ship):

```bash
curl -fLO https://github.com/ATLTuck/unofficial-grok-bot-arch-installer/releases/download/v0.30.0/grok-bot-bin-0.30.0-1-x86_64.pkg.tar.zst
sudo pacman -U grok-bot-bin-0.30.0-1-x86_64.pkg.tar.zst
```

## What it installs

| Path | Role |
| --- | --- |
| `/opt/Grok Bot/` | Upstream Electron app |
| `/usr/bin/grok-bot` | Wrapper (replaces Debian `update-alternatives`) |
| `/usr/share/applications/grok-bot.desktop` | App menu entry |

User data lives in `~/.config/Grok Bot/` and is left alone on upgrades.

Optional tray support:

```bash
sudo pacman -S libappindicator
```

## Uninstall

```bash
sudo pacman -Rns grok-bot-bin
```

## Updating

Cursor's built-in updater does not cover Linux. Bump this package instead.

- CI polls the linux-x64 update feed daily and tags a new `v<version>` when the official `.deb` moves.
- To bump by hand: `./scripts/bump.sh`, then commit, tag `v<pkgver>`, and push.

Feed used as the version oracle:

`https://api2.cursor.sh/updates/api/update/linux-x64/sand/0.0.0/00000000-0000-0000-0000-000000000000/stable`

Official `.deb`:

`https://downloads.cursor.com/grokbot/stable/<commit>/linux/x64/grok-bot_<version>_amd64.deb`

## License

Packaging scripts in this repository are MIT. That does **not** apply to Grok Bot.
