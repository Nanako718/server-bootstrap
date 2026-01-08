#!/bin/bash

# 一键安装脚本：Oh My Zsh + Docker + Docker Compose + Starship + 0xProto 字体
# 支持 macOS 和 Linux 系统

set -e  # 遇到错误立即退出（某些非关键操作会使用 || true 来避免退出）

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root 用户（某些操作可能需要）
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warn "检测到 root 用户，某些操作可能需要普通用户权限"
    fi
}

# 检测系统类型
detect_system() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SYSTEM_TYPE="macos"
        print_info "检测到系统类型: macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux-musl"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
        SYSTEM_TYPE="linux"
        print_info "检测到系统类型: Linux"
        
        # 检测 Linux 发行版
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
            print_info "检测到 Linux 发行版: $DISTRO"
        fi
    else
        print_error "不支持的系统类型: $OSTYPE"
        exit 1
    fi
}

# 检查并安装 curl 和 wget
install_curl_wget() {
    local NEED_CURL=false
    local NEED_WGET=false
    
    if ! command -v curl &> /dev/null; then
        NEED_CURL=true
    fi
    
    if ! command -v wget &> /dev/null; then
        NEED_WGET=true
    fi
    
    # 如果两者都已安装，直接返回
    if [ "$NEED_CURL" = false ] && [ "$NEED_WGET" = false ]; then
        return 0
    fi
    
    # 至少需要其中一个，优先安装 curl
    if [ "$NEED_CURL" = true ]; then
        print_info "正在安装 curl..."
        
        if [[ "$SYSTEM_TYPE" == "macos" ]]; then
            if command -v brew &> /dev/null; then
                brew install curl
            else
                print_warn "macOS 系统通常已预装 curl，如果未找到请先安装 Homebrew"
            fi
        else
            # Linux 系统
            if command -v apt-get &> /dev/null; then
                # Debian/Ubuntu
                sudo apt-get update
                sudo apt-get install -y curl
            elif command -v yum &> /dev/null; then
                # CentOS/RHEL 7
                sudo yum install -y curl
            elif command -v dnf &> /dev/null; then
                # Fedora/CentOS 8+/RHEL 8+
                sudo dnf install -y curl
            elif command -v pacman &> /dev/null; then
                # Arch Linux
                sudo pacman -S --noconfirm curl
            elif command -v zypper &> /dev/null; then
                # openSUSE
                sudo zypper install -y curl
            elif command -v apk &> /dev/null; then
                # Alpine Linux
                sudo apk add --no-cache curl
            else
                print_error "未找到支持的包管理器，无法安装 curl"
                return 1
            fi
        fi
    fi
    
    # 如果 curl 安装失败或不存在，尝试安装 wget
    if [ "$NEED_WGET" = true ] && ! command -v curl &> /dev/null; then
        print_info "正在安装 wget..."
        
        if [[ "$SYSTEM_TYPE" == "macos" ]]; then
            if command -v brew &> /dev/null; then
                brew install wget
            else
                print_warn "macOS 系统需要 Homebrew 来安装 wget"
            fi
        else
            # Linux 系统
            if command -v apt-get &> /dev/null; then
                # Debian/Ubuntu
                sudo apt-get update
                sudo apt-get install -y wget
            elif command -v yum &> /dev/null; then
                # CentOS/RHEL 7
                sudo yum install -y wget
            elif command -v dnf &> /dev/null; then
                # Fedora/CentOS 8+/RHEL 8+
                sudo dnf install -y wget
            elif command -v pacman &> /dev/null; then
                # Arch Linux
                sudo pacman -S --noconfirm wget
            elif command -v zypper &> /dev/null; then
                # openSUSE
                sudo zypper install -y wget
            elif command -v apk &> /dev/null; then
                # Alpine Linux
                sudo apk add --no-cache wget
            else
                print_error "未找到支持的包管理器，无法安装 wget"
                return 1
            fi
        fi
    fi
    
    # 验证安装
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        print_error "curl 和 wget 都未安装成功，脚本无法继续"
        return 1
    fi
}

