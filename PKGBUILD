# Maintainer: Colin130716 <qsdwin2023@outlook.com>
pkgname=yay-plus
pkgver=3.2.1
pkgrel=3
epoch=3
pkgdesc="一个更易于中国人使用的AUR Helper"
arch=('any')
url="https://github.com/Colin130716/yay-plus"
license=('GPL3')
depends=('git' 'base-devel' 'flatpak' 'jq' 'bash' 'vim')
optdepends=('npm: 用于 npm/yarn/bun 换源' 'yarn: 用于 npm/yarn/bun 换源' 'bun: 用于 npm/yarn/bun 换源')
source=("https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta3/yay-plus.sh"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta3/zh.json"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta3/en.json"
        "https://github.com/Colin130716/yay-plus/releases/download/v3.2.1-Beta3/zh_TW.json")
sha256sums=('55f7399dbe797046eac30df401944fea62857030d88c8379c275eee7d2a97d1b'
            'e5f3293e16d5be7299b8be1c66e5783a7c44bf25b350697f4802d8461372fb53'
            '958a87b475d488fbdac00fe087be9d69f427030123b68dc5b9b64a0a92f3e3eb'
            '4b37f691b8c7760ce965bcde703e541b68abaffb01361e372a1e5a712d57abfd')

package() {
    install -Dm755 "$srcdir/yay-plus.sh" "$pkgdir/usr/bin/yay-plus"
    install -Dm644 "$srcdir/zh.json" "$pkgdir/usr/share/yay-plus/locale/zh.json"
    install -Dm644 "$srcdir/en.json" "$pkgdir/usr/share/yay-plus/locale/en.json"
    install -Dm644 "$srcdir/zh_TW.json" "$pkgdir/usr/share/yay-plus/locale/zh_TW.json"
}