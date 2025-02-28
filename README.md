# yay-plus

## 别问为什么不更新，最近在准备期末考试（1月15号结束），而且还在憋大招（提前透露一下，插件功能、设置、更新、静默参数）
## 已将PyQt版迁移到[yay-plus_PyQt](https://github.com/Colin130716/yay-plus_PyQt)仓库，请前往新仓库查看

## 简介
这是一个用于快速下载AUR软件包的脚本，使用Shell脚本语言编写，正在使用PyQt写GUI版。

---

## 使用方法（Shell版）
1. ``git clone https://github.com/Colin130716/yay-plus.git``
2. ``chmod +x <git clone到的路径>/yay-plus.sh``
3. ``<git clone到的路径>/yay-plus.sh``

## 使用方法（PyQt版）
1. ``git clone https://github.com/Colin130716/yay-plus.git``
2. ``cd <git clone到的路径>/yay-plus/yay-plus_PyQt``
3. ``python3 -m pip install -r requirements.txt``
4. **[注意：这一步非常重要！必须执行这一步，不然程序会报错异常退出]** 修改软件目录下的 pwd 文件，输入用户的密码 **（不要加其他内容）** ，然后保存退出。
5. ``python3 -u home.py``

### 进阶用法（仅限zsh | bash）
1. 添加以下行到 ``.zshrc`` | ``.bashrc`` 中
```bash
alias yay+ = "<你的 yay-plus.sh 所在位置>/yay-plus.sh"
```

2. 重新加载配置文件
```bash
source ~/.zshrc
```
或
```bash
source ~/.bashrc
```

---

## 注意事项
1. 本脚本仅适用于Arch Linux及其发行版系统，其他系统无法正常运行（为了防止有某些**用Ubuntu这类系统来试，加入了系统检测功能）。
2. 运行时请不要尝试使用root权限运行，不然会导致makepkg阶段出现错误。
[![前车之鉴](https://img.z4a.net/images/2024/10/07/0828FE27048941E8E6F5C7E676C46A3E.jpeg)](https://img.z4a.net/image/0828FE27048941E8E6F5C7E676C46A3E.MlR4A)

---

## 本软件使用CodeGeeX编写部分实现代码

---

## 开发者：
Colin130716:真正的开发者，这个程序60%全是他一个字一个字敲出来的(别问剩下的40%是谁，问就是ai写的，不然你以为我上面写了个“本软件使用CodeGeeX编写部分实现代码”干什么的）

asSK：废物一个，sb一个（有点过了），你永远也想不到他下一句会蹦出什么逆天发言（给小白推荐arch的就是他！！！）

FlySkyPigg-az：那位小白，仓库吉祥物（？

---

## 初衷
这个东西制作的初衷是我有个朋友，给小白推荐arch，那个小白还真装了，然后这都不会那都不会，以至于flatpak，hmcl，jdk，qq，fcitx5都是我们帮他装的，我们实在不希望他不会合理运用aur这个好用的东西，所以我决定写这个脚本。

---

## 友链
[**展示我们对yay+这个项目的逆天发言的图片合集**](https://github.com/qwq9scan114514/yay-s-joke)

---

![FuckNvidia](https://raw.githubusercontent.com/Colin130716/yay-plus/master/E868CDC19CF3CB67081991631F2DA957.png)

---

**实际上这篇README大部分是asSK帮忙写的**

---

## yay+大事（？）祭

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

**以前的aur.sh最后一版代码“欣赏”**

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

---

**514（喜**

[![image](https://img.z4a.net/images/2024/10/10/image.png)](https://img.z4a.net/image/image.MYQrW)

---