# 检查并安装 Homebrew (仅 macOS)
install_homebrew() {
    if [[ "$SYSTEM_TYPE" != "macos" ]]; then
        return 0
    fi
    
    if command -v brew &> /dev/null; then
        print_info "Homebrew 已安装，跳过安装步骤"
        brew update
    else
        print_info "正在安装 Homebrew..."
        # 确保 curl 已安装（Homebrew 安装需要）
        if ! command -v curl &> /dev/null; then
            install_curl_wget
        fi
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # 配置 Homebrew 环境变量（适用于 Apple Silicon Mac）
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

# 安装 Zsh (Linux 系统需要先安装 zsh)
install_zsh() {
    if command -v zsh &> /dev/null; then
        print_info "Zsh 已安装，版本: $(zsh --version)"
    else
        print_info "正在安装 Zsh..."
        
        if [[ "$SYSTEM_TYPE" == "linux" ]]; then
            if command -v apt-get &> /dev/null; then
                # Debian/Ubuntu
                sudo apt-get update
                sudo apt-get install -y zsh git curl
            elif command -v yum &> /dev/null; then
                # CentOS/RHEL 7
                sudo yum install -y zsh git curl
            elif command -v dnf &> /dev/null; then
                # Fedora/CentOS 8+/RHEL 8+
                sudo dnf install -y zsh git curl
            elif command -v pacman &> /dev/null; then
                # Arch Linux
                sudo pacman -S --noconfirm zsh git curl
            elif command -v zypper &> /dev/null; then
                # openSUSE
                sudo zypper install -y zsh git curl
            elif command -v apk &> /dev/null; then
                # Alpine Linux
                sudo apk add --no-cache zsh git curl
            else
                print_error "未找到支持的包管理器，请手动安装 zsh、git 和 curl"
                exit 1
            fi
        fi
    fi
}

# 安装 Oh My Zsh
install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_info "Oh My Zsh 已安装，跳过安装步骤"
    else
        print_info "正在安装 Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        
        # 如果当前 shell 不是 zsh，提示用户切换
        if [[ "$SHELL" != *"zsh"* ]]; then
            print_warn "当前 shell 不是 zsh，请运行: chsh -s $(which zsh)"
        fi
    fi
}

# 安装 Oh My Zsh 常用插件
install_zsh_plugins() {
    print_info "正在安装和配置 Oh My Zsh 常用插件..."
    
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    # zsh-autosuggestions - 自动建议插件
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        print_info "安装 zsh-autosuggestions 插件..."
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
    else
        print_info "zsh-autosuggestions 插件已存在，跳过安装"
    fi
    
    # zsh-syntax-highlighting - 语法高亮插件
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        print_info "安装 zsh-syntax-highlighting 插件..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
    else
        print_info "zsh-syntax-highlighting 插件已存在，跳过安装"
    fi
    
    # zsh-completions - 自动补全插件
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
        print_info "安装 zsh-completions 插件..."
        git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM}/plugins/zsh-completions
    else
        print_info "zsh-completions 插件已存在，跳过安装"
    fi
    
    # 配置 .zshrc 文件
    print_info "正在配置 .zshrc 文件..."
    
    local ZSHRC="$HOME/.zshrc"
    
    # 备份现有配置
    if [ -f "$ZSHRC" ]; then
        cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "已备份现有 .zshrc 文件"
    fi
    
    # 更新插件配置
    if grep -q "plugins=(" "$ZSHRC"; then
        # 如果已有插件配置，更新它
        # 兼容 macOS 和 Linux 的 sed 命令
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions docker docker-compose kubectl)/' "$ZSHRC"
        else
            sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions docker docker-compose kubectl)/' "$ZSHRC"
        fi
    else
        # 如果没有插件配置，添加它
        echo "" >> "$ZSHRC"
        echo "# 常用插件配置" >> "$ZSHRC"
        echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions docker docker-compose kubectl)" >> "$ZSHRC"
    fi
    
    # 添加一些常用别名
    if ! grep -q "# 常用别名" "$ZSHRC"; then
        echo "" >> "$ZSHRC"
        echo "# 常用别名" >> "$ZSHRC"
        echo "alias ll='ls -alF'" >> "$ZSHRC"
        echo "alias la='ls -A'" >> "$ZSHRC"
        echo "alias l='ls -CF'" >> "$ZSHRC"
        echo "alias d='docker'" >> "$ZSHRC"
        echo "alias dc='docker-compose'" >> "$ZSHRC"
        echo "alias dcu='docker-compose up -d'" >> "$ZSHRC"
        echo "alias dcd='docker-compose down'" >> "$ZSHRC"
        echo "alias dcl='docker-compose logs -f'" >> "$ZSHRC"
        echo "alias dps='docker ps'" >> "$ZSHRC"
        echo "alias dpsa='docker ps -a'" >> "$ZSHRC"
    fi
    
    print_info "Oh My Zsh 插件配置完成"
}

