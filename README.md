# Auto Backup Crontab

自动化个人脚本备份工具，支持文件筛选、Git 版本控制和 Conda 环境导出。

## 主要功能

- **智能文件筛选**: 按大小、类型、排除目录进行文件过滤
- **自动 Git 版本控制**: 自动提交并推送到 GitHub 远程仓库
- **Conda 环境备份**: 自动导出 Conda 环境为 YAML 文件
- **定时任务支持**: 支持通过 crontab 配置定时备份
- **完善的日志记录**: 所有操作记录到日志文件

## 快速开始

### 前置要求

确保以下工具已安装:

```bash
which fd      # 文件搜索工具
which rsync   # 文件同步工具
which git     # 版本控制工具
ssh -i ~/.ssh/id_rsa -T git@github.com  # 验证 SSH 密钥
```

### 快速配置

#### 1. 修改脚本配置

编辑 `auto_backup_crontab.sh`，修改以下关键配置:

**第3行 - 家目录:**
```bash
export HOME="/your/home/path"
```

**第24行 - 备份目录:**
```bash
BACKUP_DIR="$HOME/my_script_backup"
```

**第17行 - SSH 密钥:**
```bash
export GIT_SSH_COMMAND='ssh -i "$HOME/.ssh/id_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
```

**第116行 - GitHub 仓库:**
```bash
git remote add origin "git@github.com:YourUsername/YourRepo.git"
```

#### 2. 验证配置

```bash
# 手动运行测试
bash auto_backup_crontab.sh

# 查看日志
tail -f ~/backup_log.txt
```

#### 3. 设置定时任务

```bash
crontab -e
# 添加以下行(每天凌晨2点执行)
0 2 * * * /bin/bash /path/to/auto_backup_crontab.sh
```

## 配置说明

### 关键参数

```bash
BACKUP_DIR="$HOME/my_script_backup"      # 备份目录
MAX_SIZE="-100m"                         # 文件大小限制(-100m = 小于100MB)
SEARCH_PATTERN="\.(sh|py|js)$"           # 文件类型正则
BRANCH="main"                            # Git 分支名称
LOG_FILE="$HOME/backup_log.txt"          # 日志文件路径
```

### 排除目录

在 `EXCLUDES` 数组中添加需要排除的目录:

```bash
EXCLUDES=(
    --exclude "node_modules"       # Node.js 依赖
    --exclude ".git"               # 版本控制目录
    --exclude ".env"               # 环境变量文件
    --exclude ".ssh"               # SSH 密钥
)
```

### Conda 环境

脚本会自动检测 conda 安装并导出所有环境到 `$BACKUP_DIR/conda_envs/`。

如果不需要 Conda 备份，删除脚本第20行的 `source activate storage_monitor`。

## 使用方法

### 手动执行

```bash
bash auto_backup_crontab.sh
```

### 查看日志

```bash
# 实时监控
tail -f ~/backup_log.txt

# 查看最近 50 行
tail -n 50 ~/backup_log.txt
```

### 验证备份

```bash
cd $BACKUP_DIR
git status
git log --oneline -10
```

## 故障排除

### fd 命令找不到

**推荐使用 conda 安装（无需 root 权限）:**

```bash
# 创建非 base 环境安装 fd
conda create -n fd_env fd-find
conda activate fd_env

# 或在现有非 base 环境中安装
conda install -n your_env fd-find
```

**其他安装方式:**
```bash
# 检查 PATH
which fd

# 系统包管理器安装（需要 root 权限）
sudo apt install fd-find  # Debian/Ubuntu
sudo yum install fd-find  # RHEL/CentOS

# 使用 cargo 安装
cargo install fd-find
```

### Git push 失败

**SSH 密钥问题:**
```bash
# 检查密钥权限
chmod 600 ~/.ssh/id_rsa
chmod 700 ~/.ssh

# 测试连接
ssh -i ~/.ssh/id_rsa -T git@github.com
```

**仓库权限问题:**
- 确认第116行仓库地址正确
- 将公钥添加到 GitHub Settings → SSH and GPG keys

### Conda 环境导出失败

```bash
# 检查 conda 是否安装
which conda
conda --version

# 手动导出测试
conda env list
conda env export -n my_env | head -20
```

### 常见错误速查表

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `fd: command not found` | fd 未安装 | 安装 fd 或更新 PATH |
| `git push failed` | SSH 配置或网络 | 检查 SSH 密钥和网络连接 |
| `Permission denied` | 文件权限不足 | `chmod +x auto_backup_crontab.sh` |
| `No space left on device` | 磁盘空间不足 | 清理磁盘空间 |

### 调试日志

```bash
# 启用详细输出模式
bash -x auto_backup_crontab.sh 2>&1 | tee debug.log

# 查看完整日志
cat ~/backup_log.txt
```

## 安全建议

1. **SSH 密钥保护:**
   ```bash
   chmod 600 ~/.ssh/id_rsa
   chmod 700 ~/.ssh
   ```

2. **排除敏感文件:**
   在 `EXCLUDES` 中添加:
   ```bash
   --exclude ".env"
   --exclude "*.key"
   --exclude "*.pem"
   ```

3. **生产环境 SSH 配置:**
   ```bash
   export GIT_SSH_COMMAND='ssh -i "$HOME/.ssh/id_rsa"'
   ```

## 许可证

MIT License

## 作者

caozh