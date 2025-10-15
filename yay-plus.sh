#!/bin/bash

# 全局变量
readonly CONFIG_FILE="$HOME/.yay-plus/yay-plus.conf"
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

# 默认配置
DEFAULT_GITHUB_PROXY="1"
DEFAULT_GO_PROXY="true"
DEFAULT_NPM_PROXY="true"
DEFAULT_KERNEL_ORG_PROXY="true"
DEFAULT_AUR_SOURCE="aur"

AUR_GITHUB_MIRROR="https://github.com/archlinux/aur.git"

# 初始化函数
init() {
    mkdir -p "$LOG_DIR" "$PACKAGE_DIR"
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 日志开始记录" >> "$LOG_DIR/$CREATE_LOG_TIME.log"
    
    # 检查并创建配置文件
    check_and_create_config
    
    # 加载配置文件
    load_config
}

# 检查并创建配置文件
check_and_create_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "配置文件不存在，创建默认配置"
        print_color "$YELLOW" "检测到配置文件不存在，正在创建默认配置文件: $CONFIG_FILE"
        print_color "$YELLOW" "您可以在配置文件中设置默认的代理选项"
        create_default_config
        sleep 2
    fi
}

# 加载配置文件
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log "加载配置文件: $CONFIG_FILE"
        # 读取配置
        DEFAULT_GITHUB_PROXY=$(get_config_value "github_proxy" "$DEFAULT_GITHUB_PROXY")
        DEFAULT_GO_PROXY=$(get_config_value "go_proxy" "$DEFAULT_GO_PROXY")
        DEFAULT_NPM_PROXY=$(get_config_value "npm_proxy" "$DEFAULT_NPM_PROXY")
        DEFAULT_AUR_SOURCE=$(get_config_value "aur_source" "$DEFAULT_AUR_SOURCE")
    else
        log "配置文件不存在，使用默认配置"
    fi

    case $DEFAULT_GITHUB_PROXY in
        1)
            AUR_GITHUB_MIRROR="https://github.akams.cn/https://github.com/archlinux/aur.git"
            ;;
        2)
            AUR_GITHUB_MIRROR="https://gh-proxy.com/https://github.com/archlinux/aur.git"
            ;;
        3)
            AUR_GITHUB_MIRROR="https://ghfile.geekertao.top/https://github.com/archlinux/aur.git"
            ;;
        4)
            AUR_GITHUB_MIRROR="https://gh.llkk.cc/https://github.com/archlinux/aur.git"
            ;;
    esac
}