# 安装 Docker
install_docker() {
    if command -v docker &> /dev/null; then
        print_info "Docker 已安装，版本: $(docker --version)"
    else
        print_info "正在安装 Docker..."
        
        # macOS 上推荐使用 Docker Desktop
        if [[ "$OSTYPE" == "darwin"* ]]; then
            print_info "检测到 macOS 系统，推荐使用 Docker Desktop"
            print_warn "请手动下载并安装 Docker Desktop: https://www.docker.com/products/docker-desktop"
            print_info "或者使用 Homebrew Cask 安装..."
            
            if command -v brew &> /dev/null; then
                brew install --cask docker
                print_info "Docker Desktop 已通过 Homebrew 安装"
                print_warn "请手动启动 Docker Desktop 应用程序以完成安装"
            else
                print_error "未找到 Homebrew，请先安装 Homebrew 或手动安装 Docker Desktop"
                exit 1
            fi
        else
            # Linux 系统安装 Docker
            print_info "检测到 Linux 系统，使用标准方式安装 Docker..."
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            rm get-docker.sh
            
            # 将当前用户添加到 docker 组
            if [ "$EUID" -ne 0 ]; then
                sudo usermod -aG docker $USER
                print_info "已将用户 $USER 添加到 docker 组"
            fi
        fi
    fi
}

# 安装 Docker Compose
install_docker_compose() {
    # 检查 Docker Compose V2 (作为 Docker 插件)
    if docker compose version &> /dev/null 2>&1; then
        print_info "Docker Compose V2 (插件版本) 已安装，版本: $(docker compose version)"
        return 0
    fi
    
    # 检查 Docker Compose V1 (独立命令)
    if command -v docker-compose &> /dev/null; then
        print_info "Docker Compose V1 已安装，版本: $(docker-compose --version)"
        print_warn "建议升级到 Docker Compose V2 (docker compose)"
        return 0
    fi
    
    print_info "正在安装 Docker Compose..."
    
    # Docker Desktop 已经包含了 Docker Compose V2
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_warn "Docker Desktop 已包含 Docker Compose V2，无需单独安装"
        print_info "如果 Docker Desktop 未安装，请先安装 Docker Desktop"
    else
        # Linux 系统：Docker Compose V2 通常随 Docker 一起安装
        # 如果没有，则安装 Docker Compose V2 插件
        if command -v docker &> /dev/null; then
            print_info "正在安装 Docker Compose V2 插件..."
            local COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest 2>/dev/null | grep 'tag_name' | cut -d\" -f4)
            if [ -n "$COMPOSE_VERSION" ]; then
                sudo mkdir -p /usr/local/lib/docker/cli-plugins
                if sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose 2>/dev/null; then
                    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
                    print_info "Docker Compose V2 安装完成"
                else
                    print_warn "Docker Compose V2 安装失败，尝试安装 V1 版本..."
                    # 回退到 V1 安装
                    if sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>/dev/null; then
                        sudo chmod +x /usr/local/bin/docker-compose
                        print_info "Docker Compose V1 安装完成"
                    else
                        print_error "Docker Compose 安装失败，请手动安装"
                    fi
                fi
            else
                print_warn "无法获取 Docker Compose 版本信息，请手动安装"
            fi
        else
            print_error "Docker 未安装，请先安装 Docker"
        fi
    fi
}

# 配置 Docker 开机自启
configure_docker_autostart() {
    print_info "正在配置 Docker 开机自启..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS 系统
        print_info "macOS 系统：Docker Desktop 默认会在登录时自动启动"
        print_info "如需配置，请在 Docker Desktop 设置中启用 'Start Docker Desktop when you log in'"
        
        # 尝试通过命令行配置（如果 Docker Desktop 已安装）
        if [ -d "/Applications/Docker.app" ]; then
            # 使用 launchctl 配置开机自启
            osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Docker.app", hidden:false}' 2>/dev/null || true
            print_info "已尝试配置 Docker Desktop 开机自启"
        fi
    else
        # Linux 系统
        if command -v systemctl &> /dev/null; then
            print_info "配置 systemd 服务开机自启..."
            sudo systemctl enable docker
            sudo systemctl start docker
            print_info "Docker 服务已配置为开机自启"
        elif command -v service &> /dev/null; then
            print_info "配置 service 开机自启..."
            sudo update-rc.d docker defaults 2>/dev/null || sudo chkconfig docker on 2>/dev/null || true
            print_info "Docker 服务已配置为开机自启"
        else
            print_warn "未找到 systemctl 或 service 命令，无法配置开机自启"
        fi
    fi
}

