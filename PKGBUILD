# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.1.2
pkgrel=1
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'wget' 'unzip' 'npm' 'go' 'curl' 'figlet' 'lolcat' 'vim' 'flatpak' 'jq' 'bash')
source=("https://github.com/Colin130716/yay-plus/releases/v3.1.2-Release/yay-plus.sh")
sha256sums=('405e35f6029a6ea59d6ae29acbaf301923d830ebd1e11240f128c5985717adad')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
}