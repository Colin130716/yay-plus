#!/bin/bash

# 全局变量
readonly LOG_DIR="$HOME/.yay-plus/logs"
readonly PACKAGE_DIR="$HOME/.yay-plus/packages"
readonly CREATE_LOG_TIME=$(date +'%Y%m%d_%H%M%S')
readonly AUR_BASE_URL="https://aur.archlinux.org"
readonly AUR_RPC_URL="$AUR_BASE_URL/rpc/?v=5"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# 初始化函数
init() {
    mkdir -p "$LOG_DIR" "$PACKAGE_DIR"
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 日志开始记录" >> "$LOG_DIR/$CREATE_LOG_TIME.log"
}

# 日志记录函数
log() {
    local message="$1"
    local level="${2:-INFO}"
    local now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] [$level] $message" >> "$LOG_DIR/$CREATE_LOG_TIME.log"
}

# 输出带颜色的消息
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 安装软件包函数
install_package() {
    local package="$1"
    log "安装软件包: $package"
    print_color "$BLUE" "安装软件包: $package"
    sudo pacman -S --needed --noconfirm "$package"
}

# 主菜单函数
main_menu() {
    cd "$PACKAGE_DIR" || exit 1
    echo "YAY+" | figlet | lolcat
    echo "Version 3" | figlet | lolcat
    
    echo "
    1. 安装软件包
    2. 卸载软件包
    3. 运行flatpak软件包
    4. 查找软件包
    5. 更新系统
    6. 退出
    "
    
    read -rp "请输入选项: " choice
    log "主菜单选择: $choice"
    
    case $choice in
        1) choose_install_method ;;
        2) uninstall_package ;;
        3) run_flatpak_package ;;
        4) search_packages ;;
        5) update_system ;;
        6) 
            log "程序退出"
            print_color "$GREEN" "yay+正在退出，感谢使用"
            exit 0
            ;;
        *) 
            print_color "$RED" "无效的选项，请重新输入"
            main_menu
            ;;
    esac
}

# 安装必要的软件包
install_required_packages() {
    local packages=(
        git base-devel wget unzip npm go curl
        figlet lolcat vim flatpak jq
    )
    
    for package in "${packages[@]}"; do
        if ! command_exists "$package" && ! pacman -Qs "$package" >/dev/null; then
            install_package "$package"
        fi
    done
    
    # 设置flatpak源
    setup_flatpak
}

# 设置flatpak源
setup_flatpak() {
    log "设置flatpak源"
    if ! flatpak remote-list | grep -q flathub; then
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi
    
    read -rp "是否要更换flathub源为中科大源？(Y/n): " use_mirror
    case $use_mirror in
        [nN]) return ;;
        *)
            log "更换flathub源为中科大源"
            sudo flatpak remote-delete flathub 2>/dev/null
            sudo flatpak remote-add --if-not-exists --priority=1 flathub \
                https://mirrors.ustc.edu.cn/flathub/flathub.flatpakrepo
            
            # 从上交大源导入GPG密钥
            wget -q https://mirror.sjtu.edu.cn/flathub/flathub.gpg
            sudo flatpak remote-modify flathub --gpg-import flathub.gpg
            rm -f flathub.gpg
            sudo flatpak update
            ;;
    esac
}

# 搜索软件包函数
search_packages() {
    read -rp "请输入要搜索的软件包名称: " package_name
    
    if [ -z "$package_name" ]; then
        print_color "$RED" "输入不能为空，请重新输入"
        search_packages
        return
    fi
    
    log "搜索软件包: $package_name"
    
    # 搜索官方仓库
    print_color "$CYAN" "正在搜索官方仓库..."
    pacman -Ss "$package_name" || print_color "$YELLOW" "官方仓库中未找到相关软件包"
    
    # 搜索AUR仓库
    print_color "$CYAN" "正在搜索AUR仓库..."
    local aur_results
    aur_results=$(curl -s "$AUR_RPC_URL&type=search&arg=$package_name")
    
    if echo "$aur_results" | grep -q "No results found"; then
        print_color "$YELLOW" "AUR仓库中未找到相关软件包"
    else
        echo "$aur_results" | jq -r '.results[] | "\(.Name) \(.Version)\n    \(.Description)\n"' 2>/dev/null ||
        echo "$aur_results" | grep -Eo '"Name":"[^"]*"|"Version":"[^"]*"|"Description":"[^"]*"' | \
            sed 's/"Name":"/名称: /; s/"Version":"/ 版本: /; s/"Description":"/ 描述: /; s/"$//' | \
            sed 'N;N;s/\n/ /g'
    fi
    
    read -n 1 -rp "按任意键返回主菜单..."
    main_menu
}

