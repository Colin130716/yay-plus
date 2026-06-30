# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.2.0.2
pkgrel=1
epoch=1
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'flatpak' 'jq' 'bash')
optdepends=('npm: 用于 npm/yarn 换源' 'yarn: 用于 npm/yarn 换源')
source=("https://github.com/Colin130716/yay-plus/releases/download/v3.2.0.2-Release/yay-plus.sh")
sha256sums=('d8fa93821a9647f46ddb907b863f7a7c7fb6dc0e840e368cd3ae7234d5182bd2')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
}