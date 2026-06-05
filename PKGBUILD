# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.2.0
pkgrel=1
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'npm' 'figlet' 'lolcat' 'flatpak' 'jq' 'bash')
source=("https://github.com/Colin130716/yay-plus/releases/download/v3.2.0-Release/yay-plus.sh")
sha256sums=('10f34c08c40376a020fdbef0a04a5e2468c9c417954543913e50715faf28d5ec')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
}