# 更新系统函数
update_system() {
    echo "
    请选择更新方式：
    1. 更新所有软件包 (pacman + AUR + flatpak)
    2. 仅更新 pacman 软件包
    3. 仅更新 AUR 软件包
    4. 仅更新 flatpak 软件包
    "
    
    read -r update_method
    log "系统更新，方式: $update_method"
    
    case $update_method in
        1)
            update_pacman_packages
            update_aur_packages
            update_flatpak_packages
            ;;
        2) update_pacman_packages ;;
        3) update_aur_packages ;;
        4) update_flatpak_packages ;;
        *)
            print_color "$RED" "输入错误，返回主菜单"
            main_menu
            ;;
    esac
    
    print_color "$GREEN" "系统更新完成，按任意键返回主菜单..."
    read -n 1
    main_menu
}

# 更新pacman包
update_pacman_packages() {
    print_color "$CYAN" "正在更新 pacman 软件包..."
    sudo pacman -Syu --noconfirm
}

# 更新AUR包
update_aur_packages() {
    print_color "$CYAN" "检查AUR包更新..."
    local aur_packages
    aur_packages=$(pacman -Qm | awk '{print $1}')
    
    for pkg in $aur_packages; do
        print_color "$CYAN" "检查 $pkg 更新..."
        
        local local_version
        local_version=$(pacman -Q "$pkg" | awk '{print $2}')
        
        local aur_info
        aur_info=$(curl -s "$AUR_RPC_URL&type=info&arg[]=$pkg")
        local latest_version
        latest_version=$(echo "$aur_info" | jq -r ".results[0].Version" 2>/dev/null)
        
        if [ "$latest_version" != "null" ] && [ "$local_version" != "$latest_version" ]; then
            print_color "$YELLOW" "发现更新: $pkg ($local_version -> $latest_version)"
            read -rp "是否更新 $pkg? (Y/n): " update_choice
            if [[ "$update_choice" =~ ^[Nn]$ ]]; then
                continue
            fi
            
            # 下载并构建更新
            cd "$PACKAGE_DIR" || continue
            rm -rf "$pkg"
            git clone "$AUR_BASE_URL/$pkg.git"
            cd "$pkg" || continue
            
            # 处理依赖
            process_dependencies
            
            # 构建并安装
            set_env
            set_proxy
            makepkg -si --skippgpcheck --noconfirm
        else
            print_color "$GREEN" "$pkg 已是最新版本"
        fi
    done
}

# 更新flatpak包
update_flatpak_packages() {
    print_color "$CYAN" "正在更新 flatpak 软件包..."
    flatpak update -y
}

# 卸载软件包函数
uninstall_package() {
    echo "
    请选择卸载方式：
    1. 卸载 pacman 安装的软件包
    2. 卸载 flatpak(flathub) 安装的软件包
    "
    
    read -r uninstall_package_type
    
    case $uninstall_package_type in
        1)
            read -rp "请输入软件包名称（支持多个软件包同时卸载，用空格隔开）: " uninstall_package_name
            log "卸载pacman包: $uninstall_package_name"
            print_color "$BLUE" "卸载软件包: $uninstall_package_name"
            sudo pacman -Rsn --noconfirm $uninstall_package_name
            ;;
        2)
            read -rp "请输入软件包名称（支持多个软件包同时卸载，用空格隔开）: " uninstall_package_name
            log "卸载flatpak包: $uninstall_package_name"
            print_color "$BLUE" "卸载flatpak软件包: $uninstall_package_name"
            flatpak uninstall $uninstall_package_name
            ;;
        *)
            print_color "$RED" "输入错误，请重新输入"
            uninstall_package
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        print_color "$GREEN" "卸载成功"
    else
        print_color "$RED" "卸载失败，请查看日志: $LOG_DIR/$CREATE_LOG_TIME.log"
    fi
    
    main_menu
}

