#!/usr/bin/env bash
# Unofficial Grok Bot Arch installer
# Builds a native pacman package from the official Linux .deb.
# Not affiliated with xAI, SpaceXAI, or Cursor.
set -euo pipefail

REPO_OWNER="ATLTuck"
REPO_NAME="unofficial-grok-bot-arch-installer"
RAW_BASE="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main"

usage() {
  cat <<'EOF'
Unofficial Grok Bot Arch installer

Builds grok-bot-bin with makepkg from the official Linux .deb and installs
it with pacman. debtap is not used.

Usage:
  ./install.sh                  Download the official .deb, build, install
  ./install.sh /path/to.deb     Use a local .deb instead of downloading
  ./install.sh --deb FILE       Same as passing FILE
  ./install.sh --build-only     Build the package, do not install
  ./install.sh -h | --help      Show this help

Requires an Arch-based distro (Arch, Manjaro, EndeavourOS, CachyOS, …)
and base-devel. You will be asked for sudo when pacman installs.
EOF
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

LOCAL_DEB=""
BUILD_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --build-only)
      BUILD_ONLY=1
      shift
      ;;
    --deb)
      [[ $# -ge 2 ]] || die "--deb needs a path"
      LOCAL_DEB=$2
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      LOCAL_DEB=$1
      shift
      ;;
  esac
done

if [[ -n "$LOCAL_DEB" ]]; then
  [[ -f "$LOCAL_DEB" ]] || die "deb not found: $LOCAL_DEB"
  LOCAL_DEB=$(readlink -f "$LOCAL_DEB")
fi

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
else
  die "cannot read /etc/os-release"
fi

case "${ID:-}|${ID_LIKE:-}" in
  *arch*|*manjaro*|*endeavouros*|*cachyos*)
    ;;
  *)
    die "this installer is for Arch-based systems (found ID=${ID:-unknown})"
    ;;
esac

command -v pacman >/dev/null || die "pacman not found"
command -v makepkg >/dev/null || die "makepkg not found — install base-devel: sudo pacman -S --needed base-devel"
command -v bsdtar >/dev/null || die "bsdtar not found — install libarchive"
command -v fakeroot >/dev/null || die "fakeroot not found — install base-devel: sudo pacman -S --needed base-devel"

if [[ "${EUID}" -eq 0 ]]; then
  die "do not run as root; makepkg refuses that. run as your user (sudo is used only for pacman)"
fi

ORIG_PWD=$PWD
SCRIPT_PATH=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=""
if [[ -e "$SCRIPT_PATH" && ! "$SCRIPT_PATH" =~ ^(/dev/fd/|/proc/self/fd/) ]]; then
  SCRIPT_DIR=$(cd "$(dirname "$SCRIPT_PATH")" && pwd)
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/grok-bot-arch-XXXXXX")
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/PKGBUILD" ]]; then
  cp "$SCRIPT_DIR/PKGBUILD" "$WORK/PKGBUILD"
else
  command -v curl >/dev/null || die "curl not found (needed to fetch PKGBUILD)"
  printf 'Fetching PKGBUILD from GitHub…\n'
  curl -fsSL "$RAW_BASE/PKGBUILD" -o "$WORK/PKGBUILD"
fi

[[ -f "$WORK/PKGBUILD" ]] || die "PKGBUILD missing"

pkgver=$(sed -n 's/^pkgver=//p' "$WORK/PKGBUILD" | head -n1)
[[ -n "$pkgver" ]] || die "could not read pkgver from PKGBUILD"

deb_name="grok-bot_${pkgver}_amd64.deb"
if [[ -n "$LOCAL_DEB" ]]; then
  cp "$LOCAL_DEB" "$WORK/$deb_name"
  printf 'Using local deb: %s\n' "$LOCAL_DEB"
fi

cd "$WORK"
printf 'Building grok-bot-bin %s…\n' "$pkgver"

MAKEPKG_OPTS=(-s --cleanbuild)
if [[ ! -t 0 ]]; then
  MAKEPKG_OPTS+=(--noconfirm)
fi

makepkg "${MAKEPKG_OPTS[@]}"

shopt -s nullglob
pkgs=(grok-bot-bin-*.pkg.tar.zst)
shopt -u nullglob
[[ ${#pkgs[@]} -eq 1 ]] || die "expected one package, found: ${pkgs[*]:-none}"

printf 'Built %s\n' "${pkgs[0]}"

if [[ "$BUILD_ONLY" -eq 1 ]]; then
  dest=${SCRIPT_DIR:-$ORIG_PWD}
  cp "${pkgs[0]}" "$dest/"
  printf 'Package copied to %s/%s\n' "$dest" "${pkgs[0]}"
  exit 0
fi

if [[ -t 0 ]]; then
  sudo pacman -U "${pkgs[0]}"
else
  sudo pacman -U --noconfirm "${pkgs[0]}"
fi

printf '\nInstalled. Launch from the app menu or run: grok-bot\n'
printf 'Uninstall: sudo pacman -Rns grok-bot-bin\n'
