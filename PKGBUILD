# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.1.1
pkgrel=1
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'wget' 'unzip' 'npm' 'go' 'curl' 'figlet' 'lolcat' 'vim' 'flatpak' 'jq')
source=("https://github.com/Colin130716/yay-plus/raw/master/yay-plus.sh")
sha256sums=('d8a923b611e3522859641686f4c7855bb5eabd81487d22f52541f56c6fd044ca')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
}