# 获取配置值
get_config_value() {
    local key="$1"
    local default_value="$2"
    local value
    
    value=$(grep -E "^$key=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2-)
    if [ -z "$value" ]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# 创建默认配置文件
create_default_config() {
    log "创建默认配置文件"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Yay+ 配置文件
# 此文件用于设置 Yay+ 的默认行为

# GitHub代理设置 (空:每次询问, 1-5:使用对应代理)
# 1: https://github.akams.cn/ (推荐，采用Geo-IP 302重定向其他高速及镜像站)
# 2: https://gh-proxy.com/ (推荐，下载速度快)
# 3: https://ghfile.geekertao.top/ (推荐，速度快)
# 4: https://gh.llkk.cc/ (速度较快)
# 5: 不使用GitHub代理 (不推荐)
github_proxy=$DEFAULT_GITHUB_PROXY

# Go代理设置 (true:启用代理, false:不启用代理)
# 启用后会使用 https://goproxy.cn 作为Go模块代理
go_proxy=$DEFAULT_GO_PROXY

# NPM代理设置 (true:启用代理, false:不启用代理)
# 启用后会使用 https://registry.npmmirror.com 作为NPM镜像源
npm_proxy=$DEFAULT_NPM_PROXY

# AUR源选择 (aur:使用AUR官方, github:使用GitHub镜像)
aur_source=$DEFAULT_AUR_SOURCE

# kernel.org代理设置 (true:启动代理, false:不启用代理)
kernel_org_proxy=$DEFAULT_KERNEL_ORG_PROXY
EOF
    
    print_color "$GREEN" "配置文件已创建: $CONFIG_FILE"
    print_color "$CYAN" "默认设置: GitHub代理=1, Go代理=true, NPM代理=true, kernel.org代理=true, AUR源=aur"
    print_color "$CYAN" "您可以编辑此文件来自定义默认行为"
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

# 获取AUR包的实际Git仓库信息
get_aur_package_info() {
    local package="$1"
    local aur_info
    aur_info=$(curl -s "$AUR_RPC_URL&type=info&arg[]=$package")
    
    if echo "$aur_info" | grep -q '"ResultCount":1'; then
        local pkgname=$(echo "$aur_info" | jq -r ".results[0].Name" 2>/dev/null)
        local urlpath=$(echo "$aur_info" | jq -r ".results[0].URLPath" 2>/dev/null)
        
        if [ -n "$pkgname" ] && [ "$pkgname" != "null" ]; then
            # 从URLPath中提取实际的仓库名
            # URLPath格式通常是: cgit/aur.git/snapshot/package-name.tar.gz
            # 或者: cgit/aur.git/snapshot/actual-repo-name.tar.gz
            if [ -n "$urlpath" ] && [ "$urlpath" != "null" ]; then
                # 提取实际的仓库名称
                local actual_repo=$(basename "$urlpath" .tar.gz)
                echo "$pkgname|$actual_repo"
                return 0
            else
                echo "$pkgname|$pkgname"
                return 0
            fi
        fi
    fi
    echo "$package|$package"
    return 1
}

# 克隆AUR包函数
clone_aur_package() {
    local package="$1"
    local target_dir="$2"
    
    cd "$PACKAGE_DIR" || return 1
    sudo rm -rf "$target_dir"
    
    # 根据配置选择AUR源
    local aur_source="${3:-$DEFAULT_AUR_SOURCE}"
    
    # 获取AUR包的实际信息
    local package_info
    package_info=$(get_aur_package_info "$package")
    local actual_package=$(echo "$package_info" | cut -d'|' -f1)
    local actual_repo=$(echo "$package_info" | cut -d'|' -f2)
    
    log "包信息: 请求包=$package, 实际包=$actual_package, 仓库=$actual_repo"
    
    if [ "$aur_source" = "github" ]; then
        log "从GitHub镜像克隆AUR包: $actual_repo (原请求: $package)"
        print_color "$CYAN" "从GitHub镜像克隆AUR包: $actual_repo"
        
        if ! git clone --branch "$actual_repo" --single-branch "$AUR_GITHUB_MIRROR" "$target_dir" >> "$LOG_DIR/$CREATE_LOG_TIME.log" 2>&1; then
            log "从GitHub镜像克隆失败，尝试使用AUR官方源"
            print_color "$YELLOW" "从GitHub镜像克隆失败，尝试使用AUR官方源"
            
            # 回退到AUR官方源
            if ! git clone "$AUR_BASE_URL/$actual_repo.git" "$target_dir" >> "$LOG_DIR/$CREATE_LOG_TIME.log" 2>&1; then
                log "git clone失败: $package (尝试仓库: $actual_repo)"
                print_color "$RED" "git clone失败，请检查网络连接或软件包名称"
                return 1
            fi
        fi
    else
        log "从AUR官方克隆AUR包: $actual_repo (原请求: $package)"
        print_color "$CYAN" "从AUR官方克隆AUR包: $actual_repo"
        
        if ! git clone "$AUR_BASE_URL/$actual_repo.git" "$target_dir" >> "$LOG_DIR/$CREATE_LOG_TIME.log" 2>&1; then
            log "从AUR官方克隆失败，尝试使用GitHub镜像"
            print_color "$YELLOW" "从AUR官方克隆失败，尝试使用GitHub镜像"
            
            # 回退到GitHub镜像
            if ! git clone --branch "$actual_repo" --single-branch "$AUR_GITHUB_MIRROR" "$target_dir" >> "$LOG_DIR/$CREATE_LOG_TIME.log" 2>&1; then
                log "git clone失败: $package (尝试仓库: $actual_repo)"
                print_color "$RED" "git clone失败，请检查网络连接或软件包名称"
                return 1
            fi
        fi
    fi
    
    return 0
}

# 安装软件包函数
install_package() {
    local package="$1"
    log "安装软件包: $package"
    print_color "$BLUE" "安装软件包: $package"
    sudo pacman -S --needed --noconfirm "$package"
}

# 显示帮助信息
show_help() {
    cat << EOF
Yay+ - 一个 AUR Helper，但不只局限于 AUR

用法:
  yay-plus [选项] [包名]

选项:
  -S, --install <包名>     安装软件包
      --pacman             从官方仓库安装
      --aur                从AUR安装
      --flatpak            从Flatpak安装

  -R, --remove <包名>      卸载软件包
      --pacman             卸载官方仓库软件包
      --flatpak            卸载Flatpak软件包

  -Q, --query <包名>       查询软件包信息
      --pacman             查询官方仓库软件包
      --aur                查询AUR软件包
      --flatpak            查询Flatpak软件包
      --online             查询云端仓库软件包
      --local              查询本地已安装软件包

  -U, --update             更新系统
      --pacman             更新官方仓库软件包
      --aur                更新AUR软件包
      --flatpak            更新Flatpak软件包
      --all                更新所有软件包 (pacman + AUR + flatpak)

  -L, --local-install <路径> 本地安装
                          支持: AUR包目录、.pkg.tar.zst包、.flatpakref文件

  -h, --help               显示此帮助信息
  -v, --version            显示版本信息

示例:
  yay-plus -S --pacman firefox         从官方仓库安装Firefox
  yay-plus -S --aur yay                从AUR安装yay
  yay-plus -R --pacman firefox         卸载Firefox
  yay-plus -Q --pacman firefox         查询Firefox信息
  yay-plus -Q --online --aur firefox   查询AUR云端Firefox信息
  yay-plus -Q --local --aur            查询所有本地AUR软件包
  yay-plus -U --aur                    更新所有AUR软件包
  yay-plus -U --all                    更新所有软件包
  yay-plus -L /path/to/package         本地安装包
  yay-plus -L /path/to/pkg.tar.zst     安装本地包文件
  yay-plus -L /path/to/file.flatpakref 安装Flatpak引用文件
EOF
    exit 0
}

# 显示版本信息
show_version() {
    echo "Yay+ Version 3.1.2-Release.fix1"
    exit 0
}

# 解析命令行参数
parse_args() {
    local install_mode=""
    local remove_mode=""
    local query_mode=""
    local query_scope=""  # 查询范围（online/local）
    local update_mode=""
    local local_install_path=""
    local package_name=""
    local has_specific_mode=false
    local query_type=""   # 查询类型（pacman/aur/flatpak）

    # 保存原始参数用于调试
    log "命令行参数: $*"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -S|--install)
                install_mode="generic"
                shift
                # 只有在没有后续选项时才将下一个参数视为包名
                if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
                    package_name="$1"
                    shift
                fi
                ;;
            -R|--remove)
                remove_mode="generic"
                shift
                if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
                    package_name="$1"
                    shift
                fi
                ;;
            -Q|--query)
                query_mode="true"
                shift
                if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
                    package_name="$1"
                    shift
                fi
                ;;
            -U|--update)
                update_mode="generic"
                shift
                ;;
            -L|--local-install)
                shift
                if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
                    local_install_path="$1"
                    shift
                else
                    print_color "$RED" "错误: -L/--local-install 需要指定路径"
                    exit 1
                fi
                ;;
            --pacman)
                if [ -n "$install_mode" ]; then
                    install_mode="pacman"
                elif [ -n "$remove_mode" ]; then
                    remove_mode="pacman"
                elif [ -n "$query_mode" ]; then
                    query_type="pacman"
                elif [ -n "$update_mode" ]; then
                    update_mode="pacman"
                fi
                has_specific_mode=true
                shift
                ;;
            --aur)
                if [ -n "$install_mode" ]; then
                    install_mode="aur"
                elif [ -n "$query_mode" ]; then
                    query_type="aur"
                elif [ -n "$update_mode" ]; then
                    update_mode="aur"
                fi
                has_specific_mode=true
                shift
                ;;
            --flatpak)
                if [ -n "$install_mode" ]; then
                    install_mode="flatpak"
                elif [ -n "$remove_mode" ]; then
                    remove_mode="flatpak"
                elif [ -n "$query_mode" ]; then
                    query_type="flatpak"
                elif [ -n "$update_mode" ]; then
                    update_mode="flatpak"
                fi
                has_specific_mode=true
                shift
                ;;
            --online)
                if [ -n "$query_mode" ]; then
                    query_scope="online"
                fi
                has_specific_mode=true
                shift
                ;;
            --local)
                if [ -n "$query_mode" ]; then
                    query_scope="local"
                fi
                has_specific_mode=true
                shift
                ;;
            --all)
                if [ -n "$update_mode" ]; then
                    update_mode="all"
                fi
                has_specific_mode=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            *)
                # 如果没有指定模式，则认为是包名
                if [ -z "$package_name" ] && [[ ! $1 =~ ^- ]]; then
                    package_name="$1"
                    shift
                else
                    print_color "$RED" "未知参数: $1"
                    exit 1
                fi
                ;;
        esac
    done

    log "解析结果: install_mode=$install_mode, remove_mode=$remove_mode, query_mode=$query_mode, update_mode=$update_mode, local_install_path=$local_install_path, package_name=$package_name"

    # 执行相应操作
    if [ -n "$local_install_path" ]; then
        local_install "$local_install_path"
        exit 0
    elif [ -n "$install_mode" ]; then
        if [ -z "$package_name" ]; then
            print_color "$RED" "错误: 安装操作需要指定包名"
            exit 1
        fi
        
        case $install_mode in
            pacman) install_via_pacman "$package_name" ;;
            aur) install_via_aur "$package_name" ;;
            flatpak) install_via_flatpak "$package_name" ;;
            generic)
                print_color "$RED" "错误: 必须指定安装来源 (--pacman, --aur 或 --flatpak)"
                exit 1
                ;;
        esac
        exit 0
    elif [ -n "$remove_mode" ]; then
        if [ -z "$package_name" ]; then
            print_color "$RED" "错误: 卸载操作需要指定包名"
            exit 1
        fi
        
        case $remove_mode in
            pacman) remove_via_pacman "$package_name" ;;
            flatpak) remove_via_flatpak "$package_name" ;;
            generic)
                print_color "$RED" "错误: 必须指定卸载来源 (--pacman 或 --flatpak)"
                exit 1
                ;;
        esac
        exit 0
    elif [ -n "$query_mode" ]; then
        # 处理查询操作
        if [ -z "$query_scope" ]; then
            print_color "$RED" "必须指定查询范围: --online 或 --local"
            exit 1
        fi

        if [ -z "$query_type" ]; then
            # 如果没有指定查询类型，默认查询所有类型
            case "$query_scope" in
                online) query_online_all "$package_name" ;;
                local) query_local_all "$package_name" ;;
            esac
        else
            # 指定了查询类型
            case "$query_scope" in
                online)
                    case "$query_type" in
                        pacman) query_online_pacman "$package_name" ;;
                        aur) query_online_aur "$package_name" ;;
                        flatpak) query_online_flatpak "$package_name" ;;
                    esac
                    ;;
                local)
                    case "$query_type" in
                        pacman) query_local_pacman "$package_name" ;;
                        aur) query_local_aur "$package_name" ;;
                        flatpak) query_local_flatpak "$package_name" ;;
                    esac
                    ;;
            esac
        fi
        exit 0
    elif [ -n "$update_mode" ]; then
        case $update_mode in
            pacman) update_pacman_packages ;;
            aur) update_aur_packages ;;
            flatpak) update_flatpak_packages ;;
            all) update_all_packages ;;
            generic) update_system ;;
        esac
        exit 0
    fi

    # 如果没有指定命令行参数，进入交互模式
    return 1
}