# 运行flatpak软件包
run_flatpak_package() {
    read -rp "请输入要运行的flatpak软件包名: " flatpak_package_name
    log "运行flatpak包: $flatpak_package_name"
    print_color "$BLUE" "执行: flatpak run $flatpak_package_name"
    
    if flatpak run "$flatpak_package_name"; then
        print_color "$GREEN" "flatpak软件包 $flatpak_package_name 运行完成"
    else
        print_color "$RED" "flatpak软件包 $flatpak_package_name 运行失败"
    fi
    
    main_menu
}

# 设置环境变量
set_env() {
    # Go代理设置
    read -rp "需要使用go代理下载吗？（代理下载地址：https://goproxy.cn）(y/N): " set_go_proxy
    if [[ "$set_go_proxy" =~ ^[Yy]$ ]]; then
        log "设置Go代理: https://goproxy.cn"
        export GO111MODULE=on
        export GOPROXY=https://goproxy.cn
    else
        read -rp "是否还原为默认代理下载地址？(Y/n): " set_go_proxy_default
        if [[ ! "$set_go_proxy_default" =~ ^[Nn]$ ]]; then
            log "还原Go代理: https://proxy.golang.org"
            export GOPROXY=https://proxy.golang.org
        fi
    fi
    
    # NPM代理设置
    read -rp "需要使用npm代理吗？（代理地址：https://registry.npmmirror.com）(y/N): " set_npm_proxy
    if [[ "$set_npm_proxy" =~ ^[Yy]$ ]]; then
        log "设置NPM代理: https://registry.npmmirror.com"
        npm config set registry https://registry.npmmirror.com
        sudo npm config set registry https://registry.npmmirror.com
    else
        read -rp "是否还原为默认代理下载地址？(Y/n): " set_npm_proxy_default
        if [[ ! "$set_npm_proxy_default" =~ ^[Nn]$ ]]; then
            log "还原NPM代理: https://registry.npmjs.org"
            npm config set registry https://registry.npmjs.org
        fi
    fi
    
    # Kernel.org镜像替换
    read -rp "是否需要替换kernel.org镜像为中科大镜像以加速内核下载？(y/N): " set_kernel_mirror
    if [[ "$set_kernel_mirror" =~ ^[Yy]$ ]]; then
        log "替换kernel.org镜像为中科大镜像"
        sed -i 's#https://www.kernel.org/pub/#https://mirrors.ustc.edu.cn/kernel.org/#g' PKGBUILD
        sed -i 's#https://cdn.kernel.org/pub/#https://mirrors.ustc.edu.cn/kernel.org/#g' PKGBUILD
    fi
    
    # 查看PKGBUILD
    read -rp "是否要查看PKGBUILD内容？(y/N): " read_PKGBUILD
    if [[ "$read_PKGBUILD" =~ ^[Yy]$ ]]; then
        log "查看PKGBUILD内容"
        vim PKGBUILD
    fi
}

