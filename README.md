# 🚀 Server Bootstrap

一键服务器开荒脚本，自动配置开发环境，支持 macOS 和 Linux 系统。

## ✨ 功能特性

- 🐚 **Zsh + Oh My Zsh** - 强大的 shell 环境和插件系统
- 🐳 **Docker + Docker Compose** - 容器化开发环境
- ⭐ **Starship** - 快速、可定制的跨 shell 提示符
- 🔤 **0xProto 字体** - 美观的等宽编程字体
- 🔧 **自动配置** - 自动安装和配置所有组件
- 📦 **智能下载** - 自动从 GitHub 下载最新配置和字体

## 📋 系统要求

### 支持的操作系统

- **macOS** (10.14+)
- **Linux** 发行版：
  - Debian/Ubuntu
  - CentOS/RHEL (7+)
  - Fedora
  - Arch Linux
  - openSUSE
  - Alpine Linux

### 必需权限

- `sudo` 权限（Linux 系统需要）
- 网络连接（用于下载组件）

## 🚀 快速开始

### 方法一：直接运行（推荐）

```bash
# 下载脚本
curl -fsSL https://raw.githubusercontent.com/Nanako718/server-bootstrap/main/bootstrap.sh -o bootstrap.sh

# 添加执行权限
chmod +x bootstrap.sh

# 运行脚本
./bootstrap.sh
```

### 方法二：克隆仓库

```bash
# 克隆仓库
git clone https://github.com/Nanako718/server-bootstrap.git
cd server-bootstrap

# 运行脚本
chmod +x bootstrap.sh
./bootstrap.sh
```

### 方法三：一键安装（无需下载脚本）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Nanako718/server-bootstrap/main/bootstrap.sh)
```

## 📦 安装内容

脚本会自动安装和配置以下组件：

### 1. Zsh & Oh My Zsh

- **Zsh** - 强大的 shell 替代品
- **Oh My Zsh** - Zsh 配置框架
- **常用插件**：
  - `zsh-autosuggestions` - 自动建议
  - `zsh-syntax-highlighting` - 语法高亮
  - `zsh-completions` - 自动补全
  - `docker` - Docker 命令补全
  - `docker-compose` - Docker Compose 命令补全
  - `kubectl` - Kubernetes 命令补全

### 2. Docker & Docker Compose

- **Docker** - 容器化平台
  - macOS: Docker Desktop（通过 Homebrew）
  - Linux: Docker Engine（官方安装脚本）
- **Docker Compose V2** - 多容器应用编排工具
- **自动配置**：
  - 用户添加到 docker 组（Linux）
  - 开机自启动配置

### 3. Starship 提示符

- **Starship** - 跨 shell 提示符引擎
- **配置文件**：
  - 自动从 GitHub 下载最新配置
  - 使用 Catppuccin Mocha 主题
  - 支持多种编程语言显示
  - 美观的 Git 状态显示

### 4. 0xProto 字体

- **0xProto** - 等宽编程字体
- **自动安装**：
  - macOS: `~/Library/Fonts`
  - Linux: `~/.local/share/fonts` 或 `~/.fonts`
- **自动刷新字体缓存**（Linux）

## ⚙️ 配置说明

### Starship 配置

配置文件位置：`~/.config/starship.toml`

脚本会自动：
1. 从 GitHub 下载最新配置
2. 备份现有配置（如果存在）
3. 在 `.zshrc` 中添加初始化代码

### Zsh 配置

配置文件位置：`~/.zshrc`

脚本会自动：
1. 备份现有配置
2. 配置 Oh My Zsh 插件
3. 添加常用别名
4. 配置 Starship 提示符

### 常用别名

脚本会自动添加以下别名：

```bash
# 文件操作
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Docker 相关
alias d='docker'
alias dc='docker-compose'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'
alias dcl='docker-compose logs -f'
alias dps='docker ps'
alias dpsa='docker ps -a'
```

## 🔄 使用脚本

### 首次运行

脚本会自动检测系统类型并安装所需组件：

```bash
./bootstrap.sh
```

### 重新运行

脚本会检测已安装的组件，跳过已安装的部分：

```bash
./bootstrap.sh
```

### 应用配置

安装完成后，需要重新加载配置：

```bash
# 重新加载 Zsh 配置
source ~/.zshrc