# 本地安装函数
local_install() {
    local path="$1"
    
    if [ ! -e "$path" ]; then
        print_color "$RED" "错误: 路径不存在: $path"
        exit 1
    fi
    
    log "本地安装: $path"
    
    if [ -d "$path" ]; then
        # 处理目录（AUR包）
        local_install_aur "$path"
    elif [ -f "$path" ]; then
        # 处理文件
        case "$path" in
            *.pkg.tar.zst|*.pkg.tar.xz|*.pkg.tar.gz)
                local_install_package_file "$path"
                ;;
            *.flatpakref)
                local_install_flatpakref "$path"
                ;;
            *)
                print_color "$RED" "错误: 不支持的文件类型: $path"
                print_color "$YELLOW" "支持的文件类型: .pkg.tar.zst, .pkg.tar.xz, .pkg.tar.gz, .flatpakref"
                exit 1
                ;;
        esac
    else
        print_color "$RED" "错误: 无效的路径: $path"
        exit 1
    fi
}

# 本地安装AUR包目录
local_install_aur() {
    local dir_path="$1"
    
    log "本地安装AUR包: $dir_path"
    print_color "$CYAN" "检测到AUR包目录，开始构建安装..."
    
    cd "$dir_path" || {
        print_color "$RED" "错误: 无法进入目录: $dir_path"
        exit 1
    }
    
    if [ ! -f "PKGBUILD" ]; then
        print_color "$RED" "错误: 目录中未找到PKGBUILD文件，不是有效的AUR包"
        exit 1
    fi
    
    # 获取包信息
    local pkgname pkgver pkgrel
    source PKGBUILD >/dev/null 2>&1
    
    if [ -z "$pkgname" ]; then
        print_color "$RED" "错误: 无法从PKGBUILD解析包信息"
        exit 1
    fi
    
    # 显示安装信息
    print_color "$BLUE" ":: 即将安装的AUR包"
    print_color "$GREEN" "AUR/$pkgname $pkgver-$pkgrel (本地构建)"
    echo ""
    
    # 确认安装
    read -rp ":: 是否安装？[Y/n] " confirm
    case "$confirm" in
        [nN]*) 
            print_color "$YELLOW" "安装已取消"
            exit 0
            ;;
    esac
    
    # 处理依赖
    process_dependencies
    
    set_ghproxy
    set_proxy
    
    # 构建并安装
    print_color "$CYAN" "开始构建包..."
    if makepkg -si --skippgpcheck --noconfirm; then
        print_color "$GREEN" "AUR包安装成功: $pkgname"
    else
        print_color "$RED" "AUR包安装失败: $pkgname"
        exit 1
    fi
}