# 设置系统时区
configure_timezone() {
    print_info "正在设置系统时区..."
    
    if [[ "$SYSTEM_TYPE" == "macos" ]]; then
        # macOS 系统使用系统设置
        print_info "macOS 系统请手动在系统设置中配置时区"
        print_info "或使用命令: sudo systemsetup -settimezone Asia/Shanghai"
        # 尝试设置（需要管理员权限）
        sudo systemsetup -settimezone Asia/Shanghai 2>/dev/null && print_info "时区已设置为 Asia/Shanghai" || print_warn "时区设置失败，请手动配置"
    else
        # Linux 系统使用 timedatectl
        if command -v timedatectl &> /dev/null; then
            if sudo timedatectl set-timezone Asia/Shanghai 2>/dev/null; then
                print_info "时区已设置为 Asia/Shanghai"
                print_info "当前时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
            else
                print_warn "时区设置失败，可能需要管理员权限"
            fi
        else
            print_warn "未找到 timedatectl 命令，无法自动设置时区"
            print_info "请手动设置时区或安装 systemd"
        fi
    fi
}

# 下载并安装 0xProto 字体
install_0xproto_font() {
    print_info "正在下载并安装 0xProto 字体..."
    
    local FONT_ZIP="0xProto.zip"
    local FONT_DIR=""
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # 确定字体安装目录
    if [[ "$SYSTEM_TYPE" == "macos" ]]; then
        FONT_DIR="$HOME/Library/Fonts"
    else
        # Linux 系统：优先使用 ~/.local/share/fonts，如果没有则使用 ~/.fonts
        FONT_DIR="$HOME/.local/share/fonts"
        if [ ! -d "$FONT_DIR" ]; then
            FONT_DIR="$HOME/.fonts"
        fi
    fi
    
    # 创建字体目录
    mkdir -p "$FONT_DIR"
    
    # 检查本地是否有字体文件
    local LOCAL_FONT_ZIP="$SCRIPT_DIR/$FONT_ZIP"
    local TEMP_DIR=$(mktemp -d)
    local FONT_URL="https://github.com/Nanako718/server-bootstrap/raw/refs/heads/main/0xProto.zip"
    
    if [ -f "$LOCAL_FONT_ZIP" ]; then
        print_info "找到本地字体文件: $LOCAL_FONT_ZIP"
        cp "$LOCAL_FONT_ZIP" "$TEMP_DIR/$FONT_ZIP"
    else
        print_info "本地未找到字体文件，正在从 GitHub 下载..."
        if command -v curl &> /dev/null; then
            if curl -fsSL -o "$TEMP_DIR/$FONT_ZIP" "$FONT_URL"; then
                print_info "字体文件下载成功"
            else
                print_error "字体文件下载失败，请检查网络连接"
                print_info "您也可以手动下载并放置到脚本同目录: $FONT_URL"
                rm -rf "$TEMP_DIR"
                return 1
            fi
        elif command -v wget &> /dev/null; then
            if wget -q -O "$TEMP_DIR/$FONT_ZIP" "$FONT_URL"; then
                print_info "字体文件下载成功"
            else
                print_error "字体文件下载失败，请检查网络连接"
                print_info "您也可以手动下载并放置到脚本同目录: $FONT_URL"
                rm -rf "$TEMP_DIR"
                return 1
            fi
        else
            print_warn "未找到 curl 或 wget 命令，正在尝试安装..."
            install_curl_wget
            # 重试下载
            if command -v curl &> /dev/null; then
                if curl -fsSL -o "$TEMP_DIR/$FONT_ZIP" "$FONT_URL"; then
                    print_info "字体文件下载成功"
                else
                    print_error "字体文件下载失败，请检查网络连接"
                    print_info "您也可以手动下载并放置到脚本同目录: $FONT_URL"
                    rm -rf "$TEMP_DIR"
                    return 1
                fi
            elif command -v wget &> /dev/null; then
                if wget -q -O "$TEMP_DIR/$FONT_ZIP" "$FONT_URL"; then
                    print_info "字体文件下载成功"
                else
                    print_error "字体文件下载失败，请检查网络连接"
                    print_info "您也可以手动下载并放置到脚本同目录: $FONT_URL"
                    rm -rf "$TEMP_DIR"
                    return 1
                fi
            else
                print_error "curl 和 wget 都未安装成功，无法下载字体文件"
                print_info "请手动下载字体文件: $FONT_URL"
                rm -rf "$TEMP_DIR"
                return 1
            fi
        fi
    fi
    
    # 解压字体文件
    if command -v unzip &> /dev/null; then
        print_info "正在解压字体文件..."
        cd "$TEMP_DIR"
        unzip -q "$FONT_ZIP" -d "$TEMP_DIR" 2>/dev/null || {
            print_error "字体文件解压失败，请检查文件是否完整"
            rm -rf "$TEMP_DIR"
            return 1
        }
        
        # 查找并复制字体文件（.ttf 或 .otf）
        local FONT_COUNT=0
        find "$TEMP_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | while read -r font_file; do
            if [ -n "$font_file" ]; then
                cp "$font_file" "$FONT_DIR/"
                FONT_COUNT=$((FONT_COUNT + 1))
                print_info "已安装字体: $(basename "$font_file")"
            fi
        done
        
        # 重新计算字体数量（因为 while 循环在子 shell 中）
        FONT_COUNT=$(find "$FONT_DIR" -maxdepth 1 -type f \( -name "*0xProto*" -o -name "*0xproto*" \) 2>/dev/null | wc -l | tr -d ' ')
        
        if [ "$FONT_COUNT" -eq 0 ] || [ -z "$FONT_COUNT" ]; then
            print_warn "未在压缩包中找到字体文件（.ttf 或 .otf），或字体安装失败"
        else
            print_info "0xProto 字体安装完成"
        fi
        
        # 清理临时文件
        rm -rf "$TEMP_DIR"
        
        # Linux 系统需要刷新字体缓存
        if [[ "$SYSTEM_TYPE" == "linux" ]]; then
            if command -v fc-cache &> /dev/null; then
                print_info "正在刷新字体缓存..."
                fc-cache -fv "$FONT_DIR" 2>/dev/null || true
            fi
        fi
    else
        print_error "未找到 unzip 命令，无法解压字体文件"
        print_info "请安装 unzip: sudo apt-get install unzip (Debian/Ubuntu) 或 sudo yum install unzip (CentOS/RHEL)"
        rm -rf "$TEMP_DIR"
        return 1
    fi
}

