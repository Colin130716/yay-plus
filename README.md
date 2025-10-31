# yay-plus README v40.1

![Yay+ Version](https://img.shields.io/github/v/release/Colin130716/yay-plus?display_name=release&style=for-the-badge)
![Downloads](https://img.shields.io/github/downloads/Colin130716/yay-plus/total?style=for-the-badge)
![License](https://img.shields.io/github/license/Colin130716/yay-plus?style=for-the-badge)

## 目录

- [简介](#简介)
- [使用方法（Shell版）](#使用方法)
- [注意事项](#你需要注意)
- [目前已知的一些问题](#已知问题)
- [开发者信息](#开发者信息)
- [初衷](#初衷)
- [友链](#友情链接)

---

2025.08.24 ArchLinux官网及AUR被攻击，请见[ArchLinuxCN对此情况的说明](https://www.archlinuxcn.org/recent-services-outages/)。**（已解决，增加了官方Github地址）**


## 简介

这是一个用于快速下载AUR软件包的脚本，使用Shell脚本语言编写，正在使用PyQt开发GUI版本。[PyQt版](https://github.com/Colin130716/yay-plus_PyQt)已经迁移到新仓库，请前往查看。开源协议：GPLv3。

**喜报：官网已配置完成，请见[yayplus.qzz.io](https://yayplus.qzz.io/)。官网使用DeepSeek进行整体框架编写。**

**新增 IRC 服务器，地址：irc.yayplus.qzz.io（不启用 TLS/SSL 使用 38060 端口，启用 TLS/SSL 使用 30080 端口），规则请见[https://github.com/Colin130716/yay-plus/blob/master/Yay+_IRC_Rules.md](https://github.com/Colin130716/yay-plus/blob/master/Yay+_IRC_Rules.md)**

> [!WARNING]
> 不要拿各种非Arch-Based系统来试，禁止因此问题提Issue。
> **提问前请看[提问的智慧](https://github.com/ryanhanwu/How-To-Ask-Questions-The-Smart-Way/blob/main/README-zh_CN.md)**。

![icon](https://github.com/Colin130716/yay-plus_PyQt/blob/master/icons/256x256.png)

## 使用方法

### 使用步骤

```bash
git clone https://github.com/Colin130716/yay-plus.git
chmod +x <git clone到的路径>/yay-plus.sh
<git clone到的路径>/yay-plus.sh
```

> [!TIP]
> 你可以在Releases发布页中找到最新稳定版的包，可以直接使用pacman -U安装。

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

