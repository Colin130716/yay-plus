#!/bin/bash
# =====================================================================
# Yay+ v3.2.0.1
# =====================================================================
# 用法请见 yay-plus -h 或 yay-plus --help 
#
# 配置文件: ~/.yay-plus/yay-plus.conf
# 日志文件: ~/.yay-plus/logs/<时间戳>.log
# 包缓存:   ~/.yay-plus/packages/
# =====================================================================

# ==================== 全局常量 ====================

# --- 路径常量 ---
# 用户配置文件，存储代理/源等选项（key=value 格式）
readonly CONFIG_FILE="$HOME/.yay-plus/yay-plus.conf"
# 日志目录，每次脚本运行生成一个以时间戳命名的 .log 文件
readonly LOG_DIR="$HOME/.yay-plus/logs"
# AUR 克隆和构建的临时工作目录
readonly PACKAGE_DIR="$HOME/.yay-plus/packages"
# 本次运行的日志时间戳（脚本启动时固化，同一次运行的所有日志写入同一文件）
readonly CREATE_LOG_TIME=$(date +'%Y%m%d_%H%M%S')

# --- AUR API ---
# AUR 官方站点
readonly AUR_BASE_URL="https://aur.archlinux.org"
# AUR RPC v5 接口基础地址，用于 search / info 等端点
readonly AUR_RPC_URL="$AUR_BASE_URL/rpc/v5"

# --- ANSI 颜色（用于 print_color） ---
readonly RED='\033[0;31m'      # 错误：包未找到、安装失败
readonly GREEN='\033[0;32m'    # 成功：安装完成、版本已最新
readonly YELLOW='\033[1;33m'   # 警告：配置更新、跳过已处理
readonly BLUE='\033[0;34m'     # 标题：即将安装的包列表
readonly CYAN='\033[0;36m'     # 进度：正在克隆、正在检查更新
readonly NC='\033[0m'          # 重置为终端默认颜色

# --- 默认配置（可被 ~/.yay-plus/yay-plus.conf 覆盖） ---
# GitHub 代理: 1=akams.cn  2=gh-proxy.com  3=geekertao.top  4=llkk.cc  5=不使用
DEFAULT_GITHUB_PROXY="1"
# NPM 镜像: true→使用 npmmirror.com 加速
DEFAULT_NPM_PROXY="true"
# kernel.org 镜像: true→替换为中科大镜像
DEFAULT_KERNEL_ORG_PROXY="true"
# AUR 克隆源: "aur"=官方  "github"=GitHub 镜像
DEFAULT_AUR_SOURCE="aur"
# 调试模式: true→DEBUG 日志同步输出到终端
DEFAULT_DEBUG_MODE="false"
# AUR 缓存有效期（分钟），超时自动刷新；设为 0 则每次都刷新
DEFAULT_AUR_CACHE_TTL="30"
# 无需确认模式: true→跳过所有交互确认，自动执行
NOCONFIRM="false"
# 强制刷新 AUR 缓存: true→忽略 TTL，强制重新拉取
FORCE_AUR_REFRESH="false"
# 自更新通道: release / beta / dev
DEFAULT_SELF_UPDATE_CHANNEL="release"
# 配置文件格式版本（用于自动升级旧配置）
CONFIG_VERSION="7"
# AUR 包版本缓存文件，批量缓存避免逐包 RPC 调用
readonly AUR_CACHE_FILE="$HOME/.yay-plus/aur-packages.cache"
# 自更新版本 JSON 地址
readonly VERSION_JSON_URL="https://yayplus.qzz.io/version.json"
# 自更新状态文件（记录上次检查的版本，避免重复提示）
readonly SELF_UPDATE_STATE="$HOME/.yay-plus/.self-update"
# 脚本版本号
YAY_PLUS_VERSION="3.2.0.1"
# GitHub 上 AUR 的镜像仓库地址（load_config 根据代理设置动态替换）
AUR_GITHUB_MIRROR="https://github.com/archlinux/aur.git"


# ==================== 初始化与配置管理 ====================

# ---------------------------------------------------------------------------
# init — 脚本入口初始化
#   创建日志/包目录，检查配置文件版本，加载配置
#   无参数，无返回值
#   由 main() 在启动时调用
# ---------------------------------------------------------------------------
init() {
    mkdir -p "$LOG_DIR" "$PACKAGE_DIR"
    now_time=$(date +'%Y/%m/%d %H:%M:%S')
    echo "[$now_time] 日志开始记录" >> "$LOG_DIR/$CREATE_LOG_TIME.log"
    # 检查并创建配置文件
    check_and_create_config
    # 加载配置文件
    load_config
}

# ---------------------------------------------------------------------------
# check_and_create_config — 确保配置文件存在且版本匹配
#   如果配置文件不存在，创建默认配置
#   如果版本过旧，备份旧文件后升级
# ---------------------------------------------------------------------------
check_and_create_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "配置文件不存在，创建默认配置"
        print_color "$YELLOW" "检测到配置文件不存在，正在创建默认配置文件: $CONFIG_FILE"
        print_color "$YELLOW" "您可以在配置文件中设置默认的代理选项"
        create_default_config
        sleep 2
    else
        # 检查配置文件版本
        local config_file_version
        config_file_version=$(get_config_value "config_version" "1")
        log "当前配置文件版本: $config_file_version, 期望版本: $CONFIG_VERSION"
        if [ "$config_file_version" != "$CONFIG_VERSION" ]; then
            log "配置文件版本不匹配，更新配置文件"
            print_color "$YELLOW" "检测到配置文件版本不匹配 ($config_file_version -> $CONFIG_VERSION)，正在更新配置文件: $CONFIG_FILE"
            update_config
            sleep 2
        else
            log "配置文件版本已是最新"
        fi
    fi
}

# ---------------------------------------------------------------------------
# update_config — 升级配置文件到最新版本
#   读取旧配置项 → 备份旧文件 → 写入新格式文件，保留用户已有的设置值
# ---------------------------------------------------------------------------
update_config() {
    # 备份旧配置文件
    local backup_file="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$backup_file"
    log "备份旧配置文件到: $backup_file"
    # 读取旧配置
    local old_github_proxy=$(get_config_value "github_proxy" "$DEFAULT_GITHUB_PROXY")
    local old_npm_proxy=$(get_config_value "npm_proxy" "$DEFAULT_NPM_PROXY")
    local old_kernel_org_proxy=$(get_config_value "kernel_org_proxy" "$DEFAULT_KERNEL_ORG_PROXY")
    local old_aur_source=$(get_config_value "aur_source" "$DEFAULT_AUR_SOURCE")
    local old_debug_mode=$(get_config_value "debug_mode" "$DEFAULT_DEBUG_MODE")
    local old_aur_cache_ttl=$(get_config_value "aur_cache_ttl" "$DEFAULT_AUR_CACHE_TTL")
    local old_self_update_channel=$(get_config_value "self_update_channel" "$DEFAULT_SELF_UPDATE_CHANNEL")
    log "读取旧配置: github_proxy=$old_github_proxy, npm_proxy=$old_npm_proxy, kernel_org_proxy=$old_kernel_org_proxy, aur_source=$old_aur_source, debug_mode=$old_debug_mode, aur_cache_ttl=$old_aur_cache_ttl, self_update_channel=$old_self_update_channel"
    # 创建新的配置文件
    cat > "$CONFIG_FILE" << EOF
# Yay+ 配置文件
# 此文件用于设置 Yay+ 的默认行为

# GitHub代理设置 (空:每次询问, 1-5:使用对应代理)
# 1: https://github.akams.cn/ (推荐)
# 2: https://gh-proxy.com/ (推荐，下载速度快)
# 3: https://ghfile.geekertao.top/ (推荐，速度快)
# 4: https://gh.llkk.cc/ (速度较快)
# 5: 不使用GitHub代理 (不推荐)
github_proxy=$old_github_proxy

# NPM代理设置 (true:启用代理, false:不启用代理)
# 启用后会使用 https://registry.npmmirror.com 作为NPM镜像源
npm_proxy=$old_npm_proxy

# AUR源选择 (aur:使用AUR官方, github:使用GitHub镜像)
aur_source=$old_aur_source

# kernel.org代理设置 (true:启动代理, false:不启用代理)
kernel_org_proxy=$old_kernel_org_proxy

# 调试模式 (true:启用调试模式, false:不启用调试模式)
debug_mode=$old_debug_mode

# AUR缓存有效期（分钟，默认30；设为0则每次检查都刷新）
aur_cache_ttl=$old_aur_cache_ttl

# 自更新通道 (release: 稳定版, beta: 测试版, dev: 开发版)
self_update_channel=$old_self_update_channel

# 配置文件版本
config_version=$CONFIG_VERSION
EOF
    print_color "$GREEN" "配置文件已更新到版本 $CONFIG_VERSION"
    print_color "$CYAN" "旧配置文件已备份到: $backup_file"
}

# ---------------------------------------------------------------------------
# load_config — 从配置文件读取所有选项到全局变量
#   同时根据 DEFAULT_GITHUB_PROXY 值构造 AUR_GITHUB_MIRROR 代理 URL
# ---------------------------------------------------------------------------
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log "加载配置文件: $CONFIG_FILE"
        # 读取配置
        DEFAULT_GITHUB_PROXY=$(get_config_value "github_proxy" "$DEFAULT_GITHUB_PROXY")
        DEFAULT_NPM_PROXY=$(get_config_value "npm_proxy" "$DEFAULT_NPM_PROXY")
        DEFAULT_AUR_SOURCE=$(get_config_value "aur_source" "$DEFAULT_AUR_SOURCE")
        DEFAULT_KERNEL_ORG_PROXY=$(get_config_value "kernel_org_proxy" "$DEFAULT_KERNEL_ORG_PROXY")
        DEFAULT_DEBUG_MODE=$(get_config_value "debug_mode" "$DEFAULT_DEBUG_MODE")
        DEFAULT_AUR_CACHE_TTL=$(get_config_value "aur_cache_ttl" "$DEFAULT_AUR_CACHE_TTL")
        DEFAULT_SELF_UPDATE_CHANNEL=$(get_config_value "self_update_channel" "$DEFAULT_SELF_UPDATE_CHANNEL")
        CONFIG_VERSION=$(get_config_value "config_version" "$CONFIG_VERSION")
    else
        log "配置文件不存在，使用默认配置"
    fi

    # 根据代理编号拼接 GitHub 镜像地址
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

# ---------------------------------------------------------------------------
# get_config_value — 从配置文件读取指定键的值
#   参数: $1=键名  $2=默认值（键不存在时返回）
#   输出: 配置值（写入 stdout）
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# create_default_config — 写入全新的默认配置文件
#   仅在配置文件不存在时由 check_and_create_config 调用
# ---------------------------------------------------------------------------
create_default_config() {
    log "创建默认配置文件"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Yay+ 配置文件
# 此文件用于设置 Yay+ 的默认行为

# GitHub代理设置 (空:每次询问, 1-5:使用对应代理)
# 1: https://github.akams.cn/ (推荐)
# 2: https://gh-proxy.com/ (推荐，下载速度快)
# 3: https://ghfile.geekertao.top/ (推荐，速度快)
# 4: https://gh.llkk.cc/ (速度较快)
# 5: 不使用GitHub代理 (不推荐)
github_proxy=$DEFAULT_GITHUB_PROXY

# NPM代理设置 (true:启用代理, false:不启用代理)
# 启用后会使用 https://registry.npmmirror.com 作为NPM镜像源
npm_proxy=$DEFAULT_NPM_PROXY

# AUR源选择 (aur:使用AUR官方, github:使用GitHub镜像)
aur_source=$DEFAULT_AUR_SOURCE

# kernel.org代理设置 (true:启动代理, false:不启用代理)
kernel_org_proxy=$DEFAULT_KERNEL_ORG_PROXY

# 调试模式 (true:启用调试模式, false:不启用调试模式)
debug_mode=$DEFAULT_DEBUG_MODE

# AUR缓存有效期（分钟，默认30；设为0则每次检查都刷新）
aur_cache_ttl=$DEFAULT_AUR_CACHE_TTL

# 自更新通道 (release: 稳定版, beta: 测试版, dev: 开发版)
self_update_channel=$DEFAULT_SELF_UPDATE_CHANNEL

# 配置文件版本
config_version=$CONFIG_VERSION
EOF
    print_color "$GREEN" "配置文件已创建: $CONFIG_FILE"
    print_color "$CYAN" "默认设置: GitHub代理=1, NPM代理=true, kernel.org代理=true, AUR源=aur"
    print_color "$CYAN" "您可以编辑此文件来自定义默认行为"
}