# 安装 Starship
install_starship() {
    if command -v starship &> /dev/null; then
        print_info "Starship 已安装，版本: $(starship --version)"
    else
        print_info "正在安装 Starship..."
        
        # 确保 curl 已安装（安装脚本需要）
        if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
            print_info "安装 Starship 需要 curl 或 wget，正在安装..."
            install_curl_wget
        fi
        
        if [[ "$SYSTEM_TYPE" == "macos" ]]; then
            # macOS 使用 Homebrew 安装（如果可用）
            if command -v brew &> /dev/null; then
                print_info "使用 Homebrew 安装 Starship..."
                brew install starship
            else
                # 使用官方安装脚本
                print_info "使用官方安装脚本安装 Starship..."
                if command -v curl &> /dev/null; then
                    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
                elif command -v wget &> /dev/null; then
                    # 使用 wget 下载安装脚本
                    local INSTALL_SCRIPT=$(mktemp)
                    wget -q -O "$INSTALL_SCRIPT" https://starship.rs/install.sh
                    sh "$INSTALL_SCRIPT" -- --yes
                    rm -f "$INSTALL_SCRIPT"
                else
                    print_error "无法安装 Starship：需要 curl 或 wget"
                    return 1
                fi
            fi
        else
            # Linux 系统使用官方安装脚本
            print_info "使用官方安装脚本安装 Starship..."
            if command -v curl &> /dev/null; then
                sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
            elif command -v wget &> /dev/null; then
                # 使用 wget 下载安装脚本
                local INSTALL_SCRIPT=$(mktemp)
                wget -q -O "$INSTALL_SCRIPT" https://starship.rs/install.sh
                sh "$INSTALL_SCRIPT" -- --yes
                rm -f "$INSTALL_SCRIPT"
            else
                print_error "无法安装 Starship：需要 curl 或 wget"
                return 1
            fi
        fi
    fi
}

