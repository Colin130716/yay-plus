#!/bin/bash
# =====================================================================
# Yay+ v3.2.0.2
# =====================================================================
# 用法请见 yay-plus -h 或 yay-plus --help 
# SC2086: NOCONFIRM_FLAG/FLATPAK_ASSUMEYES intentionally unquoted for
#   empty→zero-args semantics (e.g. pacman -S $NOCONFIRM_FLAG "$pkg")
# shellcheck disable=SC2086 
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
CREATE_LOG_TIME=$(date +'%Y%m%d_%H%M%S'); readonly CREATE_LOG_TIME

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

# ==================== 国际化 / i18n ====================

# ---------------------------------------------------------------------------
# _ — 查找并输出当前语言的翻译文本
#   参数:
#     $1 = 翻译键名（如 "CONFIG_NOT_FOUND"）
#     $@ = 后续参数作为 printf 格式化参数（可选）
#   输出: 翻译后的文本（写入 stdout）
#   查找优先级: locale 文件定义的 TEXT_<KEY> 变量 > 键名本身（fallback）
# ---------------------------------------------------------------------------
_() {
    local key="$1"
    local var_name="TEXT_${key}"
    local msg="${!var_name}"
    shift
    if [ -n "$msg" ]; then
        if [ $# -gt 0 ]; then
            # shellcheck disable=SC2059
            printf "$msg" "$@"
        else
            printf '%s' "$msg"
        fi
    else
        # fallback：键名没有翻译时直接输出 key
        if [ $# -gt 0 ]; then
            # shellcheck disable=SC2059
            printf "$key" "$@"
        else
            printf '%s' "$key"
        fi
    fi
}

# ---------------------------------------------------------------------------
# load_locale — 根据系统语言和用户配置加载对应语言翻译
#   检测优先级: --lang 命令行参数 > LANG_OVERRIDE 变量 > 系统 $LANG
#   默认: zh（中文）
# ---------------------------------------------------------------------------
load_locale() {
    local lang_code="${LANG_OVERRIDE:-}"
    if [ -z "$lang_code" ]; then
        case "${LANG:-}" in
            zh_TW*|zh_HK*|zh_MO*) lang_code="zh_TW" ;;
            zh*) lang_code="zh" ;;
            *)   lang_code="en" ;;
        esac
    fi
    local locale_file="$LOCALE_DIR/${lang_code}.sh"
    if [ -f "$locale_file" ]; then
        # shellcheck source=/dev/null
        source "$locale_file"
        CURRENT_LANG="$lang_code"
    else
        log "$(_ LOG_LOCALE_NOT_FOUND "$locale_file")" "WARN"
        CURRENT_LANG="en"
        if [ -f "$LOCALE_DIR/en.sh" ]; then
            # shellcheck source=/dev/null
            source "$LOCALE_DIR/en.sh"
        fi
    fi
}

# --- 语言设置 ---
# 用户指定的语言（空=自动检测，zh=中文，en=英文）
LANG_OVERRIDE=""
# 语言文件目录：优先脚本所在目录的 locale/，其次系统安装路径 /usr/share/yay-plus/locale/，最后 ~/.yay-plus/locale/
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || echo "$HOME/.yay-plus")"
if [ -d "${_SCRIPT_DIR}/locale" ]; then
    LOCALE_DIR="${_SCRIPT_DIR}/locale"
elif [ -d "/usr/share/yay-plus/locale" ]; then
    LOCALE_DIR="/usr/share/yay-plus/locale"
else
    mkdir -p "$HOME/.yay-plus/locale"
    LOCALE_DIR="$HOME/.yay-plus/locale"
fi
readonly LOCALE_DIR

# --- 默认配置（可被 ~/.yay-plus/yay-plus.conf 覆盖） ---
# GitHub 代理: 1=akams.cn  2=gh-proxy.com  3=gh.dpik.top  4=llkk.cc  5=不使用
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
# pacman/makepkg 确认标志（--noconfirm 时设为 --noconfirm，否则为空）
NOCONFIRM_FLAG=""
# flatpak 确认标志（--noconfirm 时设为 -y，否则为空）
FLATPAK_ASSUMEYES=""
# 强制刷新 AUR 缓存: true→忽略 TTL，强制重新拉取
FORCE_AUR_REFRESH="false"
# 自更新通道: release / beta / dev
DEFAULT_SELF_UPDATE_CHANNEL="release"
# 语言: 空=自动检测  zh=中文  en=英文
DEFAULT_LANG=""
# 配置文件格式版本（用于自动升级旧配置）
CONFIG_VERSION="9"
# AUR 包版本缓存文件，批量缓存避免逐包 RPC 调用
readonly AUR_CACHE_FILE="$HOME/.yay-plus/aur-packages.cache"
# AUR RPC 请求重试次数（0=不重试，默认 3 即最多重试 3 次，共 4 次尝试）
DEFAULT_AUR_RETRY="3"
# 自更新版本 JSON 地址
readonly VERSION_JSON_URL="https://yayplus.qzz.io/version.json"
# 自更新状态文件（记录上次检查的版本，避免重复提示）
readonly SELF_UPDATE_STATE="$HOME/.yay-plus/.self-update"
# 脚本版本号
YAY_PLUS_VERSION="3.2.1"
# GitHub 上 AUR 的镜像仓库地址（load_config 根据代理设置动态替换）
# shellcheck disable=SC2034
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
    # 加载语言翻译（提前执行，使 check_and_create_config 的日志也能翻译；
    # 配置文件中的 lang 设置会在 load_config 后生效）
    load_locale
    echo "[$now_time] $(_ LOG_START)" >> "$LOG_DIR/$CREATE_LOG_TIME.log"
    log "$(_ LOG_LOCALE_LOADED "$CURRENT_LANG")"
    # 检查并创建配置文件
    check_and_create_config
    # 加载配置文件
    load_config

    # 如果未通过 --lang 参数指定语言，则使用配置文件中的 lang 设置重新加载
    if [ -z "$LANG_OVERRIDE" ] && [ -n "$DEFAULT_LANG" ]; then
        LANG_OVERRIDE="$DEFAULT_LANG"
        load_locale
        log "$(_ LOG_LOCALE_LOADED "$CURRENT_LANG")"
    fi

    # 检测可用的 JS 包管理器（npm/yarn 为 optdepends）
    HAS_NPM="false"
    HAS_YARN="false"
    if command -v npm &>/dev/null && npm --version &>/dev/null 2>&1; then
        HAS_NPM="true"
        log "$(_ LOG_NPM_DETECTED "$(npm --version 2>/dev/null)")"
    fi
    if command -v yarn &>/dev/null && yarn --version &>/dev/null 2>&1; then
        HAS_YARN="true"
        log "$(_ LOG_YARN_DETECTED "$(yarn --version 2>/dev/null)")"
    fi
    if [ "$HAS_NPM" = "false" ] && [ "$HAS_YARN" = "false" ]; then
        log "$(_ LOG_NO_JS_MANAGER)"
    fi
}

# ---------------------------------------------------------------------------
# check_and_create_config — 确保配置文件存在且版本匹配
#   如果配置文件不存在，创建默认配置
#   如果版本过旧，备份旧文件后升级
# ---------------------------------------------------------------------------
check_and_create_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "$(_ LOG_CONFIG_NOT_FOUND_CREATING)"
        print_color "$YELLOW" "$(_ CONFIG_NOT_FOUND "$CONFIG_FILE")"
        print_color "$YELLOW" "$(_ CONFIG_NOT_FOUND_HINT)"
        create_default_config
        sleep 2
    else
        # 检查配置文件版本
        local config_file_version
        config_file_version=$(get_config_value "config_version" "1")
        log "$(_ LOG_CONFIG_VERSION_CURRENT "$config_file_version" "$CONFIG_VERSION")"
        if [ "$config_file_version" != "$CONFIG_VERSION" ]; then
            log "$(_ LOG_CONFIG_VERSION_MISMATCH)"
            print_color "$YELLOW" "$(_ CONFIG_VERSION_MISMATCH "$config_file_version" "$CONFIG_VERSION" "$CONFIG_FILE")"
            update_config
            sleep 2
        else
            log "$(_ LOG_CONFIG_ALREADY_LATEST)"
        fi
    fi
}

# ---------------------------------------------------------------------------
# update_config — 升级配置文件到最新版本
#   读取旧配置项 → 备份旧文件 → 写入新格式文件，保留用户已有的设置值
# ---------------------------------------------------------------------------
update_config() {
    # 备份旧配置文件
    local backup_file
    backup_file="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$backup_file"
    log "$(_ LOG_CONFIG_BACKUP "$backup_file")"
    # 读取旧配置
    local old_github_proxy; old_github_proxy=$(get_config_value "github_proxy" "$DEFAULT_GITHUB_PROXY")
    local old_npm_proxy; old_npm_proxy=$(get_config_value "npm_proxy" "$DEFAULT_NPM_PROXY")
    local old_kernel_org_proxy; old_kernel_org_proxy=$(get_config_value "kernel_org_proxy" "$DEFAULT_KERNEL_ORG_PROXY")
    local old_aur_source; old_aur_source=$(get_config_value "aur_source" "$DEFAULT_AUR_SOURCE")
    local old_debug_mode; old_debug_mode=$(get_config_value "debug_mode" "$DEFAULT_DEBUG_MODE")
    local old_aur_cache_ttl; old_aur_cache_ttl=$(get_config_value "aur_cache_ttl" "$DEFAULT_AUR_CACHE_TTL")
    local old_self_update_channel; old_self_update_channel=$(get_config_value "self_update_channel" "$DEFAULT_SELF_UPDATE_CHANNEL")
    local old_aur_retry; old_aur_retry=$(get_config_value "aur_retry" "$DEFAULT_AUR_RETRY")
    local old_lang; old_lang=$(get_config_value "lang" "$DEFAULT_LANG")
    log "$(_ LOG_CONFIG_READING_OLD "github_proxy=$old_github_proxy, npm_proxy=$old_npm_proxy, kernel_org_proxy=$old_kernel_org_proxy, aur_source=$old_aur_source, debug_mode=$old_debug_mode, aur_cache_ttl=$old_aur_cache_ttl, self_update_channel=$old_self_update_channel, aur_retry=$old_aur_retry, lang=$old_lang")"
    # 创建新的配置文件
    cat > "$CONFIG_FILE" << EOF
# Yay+ 配置文件
# 此文件用于设置 Yay+ 的默认行为

# GitHub代理设置 (空:每次询问, 1-5:使用对应代理, 或直接填自定义代理URL)
# 1: https://github.akams.cn/
# 2: https://gh-proxy.com/
# 3: https://gh.dpik.top/
# 4: https://gh.llkk.cc/
# 5: 不使用GitHub代理 (不推荐)
# 自定义代理示例: github_proxy=https://gh.xxx.com/
github_proxy=$old_github_proxy

# NPM代理设置 (true:启用默认镜像, false:不启用, 或直接填自定义registry URL)
# 启用后会使用 https://registry.npmmirror.com 作为NPM镜像源
# 自定义镜像示例: npm_proxy=https://registry.xxx.com
npm_proxy=$old_npm_proxy

# AUR源选择 (aur:使用AUR官方, github:使用GitHub镜像)
aur_source=$old_aur_source

# kernel.org代理设置 (true:启用默认镜像, false:不启用, 或直接填自定义镜像URL)
# 自定义镜像示例: kernel_org_proxy=https://mirrors.nju.edu.cn/kernel.org/
kernel_org_proxy=$old_kernel_org_proxy

# 调试模式 (true:启用调试模式, false:不启用调试模式)
debug_mode=$old_debug_mode

# AUR缓存有效期（分钟，默认30；设为0则每次检查都刷新）
aur_cache_ttl=$old_aur_cache_ttl

# 自更新通道 (release: 稳定版, beta: 测试版, dev: 开发版)
self_update_channel=$old_self_update_channel

# AUR RPC 请求重试次数（0=不重试，默认3次重试）
aur_retry=$old_aur_retry

# 语言设置（空:自动检测, zh:简体中文, zh_TW:繁体中文, en:英文）
lang=$old_lang

# 配置文件版本
config_version=$CONFIG_VERSION
EOF
    print_color "$GREEN" "$(_ CONFIG_UPDATED "$CONFIG_VERSION")"
    print_color "$CYAN" "$(_ CONFIG_BACKUP "$backup_file")"
}

