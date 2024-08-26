#!/bin/sh

install_package() {
    sudo pacman -Syyu
    sudo pacman -S --noconfirm "$1"
}

install_packages() {
    install_package git
    install_package base-devel
    install_package wget
    install_package unzip
    install_package npm
    install_package go
}

set_env() {
    echo "需要使用go代理吗？(y/n)"
    read set_go_proxy
    if [ "$set_go_proxy" == "y" ]; then
        export GO111MODULE=on
        export GOPROXY=https://goproxy.cn
    fi
    echo "需要使用npm代理吗？(y/n)"
    read set_npm_proxy
    if [ "$set_npm_proxy" == "y" ]; then
    npm config set registry https://registry.npmmirror.com
}

download_dialog() {
    echo "下载dialog（TUI工具）时需要使用代理吗？(y/n)"
    read use_proxy
    if [ "$use_proxy" == "y" ]; then
        proxy_url="httpa://fastgit.cc/"
        wget "$proxy_url"https://github.com/Colin130716/AUR_Quick_Download_for_Chinese/raw/master/dialog
    else
        wget https://github.com/Colin130716/AUR_Quick_Download_for_Chinese/raw/master/dialog
    fi
    sudo mv dialog /usr/bin/dialog
    sudo rm -rf dialog
}

clone_aur_repo() {
    aur_source=$(dialog --inputbox "请输入你想要下载项目的aur名称：" 0 0 --output-fd 1)
    cd ~/Gitdir
    sudo rm -rf "$aur_source"
    git clone https://aur.archlinux.org/"$aur_source".git
    cd "$aur_source"
}

set_proxy() {
    options=("https://fastgit.cc/" "https://mirror.ghproxy.com/（备用，下载速度较慢）" "https://gh.api.99988866.xyz/（备用2,不稳定）" "不使用Github代理（不推荐）")
    choice=$(dialog --title "请选择代理地址" 0 0 0 $(options[@]) --output-fd 1)
    case $choice in
        "https://fastgit.cc/")
            sed -i 's/https:\/\/github.com\//https:\/\/fastgit.cc\/https:\/\/github.com\//g' PKGBUILD
            ;;
        "https://mirror.ghproxy.com/（备用，下载速度较慢）")
            sed -i 's/https:\/\/github.com\//https:\/\/mirror.ghproxy.com\/https:\/\/github.com\//g' PKGBUILD
            ;;
        "https://gh.api.99988866.xyz/（备用2,不稳定）")
            sed -i 's/https:\/\/github.com\//https:\/\/gh.api.99988866.xyz\/https:\/\/github.com\//g' PKGBUILD
            ;;
        "不使用Github代理")
            ;;
    esac
}

build_package() {
    makepkg -si
}

install_packages
set_env
download_dialog
clone_aur_repo
set_proxy
build_package