# 配置 Starship
configure_starship() {
    print_info "正在配置 Starship..."
    
    local STARSHIP_CONFIG_DIR="$HOME/.config"
    local STARSHIP_CONFIG_FILE="$STARSHIP_CONFIG_DIR/starship.toml"
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local LOCAL_CONFIG="$SCRIPT_DIR/starship.toml"
    
    # 创建配置目录
    mkdir -p "$STARSHIP_CONFIG_DIR"
    
    # 检查本地是否有配置文件
    local CONFIG_URL="https://raw.githubusercontent.com/Nanako718/server-bootstrap/refs/heads/main/starship.toml"
    
    if [ -f "$LOCAL_CONFIG" ]; then
        print_info "找到本地配置文件: $LOCAL_CONFIG"
        if [ -f "$STARSHIP_CONFIG_FILE" ]; then
            cp "$STARSHIP_CONFIG_FILE" "$STARSHIP_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
            print_info "已备份现有 Starship 配置文件"
        fi
        cp "$LOCAL_CONFIG" "$STARSHIP_CONFIG_FILE"
        print_info "Starship 配置文件已复制到: $STARSHIP_CONFIG_FILE"
    else
        print_info "本地未找到配置文件，正在从 GitHub 下载..."
        # 如果已存在配置文件，先备份
        if [ -f "$STARSHIP_CONFIG_FILE" ]; then
            cp "$STARSHIP_CONFIG_FILE" "$STARSHIP_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
            print_info "已备份现有 Starship 配置文件"
        fi
        
        if command -v curl &> /dev/null; then
            if curl -fsSL -o "$STARSHIP_CONFIG_FILE" "$CONFIG_URL"; then
                print_info "Starship 配置文件下载成功: $STARSHIP_CONFIG_FILE"
            else
                print_warn "配置文件下载失败，将使用 Starship 默认配置"
                print_info "您也可以稍后手动下载: $CONFIG_URL"
            fi
        elif command -v wget &> /dev/null; then
            if wget -q -O "$STARSHIP_CONFIG_FILE" "$CONFIG_URL"; then
                print_info "Starship 配置文件下载成功: $STARSHIP_CONFIG_FILE"
            else
                print_warn "配置文件下载失败，将使用 Starship 默认配置"
                print_info "您也可以稍后手动下载: $CONFIG_URL"
            fi
        else
            print_warn "未找到 curl 或 wget 命令，正在尝试安装..."
            install_curl_wget
            # 重试下载
            if command -v curl &> /dev/null; then
                if curl -fsSL -o "$STARSHIP_CONFIG_FILE" "$CONFIG_URL"; then
                    print_info "Starship 配置文件下载成功: $STARSHIP_CONFIG_FILE"
                else
                    print_warn "配置文件下载失败，将使用 Starship 默认配置"
                    print_info "您也可以稍后手动下载: $CONFIG_URL"
                fi
            elif command -v wget &> /dev/null; then
                if wget -q -O "$STARSHIP_CONFIG_FILE" "$CONFIG_URL"; then
                    print_info "Starship 配置文件下载成功: $STARSHIP_CONFIG_FILE"
                else
                    print_warn "配置文件下载失败，将使用 Starship 默认配置"
                    print_info "您也可以稍后手动下载: $CONFIG_URL"
                fi
            else
                print_warn "curl 和 wget 都未安装成功，无法下载配置文件"
                print_info "将使用 Starship 默认配置，或您可以稍后手动下载: $CONFIG_URL"
            fi
        fi
    fi
    
    # 在 .zshrc 中添加 Starship 初始化代码
    local ZSHRC="$HOME/.zshrc"
    
    # 确保 .zshrc 文件存在
    if [ ! -f "$ZSHRC" ]; then
        touch "$ZSHRC"
        print_info "创建 .zshrc 文件"
    fi
    
    # 检查并添加 Starship 初始化代码
    if ! grep -q "starship init zsh" "$ZSHRC"; then
        print_info "正在在 .zshrc 中添加 Starship 初始化代码..."
        echo "" >> "$ZSHRC"
        echo "# Starship 提示符配置" >> "$ZSHRC"
        echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
        print_info "Starship 初始化代码已添加到 .zshrc"
    else
        print_info "Starship 初始化代码已存在于 .zshrc 中"
    fi
    
    # 验证 Starship 配置
    if command -v starship &> /dev/null; then
        if [ -f "$STARSHIP_CONFIG_FILE" ]; then
            # 验证配置文件格式
            if starship config --config-file "$STARSHIP_CONFIG_FILE" &> /dev/null; then
                print_info "Starship 配置文件验证成功"
            else
                print_warn "Starship 配置文件格式可能有问题，但已安装"
            fi
        fi
        print_info "Starship 配置完成，请运行 'source ~/.zshrc' 或重新打开终端以应用配置"
    else
        print_warn "Starship 未安装，配置将在 Starship 安装后生效"
    fi
}