# ==================== 日志与输出 ====================

# ---------------------------------------------------------------------------
# log — 统一日志记录
#   参数:
#     $1 = 日志消息（必填）
#     $2 = 日志级别（可选，默认 "INFO"），如 "WARN" "ERROR"
#     $3 = 为 "nostdout" 时抑制终端输出（仅写入日志文件）
#   终端输出仅当 DEFAULT_DEBUG_MODE=true 且未传 nostdout 时生效
#   日志格式: [时间] [级别] 消息
# ---------------------------------------------------------------------------
log() {
    local message="$1"
    local level="${2:-INFO}"
    local now_time=$(date +'%Y/%m/%d %H:%M:%S')
    local log_output="$LOG_DIR/$CREATE_LOG_TIME.log"

    # 检查是否传递了 nostdout 参数
    local stdout_enabled=true
    if [ "$#" -ge 3 ] && [ "$3" = "nostdout" ]; then
        stdout_enabled=false
    fi

    # 总是写入日志文件
    echo "[$now_time] [$level] $message" >> "$log_output"

    # 根据参数决定是否输出到标准输出
    if [ "$stdout_enabled" = true ] && [ "$DEFAULT_DEBUG_MODE" = "true" ]; then
        echo "[DEBUG] [$now_time] [$level] $message"
    fi
}

# ---------------------------------------------------------------------------
# print_color — 输出带 ANSI 颜色的文本
#   参数: $1=颜色常量(如 $RED $GREEN)  $2=消息文本
# ---------------------------------------------------------------------------
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}


# ==================== AUR / 辅助函数 ====================

# ---------------------------------------------------------------------------
# confirm_action — 统一确认交互，受 NOCONFIRM 全局变量控制
#   参数: $1=提示消息  $2=默认值(可选, Y=默认确认, N=默认取消)
#   返回: 0(确认/自动通过) / 1(取消)
#   NOCONFIRM=true 时跳过所有提示，直接返回 0
# ---------------------------------------------------------------------------
confirm_action() {
    if [ "$NOCONFIRM" = "true" ]; then
        return 0
    fi
    local prompt="$1"
    local default="${2:-Y}"
    read -rp "$prompt" confirm
    case "$confirm" in
        [nN]*) return 1 ;;
        *) return 0 ;;
    esac
}

# ---------------------------------------------------------------------------
# command_exists — 检测外部命令是否可用
#   参数: $1=命令名
#   返回: 0(存在) / 1(不存在)
# ---------------------------------------------------------------------------
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# get_aur_package_info_json — 调用 AUR RPC info 端点获取包元数据 JSON
#   参数: $1=包名（精确匹配）
#   输出: 原始 JSON 字符串
#   对应 API: GET /rpc/v5/info?arg[]=<package>
# ---------------------------------------------------------------------------
get_aur_package_info_json() {
    local package="$1"
    local aur_json=$(curl -s "$AUR_RPC_URL/info?arg[]=$package")
    log "接收到的json：$aur_json" "INFO" "nostdout"
    echo "$aur_json"
}

