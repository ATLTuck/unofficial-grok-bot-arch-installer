#!/usr/bin/env bash
# Query Cursor's linux-x64 update feed and bump PKGBUILD + .SRCINFO if needed.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

FEED='https://api2.cursor.sh/updates/api/update/linux-x64/sand/0.0.0/00000000-0000-0000-0000-000000000000/stable'

command -v python3 >/dev/null || { printf 'error: python3 is required\n' >&2; exit 1; }
command -v curl >/dev/null || { printf 'error: curl is required\n' >&2; exit 1; }

resp=$(curl -fsSL "$FEED")

eval "$(printf '%s' "$resp" | python3 -c '
import json, re, sys
data = json.load(sys.stdin)
version = data.get("version") or ""
url = data.get("url") or ""
m = re.search(r"/stable/([0-9a-f]{40})/", url)
if not version or not m:
    sys.stderr.write("could not parse update feed\n")
    sys.exit(1)
print(f"version={version!r}")
print(f"commit={m.group(1)!r}")
')"

[[ "$version" =~ ^[0-9.]+$ ]] || { printf 'error: bad version %s\n' "$version" >&2; exit 1; }
[[ "$commit" =~ ^[0-9a-f]{40}$ ]] || { printf 'error: bad commit %s\n' "$commit" >&2; exit 1; }

current=$(sed -n 's/^pkgver=//p' PKGBUILD | head -n1)
if [[ "$version" == "$current" ]]; then
  printf 'Already at %s (%s)\n' "$version" "$commit"
  exit 0
fi

deb_url="https://downloads.cursor.com/grokbot/stable/${commit}/linux/x64/grok-bot_${version}_amd64.deb"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
printf 'Downloading %s\n' "$deb_url"
curl -fsSL --retry 3 "$deb_url" -o "$tmp"
sha=$(sha256sum "$tmp" | awk '{print $1}')

sed -i \
  -e "s/^pkgver=.*/pkgver=${version}/" \
  -e "s/^_commit=.*/_commit=${commit}/" \
  -e "s/^sha256sums=.*/sha256sums=('${sha}')/" \
  PKGBUILD

if command -v makepkg >/dev/null; then
  makepkg --printsrcinfo > .SRCINFO
elif [[ -f .SRCINFO ]]; then
  sed -i \
    -e "s/^	pkgver = .*/	pkgver = ${version}/" \
    -e "s|^	source = .*|	source = https://downloads.cursor.com/grokbot/stable/${commit}/linux/x64/grok-bot_${version}_amd64.deb|" \
    -e "s/^	sha256sums = .*/	sha256sums = ${sha}/" \
    .SRCINFO
fi

printf 'Bumped %s -> %s (commit %s)\n' "$current" "$version" "$commit"
printf 'sha256 %s\n' "$sha"
