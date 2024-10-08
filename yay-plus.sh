#!/bin/bash

upgrade_or_install_aur_package() {
	cd /tmp/yay-plus
	echo YAY+ | figlet | lolcat
    echo Final | figlet | lolcat
    echo Version | figlet | lolcat
	echo "
    1. 安装软件包
    2. 卸载软件包
    3. 退出
    "
    read -p "请输入选项: " choice
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 首页选择：$choice" >> ~/.yay-plus/$create_log_time.log
    case $choice in
        1)
            clone_aur_repo
            ;;
        2)
            uninstall_package
            ;;
        3)
            clear
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 软件退出，返回值0" >> ~/.yay-plus/$create_log_time.log
            echo "yay+正在退出，感谢使用，Shell版不再更新，可以去我的代码仓库下载PyQt版"
            exit 0
            ;;
    esac
}

install_package() {
    sudo pacman -S --needed --noconfirm "$1"
}

install_packages() {
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 git" >> ~/.yay-plus/$create_log_time.log
    echo -e "安装软件包：\033[34m git \033[0m"
    install_package git

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 base-devel" >> ~/.yay-plus/$create_log_time.log
    echo -e "安装软件包：\033[34m base-devel \033[0m"
    install_package base-devel

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 wget" >> ~/.yay-plus/$create_log_time.log
    echo -e "安装软件包：\033[34m wget \033[0m"
    install_package wget

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 unzip" >> ~/.yay-plus/$create_log_time.log
    echo -e "安装软件包：\033[34m unzip \033[0m"
    install_package unzip

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 npm" >> ~/.yay-plus/$create_log_time.log
    echo -e "安装软件包：\033[34m npm \033[0m"
    install_package npm

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 go" >> ~/.yay-plus/$create_log_time.log
    echo -e "安装软件包：\033[34m go \033[0m"
    install_package go

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 curl" >> ~/.yay-plus/$create_log_time.log
    echo -e "安装软件包：\033[34m curl \033[0m"
    install_package curl

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 figlet" >> ~/.yay-plus/$create_log_time.log
    echo -e "安装软件包：\033[34m figlet \033[0m"
    install_package figlet

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 lolcat" >> ~/.yay-plus/$create_log_time.log
    echo -e "安装软件包：\033[34m lolcat \033[0m"
    install_package lolcat

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 vim" >> ~/.yay-plus/$create_log_time.log
    echo -e "安装软件包：\033[34m vim \033[0m"
    install_package vim
}

uninstall_package() {
    read -p "请输入软件包名称（使用 pacman 安装的所有软件包都可以，包括 makepkg 使用的也是 pacman 来安装，支持多个软件包同时卸载，用空格隔开）：" uninstall_package_name
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -Rsn --noconfirm 卸载 $uninstall_package_name" >> ~/.yay-plus/$create_log_time.log
    echo -e "卸载软件包：\033[34m $uninstall_package_name \033[0m"
    sudo pacman -Rsn --noconfirm $uninstall_package_name
    if [ $? -eq 0 ]; then
        clear
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 卸载完成" >> ~/.yay-plus/$create_log_time.log
        echo "卸载成功"
        upgrade_or_install_aur_package
    else
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 卸载失败" >> ~/.yay-plus/$create_log_time.log
        echo "卸载失败，请查看命令输出"
        exit 1
    fi
}

