#!/bin/bash
# 吊爆的AUR安装工具

upgrade_or_install_aur_package() {
	cd /tmp/yay-plus
	echo "
    1. 安装AUR包
    2. 退出
    "
    read -p "请输入选项: " choice
    case $choice in
        1)
            clone_aur_repo
            ;;
        2)
            exit 0
            ;;
    esac
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
    install_package mpv
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
        npm config set registry https://registry.npmmirror.com/
    fi
	echo "是否要查看PKGBUILD内容？(y/n)"
	read read_PKGBUILD
	if [ "$read_PKGBUILD" == "y" ]; then
		sudo vim PKGBUILD
	fi
}

clone_aur_repo() {
    read -p "请输入软件包名称：" aur_source
    sudo rm -rf "$aur_source"
    sudo git clone https://aur.archlinux.org/"$aur_source".git
    cd "$aur_source"
    set_env
    set_proxy
    build_package
}

set_proxy() {
    echo "请问您需要哪个代理？1：https://fastgit.cc/（目前测试速度较慢） 2：https://mirror.ghproxy.com/（备用，下载速度较慢） 3：https://gh.api.99988866.xyz/（备用2,不稳定） 4：https://gh.llkk.cc/（推荐，速度较快） 5：https://github.moeyy.xyz/（推荐） 6：不使用Github代理（不推荐）"
    read proxy
    case $proxy in
        1)
            sudo sed -i 's#https://github.com/#https://fastgit.cc/https://github.com/#g' PKGBUILD
            sudo sed -i 's#https://raw.githubusercontent.com/#https://fastgit.cc/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        2)
            sudo sed -i 's#https://github.com/#https://mirror.ghproxy.com/https://github.com/#g' PKGBUILD
            sudo sed -i 's#https://raw.githubusercontent.com/#https://mirror.ghproxy.com/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        3)
            sudo sed -i 's#https://github.com/#https://gh.api.99988866.xyz/https://github.com/#g' PKGBUILD
            sudo sed -i 's#https://raw.githubusercontent.com/#https://gh.api.99988866.xyz/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        4)
            sudo sed -i 's#https://github.com/#https://gh.llkk.cc/https://github.com/#g' PKGBUILD
            sudo sed -i 's#https://raw.githubusercontent.com/#https://gh.llkk.cc/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        5)
            sudo sed -i 's#https://github.com/#https://github.moeyy.xyz/https://github.com/#g' PKGBUILD
            sudo sed -i 's#https://raw.githubusercontent.com/#https://github.moeyy.xyz/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;

    esac
    sudo chmod 777 ./
    build_package
}

build_package() {
    makepkg -si --skippgpcheck
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "makepkg出现错误 $exit_status ，该AUR包可能是过时的，或者您的网络不通畅，当然也可以去 https://github.com/Colin130716/yay-plus/issues 打Colin130716(bushi)，目前更新AUR包的功能暂未完善（不会写.jpg），也可以帮助我们，提交一个PR"
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
upgrade_or_install_aur_package
