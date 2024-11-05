#!/bin/bash

# 定义一个函数，用于升级或安装AUR软件包
upgrade_or_install_aur_package() {
    cd ~/.yay-plus/packages
    echo YAY+ | figlet | lolcat
    echo Version 3 | figlet | lolcat
    echo "
    1. 安装软件包
    2. 卸载软件包
    3. 运行flatpak软件包
    4. 退出
    "
    select choice in 1 2 3 4; do
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 首页选择：$choice" >> ~/.yay-plus/logs/$create_log_time.log
        case $choice in
            1)
                choose_install_method
                ;;
            2)
                uninstall_package
                ;;
            3)
                run_flatpak_package
                ;;
            4)
                clear
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 软件退出，返回值0" >> ~/.yay-plus/logs/$create_log_time.log
                echo "yay+正在退出，感谢使用"
                exit 0
                ;;
            *)
                clear
                echo "无效的选项，请重新输入"
                upgrade_or_install_aur_package
                ;;
        esac
    done
}

# 定义一个函数，用于安装软件包
install_package() {
    sudo pacman -S --needed --noconfirm "$1"
}

# 定义一个函数，用于安装多个软件包
install_packages() {
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 git" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "安装软件包：\033[34m git \033[0m"
    install_package git

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 base-devel" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "安装软件包：\033[34m base-devel \033[0m"
    install_package base-devel

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 wget" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "安装软件包：\033[34m wget \033[0m"
    install_package wget

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 unzip" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "安装软件包：\033[34m unzip \033[0m"
    install_package unzip

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 npm" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "安装软件包：\033[34m npm \033[0m"
    install_package npm

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 go" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "安装软件包：\033[34m go \033[0m"
    install_package go

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 curl" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "安装软件包：\033[34m curl \033[0m"
    install_package curl

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 figlet" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "安装软件包：\033[34m figlet \033[0m"
    install_package figlet

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 lolcat" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "安装软件包：\033[34m lolcat \033[0m"
    install_package lolcat

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 vim" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "安装软件包：\033[34m vim \033[0m"
    install_package vim

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 使用 sudo pacman -S --needed --noconfirm 安装 flatpak" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "安装软件包：\033[34m flatpak \033[0m"
    install_package flatpak

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 为flatpak添加flathub官方源" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "\033[34m 执行：sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo \033[0m"
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    read -p "是否要更换flathub源为上交大源？(Y/n)" use_mirror
    case $use_mirror in
        n | N)
            break
            ;;
        *)
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 为flatpak更换flathub源为上交大源" >> ~/.yay-plus/logs/$create_log_time.log
            echo -e "\033[34m 执行：wget https://mirror.sjtu.edu.cn/flathub/flathub.gpg \033[0m"
            wget https://mirror.sjtu.edu.cn/flathub/flathub.gpg
            echo -e "\033[34m 执行：sudo flatpak remote-modify flathub --gpg-import flathub.gpg \033[0m"
            sudo flatpak remote-modify flathub --gpg-import flathub.gpg
            echo -e "\033[34m 执行：rm flathub.gpg \033[0m"
            rm flathub.gpg
            echo -e "\033[34m 执行：sudo flatpak remote-modify flathub --url=https://mirror.sjtu.edu.cn/flathub \033[0m"
            sudo flatpak remote-modify flathub --url=https://mirror.sjtu.edu.cn/flathub
            sudo flatpak update
            break
            ;;
    esac
}

# 定义一个函数，用于卸载软件包
uninstall_package() {
    echo "
    请选择卸载方式：
    1. 卸载 pacman 安装的软件包
    2. 卸载 flatpak(flathub) 安装的软件包
    "
    read uninstall_package_type
    case $uninstall_package_type in
        1)
            read -p "请输入软件包名称（使用 pacman 安装的所有软件包都可以，包括 makepkg 使用的也是 pacman 来安装，支持多个软件包同时卸载，用空格隔开）：" uninstall_package_name
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用 sudo pacman -Rsn --noconfirm 卸载 $uninstall_package_name" >> ~/.yay-plus/logs/$create_log_time.log
            echo -e "卸载软件包：\033[34m $uninstall_package_name \033[0m"
            sudo pacman -Rsn --noconfirm $uninstall_package_name
            if [ $? -eq 0 ]; then
                clear
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 卸载完成" >> ~/.yay-plus/logs/$create_log_time.log
                echo "卸载成功"
                upgrade_or_install_aur_package
            else
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 卸载失败" >> ~/.yay-plus/logs/$create_log_time.log
                echo "卸载失败，请去 ~/.yay-plus/logs/$create_log_time.log 查看日志"
                exit 4
            fi
            ;;
        2)
            read -p "请输入软件包名称（使用 flatpak 安装的所有软件包都可以，支持多个软件包同时卸载，用空格隔开）：" uninstall_package_name
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用 flatpak uninstall $uninstall_package_name" >> ~/.yay-plus/logs/$create_log_time.log
            echo -e "卸载flatpak软件包：\033[34m $uninstall_package_name \033[0m"
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 卸载完成" >> ~/.yay-plus/logs/$create_log_time.log
            echo "卸载成功"
            upgrade_or_install_aur_package
            ;;
        *)
            echo "输入错误，请重新输入"
            ;;
    esac
}

# 定义一个函数，用于设置代理
set_env() {
    echo "需要使用go代理下载吗？（代理下载地址：https://goproxy.cn）(y/N)"
    read set_go_proxy
    if [ "$set_go_proxy" == "y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] go代理：是 代理地址：https://goproxy.cn" >> ~/.yay-plus/logs/$create_log_time.log
        echo -e "执行：\033[34m export GO111MODULE=on \033[0m"
        export GO111MODULE=on
        echo -e "执行：\033[34m export GOPROXY=https://goproxy.cn \033[0m"
        export GOPROXY=https://goproxy.cn
    elif [ "$set_go_proxy" == "Y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] go代理：是 代理地址：https://goproxy.cn" >> ~/.yay-plus/logs/$create_log_time.log
        echo -e "执行：\033[34m export GO111MODULE=on \033[0m"
        export GO111MODULE=on
        echo -e "执行：\033[34m export GOPROXY=https://goproxy.cn \033[0m"
        export GOPROXY=https://goproxy.cn
    else
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] go代理：否" >> ~/.yay-plus/logs/$create_log_time.log
        echo "是否还原为默认代理下载地址？(Y/n)"
        select set_go_proxy_default in y n Y N; do
            if [ "$set_go_proxy_default" == "n" ]; then
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 还原go代理：否" >> ~/.yay-plus/logs/$create_log_time.log
                break
            elif [ "$set_go_proxy_default" == "N" ]; then
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 还原go代理：否" >> ~/.yay-plus/logs/$create_log_time.log
                break
            else
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 还原go代理：是 代理地址：https://proxy.golang.org" >> ~/.yay-plus/logs/$create_log_time.log
                echo -e "执行：\033[34m export GOPROXY=https://proxy.golang.org \033[0m"
                export GOPROXY=https://proxy.golang.org
                break
            fi
        done
    fi

    echo "需要使用npm代理吗？(y/N)"
    read set_npm_proxy
    if [ "$set_npm_proxy" == "y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] npm代理：是 代理地址：https://registry.npmmirror.com" >> ~/.yay-plus/logs/$create_log_time.log
        echo -e "执行：\033[34m npm config set registry https://registry.npmmirror.com \033[0m"
        npm config set registry https://registry.npmmirror.com
        npm config set registry https://registry.npmmirror.com
    elif [ "$set_npm_proxy" == "Y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] npm代理：是 代理地址：https://registry.npmmirror.com" >> ~/.yay-plus/logs/$create_log_time.log
        echo -e "执行：\033[34m npm config set registry https://registry.npmmirror.com \033[0m"
        npm config set registry https://registry.npmmirror.com
        npm config set registry https://registry.npmmirror.com
    else
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] npm代理：否" >> ~/.yay-plus/logs/$create_log_time.log
        echo "是否还原为默认代理下载地址？(Y/n)"
        select set_npm_proxy_default in y n Y N; do
            if [ "$set_npm_proxy_default" == "n" ]; then
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 还原npm代理：否" >> ~/.yay-plus/logs/$create_log_time.log
                break
            elif [ "$set_npm_proxy_default" == "N" ]; then
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 还原npm代理：否" >> ~/.yay-plus/logs/$create_log_time.log
                break
            else
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 还原npm代理：是 代理地址：https://registry.npmjs.org" >> ~/.yay-plus/logs/$create_log_time.log
                echo -e "执行：\033[34m npm config set registry https://registry.npmjs.org \033[0m"
                npm config set registry https://registry.npmjs.org
                break
            fi
        done
    fi

	echo "是否要查看PKGBUILD内容？(y/N)"
	read read_PKGBUILD
	if [ "$read_PKGBUILD" == "y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 查看PKGBUILD：是 编辑器：vim" >> ~/.yay-plus/logs/$create_log_time.log
        echo -e "执行：\033[34m vim PKGBUILD \033[0m"
		vim PKGBUILD
    elif [ "$read_PKGBUILD" == "Y" ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 查看PKGBUILD：是 编辑器：vim" >> ~/.yay-plus/logs/$create_log_time.log
        echo -e "执行：\033[34m vim PKGBUILD \033[0m"
		vim PKGBUILD
    else
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 查看PKGBUILD：否" >> ~/.yay-plus/logs/$create_log_time.log
	fi
	clear
}

# 定义一个函数，用于选择安装方式
choose_install_method() {
    read -p "请输入软件包名称（如果要从flathub安装软件包，请填写完整包名，例如org.kde.kalk，不要只填一个kalk）：" aur_source
    echo "请选择安装方式："
    echo "1. 从pacman安装"
    echo "2. 从AUR安装"
    echo "3. 从flathub（flatpak）安装"
    read install_method
    sudo rm -rf $aur_source

    if [ "$install_method" == "1" ]; then
        clear
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 安装方式：从pacman安装" >> ~/.yay-plus/logs/$create_log_time.log
        echo "正在尝试pacman安装..."
        echo -e "执行：\033[34m sudo pacman -S --noconfirm $aur_source \033[0m"
        sudo pacman -S --noconfirm $aur_source >> ~/.yay-plus/logs/$create_log_time.log 2>&1

        if [ $? -eq 0 ]; then
            clear
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用 pacman 安装 $aur_source 成功" >> ~/.yay-plus/logs/$create_log_time.log
            echo "pacman安装成功"
            upgrade_or_install_aur_package
        else
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用 pacman 安装 $aur_source 失败" >> ~/.yay-plus/logs/$create_log_time.log
            echo "pacman安装失败，请检查网络连接，或您输入的是不存在的软件包"
            echo "是否要尝试从AUR安装？(Y/n)"
            read install_from_aur

            if [ "$install_from_aur" == "N" ] || [ "$install_from_aur" == "n" ]; then
                echo "是否要尝试使用flatpak安装？(Y/n)"
                read install_from_flatpak

                if [ "$install_from_flatpak" == "N" ] || [ "$install_from_flatpak" == "n" ]; then
                    clear
                    echo "用户取消安装" > ~/.yay-plus/logs/$create_log_time.log
                    echo -e "\033[31m已取消安装"
                    upgrade_or_install_aur_package
                else
                    clear
                    now_time=$(date +'%Y/%m/%d %H:%M:%S')
                    echo "[$now_time] 安装方式：从flathub（flatpak）安装" >> ~/.yay-plus/logs/$create_log_time.log
                    echo "正在尝试从flatpak安装..."
                    echo -e "执行：\033[34m flatpak install flathub $aur_source \033[0m"
                    flatpak install flathub $aur_source >> ~/.yay-plus/logs/$create_log_time.log 2>&1

                    if [ $? -eq 0 ]; then
                        clear
                        now_time=$(date +'%Y/%m/%d %H:%M:%S')
                        echo "[$now_time] 使用 flatpak 安装 $aur_source 成功" >> ~/.yay-plus/logs/$create_log_time.log
                        echo "flatpak安装成功"
                        upgrade_or_install_aur_package
                    else
                        clear
                        now_time=$(date +'%Y/%m/%d %H:%M:%S')
                        echo "[$now_time] 使用 flatpak 安装 $aur_source 失败" >> ~/.yay-plus/logs/$create_log_time.log
                        echo "flatpak安装失败，请检查网络连接，或您输入的是不存在的软件包"
                        upgrade_or_install_aur_package
                    fi
            else
                clear
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 安装方式：从AUR安装" >> ~/.yay-plus/logs/$create_log_time.log
                clear
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 尝试从 AUR 安装" >> ~/.yay-plus/logs/$create_log_time.log
                echo "正在静默尝试从AUR安装..."
                now_time=$(date +'%Y/%m/%d %H:%M:%S')
                echo "[$now_time] 开始 git clone" >> ~/.yay-plus/logs/$create_log_time.log
                sudo rm -rf "$aur_source"
                echo -e "执行：\033[34m git clone https://aur.archlinux.org/"$aur_source".git \033[0m"
                git clone https://aur.archlinux.org/"$aur_source".git >> ~/.yay-plus/logs/$create_log_time.log 2>&1
                ls ./$aur_source | grep 'PKGBUILD'

                if [ $? -eq 1 ]; then
                    echo "查找到 $aur_source ，正在开始makepkg过程"
                else
                    now_time=$(date +'%Y/%m/%d %H:%M:%S')
                    echo "[$now_time] 使用 git clone $aur_source 失败" >> ~/.yay-plus/logs/$create_log_time.log
                    clear
                    echo "git clone失败，请检查网络连接，或您输入的是不存在的软件包"
                    upgrade_or_install_aur_package
                fi

                cd "$aur_source"
                set_env
                set_proxy
                build_package
            fi
        fi
    elif [ "$install_method" == "2" ]; then
        clear
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 安装方式：从AUR安装" >> ~/.yay-plus/logs/$create_log_time.log
        clear
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 尝试从 AUR 安装" >> ~/.yay-plus/logs/$create_log_time.log
        echo "正在尝试从AUR安装..."
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 开始 git clone" >> ~/.yay-plus/logs/$create_log_time.log
        echo -e "执行：\033[34m git clone https://aur.archlinux.org/"$aur_source".git \033[0m"
        git clone https://aur.archlinux.org/"$aur_source".git >> ~/.yay-plus/logs/$create_log_time.log
        ls ./$aur_source | grep 'PKGBUILD'

        if [ $? -eq 0 ]; then
            echo "查找到 $aur_source ，正在开始makepkg过程"
        else
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用 git clone $aur_source 失败" >> ~/.yay-plus/logs/$create_log_time.log
            echo "git clone失败，请检查网络连接，或您输入的是不存在的软件包"
            clear
            upgrade_or_install_aur_package
        fi

        cd "$aur_source"
        set_env
        set_proxy
        build_package
    elif [ "$install_method" == "3" ]; then
        clear
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 安装方式：从flathub（flatpak）安装" >> ~/.yay-plus/logs/$create_log_time.log
        echo "正在尝试从flatpak安装..."
        echo -e "执行：\033[34m flatpak install flathub $aur_source \033[0m"
        flatpak install flathub $aur_source >> ~/.yay-plus/logs/$create_log_time.log 2>&1

        if [ $? -eq 0 ]; then
            clear
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用 flatpak 安装 $aur_source 成功" >> ~/.yay-plus/logs/$create_log_time.log
            echo "flatpak安装成功"
            upgrade_or_install_aur_package
        else
            clear
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用 flatpak 安装 $aur_source 失败" >> ~/.yay-plus/logs/$create_log_time.log
            echo "flatpak安装失败，请检查网络连接，或您输入的是不存在的软件包"
            upgrade_or_install_aur_package
        fi
    fi
}


set_proxy() {
    echo "请问您需要哪个代理？1：https://fastgit.cc/（目前测试速度较慢） 2：https://mirror.ghproxy.com/（备用，下载速度较慢） 3：https://gh.api.99988866.xyz/（备用2,不稳定） 4：https://gh.llkk.cc/（推荐，速度较快） 5：https://github.moeyy.xyz/（推荐） 6：不使用Github代理（不推荐）"
    read proxy
    case $proxy in
        1)
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用Github代理：是 代理：https://fastgit.cc/" >> ~/.yay-plus/logs/$create_log_time.log
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://fastgit.cc/https://github.com/ \033[0m"
            sed -i 's#https://github.com/#https://fastgit.cc/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://fastgit.cc/https://raw.githubusercontent.com/ \033[0m"
            sed -i 's#https://raw.githubusercontent.com/#https://fastgit.cc/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        2)
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用Github代理：是 代理：https://mirror.ghproxy.com/" >> ~/.yay-plus/logs/$create_log_time.log
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://mirror.ghproxy.com/https://github.com/ \033[0m"
            sed -i 's#https://github.com/#https://mirror.ghproxy.com/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://mirror.ghproxy.com/https://raw.githubusercontent.com/ \033[0m"
            sed -i 's#https://raw.githubusercontent.com/#https://mirror.ghproxy.com/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        3)
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用Github代理：是 代理：https://gh.api.99988866.xyz/" >> ~/.yay-plus/logs/$create_log_time.log
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://gh.api.99988866.xyz/https://github.com/ \033[0m"
            sed -i 's#https://github.com/#https://gh.api.99988866.xyz/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://gh.api.99988866.xyz/https://raw.githubusercontent.com/ \033[0m"
            sed -i 's#https://raw.githubusercontent.com/#https://gh.api.99988866.xyz/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        4)
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用Github代理：是 代理：https://gh.llkk.cc/" >> ~/.yay-plus/logs/$create_log_time.log
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://gh.llkk.cc/https://github.com/ \033[0m"
            sed -i 's#https://github.com/#https://gh.llkk.cc/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://gh.llkk.cc/https://raw.githubusercontent.com/ \033[0m"
            sed -i 's#https://raw.githubusercontent.com/#https://gh.llkk.cc/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        5)
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 使用Github代理：是 代理：https://github.moeyy.xyz/" >> ~/.yay-plus/logs/$create_log_time.log
            echo -e "替换：\033[37m https://github.com/ \033[0m为 \033[37m https://github.moeyy.xyz/https://github.com/ \033[0m"
            sed -i 's#https://github.com/#https://github.moeyy.xyz/https://github.com/#g' PKGBUILD
            echo -e "替换：\033[37m https://raw.githubusercontent.com/ \033[0m为 \033[37m https://github.moeyy.xyz/https://raw.githubusercontent.com/ \033[0m"
            sed -i 's#https://raw.githubusercontent.com/#https://github.moeyy.xyz/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
    esac
    clear
    build_package
}

build_package() {
    echo -e "执行：\033[34m makepkg -si --skippgpcheck --noconfirm \033[0m"
    makepkg -si --skippgpcheck --noconfirm >> ~/.yay-plus/logs/$create_log_time.log 2>&1
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        echo "makepkg 返回值 $exit_status，软件退出，返回值2" >> ~/.yay-plus/logs/$create_log_time.log
        echo "makepkg出现错误 $exit_status ，详细信息请查看~/.yay-plus/logs/$create_log_time.log，如果不会看日志，可以去 https://github.com/Colin130716/yay-plus/issues 提交issue"
        exit 2
    else
        clear
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] makepkg 阶段完成" >> ~/.yay-plus/logs/$create_log_time.log
        echo "makepkg 成功完成"
        sleep 1
        upgrade_or_install_aur_package
    fi
}

run_flatpak_package() {
    read -p "请输入要运行的flatpak软件包名：" flatpak_package_name
    echo -e "执行：\033[34m flatpak run $flatpak_package_name \033[0m"
    flatpak run $flatpak_package_name
    if [ $? -eq 0 ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] flatpak软件包 $flatpak_package_name 运行完成" >> ~/.yay-plus/logs/$create_log_time.log
        echo "flatpak软件包 $flatpak_package_name 运行完成"
    else
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] flatpak软件包 $flatpak_package_name 运行失败" >> ~/.yay-plus/logs/$create_log_time.log
        echo "flatpak软件包 $flatpak_package_name 运行失败"
    fi
}

start_yay_plus() {
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 同步软件仓库" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "使用\033[34m -Syyy \033[0m参数同步\033[34m pacman \033[0m软件仓库"
    sudo pacman -Syyy
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 更新系统" >> ~/.yay-plus/logs/$create_log_time.log
    echo -e "使用\033[34m -Su --noconfirm \033[0m参数更新\033[34m pacman \033[0m软件包"
    sudo pacman -Su --noconfirm
    install_packages
    clear

    echo -e "欢迎使用yay+ \033[31mVersion 3\033[0m"
    echo -e "\033[36m仓库地址：https://github.com/Colin130716/yay-plus/\033[0m"
    echo -e "\033[36m看乐子（感谢我的朋友asSK）：https://github.com/qwq9scan114514/yay-s-joke/\033[0m"

    sleep 5
    upgrade_or_install_aur_package
}


warn() {
    echo -e "建立文件夹：\033[34m ~/.yay-plus \033[0m"
    mkdir ~/.yay-plus

    echo -e "建立文件夹：\033[34m ~/.yay-plus/logs \033[0m"
    mkdir ~/.yay-plus/logs

    echo -e "建立文件夹：\033[34m ~/.yay-plus/packages \033[0m"
    mkdir ~/.yay-plus/packages

    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 日志开始记录" >> ~/.yay-plus/logs/$create_log_time.log

    clear
    echo -e "\033[41;37m WARNING \033[0m"
    echo -e "必须要用\033[31m Arch \033[0m系的系统和非\033[31m root \033[0m用户，别拿着个\033[33m Ubuntu \033[0m跑过来用这个脚本，到时候出问题又来找我，我直接给你挂 https://github.com/qwq9scan114514/yay-s-joke/ 里"
    sleep 5

    pacman -h > /dev/zero
    if [ $? -eq 0 ]; then
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 系统检测通过" >> ~/.yay-plus/logs/$create_log_time.log
        echo "检测到您是Arch系用户，正在检测用户"
        account_name=$(whoami)
        if [ "$account_name" = "root" ]; then
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 用户检测未通过，返回值5" >> ~/.yay-plus/logs/$create_log_time.log
            echo -e "\033[37mmakepkg 在root权限下运行不了，请看前车之鉴（https://img.z4a.net/images/2024/10/07/0828FE27048941E8E6F5C7E676C46A3E.jpeg）\033[0m"
            exit 5
        else
            now_time=$(date +'%Y/%m/%d %H:%M:%S')
            echo "[$now_time] 用户检测通过" >> ~/.yay-plus/logs/$create_log_time.log
            echo "用户检测通过，欢迎使用yay+"
            start_yay_plus
        fi
    else
        now_time=$(date +'%Y/%m/%d %H:%M:%S')
        echo "[$now_time] 系统检测未通过，返回值3，非Arch系用户爬（恼" >> ~/.yay-plus/logs/$create_log_time.log
        echo -e "\033[37m非Arch系用户爬\033[0m"
        exit 3
    fi
}

create_log_time=$(date +'%Y%m%d_%H%M%S')
warn