set_env() {
    echo "需要使用go代理吗？(y/N)"
    read set_go_proxy
    if [ "$set_go_proxy" == "y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] go代理：是 代理地址：https://goproxy.cn" >> ~/.yay-plus/$create_log_time.log
        echo -e "执行：\033[34m export GO111MODULE=on \033[0m"
        export GO111MODULE=on
        echo -e "执行：\033[34m export GOPROXY=https://goproxy.cn \033[0m"
        export GOPROXY=https://goproxy.cn
    elif [ "$set_go_proxy" == "Y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] go代理：是 代理地址：https://goproxy.cn" >> ~/.yay-plus/$create_log_time.log
        echo -e "执行：\033[34m export GO111MODULE=on \033[0m"
        export GO111MODULE=on
        echo -e "执行：\033[34m export GOPROXY=https://goproxy.cn \033[0m"
        export GOPROXY=https://goproxy.cn
    else
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] go代理：否" >> ~/.yay-plus/$create_log_time.log
    fi

    echo "需要使用npm代理吗？(y/N)"
    read set_npm_proxy
    if [ "$set_npm_proxy" == "y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] npm代理：是 代理地址：https://registry.npmmirror.com" >> ~/.yay-plus/$create_log_time.log
        echo -e "执行：\033[34m npm config set registry https://registry.npmmirror.com \033[0m"
        npm config set registry https://registry.npmmirror.com
        npm config set registry https://registry.npmmirror.com
    elif [ "$set_npm_proxy" == "Y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] npm代理：是 代理地址：https://registry.npmmirror.com" >> ~/.yay-plus/$create_log_time.log
        echo -e "执行：\033[34m npm config set registry https://registry.npmmirror.com \033[0m"
        npm config set registry https://registry.npmmirror.com
        npm config set registry https://registry.npmmirror.com
    else
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] npm代理：否" >> ~/.yay-plus/$create_log_time.log
    fi
	echo "是否要查看PKGBUILD内容？(y/N)"
	read read_PKGBUILD
	if [ "$read_PKGBUILD" == "y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 查看PKGBUILD：是 编辑器：vim" >> ~/.yay-plus/$create_log_time.log
        echo -e "执行：\033[34m sudo vim PKGBUILD \033[0m"
		sudo vim PKGBUILD
    elif [ "$read_PKGBUILD" == "Y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 查看PKGBUILD：是 编辑器：vim" >> ~/.yay-plus/$create_log_time.log
        echo -e "执行：\033[34m sudo vim PKGBUILD \033[0m"
		sudo vim PKGBUILD
    else
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 查看PKGBUILD：否" >> ~/.yay-plus/$create_log_time.log
	fi
	clear
}

clone_aur_repo() {
    read -p "请输入软件包名称：" aur_source
    sudo rm -rf "$aur_source"
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 尝试使用 pacman 安装 $aur_source" >> ~/.yay-plus/$create_log_time.log
    echo "正在尝试pacman安装..."
    echo -e "执行：\033[34m sudo pacman -S --noconfirm $aur_source \033[0m"
    sudo pacman -S --noconfirm $aur_source
    if [ $? -eq 0 ]; then
        clear
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 使用 pacman 安装 $aur_source 成功" >> ~/.yay-plus/$create_log_time.log
        echo "pacman安装成功"
        upgrade_or_install_aur_package
    else
        clear
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 使用 pacman 安装 $aur_source 失败，尝试使用 AUR 安装" >> ~/.yay-plus/$create_log_time.log
        echo "pacman安装失败，正在尝试AUR安装..."
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 开始 git clone" >> ~/.yay-plus/$create_log_time.log
        echo -e "执行：\033[34m sudo git clone https://aur.archlinux.org/"$aur_source".git \033[0m"
        sudo git clone https://aur.archlinux.org/"$aur_source".git
        if [ $? -eq 0 ]; then
            echo "查找到 $aur_source ，正在开始makepkg过程"
        else
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用 git clone $aur_source 失败，软件退出，返回值1" >> ~/.yay-plus/$create_log_time.log
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
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用Github代理：是 代理：https://fastgit.cc/" >> ~/.yay-plus/$create_log_time.log
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://fastgit.cc/https://github.com/ \033[0m"
            sudo sed -i 's#https://github.com/#https://fastgit.cc/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://fastgit.cc/https://raw.githubusercontent.com/ \033[0m"
            sudo sed -i 's#https://raw.githubusercontent.com/#https://fastgit.cc/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        2)
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用Github代理：是 代理：https://mirror.ghproxy.com/" >> ~/.yay-plus/$create_log_time.log
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://mirror.ghproxy.com/https://github.com/ \033[0m"
            sudo sed -i 's#https://github.com/#https://mirror.ghproxy.com/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://mirror.ghproxy.com/https://raw.githubusercontent.com/ \033[0m"
            sudo sed -i 's#https://raw.githubusercontent.com/#https://mirror.ghproxy.com/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        3)
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用Github代理：是 代理：https://gh.api.99988866.xyz/" >> ~/.yay-plus/$create_log_time.log
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://gh.api.99988866.xyz/https://github.com/ \033[0m"
            sudo sed -i 's#https://github.com/#https://gh.api.99988866.xyz/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://gh.api.99988866.xyz/https://raw.githubusercontent.com/ \033[0m"
            sudo sed -i 's#https://raw.githubusercontent.com/#https://gh.api.99988866.xyz/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        4)
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用Github代理：是 代理：https://gh.llkk.cc/" >> ~/.yay-plus/$create_log_time.log
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://gh.llkk.cc/https://github.com/ \033[0m"
            sudo sed -i 's#https://github.com/#https://gh.llkk.cc/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://gh.llkk.cc/https://raw.githubusercontent.com/ \033[0m"
            sudo sed -i 's#https://raw.githubusercontent.com/#https://gh.llkk.cc/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        5)
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用Github代理：是 代理：https://github.moeyy.xyz/" >> ~/.yay-plus/$create_log_time.log
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://github.moeyy.xyz/https://github.com/ \033[0m"
            sudo sed -i 's#https://github.com/#https://github.moeyy.xyz/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://github.moeyy.xyz/https://raw.githubusercontent.com/ \033[0m"
            sudo sed -i 's#https://raw.githubusercontent.com/#https://github.moeyy.xyz/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
    esac
    clear
    echo -e "为 \033[37m /tmp/yay-plus 文件夹及目录下的所有文件（夹） \033[0m提取\033[34m 777 \033[0m权限"
    sudo chmod 777 /tmp/yay-plus/*/*
    sudo chmod 777 /tmp/yay-plus/*
    sudo chmod 777 /tmp/yay-plus/
    build_package
}

build_package() {
    echo -e "执行：\033[34m makepkg -si --skippgpcheck \033[0m"
    makepkg -si --skippgpcheck
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "makepkg 返回值 $exit_status，软件退出，返回值2" >> ~/.yay-plus/$create_log_time.log
        echo "makepkg出现错误 $exit_status ，该AUR包可能是过时的，或者您的网络不通畅，当然也可以去 https://github.com/Colin130716/yay-plus/issues 打Colin130716(bushi)，目前更新AUR包的功能暂未完善（不会写.jpg），也可以帮助我们，提交一个PR"
        exit 2
    else
        clear
        echo "[$now_time] makepkg 阶段完成" >> ~/.yay-plus/$create_log_time.log
        echo "makepkg 成功完成"
        sleep 1
        upgrade_or_install_aur_package
    fi
}


start_yay_plus() {
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 创建文件夹：/tmp/yay-plus" >> ~/.yay-plus/$create_log_time.log
    echo -e "建立文件夹：\033[34m /tmp/yay-plus \033[0m"
    sudo mkdir /tmp/yay-plus
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 同步软件仓库" >> ~/.yay-plus/$create_log_time.log
    echo -e "使用\033[34m -Syyy \033[0m参数同步\033[34m pacman \033[0m软件仓库"
    sudo pacman -Syyy
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 更新系统" >> ~/.yay-plus/$create_log_time.log
    echo -e "使用\033[34m -Su --noconfirm \033[0m参数更新\033[34m pacman \033[0m软件包"
    sudo pacman -Su --noconfirm
    install_packages
    clear

    echo -e "欢迎使用yay+ \033[31m最终版本\033[0m"
    echo -e "\033[36m仓库地址：https://github.com/Colin130716/yay-plus/\033[0m"
    echo -e "\033[36m看乐子（感谢我的朋友asSK）：https://github.com/qwq9scan114514/yay-s-joke/\033[0m"

    sleep 5
    upgrade_or_install_aur_package
}


warn() {
    mkdir ~/.yay-plus
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 日志开始记录" >> ~/.yay-plus/$create_log_time.log
    echo -e "\033[41;37m WARNING \033[0m"
    echo -e "  必须要用\033[31m Arch \033[0m系的系统，别拿着个\033[33m Ubuntu \033[0m跑过来用这个脚本，到时候出问题又来找我，我直接给你挂 https://github.com/qwq9scan114514/yay-s-joke/ 里"
    sleep 5

    pacman -h > /dev/zero
    if [ $? -eq 0 ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 系统检测通过" >> ~/.yay-plus/$create_log_time.log
        echo "检测到您是Arch系用户，正在执行下面的步骤"
        start_yay_plus
    else
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 系统检测未通过，返回值3，非Arch系用户爬（恼" >> ~/.yay-plus/$create_log_time.log
        echo -e "\033[37m非Arch系用户爬\033[0m"
        exit 3
    fi
}

create_log_time=$(date +'%Y%m%d_%H%M%S')
warn