# 验证安装
verify_installation() {
    print_info "正在验证安装..."
    
    echo ""
    print_info "=== 安装验证 ==="
    echo ""
    
    local INSTALLED_COUNT=0
    local TOTAL_COUNT=6
    
    # Zsh
    if command -v zsh &> /dev/null; then
        print_info "✓ Zsh"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        print_error "✗ Zsh"
    fi
    
    # Oh My Zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_info "✓ Oh My Zsh"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        print_error "✗ Oh My Zsh"
    fi
    
    # Docker
    if command -v docker &> /dev/null; then
        print_info "✓ Docker"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        print_error "✗ Docker"
    fi
    
    # Docker Compose
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
        print_info "✓ Docker Compose"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        print_error "✗ Docker Compose"
    fi
    
    # Starship
    if command -v starship &> /dev/null && [ -f "$HOME/.config/starship.toml" ]; then
        print_info "✓ Starship"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        print_warn "⚠ Starship（可能未完全配置）"
    fi
    
    # 字体
    local FONT_INSTALLED=false
    if [[ "$SYSTEM_TYPE" == "macos" ]]; then
        if [ -d "$HOME/Library/Fonts" ] && find "$HOME/Library/Fonts" -name "*0xProto*" -o -name "*0xproto*" 2>/dev/null | grep -q .; then
            FONT_INSTALLED=true
        fi
    else
        if find "$HOME/.local/share/fonts" "$HOME/.fonts" -name "*0xProto*" -o -name "*0xproto*" 2>/dev/null | grep -q .; then
            FONT_INSTALLED=true
        fi
    fi
    
    if [ "$FONT_INSTALLED" = true ]; then
        print_info "✓ 0xProto 字体"
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    else
        print_warn "⚠ 0xProto 字体（可能未正确安装）"
    fi
    
    echo ""
    print_info "安装进度: $INSTALLED_COUNT/$TOTAL_COUNT 组件已就绪"
    
    echo ""
    print_info "=========================================="
    print_info "            🎉 安装完成！"
    print_info "=========================================="
    echo ""
    print_info "📝 下一步操作："
    echo ""
    print_info "1. 重新加载配置："
    print_info "   source ~/.zshrc"
    echo ""
    print_info "2. 如果这是首次安装 Zsh，请切换默认 Shell："
    print_info "   chsh -s $(which zsh)"
    echo ""
    if [[ "$SYSTEM_TYPE" == "linux" ]] && [ "$EUID" -ne 0 ]; then
        print_info "3. 如果 Docker 命令需要 sudo，请重新登录："
        print_info "   重新登录后 docker 组权限将生效"
        echo ""
    fi
    print_info "4. 如果字体未显示，请重启终端应用"
    echo ""
    print_info "✨ 享受您的新开发环境！"
}

# 主函数
main() {
    print_info "=========================================="
    print_info "  一键安装脚本：Oh My Zsh + Docker + Docker Compose + Starship + 0xProto 字体"
    print_info "=========================================="
    echo ""
    
    # 检查 root 用户
    check_root
    
    # 检测系统类型
    detect_system
    
    # 首先安装 curl/wget（其他安装步骤可能需要）
    print_info "检查并安装必要的工具..."
    install_curl_wget
    
    # 安装步骤
    if [[ "$SYSTEM_TYPE" == "macos" ]]; then
        install_homebrew
    fi
    
    install_zsh
    install_oh_my_zsh
    install_zsh_plugins
    install_0xproto_font
    install_starship
    configure_starship
    install_docker
    install_docker_compose
    configure_docker_autostart
    configure_timezone
    
    # 验证安装
    verify_installation
}

# 执行主函数
main