# 本地安装包文件
local_install_package_file() {
    local file_path="$1"
    
    log "本地安装包文件: $file_path"
    print_color "$CYAN" "检测到包文件，开始安装..."
    
    # 显示文件信息
    print_color "$BLUE" ":: 即将安装的包文件"
    print_color "$GREEN" "文件: $(basename "$file_path")"
    echo ""
    
    # 确认安装
    read -rp ":: 是否安装？[Y/n] " confirm
    case "$confirm" in
        [nN]*) 
            print_color "$YELLOW" "安装已取消"
            exit 0
            ;;
    esac
    
    # 使用pacman安装
    if sudo pacman -U --noconfirm "$file_path"; then
        print_color "$GREEN" "包文件安装成功: $(basename "$file_path")"
    else
        print_color "$RED" "包文件安装失败: $(basename "$file_path")"
        exit 1
    fi
}

# 本地安装Flatpak引用文件
local_install_flatpakref() {
    local file_path="$1"
    
    log "本地安装Flatpak引用文件: $file_path"
    print_color "$CYAN" "检测到Flatpak引用文件，开始安装..."
    
    # 显示文件信息
    print_color "$BLUE" ":: 即将安装的Flatpak应用"
    print_color "$GREEN" "引用文件: $(basename "$file_path")"
    echo ""
    
    # 确认安装
    read -rp ":: 是否安装？[Y/n] " confirm
    case "$confirm" in
        [nN]*) 
            print_color "$YELLOW" "安装已取消"
            exit 0
            ;;
    esac
    
    # 使用flatpak安装
    if flatpak install -y "$file_path"; then
        print_color "$GREEN" "Flatpak应用安装成功: $(basename "$file_path")"
    else
        print_color "$RED" "Flatpak应用安装失败: $(basename "$file_path")"
        exit 1
    fi
}

# 通过pacman安装
install_via_pacman() {
    local package="$1"
    log "命令行安装pacman包: $package"
    
    # 获取包信息
    local package_info
    package_info=$(pacman -Si "$package" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # 显示安装信息
        echo ":: 即将安装的Pacman包"
        local repo=$(echo "$package_info" | grep "^Repository" | cut -d: -f2 | tr -d ' ')
        local name=$(echo "$package_info" | grep "^Name" | cut -d: -f2 | tr -d ' ')
        local version=$(echo "$package_info" | grep "^Version" | cut -d: -f2 | tr -d ' ')
        echo "$repo/$name $version"
        echo ""
        
        # 确认安装
        read -rp ":: 是否安装？[Y/n] " confirm
        case "$confirm" in
            [nN]*) 
                print_color "$YELLOW" "安装已取消"
                exit 0
                ;;
            *) 
                sudo pacman -S --noconfirm "$package"
                ;;
        esac
    else
        print_color "$RED" "无法找到包 $package 的信息"
        exit 1
    fi
}

# 通过AUR安装
install_via_aur() {
    local package="$1"
    log "命令行安装AUR包: $package"
    
    # 获取AUR包的实际信息
    local package_info
    package_info=$(get_aur_package_info "$package")
    local actual_package=$(echo "$package_info" | cut -d'|' -f1)
    local actual_repo=$(echo "$package_info" | cut -d'|' -f2)
    
    log "安装AUR包: 请求包=$package, 实际包=$actual_package, 仓库=$actual_repo"
    
    # 使用实际的仓库名进行克隆
    if ! clone_aur_package "$package" "$actual_repo"; then
        exit 1
    fi
    
    cd "$actual_repo" || exit 1
    
    if [ ! -f "PKGBUILD" ]; then
        log "PKGBUILD不存在: $actual_repo"
        print_color "$RED" "PKGBUILD不存在，可能不是有效的AUR包"
        exit 1
    fi
    
    # 处理依赖
    process_dependencies
    
    # 获取包信息
    local pkgname pkgver pkgrel
    source PKGBUILD >/dev/null 2>&1
    
    # 显示安装信息
    echo ":: 即将安装的AUR包"
    echo "AUR/$pkgname $pkgver-$pkgrel"
    echo ""
    
    # 确认安装
    read -rp ":: 是否安装？[Y/n] " confirm
    case "$confirm" in
        [nN]*) 
            print_color "$YELLOW" "安装已取消"
            exit 0
            ;;
        *) 
            set_ghproxy
            set_proxy
            # 不使用--asdeps参数，避免成为孤儿包
            makepkg -si --skippgpcheck --noconfirm
            main_menu
            ;;
    esac
}

# 通过flatpak安装
install_via_flatpak() {
    local package="$1"
    log "命令行安装flatpak包: $package"
    flatpak install -y flathub "$package"
}

# 通过pacman卸载
remove_via_pacman() {
    local package="$1"
    log "命令行卸载pacman包: $package"
    sudo pacman -Rsn --noconfirm "$package"
}

# 通过flatpak卸载
remove_via_flatpak() {
    local package="$1"
    log "命令行卸载flatpak包: $package"
    flatpak uninstall -y "$package"
}

# 查询云端pacman包
query_online_pacman() {
    local package="$1"
    log "命令行查询云端pacman包: $package"
    
    if [ -z "$package" ]; then
        # 如果没有指定包名，显示所有可用包
        pacman -Sl
    else
        # 查询特定包
        pacman -Ss "$package"
    fi
}