# 或者重新打开终端
```

### 切换默认 Shell（首次安装）

```bash
# 切换到 Zsh
chsh -s $(which zsh)

# 重新登录以生效
```

## 🛠️ 高级用法

### 仅安装特定组件

脚本会按顺序安装所有组件。如果需要跳过某些步骤，可以：

1. 手动注释掉 `main()` 函数中的相应函数调用
2. 或者直接调用特定函数（需要先设置环境变量）

### 自定义配置

#### 自定义 Starship 配置

1. 修改 `starship.toml` 文件
2. 或编辑 `~/.config/starship.toml`

#### 自定义 Zsh 配置

编辑 `~/.zshrc` 文件，添加您的自定义配置。

### 卸载组件

#### 卸载 Oh My Zsh

```bash
uninstall_oh_my_zsh
```

#### 卸载 Starship

```bash
# macOS (Homebrew)
brew uninstall starship

# Linux
rm -f ~/.local/bin/starship
rm -f ~/.config/starship.toml
```

#### 卸载 Docker

```bash
# macOS
brew uninstall --cask docker

# Linux
sudo apt-get purge docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

## ❓ 常见问题

### Q: 脚本执行失败怎么办？

A: 检查以下几点：
1. 确保有 `sudo` 权限（Linux）
2. 检查网络连接
3. 查看错误信息，根据提示操作

### Q: Docker 命令需要 sudo 怎么办？

A: Linux 系统需要重新登录以使 docker 组权限生效：
```bash
# 重新登录或运行
newgrp docker
```

### Q: 字体没有正确显示？

A: 
1. 重启终端应用
2. 在终端设置中选择 0xProto 字体
3. Linux 系统确保字体缓存已刷新

### Q: Starship 提示符没有显示？

A: 
1. 确保已运行 `source ~/.zshrc`
2. 检查 `~/.config/starship.toml` 是否存在
3. 验证 Starship 是否已安装：`starship --version`

### Q: 如何更新配置？

A: 重新运行脚本，它会自动下载最新配置并备份现有配置。

### Q: 支持哪些 Linux 发行版？

A: 支持所有主流 Linux 发行版，包括：
- Debian/Ubuntu
- CentOS/RHEL
- Fedora
- Arch Linux
- openSUSE
- Alpine Linux

## 📝 文件说明

```
server-bootstrap/
├── bootstrap.sh      # 主安装脚本
├── starship.toml     # Starship 配置文件（可选，会自动下载）
├── 0xProto.zip       # 字体文件（可选，会自动下载）
└── README.md         # 项目文档
```

## 🔧 技术细节

### 自动安装工具

脚本会自动检测并安装以下工具（如缺失）：
- `curl` - 优先安装
- `wget` - curl 不可用时的备选

### 下载源

- **Starship 配置**: `https://raw.githubusercontent.com/Nanako718/server-bootstrap/main/starship.toml`
- **0xProto 字体**: `https://github.com/Nanako718/server-bootstrap/raw/main/0xProto.zip`

### 配置文件备份

脚本会自动备份以下文件：
- `~/.zshrc` → `~/.zshrc.backup.YYYYMMDD_HHMMSS`
- `~/.config/starship.toml` → `~/.config/starship.toml.backup.YYYYMMDD_HHMMSS`

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献指南

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [Oh My Zsh](https://ohmyz.sh/) - Zsh 配置框架
- [Starship](https://starship.rs/) - 跨 shell 提示符
- [Docker](https://www.docker.com/) - 容器化平台
- [0xProto](https://github.com/0xType/0xProto) - 编程字体

## 📞 联系方式

如有问题或建议，请：
- 提交 [Issue](https://github.com/Nanako718/server-bootstrap/issues)
- 发送 Pull Request

---

**⭐ 如果这个项目对您有帮助，请给个 Star！**

