#!/bin/sh

upgrade_or_install_aur_package() {
    choice = $(dialog --title "选择操作" --menu "请选择要进行的操作" 0 0 0 \
        1 "升级" \
        2 "安装" \
        3 "升级本软件" \
        3 "退出" \
        2>&1 >/dev/tty)
    case $choice in
        1)
            check_version "$1"
            ;;
        2)
            install_aur_package
            ;;
        3)
            wget https://fastgit.cc/https://github.com/Colin130716/yay-plus/raw/master/yay-plus.sh -o yay-plus1.sh
            exit_status=$?
            if [ $exit_status -eq 0 ]; then
                md5sum -c verify.md5
                if [ $? -eq 0 ]; then
                    echo "下载成功"
                else
                    echo "MD5校验失败，请检查网络连接，或更改DNS"
                    sleep 3
                    upgrade_or_install_aur_package
                fi
            else
                echo "下载失败，请检查网络连接"
                sleep 3
                upgrade_or_install_aur_package
            fi
            chmod +x yay-plus1.sh
            echo "升级成功，重新运行中"
            mv yay-plus1.sh yay-plus.sh
            sudo ./yay-plus.sh
            ;;
        4)
            exit 0
            ;;
    esac
}

update_aur_package() {
    cd "$1"
    set_env
    set_proxy
    makepkg -si
    cd ..
}

is_aur_package() {
    if [[ $(pacman -Qi | grep "$1" | grep "AUR") ]]; then
        return 0
    else
        return 1
    fi
}

get_latest_version() {
    latest_version=$(curl -s "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${1}" | grep "pkgver" | awk '{print $3}')
    echo "$latest_version"
}

check_version() {
    sudo pacman -Syyu
    current_version=$(pacman -Qi "$1" | grep "Version" | awk '{print $3}')
    latest_version=$(get_latest_version "$1")
    if [ "$current_version" != "$latest_version" ]; then
        echo "$1 有更新: $current_version -> $latest_version"
        echo "是否更新？(y/n)"
        read update
        if [ "$update" == "y" ]; then
            update_aur_package "$1"
        fi
    else
        echo "$1 是最新版本"
    fi
}


install_package() {
    sudo pacman -S --needed --noconfirm "$1"
}

install_packages() {
    install_package git
    install_package base-devel
    install_package wget
    install_package unzip
    install_package npm
    install_package go
    install_package curl
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
    echo "正在下载dialog（TUI工具）。下载时时需要使用代理吗？(y/n)"
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
    cd /tmp/yay-plus
    if [ -d "$aur_source" ]; then
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
    exit_status=$?

    if [ $exit_status -ne 0 ]; then
        echo "makepkg出现错误 $exit_status ，该AUR包可能是过时的，或者您的网络不通畅"
        read -p "是否要继续安装其他AUR包？(y/n)" continue
        if [ "$continue" == "y" ]; then
            upgrade_or_install_aur_package
        else
            exit $exit_status
    else
        echo "makepkg 成功完成"
        sleep 1
        upgrade_or_install_aur_package
    fi
}

sudo mkdir /tmp/yay-plus
sudo pacman -Syyu --noconfirm
install_packages
download_dialog
upgrade_or_install_aur_package
