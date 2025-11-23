# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.1.3
pkgrel=1
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'wget' 'unzip' 'npm' 'go' 'curl' 'figlet' 'lolcat' 'vim' 'flatpak' 'jq' 'bash')
source=("https://github.com/Colin130716/yay-plus/releases/download/v3.1.3-Release/yay-plus.sh")
sha256sums=('ed74c7297233750404b8e6f445ecd5dcf17f0d0ecfba3f8df48910fffe41f4fc')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
}