# ---------------------------------------------------------------------------
# load_config — 从配置文件读取所有选项到全局变量
#   同时根据 DEFAULT_GITHUB_PROXY 值构造 AUR_GITHUB_MIRROR 代理 URL
# ---------------------------------------------------------------------------
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log "$(_ LOG_CONFIG_LOADING "$CONFIG_FILE")"
        # 读取配置并校验（不符合规则的值回退默认）
        # github_proxy: 1-5 内置代理编号，或自定义 http(s) URL
        DEFAULT_GITHUB_PROXY=$(validate_config_value "github_proxy" \
            "$(get_config_value "github_proxy" "$DEFAULT_GITHUB_PROXY")" \
            "$DEFAULT_GITHUB_PROXY" '^(1|2|3|4|5|https?://.+)$')
        # npm_proxy: true/false 开关，或自定义 registry URL
        DEFAULT_NPM_PROXY=$(validate_config_value "npm_proxy" \
            "$(get_config_value "npm_proxy" "$DEFAULT_NPM_PROXY")" \
            "$DEFAULT_NPM_PROXY" '^(true|false|https?://.+)$')
        DEFAULT_AUR_SOURCE=$(get_config_value "aur_source" "$DEFAULT_AUR_SOURCE")
        # kernel_org_proxy: true/false 开关，或自定义镜像 URL
        DEFAULT_KERNEL_ORG_PROXY=$(validate_config_value "kernel_org_proxy" \
            "$(get_config_value "kernel_org_proxy" "$DEFAULT_KERNEL_ORG_PROXY")" \
            "$DEFAULT_KERNEL_ORG_PROXY" '^(true|false|https?://.+)$')
        DEFAULT_DEBUG_MODE=$(validate_config_value "debug_mode" \
            "$(get_config_value "debug_mode" "$DEFAULT_DEBUG_MODE")" \
            "$DEFAULT_DEBUG_MODE" '^(true|false)$')
        DEFAULT_AUR_CACHE_TTL=$(validate_config_value "aur_cache_ttl" \
            "$(get_config_value "aur_cache_ttl" "$DEFAULT_AUR_CACHE_TTL")" \
            "$DEFAULT_AUR_CACHE_TTL" '^[0-9]+$')
        DEFAULT_SELF_UPDATE_CHANNEL=$(validate_config_value "self_update_channel" \
            "$(get_config_value "self_update_channel" "$DEFAULT_SELF_UPDATE_CHANNEL")" \
            "$DEFAULT_SELF_UPDATE_CHANNEL" '^(release|beta|dev)$')
        DEFAULT_AUR_RETRY=$(validate_config_value "aur_retry" \
            "$(get_config_value "aur_retry" "$DEFAULT_AUR_RETRY")" \
            "$DEFAULT_AUR_RETRY" '^[0-9]+$')
        DEFAULT_LANG=$(validate_config_value "lang" \
            "$(get_config_value "lang" "$DEFAULT_LANG")" \
            "$DEFAULT_LANG" '^(zh|zh_TW|en)$')
        CONFIG_VERSION=$(get_config_value "config_version" "$CONFIG_VERSION")
    else
        log "$(_ LOG_CONFIG_NOT_FOUND_DEFAULT)"
    fi

    # 根据代理设置拼接 GitHub 镜像地址（内置编号或自定义 URL）
    case $DEFAULT_GITHUB_PROXY in
        1)
            AUR_GITHUB_MIRROR="https://github.akams.cn/https://github.com/archlinux/aur.git"
            ;;
        2)
            AUR_GITHUB_MIRROR="https://gh-proxy.com/https://github.com/archlinux/aur.git"
            ;;
        3)
            AUR_GITHUB_MIRROR="https://gh.dpik.top/https://github.com/archlinux/aur.git"
            ;;
        4)
            # shellcheck disable=SC2034
            AUR_GITHUB_MIRROR="https://gh.llkk.cc/https://github.com/archlinux/aur.git"
            ;;
        https://*|http://*)
            # shellcheck disable=SC2034
            AUR_GITHUB_MIRROR="${DEFAULT_GITHUB_PROXY}https://github.com/archlinux/aur.git"
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
# validate_config_value — 校验配置值，不符合规则则跳过该设置使用默认值
#   参数: $1=键名  $2=原始值  $3=默认值  $4=合法值扩展正则（grep -E）
#   输出: 合法值或默认值（写入 stdout）
#   说明: 允许空值通过（空=未设置，交给默认值逻辑处理）
# ---------------------------------------------------------------------------
validate_config_value() {
    local key="$1"
    local value="$2"
    local default_value="$3"
    local pattern="$4"
    if [ -n "$value" ] && ! echo "$value" | grep -qE "$pattern"; then
        log "$(_ LOG_CONFIG_INVALID "$key" "$value")" "WARN"
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
    log "$(_ LOG_CONFIG_CREATING_DEFAULT)"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# Yay+ 配置文件
# 此文件用于设置 Yay+ 的默认行为

# GitHub代理设置 (空:每次询问, 1-5:使用对应代理, 或直接填自定义代理URL)
# 1: https://github.akams.cn/
# 2: https://gh-proxy.com/
# 3: https://gh.dpik.top/
# 4: https://gh.llkk.cc/
# 5: 不使用GitHub代理 (不推荐)
# 自定义代理示例: github_proxy=https://gh.xxx.com/
github_proxy=$DEFAULT_GITHUB_PROXY

# NPM代理设置 (true:启用默认镜像, false:不启用, 或直接填自定义registry URL)
# 启用后会使用 https://registry.npmmirror.com 作为NPM镜像源
# 自定义镜像示例: npm_proxy=https://registry.xxx.com
npm_proxy=$DEFAULT_NPM_PROXY

# AUR源选择 (aur:使用AUR官方, github:使用GitHub镜像)
aur_source=$DEFAULT_AUR_SOURCE

# kernel.org代理设置 (true:启用默认镜像, false:不启用, 或直接填自定义镜像URL)
# 自定义镜像示例: kernel_org_proxy=https://mirrors.nju.edu.cn/kernel.org/
kernel_org_proxy=$DEFAULT_KERNEL_ORG_PROXY

# 调试模式 (true:启用调试模式, false:不启用调试模式)
debug_mode=$DEFAULT_DEBUG_MODE

# AUR缓存有效期（分钟，默认30；设为0则每次检查都刷新）
aur_cache_ttl=$DEFAULT_AUR_CACHE_TTL

# 自更新通道 (release: 稳定版, beta: 测试版, dev: 开发版)
self_update_channel=$DEFAULT_SELF_UPDATE_CHANNEL

# AUR RPC 请求重试次数（0=不重试，默认3次重试）
aur_retry=$DEFAULT_AUR_RETRY

# 语言设置（空:自动检测, zh:简体中文, zh_TW:繁体中文, en:英文）
lang=$DEFAULT_LANG

# 配置文件版本
config_version=$CONFIG_VERSION
EOF
    print_color "$GREEN" "$(_ CONFIG_CREATED "$CONFIG_FILE")"
    print_color "$CYAN" "$(_ CONFIG_CREATED_DEFAULTS)"
    print_color "$CYAN" "$(_ CONFIG_EDIT_HINT)"
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
    local now_time; now_time=$(date +'%Y/%m/%d %H:%M:%S')
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
    # $2 (default): 默认应答方向。y=空输入继续（默认），n=空输入拒绝（安全场景用）
    local default="${2:-y}"
    read -rp "$prompt" confirm
    if [ "$default" = "n" ]; then
        case "$confirm" in
            [yY]*) return 0 ;;
            *) return 1 ;;
        esac
    else
        case "$confirm" in
            [nN]*) return 1 ;;
            *) return 0 ;;
        esac
    fi
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
    local aur_json
    local retry=0
    while [ $retry -le "$DEFAULT_AUR_RETRY" ]; do
        aur_json=$(curl -s --connect-timeout 10 --max-time 30 "$AUR_RPC_URL/info?arg[]=$package")
        [ -n "$aur_json" ] && break
        ((retry++))
        [ $retry -le "$DEFAULT_AUR_RETRY" ] && sleep 2
    done
    log "$(_ LOG_JSON_RECEIVED "$aur_json")" "INFO" "nostdout"
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
    log "$(_ LOG_AUR_RPC_SEARCHING "$package")"
    local search_result
    local retry=0
    while [ $retry -le "$DEFAULT_AUR_RETRY" ]; do
        search_result=$(curl -s --connect-timeout 10 --max-time 30 "$AUR_RPC_URL/search/$package?by=name")
        [ -n "$search_result" ] && break
        ((retry++))
        [ $retry -le "$DEFAULT_AUR_RETRY" ] && sleep 2
    done
    log "$(_ LOG_AUR_SEARCH_RESULT "$search_result")" "INFO" "nostdout"
    if echo "$search_result" | jq -e '.resultcount > 0' >/dev/null 2>&1; then
        log "$(_ LOG_AUR_PACKAGE_FOUND "$package")"
        return 0
    else
        log "$(_ LOG_AUR_PACKAGE_NOT_FOUND "$package")"
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
    log "$(_ LOG_AUR_JSON_RECEIVED "$aur_info")" "INFO" "nostdout"
    if echo "$aur_info" | grep -q '"resultcount":1'; then
        local pkgname; pkgname=$(get_json_field "$aur_info" "Name")
        local pkgbase; pkgbase=$(get_json_field "$aur_info" "PackageBase")

        log "$(_ LOG_AUR_JSON_PARSED "$pkgname" "$pkgbase")" "INFO" "nostdout"

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
        log "$(_ LOG_AUR_PARSE_FAIL "$package")" "WARN" "nostdout"
        echo "$package|$package"
        return 0
    else
        log "$(_ LOG_AUR_RPC_NO_RESULT "$package")" "ERROR" "nostdout"
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
        local depends; depends=$(get_json_field "$aur_info" "Depends[]")
        local makedepends; makedepends=$(get_json_field "$aur_info" "MakeDepends[]")
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
# ---------------------------------------------------------------------------
# check_aur_executables — AUR 投毒防御：检测克隆目录中的可执行文件
#   参数: $1=包目录
#   返回: 0(无可执行文件/用户确认继续) / 1(用户拒绝)
# ---------------------------------------------------------------------------
check_aur_executables() {
    local dir="$1"
    local exec_files
    exec_files=$(find "$dir" -path "$dir/.git" -prune -o -type f -perm /111 -print 2>/dev/null | sort)
    if [ -z "$exec_files" ]; then
        return 0
    fi
    log "$(_ LOG_AUR_EXEC_WARN "$dir")" "WARN"
    print_color "$RED" "$(_ AUR_EXEC_WARN_TITLE)"
    while IFS= read -r f; do
        print_color "$YELLOW" "  ${f#./}"
    done <<< "$exec_files"
    if ! confirm_action "$(_ AUR_EXEC_CONFIRM)" "n"; then
        log "$(_ LOG_AUR_EXEC_ABORTED "$dir")" "WARN"
        print_color "$RED" "$(_ AUR_EXEC_ABORTED)"
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# manual_review — 手动审查：ls -la 展示包目录 + 编辑器查看 PKGBUILD
#   参数: $1=包目录
#   返回: 0(用户确认继续) / 1(用户取消)
#   说明: --noconfirm 时仅展示 ls -la（不阻塞）；编辑器优先 vim，缺失时
#         回退 VISUAL → EDITOR 环境变量，均无则提示安装 vim 后继续
# ---------------------------------------------------------------------------
manual_review() {
    local dir="$1"
    ls -la "$dir"
    if [ "$NOCONFIRM" = "true" ]; then
        return 0
    fi
    if ! confirm_action "$(_ REVIEW_LS_CONFIRM)"; then
        print_color "$YELLOW" "$(_ REVIEW_CANCELED)"
        return 1
    fi
    local editor="vim"
    if ! command_exists "$editor"; then
        if [ -n "${VISUAL:-}" ] && command_exists "$VISUAL"; then
            editor="$VISUAL"
        elif [ -n "${EDITOR:-}" ] && command_exists "$EDITOR"; then
            editor="$EDITOR"
        else
            print_color "$YELLOW" "$(_ REVIEW_NO_EDITOR)"
            return 0
        fi
    fi
    "$editor" "$dir/PKGBUILD"
    if ! confirm_action "$(_ REVIEW_VIM_CONFIRM)"; then
        print_color "$YELLOW" "$(_ REVIEW_CANCELED)"
        return 1
    fi
    return 0
}

clone_aur_package() {
    local package="$1"
    local target_dir="${2:-$package}"
    # 防御：如果 target_dir 仍为空，用 package 兜底
    [ -z "$target_dir" ] && target_dir="$package"
    cd "$PACKAGE_DIR" || return 1
    rm -rf "$target_dir" 2>/dev/null || sudo rm -rf "$target_dir" 2>/dev/null || true
    # $3 (aur_source) accepted but not used; always uses aur.archlinux.org
    local package_info
    package_info=$(get_aur_package_info "$package")
    log "$(_ LOG_AUR_PKG_INFO "$package_info")"
    local actual_package; actual_package=$(echo "$package_info" | cut -d'|' -f1)
    local actual_repo; actual_repo=$(echo "$package_info" | cut -d'|' -f2)
    log "$(_ LOG_AUR_PKG_INFO_DETAIL "$package" "$actual_package" "$actual_repo")"
    # 当 RPC 返回空时（限速/未找到），直接用传入的包名克隆
    [ -z "$actual_repo" ] && actual_repo="$package"
    [ -z "$actual_package" ] && actual_package="$package"

    # 尝试 1: AUR git clone（快速，支持增量）
    log "$(_ LOG_AUR_CLONING "$actual_repo" "$package")"
    print_color "$CYAN" "$(_ AUR_CLONING "$actual_repo")"
    if git clone https://aur.archlinux.org/"$actual_repo".git "$target_dir" 2>>"$LOG_DIR/$CREATE_LOG_TIME.log"; then
        check_aur_executables "$PACKAGE_DIR/$target_dir"
        return $?
    fi

    # 尝试 2: AUR tarball 快照（curl 单次 HTTP 请求，比 git 更抗干扰，且支持代理）
    log "$(_ LOG_AUR_CLONE_FAILED)" "WARN"
    print_color "$YELLOW" "$(_ AUR_CLONE_FAILED)"

    local tarball_url="https://aur.archlinux.org/cgit/aur.git/snapshot/${actual_repo}.tar.gz"
    local tmp_tarball="/tmp/aur-${actual_repo}.tar.gz"

    if curl -sL --connect-timeout 10 --max-time 60 -o "$tmp_tarball" "$tarball_url"; then
        if tar xf "$tmp_tarball" -C "$PACKAGE_DIR" 2>/dev/null; then
            rm -f "$tmp_tarball"
            # tarball 解压出的目录名是 actual_repo，可能需要重命名为 target_dir
            if [ "$actual_repo" != "$target_dir" ] && [ -d "$PACKAGE_DIR/$actual_repo" ]; then
                mv "$PACKAGE_DIR/$actual_repo" "$PACKAGE_DIR/$target_dir" 2>/dev/null || true
            fi
            log "$(_ LOG_AUR_TARBALL_SUCCESS "$actual_repo")"
            print_color "$GREEN" "$(_ AUR_TARBALL_SUCCESS)"
            check_aur_executables "$PACKAGE_DIR/$target_dir"
            return $?
        fi
        rm -f "$tmp_tarball"
    fi

    log "$(_ LOG_AUR_DOWNLOAD_FAILED "$package")" "ERROR"
    print_color "$RED" "$(_ AUR_DOWNLOAD_FAILED)"
    return 1
}

# ---------------------------------------------------------------------------
# parse_dep_constraint — 解析依赖字符串中的版本约束
#   输入: 如 "package>=1.0.0" "package==1.0.0" "package"
#   输出: 设置全局变量 pkg_name, constraint_type, constraint_ver
#   constraint_type: ""(无约束) "==" "<=" ">=" ">" "<"
# ---------------------------------------------------------------------------
parse_dep_constraint() {
    local raw_dep="$1"
    pkg_name="$raw_dep"
    constraint_type=""
    constraint_ver=""

    # 注意: == 必须在 >= <= 之前检查，避免 >= 错误匹配 == 中的 =
    if [[ "$raw_dep" == *====* ]]; then
        pkg_name="${raw_dep%%====*}"
        constraint_type="=="
        constraint_ver="${raw_dep##*====}"
    elif [[ "$raw_dep" == *==* ]]; then
        pkg_name="${raw_dep%%==*}"
        constraint_type="=="
        constraint_ver="${raw_dep##*==}"
    elif [[ "$raw_dep" == *\<=\>* ]]; then
        pkg_name="${raw_dep%%<=*}"
        constraint_type="<="
        constraint_ver="${raw_dep##*<=}"
    elif [[ "$raw_dep" == *\>=\>* ]]; then
        pkg_name="${raw_dep%%>=*}"
        constraint_type=">="
        constraint_ver="${raw_dep##*>=}"
    elif [[ "$raw_dep" == *\>* ]]; then
        pkg_name="${raw_dep%%>*}"
        constraint_type=">"
        constraint_ver="${raw_dep##*>}"
    elif [[ "$raw_dep" == *\<* ]]; then
        pkg_name="${raw_dep%%<*}"
        constraint_type="<"
        constraint_ver="${raw_dep##*<}"
    fi
}

# ---------------------------------------------------------------------------
# ver_cmp — 使用 pacman 的 vercmp 比较两个版本号
#   返回: 0(a=b) 1(a<b) 2(a>b)
# ---------------------------------------------------------------------------
ver_cmp() {
    local a="$1"
    local b="$2"
    # vercmp 内置于 pacman，返回 -1(a<b) 0(a=b) 1(a>b)
    local r
    r=$(vercmp "$a" "$b" 2>/dev/null) || r=0
    if [ "$r" -lt 0 ]; then echo 1; elif [ "$r" -gt 0 ]; then echo 2; else echo 0; fi
}

# ---------------------------------------------------------------------------
# get_installed_version — 获取已安装包的版本号（仅版本部分）
# ---------------------------------------------------------------------------
get_installed_version() {
    local pkg="$1"
    pacman -Q "$pkg" 2>/dev/null | awk '{print $2}'
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
            print_color "$RED" "$(_ PKGBUILD_NOT_FOUND)"
            return 1
        fi
        local pkgname
        pkgname=$(grep -E '^pkgname=' PKGBUILD | cut -d'=' -f2 | tr -d "'\"")
        package="${pkgname:-unknown}"
    fi
    local all_deps
    all_deps=$(get_aur_dependencies "$package")
    if [ -z "$all_deps" ]; then
        print_color "$YELLOW" "$(_ CANNOT_FETCH_DEPS)"
        all_deps=$(parse_pkgbuild_deps)
    fi
    for dep in $all_deps; do
        local clean_dep; clean_dep=$(echo "$dep" | sed 's#\u003E#>#g' | sed 's#\u003C#<#g')
        [ -z "$clean_dep" ] && continue

        # 解析版本约束
        parse_dep_constraint "$clean_dep"
        local dep_name="$pkg_name"
        local dep_ct="$constraint_type"
        local dep_ver="$constraint_ver"

        # 检查是否已安装（考虑版本约束）
        local installed_ver
        installed_ver=$(get_installed_version "$dep_name")
        if [ -n "$installed_ver" ]; then
            case "$dep_ct" in
                "==")
                    [ "$(ver_cmp "$installed_ver" "$dep_ver")" = "0" ] && continue ;;
                "<=")
                    [ "$(ver_cmp "$installed_ver" "$dep_ver")" != "2" ] && continue ;;
                "")
                    continue ;;  # 无版本约束，已安装则跳过
            esac
        fi

        case "$dep_ct" in
            "=="|"<=")
                # 对于 <=：如果仓库当前版本已满足，直接安装仓库版本
                if [ "$dep_ct" = "<=" ]; then
                    local repo_ver
                    repo_ver=$(pacman -Si "$dep_name" 2>/dev/null | grep '^Version' | awk '{print $3}')
                    if [ -n "$repo_ver" ] && [ "$(ver_cmp "$repo_ver" "$dep_ver")" != "2" ]; then
                        print_color "$CYAN" "$(_ INSTALLING_OFFICIAL_DEP_VER "$dep_name" "$repo_ver" "$dep_ver")"
                        sudo pacman -S $NOCONFIRM_FLAG "$dep_name"
                        continue
                    fi
                fi

                # 从 archive.archlinux.org 下载特定版本
                local arch
                arch=$(pacman -Si "$dep_name" 2>/dev/null | grep '^Architecture' | awk '{print $3}')
                arch="${arch:-x86_64}"
                local first_letter="${dep_name:0:1}"

                # 尝试多种版本格式：dep_ver 直接使用，再尝试 dep_ver-1
                local try_versions=("$dep_ver" "${dep_ver}-1" "${dep_ver}-2")
                local downloaded=false
                for try_ver in "${try_versions[@]}"; do
                    local archive_url="https://archive.archlinux.org/packages/${first_letter}/${dep_name}/${dep_name}-${try_ver}-${arch}.pkg.tar.zst"
                    local tmp_archive="/tmp/aur-dep-${dep_name}-${try_ver}.pkg.tar.zst"
                    print_color "$CYAN" "$(_ DOWNLOADING_ARCHIVE_DEP "$archive_url")"
                    if curl -sL --connect-timeout 10 --max-time 60 -o "$tmp_archive" "$archive_url" 2>/dev/null; then
                        if [ -s "$tmp_archive" ] && ! grep -q '<!DOCTYPE\|<html' "$tmp_archive" 2>/dev/null; then
                            print_color "$GREEN" "$(_ ARCHIVE_DEP_SUCCESS "${dep_name}-${try_ver}")"
                            sudo pacman -U $NOCONFIRM_FLAG "$tmp_archive"
                            rm -f "$tmp_archive"
                            downloaded=true
                            break
                        fi
                    fi
                    rm -f "$tmp_archive"
                done
                if [ "$downloaded" = false ]; then
                    print_color "$YELLOW" "$(_ ARCHIVE_DEP_WARN "${dep_name}${dep_ct}${dep_ver}")"
                fi
                ;;

            ">="|">")
                # 去掉版本约束，正常安装最新版
                print_color "$CYAN" "$(_ INSTALLING_OFFICIAL_DEP "$dep_name")"
                if pacman -Si "$dep_name" >/dev/null 2>&1; then
                    sudo pacman -S $NOCONFIRM_FLAG "$dep_name"
                else
                    install_aur_dep "$dep_name"
                fi
                ;;

            "<")
                print_color "$YELLOW" "$(_ DEP_CONSTRAINT_WARN "$dep_name" "<" "$dep_ver")"
                ;;

            "")
                # 无约束，走原有流程
                if pacman -Si "$dep_name" >/dev/null 2>&1; then
                    print_color "$CYAN" "$(_ INSTALLING_OFFICIAL_DEP "$dep_name")"
                    sudo pacman -S $NOCONFIRM_FLAG "$dep_name"
                else
                    install_aur_dep "$dep_name"
                fi
                ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# install_aur_dep — 安装单个 AUR 依赖（供 process_dependencies 调用）