# 设置代理
set_proxy() {
    echo "请选择GitHub代理："
    echo "1. https://fastgit.cc/（目前测试速度较慢）"
    echo "2. https://gh-proxy.com/（推荐，下载速度快）"
    echo "3. https://gh.api.99988866.xyz/（备用,不稳定）"
    echo "4. https://gh.llkk.cc/（速度较快）"
    echo "5. 不使用GitHub代理（不推荐）"
    
    read -r proxy
    
    case $proxy in
        1)
            log "使用GitHub代理: https://fastgit.cc/"
            sed -i 's#https://github.com/#https://fastgit.cc/https://github.com/#g' PKGBUILD
            sed -i 's#https://raw.githubusercontent.com/#https://fastgit.cc/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        2)
            log "使用GitHub代理: https://gh-proxy.com/"
            sed -i 's#https://github.com/#https://gh-proxy.com/https://github.com/#g' PKGBUILD
            sed -i 's#https://raw.githubusercontent.com/#https://gh-proxy.com/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        3)
            log "使用GitHub代理: https://gh.api.99988866.xyz/"
            sed -i 's#https://github.com/#https://gh.api.99988866.xyz/https://github.com/#g' PKGBUILD
            sed -i 's#https://raw.githubusercontent.com/#https://gh.api.99988866.xyz/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
        4)
            log "使用GitHub代理: https://gh.llkk.cc/"
            sed -i 's#https://github.com/#https://gh.llkk.cc/https://github.com/#g' PKGBUILD
            sed -i 's#https://raw.githubusercontent.com/#https://gh.llkk.cc/https://raw.githubusercontent.com/#g' PKGBUILD
            ;;
    esac
}

# 处理依赖函数
process_dependencies() {
    if [ ! -f "PKGBUILD" ]; then
        print_color "$RED" "PKGBUILD不存在，无法解析依赖"
        return 1
    fi
    
    # 获取依赖列表
    local depends makedepends checkdepends all_deps
    depends=$(grep -E '^depends=' PKGBUILD | sed 's/depends=//' | tr -d '()' | tr '\n' ' ')
    makedepends=$(grep -E '^makedepends=' PKGBUILD | sed 's/makedepends=//' | tr -d '()' | tr '\n' ' ')
    checkdepends=$(grep -E '^checkdepends=' PKGBUILD | sed 's/checkdepends=//' | tr -d '()' | tr '\n' ' ')
    
    all_deps="$depends $makedepends $checkdepends"
    
    # 处理每个依赖
    for dep in $all_deps; do
        # 跳过已安装的包和空值
        if [ -z "$dep" ] || pacman -Qs "^$dep$" >/dev/null 2>&1; then
            continue
        fi
        
        # 检查是否在官方仓库中
        if pacman -Si "$dep" >/dev/null 2>&1; then
            print_color "$CYAN" "安装官方依赖: $dep"
            sudo pacman -S --noconfirm "$dep"
        else
            # 检查是否在AUR中
            local aur_info
            aur_info=$(curl -s "$AUR_RPC_URL&type=info&arg[]=$dep")
            if echo "$aur_info" | grep -q '"ResultCount":1'; then
                print_color "$CYAN" "发现AUR依赖: $dep，开始安装..."
                
                # 下载AUR依赖
                cd "$PACKAGE_DIR" || return 1
                rm -rf "$dep"
                git clone "$AUR_BASE_URL/$dep.git"
                cd "$dep" || continue
                
                # 递归处理依赖
                process_dependencies
                
                # 构建并安装依赖
                set_env
                set_proxy
                makepkg -si --skippgpcheck --noconfirm
                
                # 返回原目录
                cd "$PACKAGE_DIR" || return 1
            else
                print_color "$YELLOW" "警告: 依赖 $dep 不在官方仓库或AUR中，可能会构建失败"
            fi
        fi
    done
}

# 构建软件包
build_package() {
    print_color "$BLUE" "执行: makepkg -si --skippgpcheck --noconfirm"
    if makepkg -si --skippgpcheck --noconfirm >> "$LOG_DIR/$CREATE_LOG_TIME.log" 2>&1; then
        log "makepkg成功完成"
        print_color "$GREEN" "makepkg成功完成"
        sleep 1
        main_menu
    else
        local exit_status=$?
        log "makepkg失败，退出码: $exit_status"
        print_color "$RED" "makepkg出现错误 $exit_status，请查看日志: $LOG_DIR/$CREATE_LOG_TIME.log"
        exit 2
    fi
}