# ---------------------------------------------------------------------------
# search_aur_package — 通过 AUR RPC search 端点检查包是否存在于 AUR
#   参数: $1=包名
#   返回: 0(找到至少一个结果) / 1(未找到或请求失败)
#   对应 API: GET /rpc/v5/search/<package>?by=name
#   用于: install_auto_multi 判断 AUR 是否有该包；install_via_aur 入口校验
# ---------------------------------------------------------------------------
search_aur_package() {
    local package="$1"
    log "AUR RPC搜索: $package"
    local search_result
    search_result=$(curl -s "$AUR_RPC_URL/search/$package?by=name")
    log "AUR搜索结果: $search_result" "INFO" "nostdout"
    if echo "$search_result" | jq -e '.resultcount > 0' >/dev/null 2>&1; then
        log "AUR中找到包: $package"
        return 0
    else
        log "AUR中未找到包: $package"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# get_json_field — 从 AUR RPC JSON 中提取指定字段
#   参数: $1=JSON 字符串  $2=字段名（如 "Name" "Version" "Depends[]"）
#   输出: 字段值（可能为空或 "null"）
#   依赖: jq
# ---------------------------------------------------------------------------
get_json_field() {
    local json="$1"
    local field="$2"
    echo "$json" | jq -r ".results[0].$field" 2>/dev/null
}

# ---------------------------------------------------------------------------
# get_aur_package_info — 解析 AUR info JSON，返回 "包名|仓库名"
#   参数: $1=包名
#   输出: "Name|PackageBase"（用 | 分隔）
#   返回: 0(成功) / 1(未找到)
#   说明: AUR 中 Name 和 PackageBase 可能不同（如 -bin 包），
#         Git 克隆时需要 PackageBase 作为仓库名
# ---------------------------------------------------------------------------
get_aur_package_info() {
    local package="$1"
    local aur_info
    aur_info=$(get_aur_package_info_json "$package")
    log "接收到的AUR JSON: $aur_info" "INFO" "nostdout"
    if echo "$aur_info" | grep -q '"resultcount":1'; then
        local pkgname=$(get_json_field "$aur_info" "Name")
        local pkgbase=$(get_json_field "$aur_info" "PackageBase")

        log "从JSON获取的 pkgname: '$pkgname', pkgbase: '$pkgbase'" "INFO" "nostdout"

        if [ -n "$pkgname" ] && [ "$pkgname" != "null" ]; then
            if [ -n "$pkgbase" ] && [ "$pkgbase" != "null" ]; then
                echo "$pkgname|$pkgbase"
                return 0
            else
                echo "$pkgname|$pkgname"
                return 0
            fi
        elif [ -n "$pkgbase" ] && [ "$pkgbase" != "null" ]; then
            echo "$pkgbase|$pkgbase"
            return 0
        fi
        log "警告：无法从软件包 $package 的 AUR 信息中提取有效的软件包名或包基础，回退到传入包名" "WARN" "nostdout"
        echo "$package|$package"
        return 0
    else
        log "错误：AUR RPC 未返回软件包 $package 的任何结果" "ERROR" "nostdout"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# get_aur_dependencies — 从 AUR RPC 获取包的编译+运行依赖列表
#   参数: $1=包名
#   输出: 去重后的依赖包名列表（每行一个），过滤掉 .so 依赖
#   来源: Depends[] 和 MakeDepends[]
# ---------------------------------------------------------------------------
get_aur_dependencies() {
    local package="$1"
    local aur_info
    aur_info=$(get_aur_package_info_json "$package")
    if echo "$aur_info" | grep -q '"resultcount":1'; then
        local depends=$(get_json_field "$aur_info" "Depends[]")
        local makedepends=$(get_json_field "$aur_info" "MakeDepends[]")
        echo "$depends $makedepends" | tr ' ' '\n' | grep -v '\.so$' | grep -v '^$' | sort -u
    else
        echo ""
    fi
}

# ---------------------------------------------------------------------------
# clone_aur_package — 从 AUR（或 GitHub 镜像）克隆包仓库
#   参数:
#     $1 = 用户请求的包名（用于日志和 AUR RPC 查询）
#     $2 = 克隆目标目录名（相对于 $PACKAGE_DIR）
#     $3 = 可选，克隆源 "aur" 或 "github"，默认使用配置文件设置
#   流程:
#     1. cd $PACKAGE_DIR，删除旧目录
#     2. 通过 AUR RPC 获取真实 PackageBase
#     3. 优先使用配置的源克隆，失败则自动回退到另一个源
#   返回: 0(克隆成功) / 1(两个源均失败)
# ---------------------------------------------------------------------------
clone_aur_package() {
    local package="$1"
    local target_dir="${2:-$package}"
    # 防御：如果 target_dir 仍为空，用 package 兜底
    [ -z "$target_dir" ] && target_dir="$package"
    cd "$PACKAGE_DIR" || return 1
    sudo rm -rf "$target_dir"
    local aur_source="${3:-$DEFAULT_AUR_SOURCE}"
    local package_info
    package_info=$(get_aur_package_info "$package")
    log "从get_aur_package_info获取的信息: $package_info"
    local actual_package=$(echo "$package_info" | cut -d'|' -f1)
    local actual_repo=$(echo "$package_info" | cut -d'|' -f2)
    log "包信息: 请求包=$package, 实际包=$actual_package, 仓库=$actual_repo"
    if [ "$aur_source" = "github" ]; then
        log "从GitHub镜像克隆AUR包: $actual_repo (原请求: $package)"
        print_color "$CYAN" "从GitHub镜像克隆AUR包: $actual_repo"
        if ! git clone --branch "$actual_repo" --single-branch "$AUR_GITHUB_MIRROR" "$target_dir" >> "$LOG_DIR/$CREATE_LOG_TIME.log" 2>&1; then
            log "从GitHub镜像克隆失败，尝试使用AUR官方克隆" "WARN"
            print_color "$YELLOW" "从GitHub镜像克隆失败，尝试使用AUR官方克隆"
            if ! git clone https://aur.archlinux.org/"$actual_repo".git "$target_dir"; then
                log "AUR仓库克隆失败: $package" "ERROR"
                print_color "$RED" "AUR包下载失败，请检查网络连接或软件包名称"
                return 1
            fi
        fi
    else
        log "从AUR仓库克隆AUR包: $actual_repo (原请求: $package)"
        print_color "$CYAN" "从AUR仓库克隆AUR包: $actual_repo"
        if ! git clone https://aur.archlinux.org/"$actual_repo".git "$target_dir"; then
            log "AUR仓库克隆失败，尝试使用GitHub镜像" "WARN"
            print_color "$YELLOW" "AUR仓库克隆失败，尝试使用GitHub镜像"
            if ! git clone --branch "$actual_repo" --single-branch "$AUR_GITHUB_MIRROR" "$target_dir" >> "$LOG_DIR/$CREATE_LOG_TIME.log" 2>&1; then
                log "所有下载方式都失败: $package" "ERROR"
                print_color "$RED" "AUR包下载失败，请检查网络连接或软件包名称"
                return 1
            fi
        fi
    fi
    return 0
}

# ---------------------------------------------------------------------------
# process_dependencies — 递归解析并安装依赖（串行，深度优先）
#   参数: $1=包名（可选，为空时从当前目录 PKGBUILD 解析）
#   流程:
#     1. 通过 AUR RPC 获取依赖列表（失败则回退到 PKGBUILD 本地解析）
#     2. 遍历每个依赖:
#        a. 已安装 → 跳过
#        b. 官方仓库 → sudo pacman -S
#        c. AUR 包 → 克隆 → 递归调用自身 → 构建安装为依赖
#   关键: _caller_dir 变量显式跟踪目录，避免递归中 $OLDPWD 被覆盖导致
#         set_ghproxy/set_proxy/makepkg 运行在错误目录
# ---------------------------------------------------------------------------
process_dependencies() {
    local package="$1"
    if [ -z "$package" ]; then
        if [ ! -f "PKGBUILD" ]; then
            print_color "$RED" "PKGBUILD不存在，无法解析依赖"
            return 1
        fi
        local pkgname
        pkgname=$(grep -E '^pkgname=' PKGBUILD | cut -d'=' -f2 | tr -d "'\"")
        package="${pkgname:-unknown}"
    fi
    local all_deps
    all_deps=$(get_aur_dependencies "$package")
    if [ -z "$all_deps" ]; then
        print_color "$YELLOW" "无法从AUR获取依赖信息，尝试从PKGBUILD解析"
        all_deps=$(parse_pkgbuild_deps)
    fi
    for dep in $all_deps; do
        local clean_dep=$(echo "$dep" | sed 's#\u003E#>#g' | sed 's#\u003C#<#g')
        if [ -z "$clean_dep" ] || pacman -Qs "^$clean_dep$" >/dev/null 2>&1; then
            continue
        fi
        if pacman -Si "$clean_dep" >/dev/null 2>&1; then
            print_color "$CYAN" "安装官方依赖: $clean_dep"
            sudo pacman -S --noconfirm "$clean_dep"
        else
            local aur_info
            aur_info=$(get_aur_package_info_json "$clean_dep")
            if echo "$aur_info" | grep -q '"resultcount":1'; then
                print_color "$CYAN" "发现AUR依赖: $clean_dep，开始安装..."
                local _caller_dir="$PWD"
                cd "$PACKAGE_DIR" || return 1
                rm -rf "$clean_dep"
                if ! clone_aur_package "$clean_dep" "$clean_dep"; then
                    cd "$_caller_dir" || return 1
                    continue
                fi
                cd "$clean_dep" || { cd "$_caller_dir" || return 1; continue; }
                process_dependencies "$clean_dep"
                cd "$PACKAGE_DIR/$clean_dep" || return 1
                set_ghproxy
                set_proxy
                makepkg -si --skippgpcheck --noconfirm --asdeps
                cd "$_caller_dir" || return 1
            else
                print_color "$YELLOW" "警告: 依赖 $clean_dep 不在官方仓库或AUR中，可能会构建失败"
            fi
        fi
    done
}

# ---------------------------------------------------------------------------
# parse_pkgbuild_deps — 从 PKGBUILD 本地解析依赖（AUR RPC 失败时的备选）
#   参数: $1=PKGBUILD 路径（可选，默认 ./PKGBUILD）
#   输出: 去重后的依赖列表（depends + makedepends + checkdepends）
#   过滤: 排除 .so 库依赖和空行
# ---------------------------------------------------------------------------
parse_pkgbuild_deps() {
    local pkgbuild_file="${1:-PKGBUILD}"
    if [ ! -f "$pkgbuild_file" ]; then
        echo "错误: PKGBUILD文件不存在" >&2
        return 1
    fi
    local depends=$(grep -E '^depends=\(|^depends=' "$pkgbuild_file" | \
    sed -e 's/^depends=//' -e 's/^(\|)$//g' -e "s/'//g" | tr -d '()' | tr ' ' '\n' | grep -v '^$' | grep -v '\.so$')
    local makedepends=$(grep -E '^makedepends=\(|^makedepends=' "$pkgbuild_file" | \
    sed -e 's/^makedepends=//' -e 's/^(\|)$//g' -e "s/'//g" | tr -d '()' | tr ' ' '\n' | grep -v '^$' | grep -v '\.so$')
    local checkdepends=$(grep -E '^checkdepends=\(|^checkdepends=' "$pkgbuild_file" | \
    sed -e 's/^checkdepends=//' -e 's/^(\|)$//g' -e "s/'//g" | tr -d '()' | tr ' ' '\n' | grep -v '^$' | grep -v '\.so$')
    echo "$depends $makedepends $checkdepends" | tr ' ' '\n' | grep -v '^$' | sort -u
}


# ==================== 命令行操作接口 ====================

# ---------------------------------------------------------------------------
# show_help — 显示完整帮助信息并退出
#   触发: yay-plus -h 或 yay-plus --help
# ---------------------------------------------------------------------------
show_help() {
    echo -e "${GREEN}Yay+${NC} - 一个 AUR Helper，但不只局限于 AUR"
    echo -e "${GREEN}版本: ${YAY_PLUS_VERSION}${NC}"
    echo ""
    echo -e "${CYAN}用法:${NC}"
    echo -e "    ${YELLOW}yay-plus${NC} [选项] [包名...]"
    echo ""
    echo -e "${CYAN}选项:${NC}"
    echo ""
    echo -e "    ${YELLOW}-S, --install${NC} <包名...>  ${GREEN}安装软件包${NC} (支持多个包)"
    echo -e "        ${YELLOW}-p, --pacman${NC}           从官方仓库安装 ${CYAN}(可组合: -Sp)${NC}"
    echo -e "        ${YELLOW}-a, --aur${NC}              从AUR安装 ${CYAN}(可组合: -Sa)${NC}"
    echo -e "        ${YELLOW}-f, --flatpak${NC}          从Flatpak安装 ${CYAN}(可组合: -Sf)${NC}"
    echo -e "        ${YELLOW}-u, --auto${NC}             自动从所有源寻找并安装 ${CYAN}(默认, 可组合: -Su)${NC}"
    echo ""
    echo -e "    ${YELLOW}-R, --remove${NC} <包名...>   ${RED}卸载软件包${NC} (支持多个包)"
    echo -e "        ${YELLOW}-p, --pacman${NC}           卸载官方仓库软件包 ${CYAN}(可组合: -Rp)${NC}"
    echo -e "        ${YELLOW}-f, --flatpak${NC}          卸载Flatpak软件包 ${CYAN}(可组合: -Rf)${NC}"
    echo ""
    echo -e "    ${YELLOW}-Q, --query${NC} <包名...>   ${BLUE}查询软件包信息${NC} (支持多个包)"
    echo -e "        ${YELLOW}-p, --pacman${NC}           查询官方仓库软件包 ${CYAN}(可组合: -Qp)${NC}"
    echo -e "        ${YELLOW}-a, --aur${NC}              查询AUR软件包 ${CYAN}(可组合: -Qa)${NC}"
    echo -e "        ${YELLOW}-f, --flatpak${NC}          查询Flatpak软件包 ${CYAN}(可组合: -Qf)${NC}"
    echo -e "        ${YELLOW}-o, --online${NC}           查询云端仓库 ${CYAN}(可组合: -Qo)${NC}"
    echo -e "        ${YELLOW}-l, --local${NC}            查询本地已安装 ${CYAN}(可组合: -Ql)${NC}"
    echo -e "        ${YELLOW}--aur-search${NC}           AUR精确搜索，显示版本和描述"
    echo ""
    echo -e "    ${YELLOW}-U, --update${NC}            ${GREEN}更新系统${NC}"
    echo -e "        ${YELLOW}-p, --pacman${NC}           更新官方仓库软件包 ${CYAN}(可组合: -Up)${NC}"
    echo -e "        ${YELLOW}-a, --aur${NC}              更新AUR软件包 ${CYAN}(可组合: -Ua)${NC}"
    echo -e "        ${YELLOW}-f, --flatpak${NC}          更新Flatpak软件包 ${CYAN}(可组合: -Uf)${NC}"
    echo -e "        ${YELLOW}-l, --all${NC}              更新所有软件包 ${CYAN}(默认, 可组合: -Ul)${NC}"
    echo -e "        ${YELLOW}--aur-refresh${NC}         强制刷新AUR版本缓存（与 -Ua 联用）"
    echo ""
    echo -e "    ${YELLOW}-L, --local-install${NC} <路径> 本地安装"
    echo -e "        支持: AUR包目录、${CYAN}.pkg.tar.zst${NC}包、${CYAN}.flatpakref${NC}文件"
    echo ""
    echo -e "    ${YELLOW}-C, --clean${NC}             ${RED}清理缓存${NC}"
    echo -e "        ${YELLOW}-a, --aur${NC}              清除AUR缓存 ${CYAN}(可组合: -Ca)${NC}"
    echo -e "        ${YELLOW}-p, --pacman${NC}           清除pacman缓存 ${CYAN}(可组合: -Cp)${NC}"
    echo -e "        ${YELLOW}-f, --flatpak${NC}          清除flatpak缓存 ${CYAN}(可组合: -Cf)${NC}"
    echo -e "        ${YELLOW}-l, --all${NC}              清除所有缓存 ${CYAN}(默认, 可组合: -Cl)${NC}"
    echo ""
    echo -e "    ${YELLOW}-h, --help${NC}             显示此帮助信息"
    echo -e "    ${YELLOW}-v, --version${NC}          显示版本信息"
    echo -e "    ${YELLOW}--noconfirm${NC}            跳过所有确认提示，直接执行"
    echo -e "    ${YELLOW}--confirm${NC}              需要确认提示（默认行为）"
    echo -e "    ${YELLOW}--first-use${NC}            安装必要依赖并配置源（首次使用）"
    echo -e "    ${YELLOW}--history${NC} [N]          查看最近 N 次操作记录（默认10）"
    echo -e "    ${YELLOW}--self-update${NC} [通道]   检查并更新 Yay+ 自身"
    echo -e "                                 通道: ${CYAN}release${NC}(默认)/beta/dev"
    echo ""
    echo -e "${CYAN}示例:${NC}"
    echo -e "    ${YELLOW}yay-plus -Sp${NC} firefox chromium      ${GREEN}# 从官方仓库安装${NC} (组合形式)"
    echo -e "    ${YELLOW}yay-plus -Sa${NC} yay                   ${GREEN}# 从AUR安装${NC} (组合形式)"
    echo -e "    ${YELLOW}yay-plus -R -p${NC} firefox chromium    ${RED}# 卸载pacman包${NC}"
    echo -e "    ${YELLOW}yay-plus -Qa${NC} pkg1 pkg2             ${BLUE}# 查询AUR包信息${NC} (组合形式)"
    echo -e "    ${YELLOW}yay-plus -Q --aur-search${NC} yay       ${BLUE}# AUR精确搜索${NC}"
    echo -e "    ${YELLOW}yay-plus -Ua${NC}                       ${GREEN}# 更新所有AUR包${NC} (组合形式)"
    echo -e "    ${YELLOW}yay-plus -Ua --aur-refresh${NC}         ${GREEN}# 强制刷新缓存后更新AUR包${NC}"
    echo -e "    ${YELLOW}yay-plus -L${NC} /path/to/pkg.tar.zst   ${GREEN}# 安装本地包文件${NC}"
    echo -e "    ${YELLOW}yay-plus -Ca${NC}                       ${RED}# 仅清除AUR缓存${NC} (组合形式)"
    echo -e "    ${YELLOW}yay-plus --self-update${NC}             ${GREEN}# 检查Yay+自身更新${NC}"
    echo -e "    ${YELLOW}yay-plus --self-update beta${NC}        ${GREEN}# 检查beta通道更新${NC}"
    exit 0
}

# ---------------------------------------------------------------------------
# show_version — 输出版本号并退出
# ---------------------------------------------------------------------------
show_version() {
    echo $YAY_PLUS_VERSION
    exit 0
}

# ---------------------------------------------------------------------------
# parse_args — 解析命令行参数并分发到对应处理函数
#   支持的操作模式: -S(安装) / -R(卸载) / -Q(查询) / -U(更新) / -L(本地安装) / -C(清理)
#   子选项: -p/--pacman -a/--aur -f/--flatpak --auto -o/--online -l/--local --all
#   返回值: 0(已处理并退出) / 1(未匹配任何操作，由 main 显示帮助)
# ---------------------------------------------------------------------------
parse_args() {
    local install_mode=""
    local remove_mode=""
    local query_mode=""
    local query_scope=""
    local update_mode=""
    local clean_mode=""
    local local_install_path=""
    local package_names=()
    local query_type=""

    log "命令行参数: $*"
    while [[ $# -gt 0 ]]; do
        case $1 in
            -S*|--install)
                install_mode="generic"
                # 组合短选项: 支持 -Sp/-Sa/-Sf/-Su，多字母取最后一个
                local _combined="${1#-S}"
                shift
                if [ -n "$_combined" ]; then
                    local _i _ch
                    for ((_i=0; _i<${#_combined}; _i++)); do
                        _ch="${_combined:_i:1}"
                        case "$_ch" in
                            p) install_mode="pacman" ;;
                            a) install_mode="aur" ;;
                            f) install_mode="flatpak" ;;
                            u) install_mode="auto" ;;
                            *) print_color "$RED" "未知的子选项: -S$_ch (来自 -S$_combined)"; exit 1 ;;
                        esac
                    done
                fi
                # 收集所有非选项参数作为包名
                while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
                    package_names+=("$1")
                    shift
                done
                continue
                ;;
            -R*|--remove)
                remove_mode="generic"
                # 组合短选项: -R + 子选项字母，多字母取最后一个
                local _combined="${1#-R}"
                shift
                if [ -n "$_combined" ]; then
                    local _i _ch
                    for ((_i=0; _i<${#_combined}; _i++)); do
                        _ch="${_combined:_i:1}"
                        case "$_ch" in
                            p) remove_mode="pacman" ;;
                            f) remove_mode="flatpak" ;;
                            *) print_color "$RED" "未知的子选项: -R$_ch (来自 -R$_combined)"; exit 1 ;;
                        esac
                    done
                fi
                # 收集所有非选项参数作为包名
                while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
                    package_names+=("$1")
                    shift
                done
                continue
                ;;
            -Q*|--query)
                query_mode="true"
                # 组合短选项: 支持 -Qpo/-Qfo 等多字母（p/a/f 设查询源，o/l 设范围）
                # 例: -Qfo = 查询 flatpak + online 范围
                local _combined="${1#-Q}"
                shift
                if [ -n "$_combined" ]; then
                    local _i _ch
                    for ((_i=0; _i<${#_combined}; _i++)); do
                        _ch="${_combined:_i:1}"
                        case "$_ch" in
                            p) query_type="pacman" ;;
                            a) query_type="aur" ;;
                            f) query_type="flatpak" ;;
                            o) query_scope="online" ;;
                            l) query_scope="local" ;;
                            *) print_color "$RED" "未知的子选项: -Q$_ch (来自 -Q$_combined)"; exit 1 ;;
                        esac
                    done
                fi
                # 收集所有非选项参数作为包名
                while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
                    package_names+=("$1")
                    shift
                done
                continue
                ;;
            -U*|--update)
                update_mode="generic"
                # 组合短选项: -U + 子选项字母，多字母取最后一个
                local _combined="${1#-U}"
                shift
                if [ -n "$_combined" ]; then
                    local _i _ch
                    for ((_i=0; _i<${#_combined}; _i++)); do
                        _ch="${_combined:_i:1}"
                        case "$_ch" in
                            p) update_mode="pacman" ;;
                            a) update_mode="aur" ;;
                            f) update_mode="flatpak" ;;
                            l) update_mode="all" ;;
                            *) print_color "$RED" "未知的子选项: -U$_ch (来自 -U$_combined)"; exit 1 ;;
                        esac
                    done
                fi
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
            -p|--pacman)
                if [ -n "$install_mode" ]; then
                    install_mode="pacman"
                elif [ -n "$remove_mode" ]; then
                    remove_mode="pacman"
                elif [ -n "$query_mode" ]; then
                    query_type="pacman"
                elif [ -n "$update_mode" ]; then
                    update_mode="pacman"
                elif [ -n "$clean_mode" ]; then
                    clean_mode="pacman"
                fi
               
                shift
                ;;
            -a|--aur)
                if [ -n "$install_mode" ]; then
                    install_mode="aur"
                elif [ -n "$query_mode" ]; then
                    query_type="aur"
                elif [ -n "$update_mode" ]; then
                    update_mode="aur"
                elif [ -n "$clean_mode" ]; then
                    clean_mode="aur"
                fi
               
                shift
                ;;
            -f|--flatpak)
                if [ -n "$install_mode" ]; then
                    install_mode="flatpak"
                elif [ -n "$remove_mode" ]; then
                    remove_mode="flatpak"
                elif [ -n "$query_mode" ]; then
                    query_type="flatpak"
                elif [ -n "$update_mode" ]; then
                    update_mode="flatpak"
                elif [ -n "$clean_mode" ]; then
                    clean_mode="flatpak"
                fi
               
                shift
                ;;
            -u|--auto)
                if [ -n "$install_mode" ]; then
                    install_mode="auto"
                fi
               
                shift
                ;;
            --noconfirm)
                NOCONFIRM="true"
                shift
                ;;
            --confirm)
                NOCONFIRM="false"
                shift
                ;;
            --aur-refresh)
                FORCE_AUR_REFRESH="true"
                shift
                ;;
            --first-use)
                first_use
                exit 0
                ;;
            --aur-search)
                if [ -n "$query_mode" ]; then
                    query_type="aur-search"
                fi
                shift
                ;;
            --history)
                shift
                local _hist_n="${1:-10}"
                if [[ "$_hist_n" =~ ^[0-9]+$ ]]; then
                    shift 2>/dev/null || true
                else
                    _hist_n="10"
                fi
                show_history "$_hist_n"
                exit 0
                ;;
            --self-update)
                shift
                local _su_channel="${1:-}"
                if [[ "$_su_channel" =~ ^(release|beta|dev)$ ]]; then
                    shift
                else
                    _su_channel=""
                fi
                self_update "$_su_channel"
                exit 0
                ;;
            -o|--online)
                if [ -n "$query_mode" ]; then
                    query_scope="online"
                fi
               
                shift
                ;;
            -l|--local)
                if [ -n "$query_mode" ]; then
                    query_scope="local"
                fi
               
                shift
                ;;
            --all)
                if [ -n "$update_mode" ]; then
                    update_mode="all"
                elif [ -n "$clean_mode" ]; then
                    clean_mode="all"
                fi
               
                shift
                ;;
            -C*|--clean)
                clean_mode="all"
                # 组合短选项: -C + 子选项字母，多字母取最后一个
                local _combined="${1#-C}"
                shift
                if [ -n "$_combined" ]; then
                    local _i _ch
                    for ((_i=0; _i<${#_combined}; _i++)); do
                        _ch="${_combined:_i:1}"
                        case "$_ch" in
                            p) clean_mode="pacman" ;;
                            a) clean_mode="aur" ;;
                            f) clean_mode="flatpak" ;;
                            l) clean_mode="all" ;;
                            *) print_color "$RED" "未知的子选项: -C$_ch (来自 -C$_combined)"; exit 1 ;;
                        esac
                    done
                fi
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
                if [[ ! $1 =~ ^- ]]; then
                    package_names+=("$1")
                    shift
                else
                    print_color "$RED" "未知参数: $1"
                    exit 1
                fi
                ;;
        esac
    done
    log "解析结果: install_mode=$install_mode, remove_mode=$remove_mode, query_mode=$query_mode, update_mode=$update_mode, clean_mode=$clean_mode, local_install_path=$local_install_path, package_names=(${package_names[*]})"

    if [ -n "$local_install_path" ]; then
        local_install "$local_install_path"
        exit 0
    elif [ -n "$install_mode" ]; then
        if [ ${#package_names[@]} -eq 0 ]; then
            print_color "$RED" "错误: 安装操作需要指定包名"
            exit 1
        fi
        case $install_mode in
            pacman) install_via_pacman_multi "${package_names[@]}" ;;
            aur)
                for pkg in "${package_names[@]}"; do
                    install_via_aur "$pkg"
                done
                ;;
            flatpak) install_via_flatpak_multi "${package_names[@]}" ;;
            auto) install_auto_multi "${package_names[@]}" ;;
            generic) install_auto_multi "${package_names[@]}" ;;
        esac
        exit 0
    elif [ -n "$remove_mode" ]; then
        if [ ${#package_names[@]} -eq 0 ]; then
            print_color "$RED" "错误: 卸载操作需要指定包名"
            exit 1
        fi
        case $remove_mode in
            pacman)
                remove_via_pacman_multi "${package_names[@]}"
                ;;
            flatpak)
                remove_via_flatpak_multi "${package_names[@]}"
                ;;
            generic)
                # 自动检测卸载源：先查 pacman 本地包，再查 flatpak
                local _pkg_found=false
                for _pkg in "${package_names[@]}"; do
                    if pacman -Q "$_pkg" >/dev/null 2>&1; then
                        print_color "$CYAN" "从 pacman 卸载: $_pkg"
                        remove_via_pacman "$_pkg"
                        _pkg_found=true
                    elif flatpak list 2>/dev/null | grep -qi "^$_pkg"; then
                        print_color "$CYAN" "从 flatpak 卸载: $_pkg"
                        remove_via_flatpak "$_pkg"
                        _pkg_found=true
                    else
                        print_color "$RED" "未找到已安装的包: $_pkg"
                    fi
                done
                if [ "$_pkg_found" = false ]; then
                    print_color "$RED" "错误: 未找到任何可卸载的包"
                    exit 1
                fi
                ;;
        esac
        exit 0
    elif [ -n "$query_mode" ]; then
        if [ ${#package_names[@]} -eq 0 ]; then
            print_color "$RED" "错误: 查询操作需要指定包名"
            exit 1
        fi
        for pkg in "${package_names[@]}"; do
            if [ -z "$query_scope" ] && [ -z "$query_type" ]; then
                query_online_all "$pkg"
                query_local_all "$pkg"
            elif [ -n "$query_type" ] && [ -z "$query_scope" ]; then
                # 指定了查询源但未指定范围，同时查云端+本地
                case "$query_type" in
                    pacman) query_online_pacman "$pkg"; query_local_pacman "$pkg" ;;
                    aur) query_online_aur "$pkg"; query_local_aur "$pkg" ;;
                    aur-search) query_online_aur_search "$pkg" ;;
                    flatpak) query_online_flatpak "$pkg"; query_local_flatpak "$pkg" ;;
                esac
            elif [ -n "$query_scope" ]; then
                case "$query_scope" in
                    online)
                        case "$query_type" in
                            pacman) query_online_pacman "$pkg" ;;
                            aur) query_online_aur "$pkg" ;;
                            aur-search) query_online_aur_search "$pkg" ;;
                            flatpak) query_online_flatpak "$pkg" ;;
                            *) query_online_all "$pkg" ;;
                        esac
                        ;;
                    local)
                        case "$query_type" in
                            pacman) query_local_pacman "$pkg" ;;
                            aur) query_local_aur "$pkg" ;;
                            flatpak) query_local_flatpak "$pkg" ;;
                            *) query_local_all "$pkg" ;;
                        esac
                        ;;
                esac
            fi
        done
        exit 0
    elif [ -n "$update_mode" ]; then
        case $update_mode in
            pacman) update_pacman_packages ;;
            aur) update_aur_packages ;;
            flatpak) update_flatpak_packages ;;
            all) update_all_packages ;;
            generic) update_all_packages ;;
        esac
        exit 0
    elif [ -n "$clean_mode" ]; then
        case $clean_mode in
            pacman) clean_pacman ;;
            aur) clean_aur ;;
            flatpak) clean_flatpak ;;
            all) clean_all ;;
        esac
        exit 0
    fi
    return 1
}

