#!/bin/bash


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
            clear
            echo "yay+正在退出，感谢使用，Shell版不再更新，可以去我的代码仓库下载PyQt版"
            exit 0
            ;;
    esac
}

install_package() {
    sudo pacman -S --needed --noconfirm "$1"
}

install_packages() {
    echo -e "安装软件包：\033[34m git \033[0m"
    install_package git
    echo -e "安装软件包：\033[34m base-devel \033[0m"
    install_package base-devel
    echo -e "安装软件包：\033[34m wget \033[0m"
    install_package wget
    echo -e "安装软件包：\033[34m unzip \033[0m"
    install_package unzip
    echo -e "安装软件包：\033[34m npm \033[0m"
    install_package npm
    echo -e "安装软件包：\033[34m go \033[0m"
    install_package go
    echo -e "安装软件包：\033[34m curl \033[0m"
    install_package curl
    echo -e "安装软件包：\033[34m figlet \033[0m"
    install_package figlet
    echo -e "安装软件包：\033[34m lolcat \033[0m"
    install_package lolcat
    echo -e "安装软件包：\033[34m vim \033[0m"
    install_package vim
}

set_env() {
    echo "需要使用go代理吗？(y/N)"
    read set_go_proxy
    if [ "$set_go_proxy" == "y" ]; then
        echo -e "执行：\033[34m export GO111MODULE=on \033[0m"
        export GO111MODULE=on
        echo -e "执行：\033[34m export GOPROXY=https://goproxy.cn \033[0m"
        export GOPROXY=https://goproxy.cn
    fi
    if [ "$set_go_proxy" == "Y" ]; then
        echo -e "执行：\033[34m export GO111MODULE=on \033[0m"
        export GO111MODULE=on
        echo -e "执行：\033[34m export GOPROXY=https://goproxy.cn \033[0m"
        export GOPROXY=https://goproxy.cn
    fi
    echo "需要使用npm代理吗？(y/N)"
    read set_npm_proxy
    if [ "$set_npm_proxy" == "y" ]; then
        echo -e "执行：\033[34m npm config set registry https://registry.npmmirror.com/ \033[0m"
        npm config set registry https://registry.npmmirror.com/
    fi
    if [ "$set_npm_proxy" == "Y" ]; then
        echo -e "执行：\033[34m npm config set registry https://registry.npmmirror.com/ \033[0m"
        npm config set registry https://registry.npmmirror.com/
    fi
	echo "是否要查看PKGBUILD内容？(y/N)"
	read read_PKGBUILD
	if [ "$read_PKGBUILD" == "y" ]; then
        echo -e "执行：\033[34m sudo vim PKGBUILD \033[0m"
		sudo vim PKGBUILD
	fi
	clear
}

clone_aur_repo() {
    read -p "请输入软件包名称：" aur_source
    sudo rm -rf "$aur_source"
    echo "正在尝试pacman安装..."
    echo -e "执行：\033[34m  \033[0m"
    sudo pacman -S "$aur_source"
    if [ $? -eq 0 ]; then
        clear
        echo "pacman安装成功"
        upgrade_or_install_aur_package
    else
        clear
        echo "pacman安装失败，正在尝试AUR安装..."
        echo -e "执行：\033[34m sudo git clone https://aur.archlinux.org/"$aur_source".git \033[0m"
        sudo git clone https://aur.archlinux.org/"$aur_source".git
        if [ $? -eq 0 ]; then
            echo "查找到 $aur_source ，正在开始makepkg过程"
        else
            echo "git clone失败，请检查网络连接，或您输入的是不存在的软件包"
            exit 1
        fi
        cd "$aur_source"
        set_env
        set_proxy
        build_package
    fi
}

