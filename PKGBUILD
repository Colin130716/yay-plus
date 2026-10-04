# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.2.1
pkgrel=5
epoch=3
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'flatpak' 'jq' 'bash' 'vim')
optdepends=('npm: 用于 npm/yarn/bun 换源' 'yarn: 用于 npm/yarn/bun 换源' 'bun: 用于 npm/yarn/bun 换源')
source=("https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta5/yay-plus.sh"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta5/zh.json"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta5/en.json"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta5/zh_TW.json")
sha256sums=('b1cb9112de6516d77525020878bcf52ec6a7c45be27a5b62de49cca794b68deb'
            'caa4ddae3f58931c7700a47211767b2763cafcf83730f1cda06f0d65dd69f701'
            '2f1462f408f6d85cec523ec5de68bc642ae8b8f99f9872a160aad6229391b876'
            '142a3f03e53ad8160d427948e44fbfe415555df7b1ade26a63b6352026e86070')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
    install -Dm644 "$srcdir/zh.json" "$pkgdir/usr/share/yay-plus/locale/zh.json"
    install -Dm644 "$srcdir/en.json" "$pkgdir/usr/share/yay-plus/locale/en.json"
    install -Dm644 "$srcdir/zh_TW.json" "$pkgdir/usr/share/yay-plus/locale/zh_TW.json"
}