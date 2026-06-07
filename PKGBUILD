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
sha256sums=('66cba12343394634958535f3a625a63fd57d75d49f73880b5dafb0d3023927db')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
}