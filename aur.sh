#!/bin/sh
sudo pacman -Syyu
sudo pacman -S --noconfirm git
sudo pacman -S --noconfirm base-devel
sudo pacman -S --noconfirm wget
sudo pacman -S --noconfirm unzip
sudo pacman -S --noconfirm npm
sudo pacman -S --noconfirm go
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
npm config set registry https://registry.npmmirror.com
wget https://fastgit.cc/https://github.com/Colin130716/AUR_Quick_Download_for_Chinese/raw/master/dialog
sudo mv dialog /usr/bin/dialog
sudo rm -rf dialog
aur_source=$(dialog --inputbox "请输入你想要下载项目的aur名称：" 0 0 --output-fd 1)
cd ~/Gitdir
sudo rm -rf $aur_source
git clone https://aur.archlinux.org/$aur_source.git
cd $aur_source
sed -i 's/https:\/\/github.com/https:\/\/fastgit.cc\/https:\/\/github.com/g' PKGBUILD
makepkg -si
