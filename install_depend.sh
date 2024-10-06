#!/bin/bash

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
    install_package python3
    install_package python-pip
    install_package nodejs
    install_package yarn
}

install_packages