# 查询云端AUR包
query_online_aur() {
    local package="$1"
    log "命令行查询云端AUR包: $package"
    
    if [ -z "$package" ]; then
        # 如果没有指定包名，显示最近更新的AUR包
        print_color "$YELLOW" "需要指定包名来查询AUR包"
        return 1
    else
        # 查询特定包
        local aur_results
        aur_results=$(curl -s "$AUR_RPC_URL&type=search&arg=$package")
        
        if echo "$aur_results" | grep -q "No results found"; then
            print_color "$YELLOW" "AUR仓库中未找到相关软件包"
        else
            echo "$aur_results" | jq -r '.results[] | "\(.Name) \(.Version)\n    \(.Description)\n"' 2>/dev/null ||
            echo "$aur_results" | grep -Eo '"Name":"[^"]*"|"Version":"[^"]*"|"Description":"[^"]*"' | \
                sed 's/"Name":"/名称: /; s/"Version":"/ 版本: /; s/"Description":"/ 描述: /; s/"$//' | \
                sed 'N;N;s/\n/ /g'
        fi
    fi
}

# 查询云端flatpak包
query_online_flatpak() {
    local package="$1"
    log "命令行查询云端flatpak包: $package"
    
    if [ -z "$package" ]; then
        # 如果没有指定包名，显示所有可用包
        flatpak remote-ls flathub
    else
        # 查询特定包
        flatpak search "$package"
    fi
}

# 查询本地pacman包
query_local_pacman() {
    local package="$1"
    log "命令行查询本地pacman包: $package"
    
    if [ -z "$package" ]; then
        # 如果没有指定包名，显示所有已安装包
        pacman -Q
    else
        # 查询特定包
        pacman -Qi "$package" || pacman -Qs "$package"
    fi
}

# 查询本地AUR包
query_local_aur() {
    local package="$1"
    log "命令行查询本地AUR包: $package"
    
    if [ -z "$package" ]; then
        # 如果没有指定包名，显示所有已安装AUR包
        pacman -Qm
    else
        # 查询特定包
        pacman -Qi "$package" 2>/dev/null || pacman -Qm | grep "$package"
    fi
}

# 查询本地flatpak包
query_local_flatpak() {
    local package="$1"
    log "命令行查询本地flatpak包: $package"
    
    if [ -z "$package" ]; then
        # 如果没有指定包名，显示所有已安装flatpak包
        flatpak list
    else
        # 查询特定包
        flatpak info "$package" 2>/dev/null || flatpak list | grep "$package"
    fi
}

# 查询所有云端包
query_online_all() {
    local package="$1"
    log "命令行查询所有云端包: $package"
    
    if [ -z "$package" ]; then
        print_color "$YELLOW" "需要指定包名来查询所有云端包"
        return 1
    fi
    
    print_color "$CYAN" "=== 官方仓库 ==="
    query_online_pacman "$package"
    
    echo ""
    print_color "$CYAN" "=== AUR仓库 ==="
    query_online_aur "$package"
    
    echo ""
    print_color "$CYAN" "=== Flatpak仓库 ==="
    query_online_flatpak "$package"
}

# 查询所有本地包
query_local_all() {
    local package="$1"
    log "命令行查询所有本地包: $package"
    
    if [ -z "$package" ]; then
        # 显示所有已安装包
        print_color "$CYAN" "=== 官方仓库包 ==="
        pacman -Qn
        
        echo ""
        print_color "$CYAN" "=== AUR包 ==="
        pacman -Qm
        
        echo ""
        print_color "$CYAN" "=== Flatpak包 ==="
        flatpak list
    else
        # 查询特定包
        print_color "$CYAN" "=== 官方仓库包 ==="
        query_local_pacman "$package"
        
        echo ""
        print_color "$CYAN" "=== AUR包 ==="
        query_local_aur "$package"
        
        echo ""
        print_color "$CYAN" "=== Flatpak包 ==="
        query_local_flatpak "$package"
    fi
}

# 更新所有软件包
update_all_packages() {
    log "命令行更新所有软件包"
    print_color "$CYAN" "更新所有软件包 (pacman + AUR + flatpak)"
    
    update_pacman_packages
    update_aur_packages
    update_flatpak_packages
    
    print_color "$GREEN" "所有软件包更新完成"
}

# 主菜单函数
main_menu() {
    cd "$PACKAGE_DIR" || exit 1
    echo "YAY+" | figlet | lolcat
    echo "Version 3.1.2-Release"
    
    echo "
    1. 安装软件包
    2. 卸载软件包
    3. 运行flatpak软件包
    4. 查找软件包
    5. 更新系统
    6. 本地安装
    7. 退出
    "
    
    read -rp "请输入选项: " choice
    log "主菜单选择: $choice"
    
    case $choice in
        1) choose_install_method ;;
        2) uninstall_package ;;
        3) run_flatpak_package ;;
        4) search_packages ;;
        5) update_system ;;
        6) local_install_menu ;;
        7) 
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

# 本地安装菜单
local_install_menu() {
    echo "
    本地安装选项：
    1. 安装本地AUR包目录
    2. 安装本地包文件 (.pkg.tar.zst等)
    3. 安装本地Flatpak引用文件 (.flatpakref)
    4. 返回主菜单
    "
    
    read -rp "请输入选项: " local_choice
    log "本地安装菜单选择: $local_choice"
    
    case $local_choice in
        1)
            read -rp "请输入AUR包目录路径: " aur_dir
            if [ -n "$aur_dir" ]; then
                local_install_aur "$aur_dir"
            else
                print_color "$RED" "路径不能为空"
                local_install_menu
            fi
            ;;
        2)
            read -rp "请输入包文件路径: " pkg_file
            if [ -n "$pkg_file" ]; then
                local_install_package_file "$pkg_file"
            else
                print_color "$RED" "路径不能为空"
                local_install_menu
            fi
            ;;
        3)
            read -rp "请输入Flatpak引用文件路径: " flatpakref_file
            if [ -n "$flatpakref_file" ]; then
                local_install_flatpakref "$flatpakref_file"
            else
                print_color "$RED" "路径不能为空"
                local_install_menu
            fi
            ;;
        4)
            main_menu
            ;;
        *)
            print_color "$RED" "无效的选项"
            local_install_menu
            ;;
    esac
    
    read -n 1 -rp "按任意键返回主菜单..."
    main_menu
}

