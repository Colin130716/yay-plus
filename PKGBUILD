# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.2.0.3
pkgrel=2
epoch=3
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'flatpak' 'jq' 'bash' 'vim')
optdepends=('npm: 用于 npm/yarn 换源' 'yarn: 用于 npm/yarn 换源')
source=("https://github.com/Colin130716/yay-plus/releases/download/v3.2.0.3-Beta2/yay-plus.sh"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.0.3-Beta2/zh.sh"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.0.3-Beta2/en.sh"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.0.3-Beta2/zh_TW.sh")
sha256sums=('93fdebda78f2fc98cd864211917f0cea27ac406dcefc1dc9a89f45f9c71bf680'
            '0f97832c132ae3d99116a54ee0bbd50b9004e1ec1469aac09d3dbc35425c9063'
            '69235c0811be0607e5df620c44b20b556478a3b7c1cb869e6075713dac4f80a2'
            'dedb01a43a1d1f775e69890e40dfc2082d2fb377a6aaf6c1e5d5eed34b98d25e')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
    install -Dm644 "$srcdir/zh.sh" "$pkgdir/usr/share/yay-plus/locale/zh.sh"
    install -Dm644 "$srcdir/en.sh" "$pkgdir/usr/share/yay-plus/locale/en.sh"
    install -Dm644 "$srcdir/zh_TW.sh" "$pkgdir/usr/share/yay-plus/locale/zh_TW.sh"
}