# ---------------------------------------------------------------------------
install_aur_dep() {
    local dep_name="$1"
    local aur_info
    aur_info=$(get_aur_package_info_json "$dep_name")
    if echo "$aur_info" | grep -q '"resultcount":1'; then
        print_color "$CYAN" "$(_ AUR_DEP_FOUND "$dep_name")"
        local _caller_dir="$PWD"
        cd "$PACKAGE_DIR" || return 1
        rm -rf "$dep_name"
        if ! clone_aur_package "$dep_name" "$dep_name"; then
            cd "$_caller_dir" || return 1
            return 1
        fi
        cd "$dep_name" || { cd "$_caller_dir" || return 1; return 1; }
        process_dependencies "$dep_name"
        cd "$PACKAGE_DIR/$dep_name" || return 1
        set_ghproxy
        set_proxy
        if ! manual_review "$PACKAGE_DIR/$dep_name"; then
            cd "$_caller_dir" || return 1
            return 1
        fi
        makepkg -si --skippgpcheck $NOCONFIRM_FLAG --asdeps
        cd "$_caller_dir" || return 1
    else
        print_color "$YELLOW" "$(_ AUR_DEP_NOT_FOUND "$dep_name")"
    fi
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
        _ PARSE_DEPS_PKGBUILD_NOT_FOUND >&2
        return 1
    fi
    local depends; depends=$(grep -E '^depends=\(|^depends=' "$pkgbuild_file" | \
    sed -e 's/^depends=//' -e 's/^(\|)$//g' -e "s/'//g" | tr -d '()' | tr ' ' '\n' | grep -v '^$' | grep -v '\.so$')
    local makedepends; makedepends=$(grep -E '^makedepends=\(|^makedepends=' "$pkgbuild_file" | \
    sed -e 's/^makedepends=//' -e 's/^(\|)$//g' -e "s/'//g" | tr -d '()' | tr ' ' '\n' | grep -v '^$' | grep -v '\.so$')
    local checkdepends; checkdepends=$(grep -E '^checkdepends=\(|^checkdepends=' "$pkgbuild_file" | \
    sed -e 's/^checkdepends=//' -e 's/^(\|)$//g' -e "s/'//g" | tr -d '()' | tr ' ' '\n' | grep -v '^$' | grep -v '\.so$')
    echo "$depends $makedepends $checkdepends" | tr ' ' '\n' | grep -v '^$' | sort -u
}


