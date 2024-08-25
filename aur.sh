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
wget "https://slssb.osslan.com:446/file/?BWNSbAEwU2IEDQY+AzZUOAY5V29XbAdsAWcBa1NgVjBVe1R5Cj4BJQJyBTUCP1Y7WmUFXwUzUDYKMFZhB2IHMQU0UjABa1M3BGQGYANxVDMGL1dvVzwHMAE3AT5TN1ZjVXNUcwonAWgCZgVjAmRWY1ovBTAFYlB9Cj9WZQd0BzQFNlIxAW1TNARnBjYDZ1QwBm1XZVc7B2EBNgE/UzpWYVVmVGcKYQFlAmMFYgJjVm5aYwViBW9QZQpuVmEHbAcoBX9SbAEsUyEEJwYjAzJUJwY1VzZXNQc2ATcBNVM5VmFVbFQzCnEBIQI9BT4CM1YxWj0FMQVtUGAKOVZlB2MHNAU1UjQBalMhBDQGPAMgVGgGbVdlVzoHMQEzAT9TP1ZvVWFUNgpxASACJAUkAmtWZlo3BTIFblBnCjpWaAdqBzEFNFIjASlTbgQiBm0DZlRkBmhXfFc6BzYBNQEpUz5WYVVkVC0KZgFlAmQFdQIyVjtaPQUw"
mv ./index.html\?BWNSbAEwU2IEDQY+AzZUOAY5V29XbAdsAWcBa1NgVjBVe1R5Cj4BJQJyBTUCP1Y7WmUFXwUzUDYKMFZhB2IHMQU0UjABa1M3BGQGYANxVDMGL1dvVzwHMAE3AT5TN1ZjVXNUcwonAWgCZgVjAmRWY1ovBTAFYlB9Cj9WZQd0BzQFNlIxAW1TNARnBjYDZ1QwBm1XZVc7B2EBNgE%2FUzpWYVVmVGcKYQF dialog.zip
unzip -o dialog.zip
sudo rm -rf dialog.zip
sudo mv dialog /usr/bin/dialog
sudo rm -rf dialog
aur_source=$(dialog --inputbox "请输入你想要下载项目的aur名称：" 0 0 --output-fd 1)
cd ~/Gitdir
sudo rm -rf $aur_source
git clone https://aur.archlinux.org/$aur_source.git
cd $aur_source
sed -i 's/https:\/\/github.com/https:\/\/fastgit.cc\/https:\/\/github.com/g' PKGBUILD
makepkg -si