# ---------------------------------------------------------------------------
# local_install — 本地安装入口，根据路径类型分发
#   目录 → local_install_aur  文件 → 按扩展名分发
# ---------------------------------------------------------------------------
local_install() {
    local path="$1"
    if [ ! -e "$path" ]; then
        print_color "$RED" "错误: 路径不存在: $path"
        exit 1
    fi
    log "本地安装: $path"
    if [ -d "$path" ]; then
        local_install_aur "$path"
    elif [ -f "$path" ]; then
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

# ---------------------------------------------------------------------------
# local_install_aur — 本地构建安装 AUR 包目录（含 PKGBUILD）
# ---------------------------------------------------------------------------
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
    local pkgname pkgver pkgrel
    source PKGBUILD >/dev/null 2>&1
    if [ -z "$pkgname" ]; then
        print_color "$RED" "错误: 无法从PKGBUILD解析包信息"
        exit 1
    fi
    print_color "$BLUE" ":: 即将安装的AUR包"
    print_color "$GREEN" "AUR/$pkgname $pkgver-$pkgrel (本地构建)"
    echo ""
    if ! confirm_action ":: 是否安装？[Y/n] "; then
            print_color "$YELLOW" "安装已取消"
            exit 0
    fi
    process_dependencies "$pkgname"
    set_ghproxy
    set_proxy
    print_color "$CYAN" "开始构建包..."
    if makepkg -si --skippgpcheck --noconfirm; then
        print_color "$GREEN" "AUR包安装成功: $pkgname"
    else
        print_color "$RED" "AUR包安装失败: $pkgname"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# local_install_package_file — 本地安装 .pkg.tar.zst/.xz/.gz 包文件
# ---------------------------------------------------------------------------
local_install_package_file() {
    local file_path="$1"
    log "本地安装包文件: $file_path"
    print_color "$CYAN" "检测到包文件，开始安装..."
    print_color "$BLUE" ":: 即将安装的包文件"
    print_color "$GREEN" "文件: $(basename "$file_path")"
    echo ""
    if ! confirm_action ":: 是否安装？[Y/n] "; then
            print_color "$YELLOW" "安装已取消"
            exit 0
    fi
    if sudo pacman -U --noconfirm "$file_path"; then
        print_color "$GREEN" "包文件安装成功: $(basename "$file_path")"
    else
        print_color "$RED" "包文件安装失败: $(basename "$file_path")"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# local_install_flatpakref — 本地安装 .flatpakref 引用文件
# ---------------------------------------------------------------------------
local_install_flatpakref() {
    local file_path="$1"
    log "本地安装Flatpak引用文件: $file_path"
    print_color "$CYAN" "检测到Flatpak引用文件，开始安装..."
    print_color "$BLUE" ":: 即将安装的Flatpak应用"
    print_color "$GREEN" "引用文件: $(basename "$file_path")"
    echo ""
    if ! confirm_action ":: 是否安装？[Y/n] "; then
            print_color "$YELLOW" "安装已取消"
            exit 0
    fi
    if flatpak install -y "$file_path"; then
        print_color "$GREEN" "Flatpak应用安装成功: $(basename "$file_path")"
    else
        print_color "$RED" "Flatpak应用安装失败: $(basename "$file_path")"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# install_via_pacman — 从官方仓库安装单个包（有确认交互）
#   参数: $1=包名
#   返回: 0(成功/取消) / 1(包不在官方仓库)
# ---------------------------------------------------------------------------
install_via_pacman() {
    local package="$1"
    log "命令行安装pacman包: $package"
    local package_info
    package_info=$(pacman -Si "$package" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo ":: 即将安装的Pacman包"
        local repo=$(echo "$package_info" | grep "^Repository" | cut -d: -f2 | tr -d ' ')
        local name=$(echo "$package_info" | grep "^Name" | cut -d: -f2 | tr -d ' ')
        local version=$(echo "$package_info" | grep "^Version" | cut -d: -f2 | tr -d ' ')
        echo "$repo/$name $version"
        echo ""
        if ! confirm_action ":: 是否安装？[Y/n] "; then
                print_color "$YELLOW" "安装已取消"
                return 0
        fi
        sudo pacman -S --noconfirm "$package"
    else
        print_color "$RED" "无法找到包 $package 的信息"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# install_via_aur — 从 AUR 克隆并构建安装单个包（有确认交互）
#   参数: $1=包名
#   流程: AUR search 检查存在性 → 克隆 → 处理依赖 → makepkg
#   返回: 0(成功/取消) / 1(包不存在或安装失败)
# ---------------------------------------------------------------------------
install_via_aur() {
    local package="$1"
    log "命令行安装AUR包: $package"

    # 首先通过AUR RPC搜索确认包是否存在
    if ! search_aur_package "$package"; then
        print_color "$RED" "AUR中未找到包: $package"
        return 1
    fi

    local package_info
    package_info=$(get_aur_package_info "$package")
    local actual_package=$(echo "$package_info" | cut -d'|' -f1)
    local actual_repo=$(echo "$package_info" | cut -d'|' -f2)
    # 防御 AUR 限速导致 info 返回空，回退到原始包名
    [ -z "$actual_package" ] && actual_package="$package"
    [ -z "$actual_repo" ] && actual_repo="$package"
    log "安装AUR包: 请求包=$package, 实际包=$actual_package, 仓库=$actual_repo"
    if ! clone_aur_package "$package" "$actual_repo"; then
        return 1
    fi
    cd "$actual_repo" || return 1
    if [ ! -f "PKGBUILD" ]; then
        log "PKGBUILD不存在: $actual_repo" "ERROR"
        print_color "$RED" "PKGBUILD不存在，可能不是有效的AUR包"
        return 1
    fi
    process_dependencies "$actual_package"
    local pkgname pkgver pkgrel
    source PKGBUILD >/dev/null 2>&1
    echo ":: 即将安装的AUR包"
    echo "AUR/$pkgname $pkgver-$pkgrel"
    echo ""
    if ! confirm_action ":: 是否安装？[Y/n] "; then
            print_color "$YELLOW" "安装已取消"
            return 0
    fi
    set_ghproxy
    set_proxy
    makepkg -si --skippgpcheck --noconfirm
    return 0
}

# ---------------------------------------------------------------------------
# install_via_flatpak — 从 Flathub 安装单个 flatpak 包
# ---------------------------------------------------------------------------
install_via_flatpak() {
    local package="$1"
    log "命令行安装flatpak包: $package"
    flatpak install -y flathub "$package"
}

# ---------------------------------------------------------------------------
# install_auto — 单包自动安装（pacman → AUR → flatpak 依次尝试）
# ---------------------------------------------------------------------------
install_auto() {
    local package="$1"
    log "命令行自动安装: $package"
    print_color "$CYAN" "尝试通过 pacman 安装: $package"
    if ! install_via_pacman "$package"; then
        print_color "$YELLOW" "通过 pacman 安装失败，尝试通过 AUR 安装: $package"
        if ! install_via_aur "$package"; then
            print_color "$YELLOW" "通过 AUR 安装失败，尝试通过 flatpak 安装: $package"
            if ! install_via_flatpak "$package"; then
                print_color "$RED" "通过 flatpak 安装失败，请手动安装: $package"
                exit 1
            fi
        fi
    fi
}

# ---------------------------------------------------------------------------
# install_via_pacman_multi — 批量从官方仓库安装（一次性确认）
# ---------------------------------------------------------------------------
install_via_pacman_multi() {
    local packages=("$@")
    log "命令行批量安装pacman包: ${packages[*]}"
    print_color "$BLUE" ":: 即将安装的Pacman包"
    for pkg in "${packages[@]}"; do
        local package_info
        package_info=$(pacman -Si "$pkg" 2>/dev/null)
        if [ $? -eq 0 ]; then
            local repo=$(echo "$package_info" | grep "^Repository" | cut -d: -f2 | tr -d ' ')
            local name=$(echo "$package_info" | grep "^Name" | cut -d: -f2 | tr -d ' ')
            local version=$(echo "$package_info" | grep "^Version" | cut -d: -f2 | tr -d ' ')
            echo "$repo/$name $version"
        else
            print_color "$RED" "无法找到包 $pkg 的信息"
        fi
    done
    echo ""
    if ! confirm_action ":: 是否安装？[Y/n] "; then
            print_color "$YELLOW" "安装已取消"
            exit 0
    fi
    sudo pacman -S --noconfirm "${packages[@]}"
}

# ---------------------------------------------------------------------------
# install_via_flatpak_multi — 批量从 Flathub 安装（一次性确认）
# ---------------------------------------------------------------------------
install_via_flatpak_multi() {
    local packages=("$@")
    log "命令行批量安装flatpak包: ${packages[*]}"
    print_color "$BLUE" ":: 即将安装的Flatpak应用"
    echo "${packages[@]}"
    echo ""
    if ! confirm_action ":: 是否安装？[Y/n] "; then
            print_color "$YELLOW" "安装已取消"
            exit 0
    fi
    for pkg in "${packages[@]}"; do
        flatpak install -y flathub "$pkg"
    done
}

# ---------------------------------------------------------------------------
# install_auto_multi — 批量自动安装（核心函数）
#   流程:
#     1. 扫描所有包，区分官方仓库 / 非官方
#     2. 对官方仓库包 → 一次性确认后安装
#     3. 对剩余包 → 逐个：
#        a. search_aur_package 检查 AUR 存在性
#        b. 存在 → install_via_aur（含确认交互）
#        c. 不存在 → flatpak search + flatpak install
#        d. 都没有 → 报错退出
# ---------------------------------------------------------------------------
install_auto_multi() {
    local packages=("$@")
    log "命令行自动批量安装: ${packages[*]}"
    # 首先尝试通过pacman安装所有包
    local pacman_packages=()
    local remaining_packages=()
    
    print_color "$CYAN" "扫描各源中的包："
    for pkg in "${packages[@]}"; do
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            pacman_packages+=("$pkg")
            print_color "$GREEN" "  ✓ $pkg (官方仓库)"
        else
            remaining_packages+=("$pkg")
            print_color "$YELLOW" "  - $pkg (不在官方仓库)"
        fi
    done
    
    if [ ${#pacman_packages[@]} -gt 0 ]; then
        echo ""
        print_color "$BLUE" ":: 通过pacman安装的包"
        echo "${pacman_packages[*]}"
        echo ""
        if ! confirm_action ":: 是否安装？[Y/n] "; then
                print_color "$YELLOW" "安装已取消"
        else
            sudo pacman -S --noconfirm "${pacman_packages[@]}"
        fi
    fi
    
    # 尝试通过AUR安装剩余的包，AUR中找不到则尝试flatpak
    if [ ${#remaining_packages[@]} -gt 0 ]; then
        for pkg in "${remaining_packages[@]}"; do
            # 先通过AUR RPC搜索确认包是否存在
            if search_aur_package "$pkg"; then
                print_color "$CYAN" "尝试通过AUR安装: $pkg"
                if ! install_via_aur "$pkg"; then
                    print_color "$RED" "AUR安装失败: $pkg"
                fi
            else
                print_color "$YELLOW" "AUR中未找到包: $pkg，尝试通过flatpak安装"
                if flatpak search "$pkg" 2>/dev/null | grep -qi "^$pkg[[:space:]]"; then
                    print_color "$CYAN" "通过flatpak安装: $pkg"
                    if ! flatpak install -y flathub "$pkg"; then
                        print_color "$RED" "flatpak安装失败: $pkg"
                    fi
                else
                    print_color "$RED" "错误: 包 '$pkg' 在 pacman/AUR/flatpak 中均未找到"
                    exit 1
                fi
            fi
        done
    fi
}

# ==================== 卸载函数 ====================

# ---------------------------------------------------------------------------
# remove_via_pacman — 通过 pacman 卸载单个包（含依赖）
# ---------------------------------------------------------------------------
remove_via_pacman() {
    local package="$1"
    log "命令行卸载pacman包: $package"
    sudo pacman -Rsn --noconfirm "$package"
}

# ---------------------------------------------------------------------------
# remove_via_flatpak — 通过 flatpak 卸载单个包
# ---------------------------------------------------------------------------
remove_via_flatpak() {
    local package="$1"
    log "命令行卸载flatpak包: $package"
    flatpak uninstall -y "$package"
}

# ---------------------------------------------------------------------------
# remove_via_pacman_multi — 批量卸载 pacman 包（一次性确认）
# ---------------------------------------------------------------------------
remove_via_pacman_multi() {
    local packages=("$@")
    log "命令行批量卸载pacman包: ${packages[*]}"
    print_color "$BLUE" ":: 即将卸载的Pacman包"
    echo "${packages[*]}"
    echo ""
    if ! confirm_action ":: 是否卸载？[Y/n] "; then
            print_color "$YELLOW" "卸载已取消"
            exit 0
    fi
    sudo pacman -Rsn --noconfirm "${packages[@]}"
}

# ---------------------------------------------------------------------------
# remove_via_flatpak_multi — 批量卸载 flatpak 包（一次性确认）
# ---------------------------------------------------------------------------
remove_via_flatpak_multi() {
    local packages=("$@")
    log "命令行批量卸载flatpak包: ${packages[*]}"
    print_color "$BLUE" ":: 即将卸载的Flatpak应用"
    echo "${packages[*]}"
    echo ""
    if ! confirm_action ":: 是否卸载？[Y/n] "; then
            print_color "$YELLOW" "卸载已取消"
            exit 0
    fi
    for pkg in "${packages[@]}"; do
        flatpak uninstall -y "$pkg"
    done
}

# ==================== 查询函数 ====================

# ---------------------------------------------------------------------------
# query_online_pacman — 搜索官方仓库中的包
# ---------------------------------------------------------------------------
query_online_pacman() {
    local package="$1"
    log "命令行查询云端pacman包: $package"
    if [ -z "$package" ]; then
        pacman -Sl
    else
        pacman -Ss "$package"
    fi
}

# ---------------------------------------------------------------------------
# query_online_aur — 通过 AUR RPC suggest 端点模糊搜索 AUR 包（仅包名）
#   使用 suggest 以支持模糊匹配和包名补全
# ---------------------------------------------------------------------------
query_online_aur() {
    local package="$1"
    log "命令行查询云端AUR包: $package"
    if [ -z "$package" ]; then
        print_color "$YELLOW" "需要指定包名来查询AUR包"
        return 1
    fi
    local suggest_result
    suggest_result=$(curl -s "$AUR_RPC_URL/suggest/$package")
    log "AUR suggest结果: $suggest_result" "INFO" "nostdout"
    if [ -z "$suggest_result" ] || [ "$suggest_result" = "[]" ]; then
        print_color "$YELLOW" "AUR仓库中未找到相关软件包"
    else
        echo "$suggest_result" | jq -r '.[]' | while read -r pkg_name; do
            echo "aur/$pkg_name"
        done
        echo ""
    fi
}

# ---------------------------------------------------------------------------
# query_online_aur_search — 通过 AUR RPC search 端点精确搜索（含描述）
#   使用 /rpc/v5/search/<arg>?by=name-desc，返回 Name/Version/Description
# ---------------------------------------------------------------------------
query_online_aur_search() {
    local package="$1"
    log "命令行AUR精确搜索: $package"
    if [ -z "$package" ]; then
        print_color "$YELLOW" "需要指定包名来搜索AUR包"
        return 1
    fi
    local search_result
    search_result=$(curl -s "$AUR_RPC_URL/search/$package?by=name-desc")
    log "AUR search结果: $search_result" "INFO" "nostdout"
    if echo "$search_result" | jq -e '.resultcount > 0' >/dev/null 2>&1; then
        echo "$search_result" | jq -r '.results[] | "\(.Name) \(.Version)\n    \(.Description)\n"'
    else
        print_color "$YELLOW" "AUR仓库中未找到相关软件包"
    fi
}

# ---------------------------------------------------------------------------
# query_online_flatpak — 搜索 Flathub 中的 flatpak 包
# ---------------------------------------------------------------------------
query_online_flatpak() {
    local package="$1"
    log "命令行查询云端flatpak包: $package"
    if [ -z "$package" ]; then
        flatpak remote-ls flathub
    else
        flatpak search "$package"
    fi
}

# ---------------------------------------------------------------------------
# query_local_pacman — 查询本地已安装的 pacman 包
# ---------------------------------------------------------------------------
query_local_pacman() {
    local package="$1"
    log "命令行查询本地pacman包: $package"
    if [ -z "$package" ]; then
        pacman -Q
    else
        pacman -Qi "$package" || pacman -Qs "$package"
    fi
}

# ---------------------------------------------------------------------------
# query_local_aur — 查询本地已安装的 AUR 包（通过 pacman -Qm）
# ---------------------------------------------------------------------------
query_local_aur() {
    local package="$1"
    log "命令行查询本地AUR包: $package"
    if [ -z "$package" ]; then
        pacman -Qm
    else
        pacman -Qi "$package" 2>/dev/null || pacman -Qm | grep "$package"
    fi
}

# ---------------------------------------------------------------------------
# query_local_flatpak — 查询本地已安装的 flatpak 包
# ---------------------------------------------------------------------------
query_local_flatpak() {
    local package="$1"
    log "命令行查询本地flatpak包: $package"
    if [ -z "$package" ]; then
        flatpak list
    else
        flatpak info "$package" 2>/dev/null || flatpak list | grep "$package"
    fi
}

# ---------------------------------------------------------------------------
# query_online_all — 统一查询所有云端源（pacman + AUR + flatpak）
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# query_local_all — 统一查询所有本地源（pacman + AUR + flatpak）
# ---------------------------------------------------------------------------
query_local_all() {
    local package="$1"
    log "命令行查询所有本地包: $package"
    if [ -z "$package" ]; then
        print_color "$CYAN" "=== 官方仓库包 ==="
        pacman -Qn
        echo ""
        print_color "$CYAN" "=== AUR包 ==="
        pacman -Qm
        echo ""
        print_color "$CYAN" "=== Flatpak包 ==="
        flatpak list
    else
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

# ==================== 更新函数 ====================

# ---------------------------------------------------------------------------
# update_all_packages — 依次更新 pacman → AUR → flatpak
# ---------------------------------------------------------------------------
update_all_packages() {
    log "命令行更新所有软件包"
    print_color "$CYAN" "更新所有软件包 (pacman + AUR + flatpak)"
    update_pacman_packages
    update_aur_packages
    update_flatpak_packages
    print_color "$GREEN" "所有软件包更新完成"
}

# ---------------------------------------------------------------------------
# update_pacman_packages — 同步数据库并升级所有官方包
# ---------------------------------------------------------------------------
update_pacman_packages() {
    print_color "$CYAN" "正在更新 pacman 软件包..."
    sudo pacman -Syyy
    sudo pacman -Su --noconfirm
}

# ---------------------------------------------------------------------------
# is_aur_cache_fresh — 检查 AUR 版本缓存是否在有效期内
#   返回: 0(缓存有效) / 1(缓存不存在或已过期)
#   使用 DEFAULT_AUR_CACHE_TTL 作为有效期（分钟）；0=每次都过期
# ---------------------------------------------------------------------------
is_aur_cache_fresh() {
    if [ "$DEFAULT_AUR_CACHE_TTL" = "0" ]; then
        return 1
    fi
    if [ ! -f "$AUR_CACHE_FILE" ]; then
        return 1
    fi
    local cache_time
    cache_time=$(head -1 "$AUR_CACHE_FILE" | sed 's/^# Last refresh: //')
    if [ -z "$cache_time" ]; then
        return 1
    fi
    local now elapsed
    now=$(date +%s)
    elapsed=$(( (now - cache_time) / 60 ))
    if [ "$elapsed" -lt "$DEFAULT_AUR_CACHE_TTL" ]; then
        log "AUR缓存有效 (${elapsed}分钟前, TTL=${DEFAULT_AUR_CACHE_TTL}分钟)"
        return 0
    fi
    log "AUR缓存已过期 (${elapsed}分钟前, TTL=${DEFAULT_AUR_CACHE_TTL}分钟)"
    return 1
}

# ---------------------------------------------------------------------------
# refresh_aur_cache — 批量刷新 AUR 包版本缓存
#   一次性从 AUR RPC info 端点拉取所有已安装 AUR 包的版本信息
#   每次请求最多 100 个包（AUR RPC 建议上限），自动分批
#   缓存格式:
#     # Last refresh: <epoch_timestamp>
#     pkgname1|version1
#     pkgname2|version2
#   无参数，无返回值
#   副作用: 写入 $AUR_CACHE_FILE
# ---------------------------------------------------------------------------
refresh_aur_cache() {
    print_color "$CYAN" "正在刷新 AUR 包版本缓存..."
    local aur_packages
    aur_packages=$(pacman -Qmq 2>/dev/null | sort -u)
    if [ -z "$aur_packages" ]; then
        echo "# Last refresh: $(date +%s)" > "$AUR_CACHE_FILE"
        print_color "$GREEN" "没有已安装的 AUR 包，缓存已清空"
        return 0
    fi

    # 按每批 100 个包分组请求
    local cache_content="# Last refresh: $(date +%s)"

    # 收集所有包名到数组
    local all_pkgs=()
    while IFS= read -r p; do
        all_pkgs+=("$p")
    done <<< "$aur_packages"

    local total=${#all_pkgs[@]}
    local idx=0

    while [ "$idx" -lt "$total" ]; do
        # 构造当前批次的 arg[] 参数
        local arg_params=""
        local batch_end=$(( idx + 100 ))
        if [ "$batch_end" -gt "$total" ]; then
            batch_end="$total"
        fi
        local j
        for ((j=idx; j<batch_end; j++)); do
            arg_params="${arg_params}&arg[]=${all_pkgs[j]}"
        done

        # 调用 AUR RPC info（多包查询）
        local aur_json
        aur_json=$(curl -s "$AUR_RPC_URL/info?${arg_params#&}")
        log "批量AUR查询 (${idx}-$((batch_end-1))): 返回 $(echo "$aur_json" | jq '.resultcount') 条"

        # 解析每个结果的 Name + Version
        local results
        results=$(echo "$aur_json" | jq -r '.results[]? | "\(.Name)|\(.Version)"' 2>/dev/null)
        if [ -n "$results" ]; then
            while IFS= read -r line; do
                cache_content="$cache_content"$'\n'"$line"
            done <<< "$results"
        fi

        idx="$batch_end"
    done

    echo "$cache_content" > "$AUR_CACHE_FILE"
    # 重新计算实际处理的包数
    local cached_count
    cached_count=$(tail -n +2 "$AUR_CACHE_FILE" | wc -l)
    print_color "$GREEN" "AUR 缓存已刷新 (${cached_count} 个包)"
}

# ---------------------------------------------------------------------------
# get_cached_aur_version — 从缓存中读取指定包的 AUR 最新版本
#   参数: $1=包名
#   输出: 版本号（未找到时输出空字符串）
# ---------------------------------------------------------------------------
get_cached_aur_version() {
    local pkg="$1"
    grep "^$pkg|" "$AUR_CACHE_FILE" 2>/dev/null | head -1 | cut -d'|' -f2
}

# ---------------------------------------------------------------------------
# update_aur_packages — 检查并更新所有 AUR 包
#   流程: 检查缓存 → 刷新 → 对比版本 → PackageBase 去重 → 列出 → 构建
#   共享同一 PackageBase 的包（如 dotnet-*-bin 系列）只构建一次
# ---------------------------------------------------------------------------
update_aur_packages() {
    # 检查/刷新缓存
    if [ "$FORCE_AUR_REFRESH" = "true" ] || ! is_aur_cache_fresh; then
        refresh_aur_cache
    fi

    local aur_packages
    aur_packages=$(pacman -Qmq 2>/dev/null | sort -u)
    if [ -z "$aur_packages" ]; then
        print_color "$GREEN" "没有已安装的 AUR 包"
        return 0
    fi

    # 第一步：收集所有本地版本，同时找出缓存未命中的包
    local -A local_versions
    local -A cached_versions
    local -A pkg_to_pkgbase   # pkgname → PackageBase（去重用）
    local missing_pkgs=()

    while IFS= read -r pkg; do
        local ver
        ver=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}')
        [ -z "$ver" ] && continue
        local_versions["$pkg"]="$ver"

        local cv
        cv=$(get_cached_aur_version "$pkg")
        if [ -n "$cv" ]; then
            cached_versions["$pkg"]="$cv"
        else
            missing_pkgs+=("$pkg")
        fi
    done <<< "$aur_packages"

    # 第二步：对缓存未命中的包做补充批量查询，同时提取 PackageBase
    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        print_color "$CYAN" "正在补充查询 ${#missing_pkgs[@]} 个缓存未命中的包..."
        local miss_idx=0 miss_total=${#missing_pkgs[@]}
        while [ "$miss_idx" -lt "$miss_total" ]; do
            local miss_batch_end=$(( miss_idx + 100 ))
            [ "$miss_batch_end" -gt "$miss_total" ] && miss_batch_end="$miss_total"
            local miss_args=""
            local mj
            for ((mj=miss_idx; mj<miss_batch_end; mj++)); do
                miss_args="${miss_args}&arg[]=${missing_pkgs[mj]}"
            done
            local miss_json
            miss_json=$(curl -s "$AUR_RPC_URL/info?${miss_args#&}")
            # 提取 Name|Version|PackageBase，三字段便于后续去重
            local miss_results
            miss_results=$(echo "$miss_json" | jq -r '.results[]? | "\(.Name)|\(.Version)|\(.PackageBase)"' 2>/dev/null)
            if [ -n "$miss_results" ]; then
                while IFS= read -r line; do
                    local mn mv mp
                    mn=$(echo "$line" | cut -d'|' -f1)
                    mv=$(echo "$line" | cut -d'|' -f2)
                    mp=$(echo "$line" | cut -d'|' -f3)
                    if [ -n "$mn" ] && [ -n "$mv" ]; then
                        cached_versions["$mn"]="$mv"
                        # 记录 PackageBase（为空时回退到包名自身）
                        pkg_to_pkgbase["$mn"]="${mp:-$mn}"
                    fi
                done <<< "$miss_results"
            fi
            miss_idx="$miss_batch_end"
        done
    fi

    # 第三步：对比版本，生成更新包列表（尚未去重）
    local -a update_choices=()

    while IFS= read -r pkg; do
        local local_version="${local_versions[$pkg]}"
        [ -z "$local_version" ] && continue
        local latest_version="${cached_versions[$pkg]}"

        if [ -n "$latest_version" ] && [ "$local_version" != "$latest_version" ]; then
            update_choices+=("$pkg")
        fi
    done <<< "$aur_packages"

    if [ ${#update_choices[@]} -eq 0 ]; then
        print_color "$GREEN" "所有 AUR 包均已是最新版本"
        return 0
    fi

    # 第四步：按 PackageBase 去重，同一仓库只构建一次
    local -A base_to_pkgs       # PackageBase → "pkg1, pkg2, ..."
    local -A base_to_version    # PackageBase → "old → new"（取第一个包的版本）
    local -a unique_bases=()    # 有序的唯一 PackageBase 列表

    for pkg in "${update_choices[@]}"; do
        # 获取 PackageBase：优先使用第二步批量查询的结果，否则回退到包名
        local base="${pkg_to_pkgbase[$pkg]:-$pkg}"
        if [ -z "${base_to_pkgs[$base]}" ]; then
            unique_bases+=("$base")
            base_to_pkgs["$base"]="$pkg"
            base_to_version["$base"]="${local_versions[$pkg]} -> ${cached_versions[$pkg]}"
        else
            base_to_pkgs["$base"]="${base_to_pkgs[$base]}, $pkg"
        fi
    done

    # 第五步：显示去重后的更新列表（分组格式）
    local updates_list=""
    local idx=1
    for base in "${unique_bases[@]}"; do
        local pkgs="${base_to_pkgs[$base]}"
        local ver="${base_to_version[$base]}"
        if [ "$pkgs" = "$base" ]; then
            # 单包仓库：直接显示包名
            updates_list="$updates_list${idx}. $base $ver\n"
        else
            # 多包子仓库：显示仓库名及包含的子包
            updates_list="$updates_list${idx}. $base ($pkgs) $ver\n"
        fi
        idx=$((idx + 1))
    done

    echo ""
    print_color "$YELLOW" "发现以下 AUR 包可更新 (共 ${#update_choices[@]} 个子包，${#unique_bases[@]} 个仓库):"
    echo -e "$updates_list"

    if ! confirm_action "是否更新以上所有软件包？[Y/n]: "; then
        print_color "$YELLOW" "已取消更新"
        return 0
    fi

    print_color "$CYAN" "正在更新 ${#unique_bases[@]} 个仓库..."

    # 第六步：按唯一仓库构建（每个仓库只 build 一次）
    for base in "${unique_bases[@]}"; do
        local pkgs_in_base="${base_to_pkgs[$base]}"
        print_color "$CYAN" "正在更新 $base (包含: $pkgs_in_base)..."

        # 通过 AUR RPC 获取精确的仓库名（PackageBase 可能 ≠ 包名）
        local package_info_update
        package_info_update=$(get_aur_package_info "$base")
        local actual_package_update=$(echo "$package_info_update" | cut -d'|' -f1)
        local actual_repo_update=$(echo "$package_info_update" | cut -d'|' -f2)
        # 防御 AUR 限速导致 info 返回空
        [ -z "$actual_package_update" ] && actual_package_update="$base"
        [ -z "$actual_repo_update" ] && actual_repo_update="$base"

        if ! clone_aur_package "$base" "$actual_repo_update"; then
            print_color "$RED" "克隆 $base 失败，跳过"
            continue
        fi
        local _update_saved_dir="$PWD"
        cd "$PACKAGE_DIR/$actual_repo_update" || continue
        process_dependencies "$actual_package_update"
        set_ghproxy
        set_proxy
        if ! makepkg -si --skippgpcheck --noconfirm; then
            print_color "$RED" "更新 $base 失败"
        else
            print_color "$GREEN" "更新 $base 完成 (子包: $pkgs_in_base)"
        fi
        cd "$_update_saved_dir" || continue
    done

    print_color "$GREEN" "AUR 包更新完成"
}

# ---------------------------------------------------------------------------
# update_flatpak_packages — 更新所有 flatpak 包
# ---------------------------------------------------------------------------
update_flatpak_packages() {
    print_color "$CYAN" "正在更新 flatpak 软件包..."
    flatpak update -y
}


# ==================== 自更新 ====================

# ---------------------------------------------------------------------------
# self_update — 检查并更新 yay-plus 自身
#   参数: $1=通道名(可选, release/beta/dev, 默认取配置或 release)
#   流程:
#     1. 从 VERSION_JSON_URL 拉取版本信息
#     2. 解析指定通道的 version/filename
#     3. 空 version → 无更新
#     4. 与本地状态文件对比，相同 → 已是最新
#     5. 构造 GitHub 代理 URL 并下载
#     6. sudo pacman -U 安装
#     7. 更新本地状态文件
# ---------------------------------------------------------------------------
self_update() {
    local channel="${1:-$DEFAULT_SELF_UPDATE_CHANNEL}"
    channel="${channel:-release}"

    print_color "$CYAN" "正在检查 Yay+ 自身更新 (通道: $channel)..."

    # 拉取 version.json（主 URL + GitHub proxy 回退）
    local ver_json
    ver_json=$(curl -s --connect-timeout 8 "$VERSION_JSON_URL" 2>/dev/null)

    # 检测是否为有效 JSON（Cloudflare 挑战会返回 HTML）
    if [ -z "$ver_json" ] || echo "$ver_json" | grep -q '<\(!DOCTYPE\|html\)'; then
        log "主 URL 返回非 JSON，尝试 GitHub 代理回退" "WARN"
        # 构造 GitHub raw 回退 URL
        local fallback_url="https://raw.githubusercontent.com/Colin130716/yay-plus/master/version.json"
        local proxy_url="$fallback_url"
        case $DEFAULT_GITHUB_PROXY in
            1) proxy_url="https://github.akams.cn/${fallback_url}" ;;
            2) proxy_url="https://gh-proxy.com/${fallback_url}" ;;
            3) proxy_url="https://ghfile.geekertao.top/${fallback_url}" ;;
            4) proxy_url="https://gh.llkk.cc/${fallback_url}" ;;
        esac
        print_color "$YELLOW" "主版本源不可用，尝试代理: $proxy_url"
        ver_json=$(curl -s --connect-timeout 10 "$proxy_url" 2>/dev/null)
    fi

    # 最终校验
    if [ -z "$ver_json" ] || ! echo "$ver_json" | jq -e '.release' >/dev/null 2>&1; then
        print_color "$RED" "无法获取版本信息，请检查网络连接或稍后重试"
        return 1
    fi

    # 解析指定通道
    local remote_version remote_filename remote_date
    remote_version=$(echo "$ver_json" | jq -r ".${channel}.version // empty" 2>/dev/null)
    remote_filename=$(echo "$ver_json" | jq -r ".${channel}.filename // empty" 2>/dev/null)
    remote_date=$(echo "$ver_json" | jq -r ".${channel}.date // empty" 2>/dev/null)

    if [ -z "$remote_version" ] || [ "$remote_version" = "null" ]; then
        print_color "$GREEN" "当前 ($channel 通道) 暂无更新"
        return 0
    fi

    # 规范化版本号比较：去除 v 前缀和 -后缀，提取纯数字版本
    local local_ver="${YAY_PLUS_VERSION#v}"
    local remote_normalized="${remote_version#v}"
    remote_normalized="${remote_normalized%%-*}"

    if [ "$local_ver" = "$remote_normalized" ]; then
        print_color "$GREEN" "Yay+ 已是最新版本 ($YAY_PLUS_VERSION)"
        return 0
    fi

    # 检查本地状态：如果已记录此版本则跳过
    if [ -f "$SELF_UPDATE_STATE" ]; then
        local last_seen
        last_seen=$(grep "^${channel}=" "$SELF_UPDATE_STATE" 2>/dev/null | cut -d'=' -f2)
        if [ "$last_seen" = "$remote_version" ]; then
            print_color "$GREEN" "Yay+ 已是最新版本 ($remote_version)"
            return 0
        fi
    fi

    # 显示更新信息
    echo ""
    print_color "$YELLOW" "发现 Yay+ 新版本:"
    echo -e "  通道:   ${channel}"
    echo -e "  版本:   ${remote_version}"
    echo -e "  日期:   ${remote_date:-未知}"
    echo -e "  文件:   ${remote_filename}"
    echo ""

    if ! confirm_action "是否下载并安装此更新？[Y/n]: "; then
        print_color "$YELLOW" "已取消更新"
        # 记录已看到的版本（避免重复提示）
        mkdir -p "$(dirname "$SELF_UPDATE_STATE")"
        echo "${channel}=${remote_version}" > "$SELF_UPDATE_STATE"
        return 0
    fi

    # 构造下载 URL：<代理前缀>https://github.com/.../releases/<version>/download/<filename>
    local github_url="https://github.com/Colin130716/yay-plus/releases/download/${remote_version}/${remote_filename}"
    local download_url="$github_url"

    # 应用 GitHub 代理
    case $DEFAULT_GITHUB_PROXY in
        1) download_url="https://github.akams.cn/${github_url}" ;;
        2) download_url="https://gh-proxy.com/${github_url}" ;;
        3) download_url="https://ghfile.geekertao.top/${github_url}" ;;
        4) download_url="https://gh.llkk.cc/${github_url}" ;;
    esac

    print_color "$CYAN" "正在下载: $download_url"
    local tmp_pkg="/tmp/${remote_filename}"

    if ! curl -L -o "$tmp_pkg" "$download_url"; then
        # 代理失败时尝试直连
        print_color "$YELLOW" "代理下载失败，尝试直连..."
        if ! curl -L -o "$tmp_pkg" "$github_url"; then
            print_color "$RED" "下载失败，请检查网络连接"
            return 1
        fi
    fi

    print_color "$CYAN" "正在安装..."
    if sudo pacman -U --noconfirm "$tmp_pkg"; then
        print_color "$GREEN" "Yay+ 更新成功: $remote_version"
        # 记录已更新的版本
        mkdir -p "$(dirname "$SELF_UPDATE_STATE")"
        echo "${channel}=${remote_version}" > "$SELF_UPDATE_STATE"
        rm -f "$tmp_pkg"
        print_color "$YELLOW" "请重新启动脚本以使用新版本"
    else
        print_color "$RED" "安装失败，请手动安装: $tmp_pkg"
        return 1
    fi
}


# ==================== 代理与环境 ====================

# ---------------------------------------------------------------------------
# first_use — 首次使用时安装必要依赖并配置 flatpak 源
#   安装: base-devel, git, flatpak, npm, nodejs
#   可选: 替换 flathub 为中科大镜像
# ---------------------------------------------------------------------------
first_use() {
    log "首次使用，自动安装依赖"
    sudo pacman -S --noconfirm --needed base-devel git flatpak npm nodejs jq
    log "设置flatpak源"
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    read -rp "是否要更换flathub源为中科大源？（Y/n）: " use_mirror
    case $use_mirror in
        [nN]) return ;;
        *)
            log "更换flathub源为中科大源"
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
            wget -q https://mirror.sjtu.edu.cn/flathub/flathub.gpg
            sudo flatpak remote-modify flathub --gpg-import flathub.gpg
            rm -f flathub.gpg
            sudo flatpak remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub
            sudo flatpak update
            ;;
    esac
}

# ---------------------------------------------------------------------------
# set_proxy — 在构建前设置 NPM/kernel.org 代理
#   修改当前目录的 PKGBUILD（替换 kernel.org 链接）
#   设置 npm registry 镜像
#   必须在目标包目录中调用
# ---------------------------------------------------------------------------
set_proxy() {
    if [ "$DEFAULT_NPM_PROXY" = "true" ]; then
        log "设置NPM代理: https://registry.npmmirror.com"
        npm config set registry https://registry.npmmirror.com
        sudo npm config set registry https://registry.npmmirror.com
    fi
    if [ "$DEFAULT_KERNEL_ORG_PROXY" = "true" ]; then
        log "替换kernel.org镜像为中科大镜像"
        sed -i 's#https://www.kernel.org/pub/#https://mirrors.ustc.edu.cn/kernel.org/#g' PKGBUILD
        sed -i 's#https://cdn.kernel.org/pub/#https://mirrors.ustc.edu.cn/kernel.org/#g' PKGBUILD
    fi
}

# ---------------------------------------------------------------------------
# set_ghproxy — 替换当前目录 PKGBUILD 中的 GitHub 链接为代理地址
#   根据 DEFAULT_GITHUB_PROXY 选择代理，替换 github.com 和
#   raw.githubusercontent.com 的 URL
#   必须在目标包目录中调用（操作 ./PKGBUILD）
# ---------------------------------------------------------------------------
set_ghproxy() {
    if [ -n "$DEFAULT_GITHUB_PROXY" ]; then
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
}

# ==================== 清理函数 ====================

# ---------------------------------------------------------------------------
# clean_aur — 清除 AUR 相关缓存
#   删除: $LOG_DIR (日志) / $PACKAGE_DIR (包构建目录) / 配置备份文件
# ---------------------------------------------------------------------------
clean_aur() {
    log "清除AUR缓存"
    print_color "$CYAN" "正在清除 AUR 缓存..."

    # 清除日志
    if [ -d "$LOG_DIR" ]; then
        rm -rf "$LOG_DIR"
        print_color "$GREEN" "  ✓ 已清除日志目录: $LOG_DIR"
        log "已删除日志目录: $LOG_DIR"
    fi

    # 清除包构建目录
    if [ -d "$PACKAGE_DIR" ]; then
        rm -rf "$PACKAGE_DIR"
        print_color "$GREEN" "  ✓ 已清除包构建目录: $PACKAGE_DIR"
        log "已删除包构建目录: $PACKAGE_DIR"
    fi

    # 清除配置备份文件
    local config_dir
    config_dir=$(dirname "$CONFIG_FILE")
    if [ -d "$config_dir" ]; then
        local backup_count
        backup_count=$(find "$config_dir" -name "*.backup.*" 2>/dev/null | wc -l)
        if [ "$backup_count" -gt 0 ]; then
            find "$config_dir" -name "*.backup.*" -delete 2>/dev/null
            print_color "$GREEN" "  ✓ 已清除 $backup_count 个配置备份文件"
            log "已删除 $backup_count 个配置备份文件"
        fi
    fi

    # 清除 AUR 版本缓存
    if [ -f "$AUR_CACHE_FILE" ]; then
        rm -f "$AUR_CACHE_FILE"
        print_color "$GREEN" "  ✓ 已清除 AUR 版本缓存: $AUR_CACHE_FILE"
        log "已删除 AUR 版本缓存"
    fi

    # 清除自更新状态
    if [ -f "$SELF_UPDATE_STATE" ]; then
        rm -f "$SELF_UPDATE_STATE"
        print_color "$GREEN" "  ✓ 已清除自更新状态"
        log "已删除自更新状态文件"
    fi

    print_color "$GREEN" "AUR缓存清除完成"
}

# ---------------------------------------------------------------------------
# clean_pacman — 清除 pacman 包缓存
#   执行: sudo pacman -Scc（清除所有下载包和缓存数据库）
# ---------------------------------------------------------------------------
clean_pacman() {
    log "清除pacman缓存"
    print_color "$CYAN" "正在清除 pacman 缓存..."
    sudo pacman -Scc
    print_color "$GREEN" "pacman缓存清除完成"
}

# ---------------------------------------------------------------------------
# clean_flatpak — 清除 flatpak 缓存
#   1. flatpak uninstall --unused: 卸载未使用的运行时
#   2. 删除 /var/tmp/flatpak-cache-* 临时缓存文件
# ---------------------------------------------------------------------------
clean_flatpak() {
    log "清除flatpak缓存"
    print_color "$CYAN" "正在清除 flatpak 缓存..."

    # 卸载未使用的运行时
    if command_exists flatpak; then
        print_color "$CYAN" "  → 卸载未使用的 flatpak 运行时..."
        flatpak uninstall --unused -y
        print_color "$GREEN" "  ✓ 未使用的运行时已卸载"
    else
        print_color "$YELLOW" "  - flatpak 未安装，跳过"
    fi

    # 清除临时缓存文件
    if compgen -G "/var/tmp/flatpak-cache-*" >/dev/null 2>&1; then
        print_color "$CYAN" "  → 清除 flatpak 临时缓存..."
        sudo rm -rfv /var/tmp/flatpak-cache-*
        print_color "$GREEN" "  ✓ 临时缓存已清除"
    else
        log "无 flatpak 临时缓存文件"
    fi

    print_color "$GREEN" "flatpak缓存清除完成"
}

# ---------------------------------------------------------------------------
# clean_all — 清除所有缓存（AUR + pacman + flatpak）
# ---------------------------------------------------------------------------
clean_all() {
    log "清除所有缓存"
    print_color "$CYAN" "清除所有缓存 (AUR + pacman + flatpak)"
    echo ""
    clean_aur
    echo ""
    clean_pacman
    echo ""
    clean_flatpak
    echo ""
    print_color "$GREEN" "所有缓存清除完成"
}

# ==================== 历史记录 ====================

# ---------------------------------------------------------------------------
# show_history — 查看安装/更新/卸载历史记录
#   参数: $1=显示条数（默认10）
#   解析日志目录下的 .log 文件，按时间倒序显示操作摘要
# ---------------------------------------------------------------------------
show_history() {
    local count="${1:-10}"
    if [ ! -d "$LOG_DIR" ]; then
        print_color "$YELLOW" "暂无操作记录"
        return 0
    fi
    local logs
    logs=$(ls -1t "$LOG_DIR"/*.log 2>/dev/null | head -n "$count")
    if [ -z "$logs" ]; then
        print_color "$YELLOW" "暂无操作记录"
        return 0
    fi
    echo ""
    print_color "$CYAN" "最近 $count 次操作记录:"
    echo ""

    local _idx=1
    while IFS= read -r logfile; do
        local _ts=$(basename "$logfile" .log)
        local _date="${_ts:0:4}-${_ts:4:2}-${_ts:6:2} ${_ts:9:2}:${_ts:11:2}:${_ts:13:2}"
        local _pkg=""
        local _action=""
        # 提取关键操作行
        if grep -q "安装软件包:" "$logfile" 2>/dev/null; then
            _action="${GREEN}安装${NC}"
            _pkg=$(grep "安装软件包:" "$logfile" | head -1 | sed 's/.*安装软件包: //')
        elif grep -q "命令行卸载" "$logfile" 2>/dev/null; then
            _action="${RED}卸载${NC}"
            _pkg=$(grep "命令行卸载" "$logfile" | head -1 | sed 's/.*命令行卸载.*: //')
        elif grep -q "命令行更新" "$logfile" 2>/dev/null; then
            _action="${CYAN}更新${NC}"
            _pkg="系统更新"
        elif grep -q "清除.*缓存" "$logfile" 2>/dev/null; then
            _action="${YELLOW}清理${NC}"
            _pkg=$(grep "清除" "$logfile" | head -1 | sed 's/.*清除//;s/缓存.*//')
        else
            _action="操作"
            _pkg="-"
        fi
        printf "  ${YELLOW}%2d.${NC} [${_date}] ${_action}  ${_pkg}\n" "$_idx"
        _idx=$((_idx + 1))
    done <<< "$logs"
    echo ""
}

# ---------------------------------------------------------------------------
# system_check — 运行时环境检查
#   确认: 1) 系统是 Arch Linux（有 pacman）  2) 非 root 用户运行
#   不满足条件时输出错误并退出
# ---------------------------------------------------------------------------
system_check() {
    if ! command_exists pacman; then
        print_color "$RED" "非Arch系用户无法使用本脚本"
        exit 3
    fi
    if [ "$(whoami)" = "root" ]; then
        print_color "$RED" "makepkg不能在root权限下运行"
        exit 5
    fi
    # 检查核心依赖
    local missing=""
    for cmd in git jq curl; do
        if ! command_exists "$cmd"; then
            missing="$missing $cmd"
        fi
    done
    if [ -n "$missing" ]; then
        print_color "$RED" "缺少必要依赖:${missing}"
        print_color "$YELLOW" "请运行: yay-plus --first-use  或手动安装后重试"
        exit 6
    fi
}

# ---------------------------------------------------------------------------
# main — 脚本入口
#   流程: init → system_check → parse_args → show_help(后备)
# ---------------------------------------------------------------------------
main() {
    init
    system_check
    # 尝试解析命令行参数
    if parse_args "$@"; then
        exit 0
    fi
    show_help
}

# 运行主函数
main "$@"