# ==================== 命令行操作接口 ====================

# ---------------------------------------------------------------------------
# show_help — 显示完整帮助信息并退出
#   触发: yay-plus -h 或 yay-plus --help
# ---------------------------------------------------------------------------
show_help() {
    echo -e "$(_ HELP_TITLE)"
    echo -e "$(_ HELP_VERSION "$YAY_PLUS_VERSION")"
    echo ""
    echo -e "$(_ HELP_USAGE)"
    echo -e "$(_ HELP_USAGE_LINE)"
    echo ""
    echo -e "$(_ HELP_OPTIONS)"
    echo ""
    echo -e "$(_ HELP_INSTALL)"
    echo -e "$(_ HELP_INSTALL_PACMAN)"
    echo -e "$(_ HELP_INSTALL_AUR)"
    echo -e "$(_ HELP_INSTALL_FLATPAK)"
    echo -e "$(_ HELP_INSTALL_AUTO)"
    echo ""
    echo -e "$(_ HELP_REMOVE)"
    echo -e "$(_ HELP_REMOVE_PACMAN)"
    echo -e "$(_ HELP_REMOVE_FLATPAK)"
    echo ""
    echo -e "$(_ HELP_QUERY)"
    echo -e "$(_ HELP_QUERY_PACMAN)"
    echo -e "$(_ HELP_QUERY_AUR)"
    echo -e "$(_ HELP_QUERY_FLATPAK)"
    echo -e "$(_ HELP_QUERY_ONLINE)"
    echo -e "$(_ HELP_QUERY_LOCAL)"
    echo -e "$(_ HELP_QUERY_AUR_SEARCH)"
    echo ""
    echo -e "$(_ HELP_UPDATE)"
    echo -e "$(_ HELP_UPDATE_PACMAN)"
    echo -e "$(_ HELP_UPDATE_AUR)"
    echo -e "$(_ HELP_UPDATE_FLATPAK)"
    echo -e "$(_ HELP_UPDATE_ALL)"
    echo -e "$(_ HELP_UPDATE_AUR_REFRESH)"
    echo ""
    echo -e "$(_ HELP_LOCAL_INSTALL)"
    echo -e "$(_ HELP_LOCAL_INSTALL_DESC)"
    echo ""
    echo -e "$(_ HELP_CLEAN)"
    echo -e "$(_ HELP_CLEAN_AUR)"
    echo -e "$(_ HELP_CLEAN_PACMAN)"
    echo -e "$(_ HELP_CLEAN_FLATPAK)"
    echo -e "$(_ HELP_CLEAN_ALL)"
    echo ""
    echo -e "$(_ HELP_HELP)"
    echo -e "$(_ HELP_VERSION_OPT)"
    echo -e "$(_ HELP_NOCONFIRM)"
    echo -e "$(_ HELP_CONFIRM)"
    echo -e "$(_ HELP_FIRST_USE)"
    echo -e "$(_ HELP_HISTORY)"
    echo -e "$(_ HELP_SELF_UPDATE)"
    echo -e "$(_ HELP_SELF_UPDATE_CHANNEL)"
    echo ""
    echo -e "$(_ HELP_EXAMPLES)"
    echo -e "$(_ HELP_EXAMPLE_INSTALL_PACMAN)"
    echo -e "$(_ HELP_EXAMPLE_INSTALL_AUR)"
    echo -e "$(_ HELP_EXAMPLE_REMOVE)"
    echo -e "$(_ HELP_EXAMPLE_QUERY)"
    echo -e "$(_ HELP_EXAMPLE_QUERY_SEARCH)"
    echo -e "$(_ HELP_EXAMPLE_UPDATE_AUR)"
    echo -e "$(_ HELP_EXAMPLE_UPDATE_REFRESH)"
    echo -e "$(_ HELP_EXAMPLE_LOCAL_INSTALL)"
    echo -e "$(_ HELP_EXAMPLE_CLEAN_AUR)"
    echo -e "$(_ HELP_EXAMPLE_SELF_UPDATE)"
    echo -e "$(_ HELP_EXAMPLE_SELF_UPDATE_BETA)"
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

    log "$(_ LOG_CMD_ARGS "$*")"
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
                            *) print_color "$RED" "$(_ UNKNOWN_SUBOPTION "S" "$_ch" "S" "$_combined")"; exit 1 ;;
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
                            *) print_color "$RED" "$(_ UNKNOWN_SUBOPTION "R" "$_ch" "R" "$_combined")"; exit 1 ;;
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
                            *) print_color "$RED" "$(_ UNKNOWN_SUBOPTION "Q" "$_ch" "Q" "$_combined")"; exit 1 ;;
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
                            *) print_color "$RED" "$(_ UNKNOWN_SUBOPTION "U" "$_ch" "U" "$_combined")"; exit 1 ;;
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
                    print_color "$RED" "$(_ LOCAL_INSTALL_NEED_PATH)"
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
                NOCONFIRM_FLAG="--noconfirm"
                FLATPAK_ASSUMEYES="-y"
                shift
                ;;
            --confirm)
                NOCONFIRM="false"
                NOCONFIRM_FLAG=""
                FLATPAK_ASSUMEYES=""
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
            --lang)
                shift
                if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
                    LANG_OVERRIDE="$1"
                    shift
                fi
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
                            *) print_color "$RED" "$(_ UNKNOWN_SUBOPTION "C" "$_ch" "C" "$_combined")"; exit 1 ;;
                        esac
                    done
                fi
                ;;
            -h|--help)
                show_help
                # shellcheck disable=SC2317
                exit 0
                ;;
            -v|--version)
                show_version
                # shellcheck disable=SC2317
                exit 0
                ;;
            *)
                if [[ ! $1 =~ ^- ]]; then
                    package_names+=("$1")
                    shift
                else
                    print_color "$RED" "$(_ UNKNOWN_PARAM "$1")"
                    exit 1
                fi
                ;;
        esac
    done
    log "$(_ LOG_PARSE_RESULT "install_mode=$install_mode, remove_mode=$remove_mode, query_mode=$query_mode, update_mode=$update_mode, clean_mode=$clean_mode, local_install_path=$local_install_path, package_names=(${package_names[*]})")"

    if [ -n "$local_install_path" ]; then
        local_install "$local_install_path"
        exit 0
    elif [ -n "$install_mode" ]; then
        if [ ${#package_names[@]} -eq 0 ]; then
            print_color "$RED" "$(_ INSTALL_NEED_PACKAGE)"
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
            print_color "$RED" "$(_ REMOVE_NEED_PACKAGE)"
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
                        print_color "$CYAN" "$(_ REMOVE_PACMAN "$_pkg")"
                        remove_via_pacman "$_pkg"
                        _pkg_found=true
                    elif flatpak list 2>/dev/null | grep -qi "^$_pkg"; then
                        print_color "$CYAN" "$(_ REMOVE_FLATPAK "$_pkg")"
                        remove_via_flatpak "$_pkg"
                        _pkg_found=true
                    else
                        print_color "$RED" "$(_ REMOVE_NOT_FOUND "$_pkg")"
                    fi
                done
                if [ "$_pkg_found" = false ]; then
                    print_color "$RED" "$(_ REMOVE_NOTHING)"
                    exit 1
                fi
                ;;
        esac
        exit 0
    elif [ -n "$query_mode" ]; then
        if [ ${#package_names[@]} -eq 0 ]; then
            print_color "$RED" "$(_ QUERY_NEED_PACKAGE_ERR)"
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
        print_color "$RED" "$(_ LOCAL_PATH_NOT_EXIST "$path")"
        exit 1
    fi
    log "$(_ LOG_LOCAL_INSTALL "$path")"
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
                print_color "$RED" "$(_ LOCAL_UNSUPPORTED_TYPE "$path")"
                print_color "$YELLOW" "$(_ LOCAL_SUPPORTED_TYPES)"
                exit 1
                ;;
        esac
    else
        print_color "$RED" "$(_ LOCAL_INVALID_PATH "$path")"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# local_install_aur — 本地构建安装 AUR 包目录（含 PKGBUILD）
# ---------------------------------------------------------------------------
local_install_aur() {
    local dir_path="$1"
    log "$(_ LOG_LOCAL_INSTALL_AUR "$dir_path")"
    print_color "$CYAN" "$(_ LOCAL_INSTALLING)"
    cd "$dir_path" || {
        print_color "$RED" "$(_ LOCAL_NOT_DIR "$dir_path")"
        exit 1
    }
    if [ ! -f "PKGBUILD" ]; then
        print_color "$RED" "$(_ LOCAL_NO_PKGBUILD)"
        exit 1
    fi
    local pkgname pkgver pkgrel
    # shellcheck source=/dev/null
    source PKGBUILD >/dev/null 2>&1
    if [ -z "$pkgname" ]; then
        print_color "$RED" "$(_ LOCAL_NO_PKGINFO)"
        exit 1
    fi
    print_color "$BLUE" "$(_ LOCAL_ABOUT)"
    print_color "$GREEN" "$(_ LOCAL_DISPLAY "$pkgname" "$pkgver-$pkgrel")"
    echo ""
    if ! confirm_action "$(_ INSTALL_CONFIRM)"; then
            print_color "$YELLOW" "$(_ INSTALL_CANCELED)"
            exit 0
    fi
    process_dependencies "$pkgname"
    set_ghproxy
    set_proxy
    if ! manual_review "$dir_path"; then
        print_color "$YELLOW" "$(_ INSTALL_CANCELED)"
        exit 0
    fi
    print_color "$CYAN" "$(_ LOCAL_BUILDING)"
    if makepkg -si --skippgpcheck $NOCONFIRM_FLAG; then
        print_color "$GREEN" "$(_ LOCAL_SUCCESS "$pkgname")"
    else
        print_color "$RED" "$(_ LOCAL_FAILED "$pkgname")"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# local_install_package_file — 本地安装 .pkg.tar.zst/.xz/.gz 包文件
# ---------------------------------------------------------------------------
local_install_package_file() {
    local file_path="$1"
    log "$(_ LOG_LOCAL_INSTALL_PKG "$file_path")"
    print_color "$CYAN" "$(_ PKG_FILE_DETECTED)"
    print_color "$BLUE" "$(_ PKG_FILE_ABOUT)"
    print_color "$GREEN" "$(_ PKG_FILE_DISPLAY "$(basename "$file_path")")"
    echo ""
    if ! confirm_action "$(_ INSTALL_CONFIRM)"; then
            print_color "$YELLOW" "$(_ INSTALL_CANCELED)"
            exit 0
    fi
    if sudo pacman -U $NOCONFIRM_FLAG "$file_path"; then
        print_color "$GREEN" "$(_ PKG_FILE_SUCCESS "$(basename "$file_path")")"
    else
        print_color "$RED" "$(_ PKG_FILE_FAILED "$(basename "$file_path")")"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# local_install_flatpakref — 本地安装 .flatpakref 引用文件
# ---------------------------------------------------------------------------
local_install_flatpakref() {
    local file_path="$1"
    log "$(_ LOG_LOCAL_INSTALL_FLATPAKREF "$file_path")"
    print_color "$CYAN" "$(_ FLATPAKREF_DETECTED)"
    print_color "$BLUE" "$(_ FLATPAKREF_ABOUT)"
    print_color "$GREEN" "$(_ FLATPAKREF_DISPLAY "$(basename "$file_path")")"
    echo ""
    if ! confirm_action "$(_ INSTALL_CONFIRM)"; then
            print_color "$YELLOW" "$(_ INSTALL_CANCELED)"
            exit 0
    fi
    if flatpak install $FLATPAK_ASSUMEYES "$file_path"; then
        print_color "$GREEN" "$(_ FLATPAKREF_SUCCESS "$(basename "$file_path")")"
    else
        print_color "$RED" "$(_ FLATPAKREF_FAILED "$(basename "$file_path")")"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# install_via_pacman — 从官方仓库安装单个包（有确认交互）
#   参数: $1=包名
#   返回: 0(成功/取消) / 1(包不在官方仓库)
# ---------------------------------------------------------------------------
# shellcheck disable=SC2329
install_via_pacman() {
    local package="$1"
    log "$(_ LOG_CMD_INSTALL_PACMAN "$package")"
    local package_info
    package_info=$(pacman -Si "$package" 2>/dev/null)
    if [ -n "$package_info" ]; then
        print_color "$BLUE" "$(_ PACMAN_ABOUT)"
        local repo; repo=$(echo "$package_info" | grep "^Repository" | cut -d: -f2 | tr -d ' ')
        local name; name=$(echo "$package_info" | grep "^Name" | cut -d: -f2 | tr -d ' ')
        local version; version=$(echo "$package_info" | grep "^Version" | cut -d: -f2 | tr -d ' ')
        echo "$repo/$name $version"
        echo ""
        if ! confirm_action "$(_ INSTALL_CONFIRM)"; then
                print_color "$YELLOW" "$(_ INSTALL_CANCELED)"
                return 0
        fi
        sudo pacman -S $NOCONFIRM_FLAG "$package"
    else
        print_color "$RED" "$(_ PACMAN_NOT_FOUND "$package")"
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
    log "$(_ LOG_CMD_INSTALL_AUR "$package")"

    # 首先通过AUR RPC搜索确认包是否存在
    if ! search_aur_package "$package"; then
        print_color "$RED" "$(_ AUR_SEARCH_FAIL "$package")"
        return 1
    fi

    local package_info
    package_info=$(get_aur_package_info "$package")
    local actual_package; actual_package=$(echo "$package_info" | cut -d'|' -f1)
    local actual_repo; actual_repo=$(echo "$package_info" | cut -d'|' -f2)
    # 防御 AUR 限速导致 info 返回空，回退到原始包名
    [ -z "$actual_package" ] && actual_package="$package"
    [ -z "$actual_repo" ] && actual_repo="$package"
    log "$(_ LOG_INSTALL_AUR_DETAIL "$package" "$actual_package" "$actual_repo")"
    if ! clone_aur_package "$package" "$actual_repo"; then
        return 1
    fi
    cd "$actual_repo" || return 1
    if [ ! -f "PKGBUILD" ]; then
        log "$(_ LOG_PKGBUILD_NOT_FOUND "$actual_repo")" "ERROR"
        print_color "$RED" "$(_ AUR_NO_PKGBUILD)"
        return 1
    fi
    process_dependencies "$actual_package"
    local pkgname pkgver pkgrel
    # shellcheck source=/dev/null
    source PKGBUILD >/dev/null 2>&1
    print_color "$BLUE" "$(_ AUR_INSTALL_ABOUT)"
    print_color "$GREEN" "$(_ AUR_INSTALL_DISPLAY "$pkgname" "$pkgver-$pkgrel")"
    echo ""
    if ! confirm_action "$(_ INSTALL_CONFIRM)"; then
            print_color "$YELLOW" "$(_ INSTALL_CANCELED)"
            return 0
    fi
    set_ghproxy
    set_proxy
    if ! manual_review "$PACKAGE_DIR/$actual_repo"; then
        print_color "$YELLOW" "$(_ INSTALL_CANCELED)"
        return 0
    fi
    makepkg -si --skippgpcheck $NOCONFIRM_FLAG
    return 0
}

# ---------------------------------------------------------------------------
# install_via_flatpak — 从 Flathub 安装单个 flatpak 包
# ---------------------------------------------------------------------------
# shellcheck disable=SC2329
install_via_flatpak() {
    local package="$1"
    log "$(_ LOG_CMD_INSTALL_FLATPAK "$package")"
    flatpak install $FLATPAK_ASSUMEYES flathub "$package"
}

# ---------------------------------------------------------------------------
# install_auto — 单包自动安装（pacman → AUR → flatpak 依次尝试）
# ---------------------------------------------------------------------------
# shellcheck disable=SC2329
install_auto() {
    local package="$1"
    log "$(_ LOG_CMD_AUTO_INSTALL "$package")"
    print_color "$CYAN" "$(_ INSTALL_AUTO_PACMAN "$package")"
    if ! install_via_pacman "$package"; then
        print_color "$YELLOW" "$(_ INSTALL_AUTO_PACMAN_FAIL "$package")"
        if ! install_via_aur "$package"; then
            print_color "$YELLOW" "$(_ INSTALL_AUTO_AUR_FAIL "$package")"
            if ! install_via_flatpak "$package"; then
                print_color "$RED" "$(_ INSTALL_AUTO_FLATPAK_FAIL "$package")"
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
    log "$(_ LOG_CMD_BATCH_INSTALL_PACMAN "${packages[*]}")"
    print_color "$BLUE" "$(_ PACMAN_ABOUT)"
    for pkg in "${packages[@]}"; do
        local package_info
        package_info=$(pacman -Si "$pkg" 2>/dev/null)
        if [ -n "$package_info" ]; then
            local repo; repo=$(echo "$package_info" | grep "^Repository" | cut -d: -f2 | tr -d ' ')
            local name; name=$(echo "$package_info" | grep "^Name" | cut -d: -f2 | tr -d ' ')
            local version; version=$(echo "$package_info" | grep "^Version" | cut -d: -f2 | tr -d ' ')
            echo "$repo/$name $version"
        else
            print_color "$RED" "$(_ PACMAN_NOT_FOUND "$pkg")"
        fi
    done
    echo ""
    if ! confirm_action "$(_ INSTALL_CONFIRM)"; then
            print_color "$YELLOW" "$(_ INSTALL_CANCELED)"
            exit 0
    fi
    sudo pacman -S $NOCONFIRM_FLAG "${packages[@]}"
}

# ---------------------------------------------------------------------------
# install_via_flatpak_multi — 批量从 Flathub 安装（一次性确认）
# ---------------------------------------------------------------------------
install_via_flatpak_multi() {
    local packages=("$@")
    log "$(_ LOG_CMD_BATCH_INSTALL_FLATPAK "${packages[*]}")"
    print_color "$BLUE" "$(_ FLATPAKREF_ABOUT)"
    echo "${packages[@]}"
    echo ""
    if ! confirm_action "$(_ INSTALL_CONFIRM)"; then
            print_color "$YELLOW" "$(_ INSTALL_CANCELED)"
            exit 0
    fi
    for pkg in "${packages[@]}"; do
        flatpak install $FLATPAK_ASSUMEYES flathub "$pkg"
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
    log "$(_ LOG_CMD_BATCH_AUTO_INSTALL "${packages[*]}")"
    # 首先尝试通过pacman安装所有包
    local pacman_packages=()
    local remaining_packages=()
    
    print_color "$CYAN" "$(_ INSTALL_MULTI_SCAN)"
    for pkg in "${packages[@]}"; do
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            pacman_packages+=("$pkg")
            print_color "$GREEN" "$(_ INSTALL_MULTI_OFFICIAL "$pkg")"
        else
            remaining_packages+=("$pkg")
            print_color "$YELLOW" "$(_ INSTALL_MULTI_NOT_OFFICIAL "$pkg")"
        fi
    done
    
    if [ ${#pacman_packages[@]} -gt 0 ]; then
        echo ""
        print_color "$BLUE" "$(_ INSTALL_MULTI_ABOUT)"
        echo "${pacman_packages[*]}"
        echo ""
        if ! confirm_action "$(_ INSTALL_CONFIRM)"; then
                print_color "$YELLOW" "$(_ INSTALL_CANCELED)"
        else
            sudo pacman -S $NOCONFIRM_FLAG "${pacman_packages[@]}"
        fi
    fi
    
    # 尝试通过AUR安装剩余的包，AUR中找不到则尝试flatpak
    if [ ${#remaining_packages[@]} -gt 0 ]; then
        for pkg in "${remaining_packages[@]}"; do
            # 先通过AUR RPC搜索确认包是否存在
            if search_aur_package "$pkg"; then
                print_color "$CYAN" "$(_ INSTALL_MULTI_AUR_TRY "$pkg")"
                if ! install_via_aur "$pkg"; then
                    print_color "$RED" "$(_ INSTALL_MULTI_AUR_FAIL "$pkg")"
                fi
            else
                print_color "$YELLOW" "$(_ INSTALL_MULTI_NOT_IN_AUR "$pkg")"
                if flatpak search "$pkg" 2>/dev/null | grep -qi "^${pkg}[[:space:]]"; then
                    print_color "$CYAN" "$(_ INSTALL_MULTI_FLATPAK_TRY "$pkg")"
                    if ! flatpak install $FLATPAK_ASSUMEYES flathub "$pkg"; then
                        print_color "$RED" "$(_ INSTALL_MULTI_FLATPAK_FAIL "$pkg")"
                    fi
                else
                    print_color "$RED" "$(_ INSTALL_MULTI_NOT_FOUND "$pkg")"
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
    log "$(_ LOG_CMD_REMOVE_PACMAN "$package")"
    sudo pacman -Rsn $NOCONFIRM_FLAG "$package"
}

# ---------------------------------------------------------------------------
# remove_via_flatpak — 通过 flatpak 卸载单个包
# ---------------------------------------------------------------------------
remove_via_flatpak() {
    local package="$1"
    log "$(_ LOG_CMD_REMOVE_FLATPAK "$package")"
    flatpak uninstall $FLATPAK_ASSUMEYES "$package"
}

# ---------------------------------------------------------------------------
# remove_via_pacman_multi — 批量卸载 pacman 包（一次性确认）
# ---------------------------------------------------------------------------
remove_via_pacman_multi() {
    local packages=("$@")
    log "$(_ LOG_CMD_BATCH_REMOVE_PACMAN "${packages[*]}")"
    print_color "$BLUE" "$(_ REMOVE_ABOUT)"
    echo "${packages[*]}"
    echo ""
    if ! confirm_action "$(_ REMOVE_CONFIRM)"; then
            print_color "$YELLOW" "$(_ REMOVE_CANCELED)"
            exit 0
    fi
    sudo pacman -Rsn $NOCONFIRM_FLAG "${packages[@]}"
}

# ---------------------------------------------------------------------------
# remove_via_flatpak_multi — 批量卸载 flatpak 包（一次性确认）
# ---------------------------------------------------------------------------
remove_via_flatpak_multi() {
    local packages=("$@")
    log "$(_ LOG_CMD_BATCH_REMOVE_FLATPAK "${packages[*]}")"
    print_color "$BLUE" "$(_ REMOVE_FLATPAK_ABOUT)"
    echo "${packages[*]}"
    echo ""
    if ! confirm_action "$(_ REMOVE_CONFIRM)"; then
            print_color "$YELLOW" "$(_ REMOVE_CANCELED)"
            exit 0
    fi
    for pkg in "${packages[@]}"; do
        flatpak uninstall $FLATPAK_ASSUMEYES "$pkg"
    done
}

# ==================== 查询函数 ====================

# ---------------------------------------------------------------------------
# query_online_pacman — 搜索官方仓库中的包
# ---------------------------------------------------------------------------
query_online_pacman() {
    local package="$1"
    log "$(_ LOG_CMD_QUERY_ONLINE_PACMAN "$package")"
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
    log "$(_ LOG_CMD_QUERY_ONLINE_AUR "$package")"
    if [ -z "$package" ]; then
        print_color "$YELLOW" "$(_ QUERY_NEED_PACKAGE)"
        return 1
    fi
    local suggest_result
    local retry=0
    while [ $retry -le "$DEFAULT_AUR_RETRY" ]; do
        suggest_result=$(curl -s --connect-timeout 10 --max-time 30 "$AUR_RPC_URL/suggest/$package")
        [ -n "$suggest_result" ] && break
        ((retry++))
        [ $retry -le "$DEFAULT_AUR_RETRY" ] && sleep 2
    done
    log "$(_ LOG_AUR_SUGGEST_RESULT "$suggest_result")" "INFO" "nostdout"
    if [ -z "$suggest_result" ] || [ "$suggest_result" = "[]" ]; then
        print_color "$YELLOW" "$(_ QUERY_AUR_NOT_FOUND)"
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
    log "$(_ LOG_CMD_AUR_EXACT_SEARCH "$package")"
    if [ -z "$package" ]; then
        print_color "$YELLOW" "$(_ QUERY_NEED_PACKAGE)"
        return 1
    fi
    local search_result
    local retry=0
    while [ $retry -le "$DEFAULT_AUR_RETRY" ]; do
        search_result=$(curl -s --connect-timeout 10 --max-time 30 "$AUR_RPC_URL/search/$package?by=name-desc")
        [ -n "$search_result" ] && break
        ((retry++))
        [ $retry -le "$DEFAULT_AUR_RETRY" ] && sleep 2
    done
    log "$(_ LOG_AUR_SEARCH_RESULT_ALT "$search_result")" "INFO" "nostdout"
    if echo "$search_result" | jq -e '.resultcount > 0' >/dev/null 2>&1; then
        echo "$search_result" | jq -r '.results[] | "\(.Name) \(.Version)\n    \(.Description)\n"'
    else
        print_color "$YELLOW" "$(_ QUERY_AUR_NOT_FOUND)"
    fi
}

# ---------------------------------------------------------------------------
# query_online_flatpak — 搜索 Flathub 中的 flatpak 包
# ---------------------------------------------------------------------------
query_online_flatpak() {
    local package="$1"
    log "$(_ LOG_CMD_QUERY_ONLINE_FLATPAK "$package")"
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
    log "$(_ LOG_CMD_QUERY_LOCAL_PACMAN "$package")"
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
    log "$(_ LOG_CMD_QUERY_LOCAL_AUR "$package")"
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
    log "$(_ LOG_CMD_QUERY_LOCAL_FLATPAK "$package")"
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
    log "$(_ LOG_CMD_QUERY_ALL_ONLINE "$package")"
    if [ -z "$package" ]; then
        print_color "$YELLOW" "$(_ QUERY_NEED_PACKAGE_ALL)"
        return 1
    fi
    print_color "$CYAN" "$(_ QUERY_OFFICIAL_HEADER)"
    query_online_pacman "$package"
    echo ""
    print_color "$CYAN" "$(_ QUERY_AUR_HEADER)"
    query_online_aur "$package"
    echo ""
    print_color "$CYAN" "$(_ QUERY_FLATPAK_HEADER)"
    query_online_flatpak "$package"
}

# ---------------------------------------------------------------------------
# query_local_all — 统一查询所有本地源（pacman + AUR + flatpak）
# ---------------------------------------------------------------------------
query_local_all() {
    local package="$1"
    log "$(_ LOG_CMD_QUERY_ALL_LOCAL "$package")"
    if [ -z "$package" ]; then
        print_color "$CYAN" "$(_ QUERY_LOCAL_OFFICIAL)"
        pacman -Qn
        echo ""
        print_color "$CYAN" "$(_ QUERY_LOCAL_AUR)"
        pacman -Qm
        echo ""
        print_color "$CYAN" "$(_ QUERY_LOCAL_FLATPAK)"
        flatpak list
    else
        print_color "$CYAN" "$(_ QUERY_LOCAL_OFFICIAL)"
        query_local_pacman "$package"
        echo ""
        print_color "$CYAN" "$(_ QUERY_LOCAL_AUR)"
        query_local_aur "$package"
        echo ""
        print_color "$CYAN" "$(_ QUERY_LOCAL_FLATPAK)"
        query_local_flatpak "$package"
    fi
}

# ==================== 更新函数 ====================

# ---------------------------------------------------------------------------
# update_all_packages — 依次更新 pacman → AUR → flatpak
# ---------------------------------------------------------------------------
update_all_packages() {
    log "$(_ LOG_CMD_UPDATE_ALL)"
    print_color "$CYAN" "$(_ UPDATE_ALL)"
    update_pacman_packages
    update_aur_packages
    update_flatpak_packages
    print_color "$GREEN" "$(_ UPDATE_ALL_DONE)"
}

# ---------------------------------------------------------------------------
# update_pacman_packages — 同步数据库并升级所有官方包
# ---------------------------------------------------------------------------
update_pacman_packages() {
    print_color "$CYAN" "$(_ UPDATE_PACMAN)"
    sudo pacman -Syyy
    sudo pacman -Su $NOCONFIRM_FLAG
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
        log "$(_ LOG_AUR_CACHE_VALID "$elapsed" "$DEFAULT_AUR_CACHE_TTL")"
        return 0
    fi
    log "$(_ LOG_AUR_CACHE_EXPIRED "$elapsed" "$DEFAULT_AUR_CACHE_TTL")"
    return 1
}

# ---------------------------------------------------------------------------
# refresh_aur_cache — 批量刷新 AUR 包版本缓存
#   一次性从 AUR RPC info 端点拉取所有已安装 AUR 包的版本信息
#   每次请求最多 100 个包（AUR RPC 建议上限），自动分批
#   缓存格式:
#     # Last refresh: <epoch_timestamp>
#     pkgname1|version1|PackageBase1
#     pkgname2|version2|PackageBase2
#   无参数，无返回值
#   副作用: 写入 $AUR_CACHE_FILE
# ---------------------------------------------------------------------------
refresh_aur_cache() {
    print_color "$CYAN" "$(_ UPDATE_AUR_CACHE_REFRESH)"
    local aur_packages
    aur_packages=$(pacman -Qmq 2>/dev/null | sort -u)
    if [ -z "$aur_packages" ]; then
        echo "# Last refresh: $(date +%s)" > "$AUR_CACHE_FILE"
        print_color "$GREEN" "$(_ UPDATE_AUR_CACHE_EMPTY)"
        return 0
    fi

    # 按每批 100 个包分组请求
    local cache_content; cache_content="# Last refresh: $(date +%s)"

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

        # 调用 AUR RPC info（多包查询，含重试）
        local aur_json
        local retry=0
        while [ $retry -le "$DEFAULT_AUR_RETRY" ]; do
            aur_json=$(curl -s --connect-timeout 10 --max-time 30 "$AUR_RPC_URL/info?${arg_params#&}")
            [ -n "$aur_json" ] && break
            ((retry++))
            [ $retry -le "$DEFAULT_AUR_RETRY" ] && sleep 2
        done
        log "$(_ LOG_AUR_BATCH_QUERY "${idx}-$((batch_end-1))" "$(echo "$aur_json" | jq '.resultcount')")"

        # 解析每个结果的 Name + Version + PackageBase（用于去重）
        local results
        results=$(echo "$aur_json" | jq -r '.results[]? | "\(.Name)|\(.Version)|\(.PackageBase // .Name)"' 2>/dev/null)
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
    print_color "$GREEN" "$(_ UPDATE_AUR_CACHE_REFRESHED "$cached_count")"
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

# get_cached_pkgbase — 从缓存中读取指定包的 PackageBase
#   参数: $1=包名
#   输出: PackageBase（未找到时输出空字符串）
# ---------------------------------------------------------------------------
get_cached_pkgbase() {
    local pkg="$1"
    grep "^$pkg|" "$AUR_CACHE_FILE" 2>/dev/null | head -1 | cut -d'|' -f3
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
        print_color "$GREEN" "$(_ UPDATE_AUR_NO_PACKAGES)"
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
            local pb
            pb=$(get_cached_pkgbase "$pkg")
            [ -n "$pb" ] && pkg_to_pkgbase["$pkg"]="$pb"
        else
            missing_pkgs+=("$pkg")
        fi
    done <<< "$aur_packages"

    # 第二步：对缓存未命中的包做补充批量查询，同时提取 PackageBase
    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        print_color "$CYAN" "$(_ UPDATE_AUR_SUPPLEMENT "${#missing_pkgs[@]}")"
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
            local retry=0
            while [ $retry -le "$DEFAULT_AUR_RETRY" ]; do
                miss_json=$(curl -s --connect-timeout 10 --max-time 30 "$AUR_RPC_URL/info?${miss_args#&}")
                [ -n "$miss_json" ] && break
                ((retry++))
                [ $retry -le "$DEFAULT_AUR_RETRY" ] && sleep 2
            done
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
        print_color "$GREEN" "$(_ UPDATE_AUR_ALL_LATEST)"
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
    print_color "$YELLOW" "$(_ UPDATE_AUR_LIST_HEADER "${#update_choices[@]}" "${#unique_bases[@]}")"
    echo -e "$updates_list"

    if ! confirm_action "$(_ UPDATE_AUR_CONFIRM)"; then
        print_color "$YELLOW" "$(_ UPDATE_AUR_CANCELED)"
        return 0
    fi

    print_color "$CYAN" "$(_ UPDATE_AUR_PROGRESS "${#unique_bases[@]}")"

    # 第六步：按唯一仓库构建（每个仓库只 build 一次）
    for base in "${unique_bases[@]}"; do
        local pkgs_in_base="${base_to_pkgs[$base]}"
        print_color "$CYAN" "$(_ UPDATE_AUR_UPDATING "$base" "$pkgs_in_base")"

        # 通过 AUR RPC 获取精确的仓库名（PackageBase 可能 ≠ 包名）
        local rpc_name="$base"   # 用于 clone_aur_package 内部 RPC 查询的包名
        local package_info_update
        package_info_update=$(get_aur_package_info "$base")
        # 若 base 本身不是有效包名（如 autokey 仅作为 PackageBase 存在），
        # 用组内第一个实际包名（如 autokey-common）重新查询
        if [ -z "$package_info_update" ]; then
            local first_pkg="${base_to_pkgs[$base]%%,*}"
            rpc_name="$first_pkg"
            package_info_update=$(get_aur_package_info "$first_pkg")
        fi
        local actual_package_update; actual_package_update=$(echo "$package_info_update" | cut -d'|' -f1)
        local actual_repo_update; actual_repo_update=$(echo "$package_info_update" | cut -d'|' -f2)
        # 防御 AUR 限速导致 info 返回空
        [ -z "$actual_package_update" ] && actual_package_update="$base"
        [ -z "$actual_repo_update" ] && actual_repo_update="$base"

        if ! clone_aur_package "$rpc_name" "$actual_repo_update"; then
            print_color "$RED" "$(_ UPDATE_AUR_CLONE_FAIL "$base")"
            continue
        fi
        local _update_saved_dir="$PWD"
        cd "$PACKAGE_DIR/$actual_repo_update" || continue
        process_dependencies "$actual_package_update"
        set_ghproxy
        set_proxy
        if ! manual_review "$PACKAGE_DIR/$actual_repo_update"; then
            print_color "$YELLOW" "$(_ UPDATE_AUR_SKIP "$base")"
            cd "$_update_saved_dir" || continue
            continue
        fi
        if ! makepkg -si --skippgpcheck $NOCONFIRM_FLAG; then
            print_color "$RED" "$(_ UPDATE_AUR_BUILD_FAIL "$base")"
        else
            print_color "$GREEN" "$(_ UPDATE_AUR_BUILD_DONE "$base" "$pkgs_in_base")"
        fi
        cd "$_update_saved_dir" || continue
    done

    print_color "$GREEN" "$(_ UPDATE_AUR_DONE)"
}

# ---------------------------------------------------------------------------
# update_flatpak_packages — 更新所有 flatpak 包
# ---------------------------------------------------------------------------
update_flatpak_packages() {
    print_color "$CYAN" "$(_ UPDATE_FLATPAK)"
    flatpak update $FLATPAK_ASSUMEYES
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

    print_color "$CYAN" "$(_ SELF_UPDATE_CHECKING "$channel")"

    # 拉取 version.json（主 URL + GitHub proxy 回退）
    local ver_json
    ver_json=$(curl -s --connect-timeout 8 "$VERSION_JSON_URL" 2>/dev/null)

    # 检测是否为有效 JSON（Cloudflare 挑战会返回 HTML）
    if [ -z "$ver_json" ] || echo "$ver_json" | grep -q '<\(!DOCTYPE\|html\)'; then
        log "$(_ LOG_SOURCE_FAIL_FALLBACK)" "WARN"
        # 构造 GitHub raw 回退 URL
        local fallback_url="https://raw.githubusercontent.com/Colin130716/yay-plus/master/version.json"
        local proxy_url="$fallback_url"
        case $DEFAULT_GITHUB_PROXY in
            1) proxy_url="https://github.akams.cn/${fallback_url}" ;;
            2) proxy_url="https://gh-proxy.com/${fallback_url}" ;;
            3) proxy_url="https://gh.dpik.top/${fallback_url}" ;;
            4) proxy_url="https://gh.llkk.cc/${fallback_url}" ;;
        esac
        print_color "$YELLOW" "$(_ SELF_UPDATE_SOURCE_FAIL "$proxy_url")"
        ver_json=$(curl -s --connect-timeout 10 "$proxy_url" 2>/dev/null)
    fi

    # 最终校验
    if [ -z "$ver_json" ] || ! echo "$ver_json" | jq -e '.release' >/dev/null 2>&1; then
        print_color "$RED" "$(_ SELF_UPDATE_NO_INFO)"
        return 1
    fi

    # 解析指定通道
    local remote_version remote_filename remote_date
    remote_version=$(echo "$ver_json" | jq -r ".${channel}.version // empty" 2>/dev/null)
    remote_filename=$(echo "$ver_json" | jq -r ".${channel}.filename // empty" 2>/dev/null)
    remote_date=$(echo "$ver_json" | jq -r ".${channel}.date // empty" 2>/dev/null)

    if [ -z "$remote_version" ] || [ "$remote_version" = "null" ]; then
        print_color "$GREEN" "$(_ SELF_UPDATE_NO_UPDATE "$channel")"
        return 0
    fi

    # 规范化版本号比较：去除 v 前缀和 -后缀，提取纯数字版本
    local local_ver="${YAY_PLUS_VERSION#v}"
    local remote_normalized="${remote_version#v}"
    remote_normalized="${remote_normalized%%-*}"

    if [ "$local_ver" = "$remote_normalized" ]; then
        print_color "$GREEN" "$(_ SELF_UPDATE_LATEST "$YAY_PLUS_VERSION")"
        return 0
    fi

    # 检查本地状态：如果已记录此版本则跳过
    if [ -f "$SELF_UPDATE_STATE" ]; then
        local last_seen
        last_seen=$(grep "^${channel}=" "$SELF_UPDATE_STATE" 2>/dev/null | cut -d'=' -f2)
        if [ "$last_seen" = "$remote_version" ]; then
            print_color "$GREEN" "$(_ SELF_UPDATE_LATEST "$remote_version")"
            return 0
        fi
    fi

    # 显示更新信息
    echo ""
    print_color "$YELLOW" "$(_ SELF_UPDATE_FOUND)"
    echo -e "$(_ SELF_UPDATE_CHANNEL "$channel")"
    echo -e "$(_ SELF_UPDATE_VERSION "$remote_version")"
    echo -e "$(_ SELF_UPDATE_DATE "${remote_date:-$(_ UNKNOWN)}")"
    echo -e "$(_ SELF_UPDATE_FILENAME "$remote_filename")"
    echo ""

    if ! confirm_action "$(_ SELF_UPDATE_CONFIRM)"; then
        print_color "$YELLOW" "$(_ SELF_UPDATE_CANCELED)"
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
        3) download_url="https://gh.dpik.top/${github_url}" ;;
        4) download_url="https://gh.llkk.cc/${github_url}" ;;
    esac

    print_color "$CYAN" "$(_ SELF_UPDATE_DOWNLOADING "$download_url")"
    local tmp_pkg="/tmp/${remote_filename}"

    if ! curl -L -o "$tmp_pkg" "$download_url"; then
        # 代理失败时尝试直连
        print_color "$YELLOW" "$(_ SELF_UPDATE_PROXY_FAIL)"
        if ! curl -L -o "$tmp_pkg" "$github_url"; then
            print_color "$RED" "$(_ SELF_UPDATE_DOWNLOAD_FAIL)"
            return 1
        fi
    fi

    print_color "$CYAN" "$(_ SELF_UPDATE_INSTALLING)"
    if sudo pacman -U $NOCONFIRM_FLAG "$tmp_pkg"; then
        print_color "$GREEN" "$(_ SELF_UPDATE_SUCCESS "$remote_version")"
        # 记录已更新的版本
        mkdir -p "$(dirname "$SELF_UPDATE_STATE")"
        echo "${channel}=${remote_version}" > "$SELF_UPDATE_STATE"
        rm -f "$tmp_pkg"
        print_color "$YELLOW" "$(_ SELF_UPDATE_RESTART)"
    else
        print_color "$RED" "$(_ SELF_UPDATE_MANUAL "$tmp_pkg")"
        return 1
    fi
}


# ==================== 代理与环境 ====================

# ---------------------------------------------------------------------------
# first_use — 首次使用时安装必要依赖并配置 flatpak 源
#   安装: base-devel, git, flatpak, jq
#   npm/nodejs 为可选依赖（optdepends），用于 AUR 包的 npm 构建步骤
#   可选: 替换 flathub 为中科大镜像
# ---------------------------------------------------------------------------
first_use() {
    log "$(_ LOG_FIRST_USE_AUTO_INSTALL)"
    sudo pacman -S $NOCONFIRM_FLAG --needed base-devel git flatpak jq
    log "$(_ LOG_SETUP_FLATPAK_SOURCE)"
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    read -rp "是否要更换flathub源为中科大源？（Y/n）: " use_mirror
    case $use_mirror in
        [nN]) return ;;
        *)
            log "$(_ LOG_SWITCH_FLATHUB_SOURCE)"
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
# pkgbuild_source_has_domain — 检测 PKGBUILD 的 source* 字段是否含指定域名
#   参数: $1=域名扩展正则（grep -E）
#   返回: 0=包含  1=不包含
#   覆盖 source= / source_x86_64= 等所有 source 变体
# ---------------------------------------------------------------------------
pkgbuild_source_has_domain() {
    local domain_pattern="$1"
    grep -E '^[[:space:]]*source[A-Za-z0-9_]*=' PKGBUILD 2>/dev/null | grep -qE "$domain_pattern"
}

# ---------------------------------------------------------------------------
# pkgbuild_has_command — 检测 PKGBUILD 中是否出现指定构建命令
#   参数: $1=命令扩展正则（grep -E）
#   返回: 0=出现  1=未出现
# ---------------------------------------------------------------------------
pkgbuild_has_command() {
    grep -qE "$1" PKGBUILD 2>/dev/null
}

# ---------------------------------------------------------------------------
# set_proxy — 在构建前设置 NPM/kernel.org 代理
#   修改当前目录的 PKGBUILD（替换 kernel.org 链接）
#   设置 npm registry 镜像
#   必须在目标包目录中调用
#   仅当 PKGBUILD 实际用到对应资源时才生效：
#     npm: 检测到 npm install/ci/i 才设置 npm registry
#     yarn: 检测到 yarn install 才设置 yarn registry
#     bun: 检测到 bun install 才在其前一行插入 bunfig.toml 写入命令
#     kernel.org: source* 字段含 www.kernel.org / cdn.kernel.org 才替换镜像
# ---------------------------------------------------------------------------
set_proxy() {
    # npm registry：仅在 PKGBUILD 含 npm 安装命令时设置
    if pkgbuild_has_command 'npm[[:space:]]+(install|ci|i)([^[:alnum:]_]|$)'; then
        case $DEFAULT_NPM_PROXY in
            true)
                if [ "$HAS_NPM" = "true" ]; then
                    log "$(_ LOG_SET_NPM_MIRROR "https://registry.npmmirror.com")"
                    npm config set registry https://registry.npmmirror.com 2>/dev/null
                    sudo npm config set registry https://registry.npmmirror.com 2>/dev/null
                fi
                ;;
            https://*|http://*)
                if [ "$HAS_NPM" = "true" ]; then
                    log "$(_ LOG_SET_NPM_MIRROR "$DEFAULT_NPM_PROXY")"
                    npm config set registry "$DEFAULT_NPM_PROXY" 2>/dev/null
                    sudo npm config set registry "$DEFAULT_NPM_PROXY" 2>/dev/null
                fi
                ;;
        esac
    fi
    # yarn registry：仅在 PKGBUILD 含 yarn install 命令时设置
    if pkgbuild_has_command 'yarn[[:space:]]+install([^[:alnum:]_]|$)'; then
        case $DEFAULT_NPM_PROXY in
            true)
                if [ "$HAS_YARN" = "true" ]; then
                    log "$(_ LOG_SET_YARN_MIRROR "https://registry.npmmirror.com")"
                    yarn config set registry https://registry.npmmirror.com 2>/dev/null
                fi
                ;;
            https://*|http://*)
                if [ "$HAS_YARN" = "true" ]; then
                    log "$(_ LOG_SET_YARN_MIRROR "$DEFAULT_NPM_PROXY")"
                    yarn config set registry "$DEFAULT_NPM_PROXY" 2>/dev/null
                fi
                ;;
        esac
    fi
    # bun registry：仅在 PKGBUILD 含 bun install 命令时，在其前一行插入
    # bunfig.toml 写入命令（echo 命令行跟随原缩进，toml 内容保持顶格）
    if pkgbuild_has_command 'bun[[:space:]]+install([^[:alnum:]_]|$)'; then
        local bun_registry="https://registry.npmmirror.com"
        case $DEFAULT_NPM_PROXY in
            https://*|http://*) bun_registry="$DEFAULT_NPM_PROXY" ;;
        esac
        local bun_line bun_indent
        bun_line=$(grep -nE 'bun[[:space:]]+install' PKGBUILD | head -1 | cut -d: -f1)
        if [ -n "$bun_line" ]; then
            bun_indent=$(sed -n "${bun_line}p" PKGBUILD | sed -E 's/^([[:space:]]*).*/\1/')
            log "$(_ LOG_SET_BUN_MIRROR "$bun_registry")"
            sed -i "${bun_line}i\\
${bun_indent}echo '\\
[install]\\
registry = \"${bun_registry}\"\\
' >> bunfig.toml" PKGBUILD
        fi
    fi
    # kernel.org 镜像：仅在 source* 字段含 kernel.org 链接时替换
    if pkgbuild_source_has_domain 'www\.kernel\.org|cdn\.kernel\.org'; then
        case $DEFAULT_KERNEL_ORG_PROXY in
            true)
                log "$(_ LOG_REPLACE_KERNEL_MIRROR "https://mirrors.ustc.edu.cn/kernel.org/")"
                sed -i 's#https://www.kernel.org/pub/#https://mirrors.ustc.edu.cn/kernel.org/#g' PKGBUILD
                sed -i 's#https://cdn.kernel.org/pub/#https://mirrors.ustc.edu.cn/kernel.org/#g' PKGBUILD
                ;;
            https://*|http://*)
                log "$(_ LOG_REPLACE_KERNEL_MIRROR "$DEFAULT_KERNEL_ORG_PROXY")"
                sed -i "s#https://www.kernel.org/pub/#${DEFAULT_KERNEL_ORG_PROXY}#g" PKGBUILD
                sed -i "s#https://cdn.kernel.org/pub/#${DEFAULT_KERNEL_ORG_PROXY}#g" PKGBUILD
                ;;
        esac
    fi
}

# ---------------------------------------------------------------------------
# set_ghproxy — 替换当前目录 PKGBUILD 中的 GitHub 链接为代理地址
#   根据 DEFAULT_GITHUB_PROXY 选择代理，替换以下域名的 URL：
#     github.com（分支/标签源码、Release 文件、git clone）
#     raw.githubusercontent.com（raw 文件）
#     gist.githubusercontent.com（gist raw 文件）
#     desktop.githubusercontent.com（GitHub Desktop 客户端发布文件）
#   仅当 source* 字段含 github.com / *.githubusercontent.com 时才替换
#   必须在目标包目录中调用（操作 ./PKGBUILD）
# ---------------------------------------------------------------------------
set_ghproxy() {
    if [ -n "$DEFAULT_GITHUB_PROXY" ] && pkgbuild_source_has_domain 'github\.com|githubusercontent\.com'; then
        case $DEFAULT_GITHUB_PROXY in
            1)
                log "$(_ LOG_GITHUB_PROXY_AKAMS)"
                sed -i 's#https://github.com/#https://github.akams.cn/https://github.com/#g' PKGBUILD
                sed -i 's#https://raw.githubusercontent.com/#https://github.akams.cn/https://raw.githubusercontent.com/#g' PKGBUILD
                sed -i 's#https://gist.githubusercontent.com/#https://github.akams.cn/https://gist.githubusercontent.com/#g' PKGBUILD
                sed -i 's#https://desktop.githubusercontent.com/#https://github.akams.cn/https://desktop.githubusercontent.com/#g' PKGBUILD
                ;;
            2)
                log "$(_ LOG_GITHUB_PROXY_GH_PROXY)"
                sed -i 's#https://github.com/#https://gh-proxy.com/https://github.com/#g' PKGBUILD
                sed -i 's#https://raw.githubusercontent.com/#https://gh-proxy.com/https://raw.githubusercontent.com/#g' PKGBUILD
                sed -i 's#https://gist.githubusercontent.com/#https://gh-proxy.com/https://gist.githubusercontent.com/#g' PKGBUILD
                sed -i 's#https://desktop.githubusercontent.com/#https://gh-proxy.com/https://desktop.githubusercontent.com/#g' PKGBUILD
                ;;
            3)
                log "$(_ LOG_GITHUB_PROXY_GH_DPIK)"
                sed -i 's#https://github.com/#https://gh.dpik.top/https://github.com/#g' PKGBUILD
                sed -i 's#https://raw.githubusercontent.com/#https://gh.dpik.top/https://raw.githubusercontent.com/#g' PKGBUILD
                sed -i 's#https://gist.githubusercontent.com/#https://gh.dpik.top/https://gist.githubusercontent.com/#g' PKGBUILD
                sed -i 's#https://desktop.githubusercontent.com/#https://gh.dpik.top/https://desktop.githubusercontent.com/#g' PKGBUILD
                ;;
            4)
                log "$(_ LOG_GITHUB_PROXY_LLKK)"
                sed -i 's#https://github.com/#https://gh.llkk.cc/https://github.com/#g' PKGBUILD
                sed -i 's#https://raw.githubusercontent.com/#https://gh.llkk.cc/https://raw.githubusercontent.com/#g' PKGBUILD
                sed -i 's#https://gist.githubusercontent.com/#https://gh.llkk.cc/https://gist.githubusercontent.com/#g' PKGBUILD
                sed -i 's#https://desktop.githubusercontent.com/#https://gh.llkk.cc/https://desktop.githubusercontent.com/#g' PKGBUILD
                ;;
            https://*|http://*)
                log "$(_ LOG_GITHUB_PROXY_CUSTOM "$DEFAULT_GITHUB_PROXY")"
                sed -i "s#https://github.com/#${DEFAULT_GITHUB_PROXY}https://github.com/#g" PKGBUILD
                sed -i "s#https://raw.githubusercontent.com/#${DEFAULT_GITHUB_PROXY}https://raw.githubusercontent.com/#g" PKGBUILD
                sed -i "s#https://gist.githubusercontent.com/#${DEFAULT_GITHUB_PROXY}https://gist.githubusercontent.com/#g" PKGBUILD
                sed -i "s#https://desktop.githubusercontent.com/#${DEFAULT_GITHUB_PROXY}https://desktop.githubusercontent.com/#g" PKGBUILD
                ;;
            *)
                log "$(_ LOG_GITHUB_PROXY_NONE)"
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
    log "$(_ LOG_CLEAN_AUR)"
    print_color "$CYAN" "$(_ CLEAN_AUR)"

    # 清除日志（保留当前会话的日志文件）
    if [ -d "$LOG_DIR" ]; then
        local current_log="$LOG_DIR/$CREATE_LOG_TIME.log"
        local log_count
        log_count=$(find "$LOG_DIR" -name "*.log" ! -name "$(basename "$current_log")" 2>/dev/null | wc -l)
        if [ "$log_count" -gt 0 ]; then
            find "$LOG_DIR" -name "*.log" ! -name "$(basename "$current_log")" -delete 2>/dev/null
            print_color "$GREEN" "$(_ CLEAN_LOG_DONE "$log_count")"
        else
            print_color "$GREEN" "$(_ CLEAN_LOG_NONE)"
        fi
    fi

    # 清除包构建目录
    if [ -d "$PACKAGE_DIR" ]; then
        rm -rf "$PACKAGE_DIR"
        print_color "$GREEN" "$(_ CLEAN_PACKAGE_DIR "$PACKAGE_DIR")"
        log "$(_ LOG_CLEAN_BUILD_DIR "$PACKAGE_DIR")"
    fi

    # 清除配置备份文件
    local config_dir
    config_dir=$(dirname "$CONFIG_FILE")
    if [ -d "$config_dir" ]; then
        local backup_count
        backup_count=$(find "$config_dir" -name "*.backup.*" 2>/dev/null | wc -l)
        if [ "$backup_count" -gt 0 ]; then
            find "$config_dir" -name "*.backup.*" -delete 2>/dev/null
            print_color "$GREEN" "$(_ CLEAN_CONFIG_BACKUP "$backup_count")"
            log "$(_ LOG_CLEAN_BACKUP_FILES "$backup_count")"
        fi
    fi

    # 清除 AUR 版本缓存
    if [ -f "$AUR_CACHE_FILE" ]; then
        rm -f "$AUR_CACHE_FILE"
        print_color "$GREEN" "$(_ CLEAN_AUR_CACHE "$AUR_CACHE_FILE")"
        log "$(_ LOG_CLEAN_AUR_CACHE)"
    fi

    # 清除自更新状态
    if [ -f "$SELF_UPDATE_STATE" ]; then
        rm -f "$SELF_UPDATE_STATE"
        print_color "$GREEN" "$(_ CLEAN_SELF_UPDATE)"
        log "$(_ LOG_CLEAN_SELF_UPDATE)"
    fi

    print_color "$GREEN" "$(_ CLEAN_AUR_DONE)"
}