# 安装必要的软件包
install_required_packages() {
    sudo pacman -S --needed --noconfirm git base-devel wget unzip npm go curl figlet lolcat vim flatpak jq
    
    # 设置flatpak源
    setup_flatpak
}

# 设置flatpak源
setup_flatpak() {
    log "设置flatpak源"
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    read -rp "是否要更换flathub源为中科大源？（Y/n）: " use_mirror
    case $use_mirror in
        [nN]) return ;;
        *)
            log "更换flathub源为中科大源"
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
            
            # 从上交大源导入GPG密钥
            wget -q https://mirror.sjtu.edu.cn/flathub/flathub.gpg
            sudo flatpak remote-modify flathub --gpg-import flathub.gpg
            rm -f flathub.gpg
            sudo flatpak remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub
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
    sudo pacman -Syyy
    sudo pacman -Su --noconfirm
}

# 更新AUR包
update_aur_packages() {
    print_color "$CYAN" "检查AUR包更新..."
    local aur_packages
    aur_packages=$(pacman -Qm | awk '{print $1}')
    
    # 用于跟踪已经处理过的仓库
    local processed_repos=""
    
    for pkg in $aur_packages; do
        print_color "$CYAN" "检查 $pkg 更新..."
        
        local local_version
        local_version=$(pacman -Q "$pkg" | awk '{print $2}')
        
        # 获取AUR包的实际信息
        local package_info
        package_info=$(get_aur_package_info "$pkg")
        local actual_package=$(echo "$package_info" | cut -d'|' -f1)
        local actual_repo=$(echo "$package_info" | cut -d'|' -f2)
        
        local aur_info
        aur_info=$(curl -s "$AUR_RPC_URL&type=info&arg[]=$actual_package")
        local latest_version
        latest_version=$(echo "$aur_info" | jq -r ".results[0].Version" 2>/dev/null)
        
        # 检查是否已经处理过这个仓库
        if echo "$processed_repos" | grep -q "$actual_repo"; then
            print_color "$YELLOW" "跳过 $pkg (仓库 $actual_repo 已处理)"
            continue
        fi
        
        # 添加到已处理列表
        processed_repos="$processed_repos $actual_repo"
        
        if [ "$latest_version" != "null" ] && [ "$local_version" != "$latest_version" ]; then
            print_color "$YELLOW" "发现更新: $pkg ($local_version -> $latest_version)"
            read -rp "是否更新 $pkg? (Y/n): " update_choice
            if [[ "$update_choice" =~ ^[Nn]$ ]]; then
                continue
            fi
            
            # 使用实际的仓库名进行克隆
            if ! clone_aur_package "$pkg" "$actual_repo"; then
                continue
            fi
            
            cd "$actual_repo" || continue
            
            # 处理依赖
            process_dependencies
            
            set_ghproxy
            set_proxy
            # 不使用--asdeps参数，避免成为孤儿包
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

# 设置代理
set_proxy() {
    # local mode="${1:-interactive}"

    if [ "$DEFAULT_GO_PROXY" = "true" ]; then
        log "设置Go代理: https://goproxy.cn"
        export GO111MODULE=on
        export GOPROXY=https://goproxy.cn
    fi
    # else
    #     read -rp "需要使用go代理下载吗？（代理下载地址：https://goproxy.cn）(y/N): " set_go_proxy
    #     if [[ "$set_go_proxy" =~ ^[Yy]$ ]]; then
    #         log "设置Go代理: https://goproxy.cn"
    #         export GO111MODULE=on
    #         export GOPROXY=https://goproxy.cn
    #     else
    #         read -rp "是否还原为默认代理下载地址？(Y/n): " set_go_proxy_default
    #         if [[ ! "$set_go_proxy_default" =~ ^[Nn]$ ]]; then
    #             log "还原Go代理: https://proxy.golang.org"
    #             export GOPROXY=https://proxy.golang.org
    #         fi
    #     fi
    # fi
    
    # NPM代理设置
    if [ "$DEFAULT_NPM_PROXY" = "true" ]; then
        log "设置NPM代理: https://registry.npmmirror.com"
        npm config set registry https://registry.npmmirror.com
        sudo npm config set registry https://registry.npmmirror.com
    fi
    # else
    #     read -rp "需要使用npm代理吗？（代理地址：https://registry.npmmirror.com）(y/N): " set_npm_proxy
    #     if [[ "$set_npm_proxy" =~ ^[Yy]$ ]]; then
    #         log "设置NPM代理: https://registry.npmmirror.com"
    #         npm config set registry https://registry.npmmirror.com
    #         sudo npm config set registry https://registry.npmmirror.com
    #     else
    #         read -rp "是否还原为默认代理下载地址？(Y/n): " set_npm_proxy_default
    #         if [[ ! "$set_npm_proxy_default" =~ ^[Nn]$ ]]; then
    #             log "还原NPM代理: https://registry.npmjs.org"
    #         npm config set registry https://registry.npmjs.org
    #         fi
    #     fi
    # fi
    
    # Kernel.org镜像替换
    if [ "$DEFAULT_KERNEL_ORG_PROXY" = "true" ]; then
        log "替换kernel.org镜像为中科大镜像"
        sed -i 's#https://www.kernel.org/pub/#https://mirrors.ustc.edu.cn/kernel.org/#g' PKGBUILD
        sed -i 's#https://cdn.kernel.org/pub/#https://mirrors.ustc.edu.cn/kernel.org/#g' PKGBUILD
    fi
}

# 设置GitHub代理
set_ghproxy() {
    # local mode="${1:-interactive}"
    
    if [ -n "$DEFAULT_GITHUB_PROXY" ]; then
        # 自动配置Github代理
        case $DEFAULT_GITHUB_PROXY in
            1)
                log "使用GitHub代理: https://github.akams.cn/"
                sed -i 's#https://github.com/#https://github.akams.cn/https://github.com/#g' PKGBUILD
                sed -i 's#https://raw.githubusercontent.com/#https://github.akams.cn/https://raw.githubusercontent.com/#g' PKGBUILD
                ;;
            2)
                log "使用GitHub代理: https://gh-proxy.com/"
                sed -i 's#https://github.com/#https://gh-proxy.com/https://github.com/#g' PKGBUILD
                sed -i 's#https://raw.githubusercontent.com/#https://gh-proxy.com/https://raw.githubusercontent.com/#g' PKGBUILD
                ;;
            3)
                log "使用GitHub代理: https://ghfile.geekertao.top/"
                sed -i 's#https://github.com/#https://ghfile.geekertao.top/https://github.com/#g' PKGBUILD
                sed -i 's#https://raw.githubusercontent.com/#https://ghfile.geekertao.top/https://raw.githubusercontent.com/#g' PKGBUILD
                ;;
            4)
                log "使用GitHub代理: https://gh.llkk.cc/"
                sed -i 's#https://github.com/#https://gh.llkk.cc/https://github.com/#g' PKGBUILD
                sed -i 's#https://raw.githubusercontent.com/#https://gh.llkk.cc/https://raw.githubusercontent.com/#g' PKGBUILD
                ;;
            *)
                log "未选择GitHub代理，继续安装"
                ;;
        esac
    fi
    
    # # 交互模式
    # echo "请选择GitHub代理："
    # echo "1. https://github.akams.cn/（推荐，采用Geo-IP 302重定向其他高速及镜像站）"
    # echo "2. https://gh-proxy.com/（推荐，下载速度快）"
    # echo "3. https://ghfile.geekertao.top/（推荐，速度快）"
    # echo "4. https://gh.llkk.cc/（速度较快）"
    # echo "5. 不使用GitHub代理（不推荐）"
    
    # read -r proxy
    
    # case $proxy in
    #     1)
    #         log "使用GitHub代理: https://github.akams.cn/"
    #         sed -i 's#https://github.com/#https://github.akams.cn/https://github.com/#g' PKGBUILD
    #         sed -i 's#https://raw.githubusercontent.com/#https://github.akams.cn/https://raw.githubusercontent.com/#g' PKGBUILD
    #         ;;
    #     2)
    #         log "使用GitHub代理: https://gh-proxy.com/"
    #         sed -i 's#https://github.com/#https://gh-proxy.com/https://github.com/#g' PKGBUILD
    #         sed -i 's#https://raw.githubusercontent.com/#https://gh-proxy.com/https://raw.githubusercontent.com/#g' PKGBUILD
    #         ;;
    #     3)
    #         log "使用GitHub代理: https://ghfile.geekertao.top/"
    #         sed -i 's#https://github.com/#https://ghfile.geekertao.top/https://github.com/#g' PKGBUILD
    #         sed -i 's#https://raw.githubusercontent.com/#https://ghfile.geekertao.top/https://raw.githubusercontent.com/#g' PKGBUILD
    #         ;;
    #     4)
    #         log "使用GitHub代理: https://gh.llkk.cc/"
    #         sed -i 's#https://github.com/#https://gh.llkk.cc/https://github.com/#g' PKGBUILD
    #         sed -i 's#https://raw.githubusercontent.com/#https://gh.llkk.cc/https://raw.githubusercontent.com/#g' PKGBUILD
    #         ;;
    # esac
}

