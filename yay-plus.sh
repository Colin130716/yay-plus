#!/bin/sh

upgrade_or_install_aur_package() {
    echo "
    1. 检查全部AUR包的更新（暂未开发）
    2. 安装AUR包
    3. 升级此脚本
    4. 退出
    "
    read -p "请输入选项: " choice
    case $choice in
        1)
            echo "都说了没开发，你为什么还要选择它呢？"
            sleep 10
            echo "算了，既然你已经选择了，给你看个东西吧。我先溜了（by qwq9scan114514）"
            sleep 5
            echo "https://github.com/qwq9scan114514/yay-s-joke"
            echo "来听首歌吧"
            sudo wget https://fastgit.cc/https://github.com/qwq9scan114514/yay-s-joke/raw/master/3.aac -O /tmp/yay-plus/3.aac
            sudo mpv --no-video /tmp/yay-plus/3.aac
            sudo rm -f /tmp/yay-plus/3.aac
            exit 114514
            ;;
        2)
            clone_aur_repo
            ;;
        3)
            cd /tmp/yay-plus
            echo "是否使用代理 (y/n)"
            read -p "请输入选项: " choice
            case $choice in
                y)
                    sudo wget https://fastgit.cc/https://github.com/Colin130716/yay-plus/raw/master/yay-plus.sh -o yay-plus1.sh
                    exit_status=$?
                    sudo wget https://fastgit.cc/https://github.com/Colin130716/yay-plus/raw/master/verify.md5 -o verify.md5

                    ;;
                n)
                    sudo wget https://github.com/Colin130716/yay-plus/raw/master/yay-plus.sh -o yay-plus1.sh
                    exit_status=$?
                    sudo wget https://github.com/Colin130716/yay-plus/raw/master/verify.md5 -o verify.md5
                    ;;
            esac
            if [ $exit_status -eq 0 ]; then
                sudo md5sum -c verify.md5
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
            sudo chmod +x yay-plus1.sh
            sudo echo "升级成功，重新运行中"
            sudo rm -f verify.md5
            sudo mv yay-plus1.sh yay-plus.sh
            sudo ./yay-plus.sh
            ;;
        4)
            exit 0
            ;;
    esac
}

download_dialog() {
    sudo wget https://fastgit.cc/https://github.com/Colin130716/yay-plus/raw/master/data.tar.xz -O /data.tar.xz
    sudo tar -xf /data.tar.xz
    sudo rm -f /data.tar.xz
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
}

clone_aur_repo() {
    aur_source=$(sudo /usr/bin/dialog --inputbox "请输入你想要下载项目的名称：" 0 0 --output-fd 1 --clear)
    echo "搜索pacman中..."
    pacman -Q | grep -i "$aur_source" >/dev/null 2>&1 && pm=1 || pm=0
    echo "搜索AUR中..."
    cd /tmp/yay-plus
    sudo curl -s https://aur.archlinux.org/packages/ | grep -i "$aur_source" >/dev/null 2>&1 && aur=1 || aur=0
    if [$pm -eq 1] && [$aur -eq 1]; then
        echo "请选择安装方式：1：pacman 2：AUR"
        read install_method
        case $install_method in
            1)
                install_package $aur_source
                ;;
            2)
                sudo rm -rf ./$aur_source
                sudo git clone https://aur.archlinux.org/"$aur_source".git
                cd $aur_source
                set_env
                set_proxy
                ;;
        esac
    elif [$pm -eq 1] && [$aur -eq 0]; then
        install_package $aur_source
    elif [$pm -eq 0] && [$aur -eq 1]; then
        sudo rm -rf "$aur_source"
        sudo git clone https://aur.archlinux.org/"$aur_source".git
        cd "$aur_source"
        set_env
        set_proxy
        sudo makepkg -si --noconfirm
    else
        echo "未找到该软件包"
    fi
}

set_proxy() {
    echo 请问您需要哪个代理？1："https://fastgit.cc/ 2：https://mirror.ghproxy.com/（备用，下载速度较慢） 3：https://gh.api.99988866.xyz/（备用2,不稳定） 4：不使用Github代理（不推荐）"
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
    esac
    sudo chmod 777 ./
    build_package
}

build_package() {
    makepkg -si
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
download_dialog  # 虽然有“亿”点bug,但又不是不能用（
upgrade_or_install_aur_package
