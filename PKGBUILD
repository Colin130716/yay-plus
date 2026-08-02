# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.2.1
pkgrel=2
epoch=3
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'flatpak' 'jq' 'bash' 'vim')
optdepends=('npm: 用于 npm/yarn 换源' 'yarn: 用于 npm/yarn 换源')
source=("https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta2/yay-plus.sh"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta2/zh.sh"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta2/en.sh"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta2/zh_TW.sh")
sha256sums=('3cfcd89e51fd1346a1e5bf8ce06d3ddee591165df40762b2074af8049cf855a9'
            '3bfef9f5e8dfc8fe7aff6684f9fcb881befed6943cba2c4cac911d127e99a186'
            '0a96c3926ed07de1f38598d66ada55b2646315bb774b85c55dbb478f5604b917'
            'cfac75b0bf3feedc8679260b01deb7b02e4242cee5ae69919dbe0b4105580914')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
    install -Dm644 "$srcdir/zh.sh" "$pkgdir/usr/share/yay-plus/locale/zh.sh"
    install -Dm644 "$srcdir/en.sh" "$pkgdir/usr/share/yay-plus/locale/en.sh"
    install -Dm644 "$srcdir/zh_TW.sh" "$pkgdir/usr/share/yay-plus/locale/zh_TW.sh"
}