set_proxy() {
    echo "请问您需要哪个代理？1：https://fastgit.cc/（目前测试速度较慢） 2：https://mirror.ghproxy.com/（备用，下载速度较慢） 3：https://gh.api.99988866.xyz/（备用2,不稳定） 4：https://gh.llkk.cc/（推荐，速度较快） 5：https://github.moeyy.xyz/（推荐） 6：不使用Github代理（不推荐）"
    read proxy
    case $proxy in
        1)
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://fastgit.cc/https://github.com/ \033[0m"
            sudo sed -i 's#https://github.com/#https://fastgit.cc/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://fastgit.cc/https://raw.githubusercontent.com/ \033[0m"
            sudo sed -i 's#https://raw.githubusercontent.com/#https://fastgit.cc/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        2)
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://mirror.ghproxy.com/https://github.com/ \033[0m"
            sudo sed -i 's#https://github.com/#https://mirror.ghproxy.com/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://mirror.ghproxy.com/https://raw.githubusercontent.com/ \033[0m"
            sudo sed -i 's#https://raw.githubusercontent.com/#https://mirror.ghproxy.com/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        3)
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://gh.api.99988866.xyz/https://github.com/ \033[0m"
            sudo sed -i 's#https://github.com/#https://gh.api.99988866.xyz/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://gh.api.99988866.xyz/https://raw.githubusercontent.com/ \033[0m"
            sudo sed -i 's#https://raw.githubusercontent.com/#https://gh.api.99988866.xyz/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        4)
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://gh.llkk.cc/https://github.com/ \033[0m"
            sudo sed -i 's#https://github.com/#https://gh.llkk.cc/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://gh.llkk.cc/https://raw.githubusercontent.com/ \033[0m"
            sudo sed -i 's#https://raw.githubusercontent.com/#https://gh.llkk.cc/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        5)
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://github.moeyy.xyz/https://github.com/ \033[0m"
            sudo sed -i 's#https://github.com/#https://github.moeyy.xyz/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://github.moeyy.xyz/https://raw.githubusercontent.com/ \033[0m"
            sudo sed -i 's#https://raw.githubusercontent.com/#https://github.moeyy.xyz/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;

    esac
    clear
    echo -e "为 \033[37m /tmp/yay-plus 文件夹下的所有文件（夹） \033[0m提取\033[34m 777 \033[0m权限"
    sudo chmod 777 /tmp/yay-plus/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*
    build_package
}

build_package() {
    echo -e "执行：\033[34m makepkg -si --skippgpcheck \033[0m"
    makepkg -si --skippgpcheck
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "makepkg出现错误 $exit_status ，该AUR包可能是过时的，或者您的网络不通畅，当然也可以去 https://github.com/Colin130716/yay-plus/issues 打Colin130716(bushi)，目前更新AUR包的功能暂未完善（不会写.jpg），也可以帮助我们，提交一个PR"
        exit 2
    else
        clear
        echo "makepkg 成功完成"
        sleep 1
        upgrade_or_install_aur_package
    fi
}


start_yay_plus() {
    echo -e "建立文件夹：\033[34m /tmp/yay-plus \033[0m"
    sudo mkdir /tmp/yay-plus
    echo -e "使用\033[34m -Syyu --noconfirm \033[0m参数执行\033[34m pacman \033[0m"
    sudo pacman -Syyu --noconfirm
    install_packages
    clear


    echo "YAY+" | lolcat | figlet
    echo "Final" | lolcat | figlet
    echo "Version" | lolcat | figlet
    echo -e "欢迎使用yay+ \033[31m最终版本\033[0m"
    echo -e "\033[36m仓库地址：https://github.com/Colin130716/yay-plus/\033[0m"
    echo -e "\033[36m看乐子（感谢我的朋友asSK）：https://github.com/qwq9scan114514/yay-s-joke/\033[0m"

    sleep 5
    upgrade_or_install_aur_package
}


warn() {
    echo -e "\033[41;37m WARNING \033[0m"
    echo -e "  必须要用\033[31m Arch \033[0m系的系统，别拿着个\033[33m Ubuntu \033[0m跑过来用这个脚本，到时候出问题又来找我，我直接给你挂 https://github.com/qwq9scan114514/yay-s-joke/ 里"
    pacman -h
    if [ $? -eq 0 ]; then
        echo "检测到您是Arch系用户，正在执行下面的步骤"
        start_yay_plus
    else
        echo -e "\033[37m非Arch系用户爬\033[0m"
        exit 3
    fi
}

warn

