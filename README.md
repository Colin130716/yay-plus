# yay-plus README v42

![Yay+ Version](https://img.shields.io/github/v/release/Colin130716/yay-plus?display_name=release&style=for-the-badge)
![Downloads](https://img.shields.io/github/downloads/Colin130716/yay-plus/total?style=for-the-badge)
![License](https://img.shields.io/github/license/Colin130716/yay-plus?style=for-the-badge)

## 简介

本项目（yay-plus，也称 yay+/Yay+）是一个 **可以快速管理 ArchLinux 中软件包（包括但不限于：从 Pacman 软件包源及从 AUR 中自行编译的包）及 Flatpak包** 的 Shell 脚本。

> [!NOTE]
> 本项目和 Yay（由 Jguer 及其他贡献者开发的一个 AUR Helper，[Github](https://github.com/Jguer/yay)）没有关联，只是取名时恰巧想到了这个名字而已，请不要混淆。

官网请见：[https://yayplus.qzz.io/](https://yayplus.qzz.io/)

## 使用方法

<details open>

<summary>1. 通过预先打包好的包安装（推荐）<summary>

1. 从 Github Releases 页面下载预编译好的 Yay+ 包（请见 [Releases 链接](https://github.com/Colin130716/yay-plus/releases)）。

2. 使用 `[sudo] pacman -U <package name>` 以安装预打包好的 Yay+ 包。

3. 运行 'yay-plus' 以开始使用。

</details>

<details>

<summary>2. 直接运行仓库中的 Shell 脚本<summary>

1. 从 Github Releases 页面下载最新版的 Yay+ （这是一个指向**最新版**脚本的 [链接](https://github.com/Colin130716/yay-plus/releases/latest/download/yay-plus.sh)）。

2. 通过以下命令运行 Yay+：

```bash
chmod +x /path/to/yay-plus.sh
/path/to/yay-plus.sh
```

</details>

## 功能

| 功能 | 描述 | 命令 | 对比 |
| --- | --- | --- | --- |
| 安装软件包 | 从 **Pacman 软件包源、AUR、Flatpak** 中安装  | `yay-plus -S --<安装方式，可选 pacman / aur / flatpak> <package name>` | `yay -S <package name>` |
| 卸载软件包 | 从 **Pacman、Flatpak** 中卸载  | `yay-plus -R --<卸载方式，可选 pacman / flatpak> <package name>` | `yay -R <package name>` |
| 搜索软件包 | 在 **Pacman 软件包源、AUR、Flatpak** 中搜索  | `yay-plus -Q --<搜索方式，可选 pacman / aur / flatpak> --<搜索状态，可选 online / local> <package name>` | `yay -Ss <package name>` |
| 更新软件包 | 更新 **Pacman 软件包源、AUR、Flatpak** 中的软件包  | `yay-plus -U --<更新方式，可选 all / pacman / aur / flatpak> <package name>` | `yay -Syyyu` |
| 本地安装 | 从本地文件安装软件包  | `yay-plus -L /path/to/<AUR 包目录 或 .pkg.tar.* 文件 或 .flatpakref 文件>` | `yay -U <package name>` |

## Todos

- [ ] 修改配置文件更新逻辑，方便降级
- [ ] 修改拉取 AUR 快照失败的问题
- [ ] 修改命令行参数逻辑使其更符合 Pacman 的参数逻辑