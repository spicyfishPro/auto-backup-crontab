#!/bin/bash

export HOME="/data4/user4/caozh"

# ================= CRONTAB 专用环境配置 (新增) =================
# 1. 强制加载系统配置，确保基础命令可用
source /etc/profile
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"

# 2. 显式设置 PATH，防止找不到 fd, rsync, git 等命令
# 建议通过 'which fd' 查看你的 fd 安装位置，并确保它在下面的路径中
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/bin:$PATH

# 3. 指定 SSH 密钥 (关键！)
# Cron 无法访问 ssh-agent，必须告诉 git 使用哪个私钥。
# 请将 id_rsa 替换为你实际用于 GitHub 的私钥文件名
export GIT_SSH_COMMAND='ssh -i "$HOME/.ssh/id_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
# ============================================================

source activate storage_monitor

# ================= 配置区域 =================
# 备份仓库的绝对路径
BACKUP_DIR="$HOME/my_script_backup"

# 1. 设置最大文件大小 (fd 格式)
MAX_SIZE="-100m"

# 2. 构建搜索正则
SEARCH_PATTERN="\.(sh|sbatch|py|R|r|html|js|yaml|json|yml)$|^(Dockerfile|Makefile|requirements\.txt)$"

# GitHub 分支
BRANCH="main"

# 日志文件 (建议使用绝对路径)
LOG_FILE="$HOME/backup_log.txt"

# Conda 环境备份存放的子目录 (在备份仓库内)
CONDA_BACKUP_DIR="$BACKUP_DIR/conda_envs"

# 排除目录
EXCLUDES=(
    # --- 自身备份目录 ---
    --exclude "my_script_backup"
    
    # --- 版本控制 ---
    --exclude ".git"
    --exclude ".svn"
    --exclude ".hg"

    # --- 常见语言依赖与环境 (体积巨大) ---
    --exclude "node_modules"       # Node.js
    --exclude ".venv"              # Python venv
    --exclude "venv"               # Python venv (常见命名)
    --exclude "env"                # Python env
    --exclude "__pycache__"        # Python 编译缓存
    --exclude ".conda"             # Conda 环境
    --exclude "anaconda3"          # Conda 安装目录
    --exclude "miniconda3"         # Conda 安装目录
    --exclude ".rbenv"             # Ruby 环境
    --exclude ".nvm"               # Node 版本管理
    --exclude ".cargo"             # Rust Cargo 目录
    --exclude "target"             # Rust/Maven 构建目录
    --exclude "build"              # 一般构建目录 (Gradle/C++等)
    --exclude "dist"               # 发行目录
    --exclude "vendor"             # Go/PHP 等 vendoring 目录 (视情况可删)

    # --- 编辑器与IDE配置 (无关代码) ---
    --exclude ".idea"              # JetBrains (PyCharm/IntelliJ)
    --exclude ".vscode"            # VS Code
    --exclude ".vs"                # Visual Studio
    --exclude ".settings"          # Eclipse
    --exclude ".ipynb_checkpoints" # Jupyter Notebook 自动保存点

    # --- 系统缓存与临时文件 ---
    --exclude ".cache"             # 系统级缓存
    --exclude "cache"
    --exclude ".npm"               # npm 缓存
    --exclude ".pip"               # pip 缓存
    --exclude ".local"             # 本地安装的程序/垃圾桶 (通常不备份)
    --exclude "tmp"                # 临时文件夹
    --exclude "temp"

    # --- 安全 ---
    --exclude ".ssh"               # SSH 密钥
    --exclude ".aws"               # AWS 凭证
    --exclude ".kube"              # Kubernetes 配置
    --exclude ".gnupg"             # GPG 密钥
    --exclude ".config"
)

# ===========================================

{
    echo "========================================="
    echo "Backup started at $(date)"

    # 0. 检查依赖命令是否存在 (防止静默失败)
    if ! command -v fd &> /dev/null; then
        echo "Error: 'fd' command not found. Please check PATH in script."
        exit 1
    fi

    # 1. 准备 Git 环境
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Creating backup directory..."
        mkdir -p "$BACKUP_DIR"
    fi

    cd "$BACKUP_DIR" || { echo "Failed to cd to $BACKUP_DIR"; exit 1; }
    
    # 初始化 git (如果不存在)
    if [ ! -d ".git" ]; then
        echo "Initializing git repository..."
        git init
        git remote add origin "git@github.com:YourUsername/YourRepo.git" # 请替换为实际地址
    fi

    # 尝试拉取 (忽略错误，比如第一次运行时)
    git pull origin "$BRANCH" > /dev/null 2>&1

    # 2. 文件同步 (rsync)
    cd "$HOME" || { echo "Failed to cd to HOME"; exit 1; }
    echo "Scanning and syncing files..."

    # shellcheck disable=SC2086
    fd -H \
       --type f \
       --size "$MAX_SIZE" \
       "${EXCLUDES[@]}" \
       "$SEARCH_PATTERN" \
       --print0 \
    | rsync -av --files-from=- --from0 . "$BACKUP_DIR"

    # ================= [修改] 备份 Conda 环境 =================
    echo "Backing up Conda environments..."
    
    # 尝试加载 conda (解决 cron 执行时可能找不到 conda 命令的问题)
    # 增加了对 .bashrc 的依赖，但为了保险，保留手动 source
    CONDA_PATH=""
    if command -v conda &> /dev/null; then
        CONDA_PATH=$(which conda)
    else
        # 常见安装路径遍历
        for path in "$HOME/miniconda3" "$HOME/anaconda3" "/usr/local/miniconda3" "/opt/conda"; do
            if [ -f "$path/etc/profile.d/conda.sh" ]; then
                source "$path/etc/profile.d/conda.sh"
                break
            fi
        done
    fi

    if command -v conda &> /dev/null; then
        mkdir -p "$CONDA_BACKUP_DIR"
        
        # 优化解析逻辑，处理 base 环境和带 * 号的行
        conda env list | grep -v "^#" | grep -v "^$" | while read -r line; do
            # 提取环境名（第一列）
            env_name=$(echo "$line" | awk '{print $1}')
            
            # 如果第一列包含路径符 /，说明该环境没有名字（通常是 prefix 环境），建议跳过或使用 basename
            if [[ "$env_name" == *"/"* ]]; then
                 echo "Skipping unnamed environment at: $env_name"
                 continue
            fi

            echo "Exporting environment: $env_name"
            # 导出 yaml，过滤 prefix 避免跨机器路径问题
            conda env export -n "$env_name" | grep -v "^prefix: " > "$CONDA_BACKUP_DIR/${env_name}.yml"
        done
        echo "Conda environments exported to $CONDA_BACKUP_DIR"
    else
        echo "Warning: 'conda' command not found. Skipping environment backup."
        echo "Debug info: PATH is $PATH"
    fi
    # ========================================================

    # 4. Git 提交部分
    cd "$BACKUP_DIR" || exit 1
    git add .

    # 只有当有变更时才提交
    if git status --porcelain | grep .; then
        git commit -m "Auto backup: $(date +'%Y-%m-%d %H:%M:%S')"
        
        # 捕获 push 错误
        if ! git push origin "$BRANCH"; then
             echo "Error: Git push failed. Check SSH keys and network."
        else
             echo "Changes pushed to GitHub."
        fi
    else
        echo "No changes detected."
    fi

    # 5. Git 仓库维护
    # git gc 会自动压缩文件、清理悬空对象，保持仓库体积最小
    echo "Running git maintenance..."
    git gc --auto

    echo "Backup finished at $(date)"

} >> "$LOG_FILE" 2>&1