# ---------------------------------------------------------------------------
# clean_pacman — 清除 pacman 包缓存
#   执行: sudo pacman -Scc（清除所有下载包和缓存数据库）
# ---------------------------------------------------------------------------
clean_pacman() {
    log "$(_ LOG_CLEAN_PACMAN)"
    print_color "$CYAN" "$(_ CLEAN_PACMAN)"
    sudo pacman -Scc
    print_color "$GREEN" "$(_ CLEAN_PACMAN_DONE)"
}

# ---------------------------------------------------------------------------
# clean_flatpak — 清除 flatpak 缓存
#   1. flatpak uninstall --unused: 卸载未使用的运行时
#   2. 删除 /var/tmp/flatpak-cache-* 临时缓存文件
# ---------------------------------------------------------------------------
clean_flatpak() {
    log "$(_ LOG_CLEAN_FLATPAK)"
    print_color "$CYAN" "$(_ CLEAN_FLATPAK)"

    # 卸载未使用的运行时
    if command_exists flatpak; then
        print_color "$CYAN" "$(_ CLEAN_FLATPAK_UNUSED)"
        flatpak uninstall --unused $FLATPAK_ASSUMEYES
        print_color "$GREEN" "$(_ CLEAN_FLATPAK_UNUSED_DONE)"
    else
        print_color "$YELLOW" "$(_ CLEAN_FLATPAK_NOT_INSTALLED)"
    fi

    # 清除临时缓存文件
    if compgen -G "/var/tmp/flatpak-cache-*" >/dev/null 2>&1; then
        print_color "$CYAN" "$(_ CLEAN_FLATPAK_TEMP)"
        sudo rm -rfv /var/tmp/flatpak-cache-*
        print_color "$GREEN" "$(_ CLEAN_FLATPAK_TEMP_DONE)"
    else
        log "$(_ LOG_CLEAN_FLATPAK_NO_TEMP)"
    fi

    print_color "$GREEN" "$(_ CLEAN_FLATPAK_DONE)"
}

