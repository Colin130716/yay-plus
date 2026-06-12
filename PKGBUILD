# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.2.0.1
pkgrel=1
epoch=1
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'npm' 'flatpak' 'jq' 'bash')
source=("https://github.com/Colin130716/yay-plus/releases/download/v3.2.0.1-Release/yay-plus.sh")
sha256sums=('671503d19d4621bca6bb79eeed15b0c3d77c1c82137e13042ff5773bd9117f42')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
}