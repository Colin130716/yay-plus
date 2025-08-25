# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.1.1
pkgrel=3
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'wget' 'unzip' 'npm' 'go' 'curl' 'figlet' 'lolcat' 'vim' 'flatpak' 'jq' 'bash')
source=("https://github.com/Colin130716/yay-plus/raw/master/yay-plus.sh")
sha256sums=('dc139a0f43cb433bb1298898f309c719f4933dd3bfc976b3fd23720e45e84f5b')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
}