# 选择安装方式
choose_install_method() {
    read -rp "请输入软件包名称（如果要从flathub安装软件包，请填写完整包名，例如org.kde.kalk）: " aur_source
    
    echo "请选择安装方式："
    echo "1. 从pacman安装"
    echo "2. 从AUR安装"
    echo "3. 从flathub（flatpak）安装"
    
    read -r install_method
    sudo rm -rf "$aur_source"
    
    case $install_method in
        1) install_from_pacman ;;
        2) install_from_aur ;;
        3) install_from_flatpak ;;
        *)
            print_color "$RED" "无效的选项"
            choose_install_method
            ;;
    esac
}

# 从pacman安装
install_from_pacman() {
    log "从pacman安装: $aur_source"
    print_color "$CYAN" "正在尝试pacman安装..."
    
    if sudo pacman -S --noconfirm "$aur_source" >> "$LOG_DIR/$CREATE_LOG_TIME.log" 2>&1; then
        log "pacman安装成功: $aur_source"
        print_color "$GREEN" "pacman安装成功"
        main_menu
    else
        log "pacman安装失败: $aur_source"
        print_color "$RED" "pacman安装失败，请检查网络连接或软件包名称"
        
        read -rp "是否要尝试从AUR安装？(Y/n): " install_from_aur_choice
        if [[ "$install_from_aur_choice" =~ ^[Nn]$ ]]; then
            read -rp "是否要尝试使用flatpak安装？(Y/n): " install_from_flatpak_choice
            if [[ "$install_from_flatpak_choice" =~ ^[Nn]$ ]]; then
                print_color "$YELLOW" "已取消安装"
                main_menu
            else
                install_from_flatpak
            fi
        else
            install_from_aur
        fi
    fi
}

# 从AUR安装
install_from_aur() {
    log "从AUR安装: $aur_source"
    print_color "$CYAN" "正在尝试从AUR安装..."
    
    cd "$PACKAGE_DIR" || return 1
    sudo rm -rf "$aur_source"
    
    if ! git clone "$AUR_BASE_URL/$aur_source.git" >> "$LOG_DIR/$CREATE_LOG_TIME.log" 2>&1; then
        log "git clone失败: $aur_source"
        print_color "$RED" "git clone失败，请检查网络连接或软件包名称"
        main_menu
    fi
    
    cd "$aur_source" || return 1
    
    if [ ! -f "PKGBUILD" ]; then
        log "PKGBUILD不存在: $aur_source"
        print_color "$RED" "PKGBUILD不存在，可能不是有效的AUR包"
        main_menu
    fi
    
    # 处理依赖
    process_dependencies
    
    set_env
    set_proxy
    build_package
}

# 从flatpak安装
install_from_flatpak() {
    log "从flatpak安装: $aur_source"
    print_color "$CYAN" "正在尝试从flatpak安装..."
    
    if flatpak install flathub "$aur_source" >> "$LOG_DIR/$CREATE_LOG_TIME.log" 2>&1; then
        log "flatpak安装成功: $aur_source"
        print_color "$GREEN" "flatpak安装成功"
    else
        log "flatpak安装失败: $aur_source"
        print_color "$RED" "flatpak安装失败，请检查网络连接或软件包名称"
    fi
    
    main_menu
}

# 系统检测
system_check() {
    print_color "$RED" "WARNING"
    print_color "$YELLOW" "必须要用Arch系的系统和非root用户，别拿着个Ubuntu跑过来用这个脚本"
    sleep 3
    
    if ! command_exists pacman; then
        print_color "$RED" "非Arch系用户无法使用本脚本"
        exit 3
    fi
    
    if [ "$(whoami)" = "root" ]; then
        print_color "$RED" "makepkg不能在root权限下运行"
        exit 5
    fi
}

# 主函数
main() {
    init
    system_check
    install_required_packages
    
    clear
    print_color "$GREEN" "欢迎使用yay+ Version 3"
    print_color "$CYAN" "仓库地址: https://github.com/Colin130716/yay-plus/"
    print_color "$CYAN" "看乐子: https://github.com/qwq9scan114514/yay-s-joke/"
    
    sleep 3
    main_menu
}

# 运行主函数
main "$@"