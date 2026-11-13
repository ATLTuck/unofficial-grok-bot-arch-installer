# Unofficial Grok Bot Arch installer
# Repackages the official grok-bot_<version>_amd64.deb as a pacman package.
# Not affiliated with xAI, SpaceXAI, or Cursor.
#
# To bump: run scripts/bump.sh, or set pkgver, _commit, and sha256sums from
# https://api2.cursor.sh/updates/api/update/linux-x64/sand/0.0.0/00000000-0000-0000-0000-000000000000/stable
# Deb URL: https://downloads.cursor.com/grokbot/stable/<commit>/linux/x64/grok-bot_<version>_amd64.deb

pkgname=grok-bot-bin
pkgver=1.0.3
_commit=be8eaf76ba888db05a6a8950922f5fc8bb4d14e9
pkgrel=1
pkgdesc="Grok Bot desktop agent (unofficial Arch package of the official Linux .deb)"
arch=('x86_64')
url="https://github.com/ATLTuck/unofficial-grok-bot-arch-installer"
license=('custom:unknown')
depends=(
  'gtk3'
  'libnotify'
  'nss'
  'libxss'
  'libxtst'
  'xdg-utils'
  'at-spi2-core'
  'util-linux-libs'
  'libsecret'
)
optdepends=('libappindicator: system tray icon support')
provides=('grok-bot')
conflicts=('grok-bot')
source=("https://downloads.cursor.com/grokbot/stable/${_commit}/linux/x64/grok-bot_${pkgver}_amd64.deb")
noextract=("grok-bot_${pkgver}_amd64.deb")
options=('!debug' '!strip')
sha256sums=('ef90d8171fe207f39b887753c1ff492c6684a1a9f910d6e1dfa0303889fcf8f0')

package() {
  bsdtar -xOf "${srcdir}/grok-bot_${pkgver}_amd64.deb" data.tar.xz \
    | bsdtar -xJf - -C "${pkgdir}"

  if [[ -f "${pkgdir}/opt/Grok Bot/grok-bot" ]]; then
    _bin=grok-bot
  else
    _bin=sand
  fi

  # The .deb uses update-alternatives; Arch gets a plain wrapper instead.
  install -dm755 "${pkgdir}/usr/bin"
  cat > "${pkgdir}/usr/bin/${_bin}" <<EOF
#!/bin/sh
exec "/opt/Grok Bot/${_bin}" "\$@"
EOF
  chmod 755 "${pkgdir}/usr/bin/${_bin}"

  sed -i "s|^Exec=.*|Exec=/usr/bin/${_bin} %U|" \
    "${pkgdir}/usr/share/applications/${_bin}.desktop"

  # SUID sandbox works with or without unprivileged user namespaces.
  chmod 4755 "${pkgdir}/opt/Grok Bot/chrome-sandbox"

  # Skip the bundled AppArmor profile; Arch/Manjaro do not enforce it by default.
  # Desktop/mime/icon caches are refreshed by pacman hooks.

  install -Dm644 "${pkgdir}/opt/Grok Bot/LICENSE.electron.txt" \
    "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE.electron.txt"
}
