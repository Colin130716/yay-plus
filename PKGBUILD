# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.1.2
pkgrel=2
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'wget' 'unzip' 'npm' 'go' 'curl' 'figlet' 'lolcat' 'vim' 'flatpak' 'jq' 'bash')
source=("https://github.com/Colin130716/yay-plus/releases/download/v3.1.2-Release/yay-plus.sh")
sha256sums=('df9203996810a2658c49456bdab14131f2be6e06f5fa9d0b3d0bb8bc4db98e25')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
}