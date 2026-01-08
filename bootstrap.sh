#!/bin/bash

# 一键安装脚本：Oh My Zsh + Docker + Docker Compose
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

# 验证安装
verify_installation() {
    print_info "正在验证安装..."
    
    echo ""
    print_info "=== 安装验证 ==="
    
    if command -v zsh &> /dev/null; then
        print_info "✓ Zsh 版本: $(zsh --version)"
    else
        print_error "✗ Zsh 未安装"
    fi
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_info "✓ Oh My Zsh 已安装"
    else
        print_error "✗ Oh My Zsh 未安装"
    fi
    
    if command -v docker &> /dev/null; then
        print_info "✓ Docker 版本: $(docker --version)"
    else
        print_error "✗ Docker 未安装"
    fi
    
    if command -v docker-compose &> /dev/null; then
        print_info "✓ Docker Compose 版本: $(docker-compose --version)"
    elif docker compose version &> /dev/null; then
        print_info "✓ Docker Compose (插件版本) 版本: $(docker compose version)"
    else
        print_error "✗ Docker Compose 未安装"
    fi
    
    echo ""
    print_info "=== 安装完成 ==="
    print_info "请重新登录或运行 'source ~/.zshrc' 以应用 Oh My Zsh 配置"
    if [[ "$SYSTEM_TYPE" == "linux" ]] && [ "$EUID" -ne 0 ]; then
        print_warn "如果 Docker 命令需要 sudo，请重新登录以使 docker 组权限生效"
    fi
}

# 主函数
main() {
    print_info "=========================================="
    print_info "  一键安装脚本：Oh My Zsh + Docker + Docker Compose"
    print_info "=========================================="
    echo ""
    
    # 检查 root 用户
    check_root
    
    # 检测系统类型
    detect_system
    
    # 安装步骤
    if [[ "$SYSTEM_TYPE" == "macos" ]]; then
        install_homebrew
    fi
    
    install_zsh
    install_oh_my_zsh
    install_zsh_plugins
    install_docker
    install_docker_compose
    configure_docker_autostart
    
    # 验证安装
    verify_installation
}

# 执行主函数
main