# 改进的依赖解析函数
parse_pkgbuild_deps() {
    local pkgbuild_file="${1:-PKGBUILD}"
    
    if [ ! -f "$pkgbuild_file" ]; then
        echo "错误: PKGBUILD文件不存在" >&2
        return 1
    fi
    
    # 使用grep和sed提取依赖信息，避免使用source
    local depends=$(grep -E '^depends=\(|^depends=' "$pkgbuild_file" | \
                   sed -e 's/^depends=//' -e 's/^(\|)$//g' -e "s/'//g" | tr -d '()' | tr ' ' '\n' | grep -v '^$')
    
    local makedepends=$(grep -E '^makedepends=\(|^makedepends=' "$pkgbuild_file" | \
                      sed -e 's/^makedepends=//' -e 's/^(\|)$//g' -e "s/'//g" | tr -d '()' | tr ' ' '\n' | grep -v '^$')
    
    local checkdepends=$(grep -E '^checkdepends=\(|^checkdepends=' "$pkgbuild_file" | \
                       sed -e 's/^checkdepends=//' -e 's/^(\|)$//g' -e "s/'//g" | tr -d '()' | tr ' ' '\n' | grep -v '^$')
    
    # 输出所有依赖
    echo "$depends $makedepends $checkdepends" | tr ' ' '\n' | grep -v '^$' | sort -u
}

# 获取依赖函数
get_dependencies() {
    local pkgbuild_file="${1:-PKGBUILD}"
    
    # 解析依赖
    parse_pkgbuild_deps "$pkgbuild_file"
}

