# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.1.1
pkgrel=fix1
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'wget' 'unzip' 'npm' 'go' 'curl' 'figlet' 'lolcat' 'vim' 'flatpak' 'jq')
source=("https://github.com/Colin130716/yay-plus/raw/master/yay-plus.sh")
sha256sums=('c1b2f9076b7d58e8d152499daf9fea39be20ce1e51a2fefd235399df36422a17')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
}