# ---------------------------------------------------------------------------
# clean_all — 清除所有缓存（AUR + pacman + flatpak）
# ---------------------------------------------------------------------------
clean_all() {
    log "$(_ LOG_CLEAN_ALL)"
    print_color "$CYAN" "$(_ CLEAN_ALL)"
    echo ""
    clean_aur
    echo ""
    clean_pacman
    echo ""
    clean_flatpak
    echo ""
    print_color "$GREEN" "$(_ CLEAN_ALL_DONE)"
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
        print_color "$YELLOW" "$(_ HISTORY_NONE)"
        return 0
    fi
    local logs
    logs=$(find "$LOG_DIR" -maxdepth 1 -name '*.log' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n "$count" | awk '{print $2}')
    if [ -z "$logs" ]; then
        print_color "$YELLOW" "$(_ HISTORY_NONE)"
        return 0
    fi
    echo ""
    print_color "$CYAN" "$(_ HISTORY_HEADER "$count")"
    echo ""

    local _idx=1
    while IFS= read -r logfile; do
        local _ts; _ts=$(basename "$logfile" .log)
        local _date="${_ts:0:4}-${_ts:4:2}-${_ts:6:2} ${_ts:9:2}:${_ts:11:2}:${_ts:13:2}"
        local _pkg=""
        local _action=""
        # 提取关键操作行
        if grep -q "安装软件包:" "$logfile" 2>/dev/null; then
            _action="${GREEN}$(_ HISTORY_INSTALL)${NC}"
            _pkg=$(grep "安装软件包:" "$logfile" | head -1 | sed 's/.*安装软件包: //')
        elif grep -q "命令行卸载" "$logfile" 2>/dev/null; then
            _action="${RED}$(_ HISTORY_REMOVE)${NC}"
            _pkg=$(grep "命令行卸载" "$logfile" | head -1 | sed 's/.*命令行卸载.*: //')
        elif grep -q "命令行更新" "$logfile" 2>/dev/null; then
            _action="${CYAN}$(_ HISTORY_UPDATE)${NC}"
            _pkg="$(_ HISTORY_SYSTEM_UPDATE)"
        elif grep -q "清除.*缓存" "$logfile" 2>/dev/null; then
            _action="${YELLOW}$(_ HISTORY_CLEAN)${NC}"
            _pkg=$(grep "清除" "$logfile" | head -1 | sed 's/.*清除//;s/缓存.*//')
        else
            _action="$(_ HISTORY_ACTION)"
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
        print_color "$RED" "$(_ SYSTEM_CHECK_NOT_ARCH)"
        exit 3
    fi
    if [ "$(whoami)" = "root" ]; then
        print_color "$RED" "$(_ SYSTEM_CHECK_ROOT)"
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
        print_color "$RED" "$(_ SYSTEM_CHECK_MISSING_DEPS "$missing")"
        print_color "$YELLOW" "$(_ SYSTEM_CHECK_RUN_FIRST_USE)"
        exit 6
    fi
}

# ---------------------------------------------------------------------------
# main — 脚本入口
#   流程: init → system_check → parse_args → show_help(后备)
# ---------------------------------------------------------------------------
main() {
    # 前置扫描 --lang 参数（在 init 加载语言之前）
    for _arg in "$@"; do
        if [ "$_arg" = "--lang" ]; then
            # 找到下一个参数作为语言代码
            local _found=false
            for _i in "$@"; do
                if [ "$_found" = true ]; then
                    LANG_OVERRIDE="$_i"
                    break
                fi
                [ "$_i" = "--lang" ] && _found=true
            done
            break
        fi
    done
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