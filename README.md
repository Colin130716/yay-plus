# yay-plus README v38

## 目录

- [简介](#简介)
- [使用方法（Shell版）](#使用方法)
- [注意事项](#你需要注意)
- [目前已知的一些问题](#已知问题)
- [开发者信息](#开发者信息)
- [初衷](#初衷)
- [友链](#友情链接)
- [yay+大事祭](#大事祭)
- [旧版代码展示](#旧版代码展示)

---

2025.08.24 ArchLinux官网及AUR被攻击，请不要提Issue。


## 简介

这是一个用于快速下载AUR软件包的脚本，使用Shell脚本语言编写，正在使用PyQt开发GUI版本。[PyQt版](https://github.com/Colin130716/yay-plus_PyQt)已经迁移到新仓库，请前往查看。开源协议：GPLv3。

> [!WARNING]
> 不要拿各种非Arch-Based系统来试，禁止因此问题提Issue。
> **提问前请看[提问的智慧](https://github.com/ryanhanwu/How-To-Ask-Questions-The-Smart-Way/blob/main/README-zh_CN.md)**。

![icon](https://github.com/Colin130716/yay-plus_PyQt/blob/master/icons/256x256.png)

## 使用方法

### 安装步骤

```bash
git clone https://github.com/Colin130716/yay-plus.git
chmod +x <git clone到的路径>/yay-plus.sh
<git clone到的路径>/yay-plus.sh
```

> [!WARNING]
> 请不要去Releases里下载，Releases里的是旧版，有一些bug

### 进阶用法（仅限zsh | bash）

1. 添加以下行到 `.zshrc` 或 `.bashrc` 中：

```bash
alias yay+="<你的yay-plus.sh所在位置>/yay-plus.sh"
```

2. 重新加载配置文件：

```bash
source ~/.zshrc
```

或者

```bash
source ~/.bashrc
```

---

## 已知问题
1. 在**启动时和更新系统**时flatpak update在输出“无事可做。”时可能会卡住，经过排查应该是**flatpak自身问题**，所以在卡住时**请按Ctrl + C强行终止flatpak进程**以继续。

---

## 你需要注意

1. 本脚本仅适用于Arch Linux及其发行版系统，其他系统无法正常运行（为了防止有某些**用Ubuntu这类系统来试，加入了系统检测功能）。

2. 运行时请不要尝试使用root权限运行，不然会导致makepkg阶段出现错误。

---

## 本软件使用CodeGeeX及DeepSeek编写部分实现代码

---

## 开发者信息

1. Colin130716：真正的开发者，这个程序60%全是他一个字一个字敲出来的(别问剩下的40%是谁，问就是ai写的，不然你以为我上面写了个“本软件使用CodeGeeX及DeepSeek编写部分实现代码”干什么的)。电邮：qsdwin2023@outlook.com，欢迎提问或提出建议。

2. asSK(L1nry)：废物一个，你永远也想不到他下一句会蹦出什么逆天发言（给小白推荐arch的就是他！！！）

3. FlySkyPigg-az：那位小白，仓库吉祥物（？

---

## 初衷

这个东西制作的初衷是我有个朋友，给小白推荐arch，那个小白还真装了，然后这都不会那都不会，以至于flatpak，hmcl，jdk，qq，fcitx5都是我们帮他装的，我们实在不希望他不会合理运用aur这个好用的东西，所以我决定写这个脚本。（asSK：arch用户不会用aur就挺难崩的）

## 友情链接

[**yay-s-joke**](https://github.com/qwq9scan114514/yay-s-joke) 这是asSK和我（colin）一起建立的仓库，可以在这里讲一些你遇到的笑话。

---

**注：这篇README.md大部分是asSK写的（asSK：colin你……）（Colin130716：你不是自愿的吗（（（）**

---

## 大事祭

**2024/8/23 12:37 从asSK那里接手了一个赛博文盲**

**2024/8/25 17:02 写出了yay+第一版（当时还叫aur.sh）**

**2024/8/26 10:39 正式改名为yay+**

**2024/8/26 23:57 准备开始写GUI版，Shell版同时更新**

**2024/8/27 17:55 yay-s-joke仓库正式诞生**

**2024/8/31 21:29 asSK准备对我的yay+仓库发起袭击![image](https://github.com/user-attachments/assets/7a9826e9-9f12-48ca-99f4-3a4830c62642)**

**2024/9/6 22:32 在写完两个窗口（不到）后GUI版暂停更新，继续更新Shell版**

**2024/10/7 1:40 yay+的Shell版本最终版完成**

**2024/10/7 4:17 大事祭写完（暂时的）**

**2024/10/7 23:43 翻到了以前的aur.sh**

**2024/10/9 1:30 准备月考，但是睡不着，于是又更新了“亿点点”新模块**

**2024/10/9 20:58 又加了一个检测root的功能（真是最后一版了（bushi**

**2024/10/11 19:47 yay+ wiki完成**

**2024/10/13 0:39 加入了使用flatpak安装的功能，代码突破400行**

---

## 旧版代码展示

```bash
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
```