# 改进的依赖处理函数
process_dependencies() {
    if [ ! -f "PKGBUILD" ]; then
        print_color "$RED" "PKGBUILD不存在，无法解析依赖"
        return 1
    fi
    
    # 获取依赖列表
    local all_deps
    all_deps=$(get_dependencies)
    
    # 处理每个依赖
    for dep in $all_deps; do
        # 清理依赖名称（移除版本约束）
        local clean_dep=$(echo "$dep" | sed 's/[<>=].*//')
        
        # 跳过已安装的包和空值
        if [ -z "$clean_dep" ] || pacman -Qs "^$clean_dep$" >/dev/null 2>&1; then
            continue
        fi
        
        # 检查是否在官方仓库中
        if pacman -Si "$clean_dep" >/dev/null 2>&1; then
            print_color "$CYAN" "安装官方依赖: $clean_dep"
            sudo pacman -S --noconfirm "$clean_dep"
        else
            # 检查是否在AUR中
            local aur_info
            aur_info=$(curl -s "$AUR_RPC_URL&type=info&arg[]=$clean_dep")
            if echo "$aur_info" | grep -q '"ResultCount":1'; then
                print_color "$CYAN" "发现AUR依赖: $clean_dep，开始安装..."
                
                # 下载AUR依赖
                cd "$PACKAGE_DIR" || return 1
                rm -rf "$clean_dep"
                
                # 使用新的克隆函数
                if ! clone_aur_package "$clean_dep" "$clean_dep"; then
                    continue
                fi
                
                cd "$clean_dep" || continue
                
                # 递归处理依赖
                process_dependencies
                
                # 构建并安装依赖
                set_ghproxy
                set_proxy
                # 使用--asdeps安装依赖
                makepkg -si --skippgpcheck --noconfirm --asdeps
                
                # 返回原目录
                cd "$OLDPWD" || return 1
            else
                print_color "$YELLOW" "警告: 依赖 $clean_dep 不在官方仓库或AUR中，可能会构建失败"
            fi
        fi
    done
}

# 构建软件包
build_package() {
    print_color "$BLUE" "执行: makepkg -si --skipppgcheck --noconfirm"
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

    # 获取包信息
    local package_info
    package_info=$(pacman -Si "$aur_source" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # 显示安装信息
        print_color "$BLUE" ":: 即将安装的Pacman包"
        local repo=$(echo "$package_info" | grep "^Repository" | cut -d: -f2 | tr -d ' ')
        local name=$(echo "$package_info" | grep "^Name" | cut -d: -f2 | tr -d ' ')
        local version=$(echo "$package_info" | grep "^Version" | cut -d: -f2 | tr -d ' ')
        print_color "$GREEN" "$repo/$name $version"
        echo ""
        
        # 确认安装
        read -rp ":: 是否安装？[Y/n] " confirm
        case "$confirm" in
            [nN]*) 
                print_color "$YELLOW" "安装已取消"
                main_menu
                return
                ;;
        esac

        if sudo pacman -S --noconfirm "$aur_source" >> "$LOG_DIR/$CREATE_LOG_TIME.log" 2>&1; then
            log "pacman安装成功: $aur_source"
            print_color "$GREEN" "pacman安装成功"
            main_menu
        else
            log "pacman安装失败: $aur_source"
            print_color "$RED" "pacman安装失败，请检查网络连接或软件包名称"
            
            read -rp "是否要尝试从AUR安装？[Y/n]: " install_from_aur_choice
            if [[ "$install_from_aur_choice" =~ ^[Nn]$ ]]; then
                read -rp "是否要尝试使用flatpak安装？[Y/n]: " install_from_flatpak_choice
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
    else
        print_color "$RED" "无法找到包 $aur_source 的信息，可能不存在于官方仓库"
        
        read -rp "是否要尝试从AUR安装？[Y/n]: " install_from_aur_choice
        if [[ "$install_from_aur_choice" =~ ^[Nn]$ ]]; then
            read -rp "是否要尝试使用flatpak安装？[Y/n]: " install_from_flatpak_choice
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
install_via_aur() {
    local package="$1"
    log "命令行安装AUR包: $package"
    
    # 获取AUR包的实际信息
    local package_info
    package_info=$(get_aur_package_info "$package")
    local actual_package=$(echo "$package_info" | cut -d'|' -f1)
    local actual_repo=$(echo "$package_info" | cut -d'|' -f2)
    
    log "安装AUR包: 请求包=$package, 实际包=$actual_package, 仓库=$actual_repo"
    
    # 使用实际的仓库名进行克隆
    if ! clone_aur_package "$package" "$actual_repo"; then
        exit 1
    fi
    
    cd "$actual_repo" || exit 1
    
    if [ ! -f "PKGBUILD" ]; then
        log "PKGBUILD不存在: $actual_repo"
        print_color "$RED" "PKGBUILD不存在，可能不是有效的AUR包"
        exit 1
    fi
    
    # 处理依赖
    process_dependencies
    
    # 获取包信息
    local pkgname pkgver pkgrel
    source PKGBUILD >/dev/null 2>&1
    
    # 显示安装信息
    echo ":: 即将安装的AUR包"
    echo "AUR/$pkgname $pkgver-$pkgrel"
    echo ""
    
    # 确认安装
    read -rp ":: 是否安装？[Y/n] " confirm
    case "$confirm" in
        [nN]*) 
            print_color "$YELLOW" "安装已取消"
            exit 0
            ;;
        *) 
            set_ghproxy
            set_proxy
            # 不使用--asdeps参数，避免成为孤儿包
            makepkg -si --skippgpcheck --noconfirm
            main_menu
            ;;
    esac
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

# AUR源选择菜单
choose_aur_source() {
    echo "请选择AUR源："
    echo "1. AUR官方（aur.archlinux.org）"
    echo "2. GitHub镜像（github.com/archlinux/aur）"
    
    read -r aur_source_choice
    
    case $aur_source_choice in
        1) echo "aur" ;;
        2) echo "github" ;;
        *)
            print_color "$RED" "无效的选项，使用默认值: aur"
            echo "aur"
            ;;
    esac
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

    # 尝试解析命令行参数
    if parse_args "$@"; then
        # 如果解析成功并执行了命令，直接退出
        exit 0
    fi

    # 否则进入交互模式
    install_required_packages

    clear
    print_color "$GREEN" "欢迎使用yay+ Version 3"
    print_color "$CYAN" "仓库地址: https://github.com/Colin130716/yay-plus/"
    print_color "$CYAN" "看乐子: https://github.com/qwq9scan114514/yay-s-joke/"
    print_color "$YELLOW" "注意: AUR近期遭受攻击，已添加GitHub镜像作为备用源"

    sleep 3
    main_menu
}

# 运行主函数
main "$@"