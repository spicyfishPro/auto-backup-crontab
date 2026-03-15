# Auto Backup Crontab

自动化个人脚本备份工具,支持文件筛选、Git 版本控制和 Conda 环境导出。

## 主要功能

- **智能文件筛选**: 按大小、类型、排除目录进行文件过滤
- **自动 Git 版本控制**: 自动提交并推送到 GitHub 远程仓库
- **Conda 环境备份**: 自动导出 Conda 环境为 YAML 文件
- **定时任务支持**: 支持通过 crontab 配置定时备份
- **完善的日志记录**: 所有操作记录到日志文件
- **Git 仓库维护**: 自动执行 git gc 保持仓库体积最小

## 适用场景

- 个人开发环境备份
- 脚本版本控制
- 开发环境迁移
- 服务器文件自动同步

## 目标用户

需要自动化备份个人脚本和环境的开发者、系统管理员和数据科学家。

## 技术栈

- **Shell**: Bash
- **文件搜索**: fd
- **文件同步**: rsync
- **版本控制**: git
- **环境管理**: conda (可选)

## 快速开始

### 前置要求检查

在开始之前,请确保以下工具已安装并可用:

```bash
# 检查依赖工具
which fd      # 快速文件搜索工具
which rsync   # 文件同步工具
which git     # 版本控制工具
which conda   # Conda 环境管理工具(可选)

# 验证 SSH 密钥配置
ssh -i ~/.ssh/id_rsa -T git@github.com
```

如果某些工具未安装,请参考 [故障排除](#故障排除) 部分。

### 5 分钟快速配置

#### 1. 克隆仓库

```bash
git clone <repository-url>
cd <repo-name>
```

#### 2. 修改脚本配置(必须)

编辑 `auto_backup_crontab.sh`,根据你的环境修改以下关键配置:

**第3行 - 修改为你的家目录:**
```bash
export HOME="/your/home/path"
```

**第24行 - 设置备份目录:**
```bash
BACKUP_DIR="$HOME/my_script_backup"
```

**第17行 - 配置 SSH 密钥:**
```bash
export GIT_SSH_COMMAND='ssh -i "$HOME/.ssh/id_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
```

**第116行 - 配置 GitHub 仓库:**
```bash
git remote add origin "git@github.com:YourUsername/YourRepo.git"
```

#### 3. 验证配置

```bash
# 测试 SSH 连接
ssh -i ~/.ssh/id_rsa -T git@github.com

# 手动运行一次测试
bash auto_backup_crontab.sh

# 查看日志
tail -f ~/backup_log.txt
```

#### 4. 设置定时任务

```bash
# 编辑 crontab
crontab -e

# 添加以下行(每天凌晨2点执行)
0 2 * * * /bin/bash /path/to/auto_backup_crontab.sh
```

### 重要配置说明

- **HOME 路径**: 脚本第3行硬编码了家目录路径,如果你的家目录不同,请直接修改第3行
- **Conda 环境**: 脚本第20行包含 `source activate storage_monitor`,如果不需要请删除此行
- **SSH 密钥权限**: 确保 SSH 私钥权限正确: `chmod 600 ~/.ssh/id_rsa`

## 详细配置说明

### 配置文件结构

脚本开头的配置区域包含所有可自定义参数:

```bash
# 基本配置
BACKUP_DIR="$HOME/my_script_backup"      # 备份目录
MAX_SIZE="-100m"                         # 最大文件大小限制
SEARCH_PATTERN="\.(sh|py|js|...)$"       # 文件类型匹配正则
BRANCH="main"                            # Git 分支名称
LOG_FILE="$HOME/backup_log.txt"          # 日志文件路径
```

### 关键参数解释

#### MAX_SIZE
最大文件大小限制,使用 fd 格式:
- `-100m`: 小于 100MB 的文件
- `-10m`: 小于 10MB 的文件
- `+100m`: 大于 100MB 的文件

#### SEARCH_PATTERN
文件类型匹配正则表达式,支持:
- 文件扩展名: `\.(sh|py|js)$`
- 特定文件名: `^(Dockerfile|Makefile)$`
- 组合使用: `\.(sh|py)$|^(Dockerfile|Makefile)$`

#### EXCLUDES
排除目录数组,使用 rsync 的 `--exclude` 格式:
```bash
EXCLUDES=(
    --exclude "node_modules"       # 排除特定目录
    --exclude ".git"               # 排除版本控制目录
    --exclude ".env"               # 排除环境配置文件
)
```

#### BRANCH
Git 分支名称,默认为 `main`,可以修改为 `backup` 等自定义分支名。

#### LOG_FILE
日志文件路径,建议使用绝对路径以便于 crontab 定位。

### 自定义排除目录示例

#### 添加新的排除目录

在 `EXCLUDES` 数组中添加新的排除项:

```bash
EXCLUDES=(
    # ... 现有排除项 ...
    --exclude "my_large_project"        # 排除特定项目
    --exclude "temp_files"               # 排除临时文件目录
)
```

#### 常见需要排除的目录类型

| 目录类型 | 排除示例 | 说明 |
|---------|---------|------|
| Node.js | `--exclude "node_modules"` | npm 依赖包 |
| Python | `--exclude ".venv"`, `--exclude "__pycache__"` | 虚拟环境和编译缓存 |
| 构建产物 | `--exclude "build"`, `--exclude "dist"` | 编译和打包文件 |
| IDE 配置 | `--exclude ".idea"`, `--exclude ".vscode"` | 编辑器配置 |
| 缓存 | `--exclude ".cache"`, `--exclude ".npm"` | 系统和工具缓存 |

#### 敏感目录建议

强烈建议排除以下敏感目录:

```bash
EXCLUDES=(
    --exclude ".ssh"               # SSH 密钥
    --exclude ".aws"               # AWS 凭证
    --exclude ".kube"              # Kubernetes 配置
    --exclude ".env"               # 环境变量文件
    --exclude "*.key"              # 密钥文件
)
```

### Conda 环境备份配置

脚本会自动检测 conda 安装路径并导出所有命名环境:

#### 自动检测路径
脚本会按以下顺序搜索 conda 安装:
1. 系统路径中的 `conda` 命令
2. `$HOME/miniconda3`
3. `$HOME/anaconda3`
4. `/usr/local/miniconda3`
5. `/opt/conda`

#### 导出目录结构
Conda 环境会导出到 `$CONDA_BACKUP_DIR` (默认为 `$BACKUP_DIR/conda_envs`):

```
my_script_backup/
├── conda_envs/
│   ├── base.yml
│   ├── storage_monitor.yml
│   └── other_env.yml
└── ...
```

#### 环境处理规则
- **base 环境**: 正常导出
- **命名环境**: 导出为 `<env_name>.yml`
- **无名环境**: 跳过并记录警告
- **路径前缀**: 自动过滤以避免跨机器路径问题

### Git 配置和 SSH 密钥设置

#### GIT_SSH_COMMAND 环境变量

脚本第17行设置 SSH 命令:

```bash
export GIT_SSH_COMMAND='ssh -i "$HOME/.ssh/id_rsa" -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'
```

参数说明:
- `-i "$HOME/.ssh/id_rsa"`: 指定 SSH 私钥路径
- `-o UserKnownHostsFile=/dev/null`: 忽略已知主机文件(安全警告)
- `-o StrictHostKeyChecking=no`: 禁用严格主机检查(安全警告)

#### 安全建议

生产环境建议使用更安全的配置:

```bash
export GIT_SSH_COMMAND='ssh -i "$HOME/.ssh/id_rsa"'
```

#### GitHub 远程仓库配置

脚本第116行设置远程仓库:

```bash
git remote add origin "git@github.com:YourUsername/YourRepo.git"
```

请替换为你的实际 GitHub 仓库地址。

### 常见配置场景示例表格

| 场景 | 修改参数 | 示例值 | 说明 |
|------|----------|--------|------|
| 只备份小文件 | MAX_SIZE | `"-10m"` | 只备份小于10MB的文件 |
| 备份更多文件类型 | SEARCH_PATTERN | `"\.(sh\|py\|js\|cpp\|java)$"` | 添加 .cpp 和 .java |
| 排除特定项目 | EXCLUDES | `--exclude "project_name"` | 添加到 EXCLUDES 数组 |
| 使用不同分支 | BRANCH | `"backup"` | 修改为 backup 分支 |
| 自定义日志位置 | LOG_FILE | `"$HOME/logs/backup.log"` | 修改为自定义路径 |

## 使用示例

### 手动执行备份

```bash
# 直接执行脚本
bash auto_backup_crontab.sh

# 或者赋予执行权限后直接运行
chmod +x auto_backup_crontab.sh
./auto_backup_crontab.sh
```

### 查看日志

```bash
# 查看完整日志
cat ~/backup_log.txt

# 实时监控日志
tail -f ~/backup_log.txt

# 查看最近 50 行
tail -n 50 ~/backup_log.txt
```

### 不同配置场景示例

#### 只备份特定文件类型

修改 `SEARCH_PATTERN`:

```bash
# 只备份 Shell 和 Python 脚本
SEARCH_PATTERN="\.(sh|py)$"
```

#### 备份特定大小的文件

修改 `MAX_SIZE`:

```bash
# 只备份小于 50MB 的文件
MAX_SIZE="-50m"
```

#### 排除特定项目目录

修改 `EXCLUDES` 数组:

```bash
EXCLUDES=(
    # ... 其他排除项 ...
    --exclude "large_project"
    --exclude "experimental"
)
```

### 验证备份结果

#### 检查 Git 仓库状态

```bash
cd $BACKUP_DIR
git status
git log --oneline -10
```

#### 查看备份的文件列表

```bash
# 查看备份目录结构
tree $BACKUP_DIR

# 或使用 find
find $BACKUP_DIR -type f | head -20
```

#### 验证 Conda 环境备份文件

```bash
# 列出导出的环境文件
ls -lh $CONDA_BACKUP_DIR

# 查看特定环境内容
cat $CONDA_BACKUP_DIR/storage_monitor.yml
```

## 故障排除

### fd 命令找不到的问题

#### 问题症状
```
fd: command not found
Error: 'fd' command not found. Please check PATH in script.
```

#### 解决方案

1. **检查 PATH 配置**
   确保脚本第12行的 PATH 包含 fd 的安装位置:
   ```bash
   export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/bin:$PATH
   ```

2. **手动查找 fd 位置**
   ```bash
   which fd
   find /usr -name fd 2>/dev/null
   ```

3. **安装 fd 命令**
   ```bash
   # 使用 cargo 安装
   cargo install fd-find

   # 或使用包管理器 (根据你的发行版)
   sudo apt install fd-find  # Debian/Ubuntu
   sudo yum install fd-find  # RHEL/CentOS
   ```

4. **更新脚本 PATH**
   如果 fd 安装在非标准路径,更新脚本第12行:
   ```bash
   export PATH=/path/to/fd:$PATH
   ```

### Git push 失败的处理

#### SSH 密钥配置问题

**症状:**
```
Permission denied (publickey).
fatal: Could not read from remote repository.
```

**解决方案:**

1. 检查 SSH 密钥是否存在:
   ```bash
   ls -la ~/.ssh/id_rsa
   ```

2. 验证密钥权限:
   ```bash
   chmod 600 ~/.ssh/id_rsa
   chmod 700 ~/.ssh
   ```

3. 测试 SSH 连接:
   ```bash
   ssh -i ~/.ssh/id_rsa -T git@github.com
   ```

4. 检查脚本中的 GIT_SSH_COMMAND(第17行):
   ```bash
   export GIT_SSH_COMMAND='ssh -i "$HOME/.ssh/id_rsa"'
   ```

#### GitHub 仓库权限问题

**症状:**
```
ERROR: Repository not found.
fatal: Could not read from remote repository.
```

**解决方案:**

1. 确认仓库地址正确(第116行):
   ```bash
   git remote -v
   ```

2. 确认 SSH 密钥已添加到 GitHub:
   - 访问 GitHub Settings → SSH and GPG keys
   - 添加你的公钥: `cat ~/.ssh/id_rsa.pub`

3. 验证 GitHub 账户权限:
   ```bash
   ssh -i ~/.ssh/id_rsa -T git@github.com
   # 应该显示: Hi username! You've successfully authenticated...
   ```

#### 网络连接问题

**症状:**
```
ssh: connect to host github.com port 22: Connection timed out
```

**解决方案:**

1. 测试网络连接:
   ```bash
   ping github.com
   curl -I https://github.com
   ```

2. 检查防火墙设置:
   ```bash
   sudo iptables -L | grep 22
   ```

3. 尝试使用 HTTPS (临时解决方案):
   ```bash
   git remote set-url origin https://github.com/YourUsername/YourRepo.git
   ```

#### 错误日志查看方法

查看详细错误信息:
```bash
# 查看完整日志
cat ~/backup_log.txt

# 搜索错误信息
grep -i "error\|fail\|fatal" ~/backup_log.txt

# 查看最近的备份运行情况
tail -50 ~/backup_log.txt
```

### Conda 环境导出问题

#### conda 命令找不到

**症状:**
```
Warning: 'conda' command not found. Skipping environment backup.
```

**解决方案:**

1. **检查 conda 是否已安装:**
   ```bash
   which conda
   conda --version
   ```

2. **安装 conda (如果未安装):**
   - 下载 Miniconda: https://docs.conda.io/en/latest/miniconda.html
   - 或下载 Anaconda: https://www.anaconda.com/

3. **更新脚本环境激活(第20行):**
   ```bash
   # 如果不需要 conda,删除或注释掉此行
   # source activate storage_monitor
   ```

#### 环境路径检测失败

**症状:**
脚本无法自动找到 conda 安装路径。

**解决方案:**

1. **手动指定 conda 路径:**
   在脚本第20行之前添加:
   ```bash
   source ~/miniconda3/etc/profile.d/conda.sh  # 或你的实际路径
   ```

2. **检查 conda 路径是否在脚本搜索列表中:**
   脚本搜索的路径(第145行):
   ```bash
   for path in "$HOME/miniconda3" "$HOME/anaconda3" "/usr/local/miniconda3" "/opt/conda"; do
   ```

3. **验证 conda.sh 文件存在:**
   ```bash
   ls -la ~/miniconda3/etc/profile.d/conda.sh
   ```

#### YAML 导出失败处理

**症状:**
环境导出过程中出现错误。

**解决方案:**

1. **手动测试环境导出:**
   ```bash
   conda env list
   conda env export -n my_env | head -20
   ```

2. **检查磁盘空间:**
   ```bash
   df -h $BACKUP_DIR
   ```

3. **查看详细错误日志:**
   ```bash
   grep -A 10 "Exporting environment:" ~/backup_log.txt
   ```

4. **处理损坏的环境:**
   ```bash
   conda create -n new_env --clone old_env
   conda remove -n old_env --all
   ```

### 日志调试方法

#### 查看完整日志

```bash
# 实时监控日志
tail -f ~/backup_log.txt

# 查看最近的日志
tail -100 ~/backup_log.txt

# 搜索特定时间段
grep "2026-03-15" ~/backup_log.txt
```

#### 启用详细输出模式

脚本输出已重定向到日志文件,可以通过以下方式查看详细执行过程:

```bash
# 查看脚本执行的所有命令
set -x  # 在脚本中添加(临时调试)

# 或直接查看日志中的命令执行
bash -x auto_backup_crontab.sh 2>&1 | tee debug.log
```

#### 常见错误信息解读

| 错误信息 | 可能原因 | 解决方案 |
|---------|---------|---------|
| `fd: command not found` | fd 未安装或不在 PATH 中 | 安装 fd 或更新 PATH |
| `git push failed` | SSH 密钥配置或网络问题 | 检查 SSH 配置和网络连接 |
| `Permission denied` | 文件权限不足 | `chmod +x auto_backup_crontab.sh` |
| `No space left on device` | 磁盘空间不足 | 清理磁盘空间或修改备份策略 |
| `conda: command not found` | conda 未安装或配置错误 | 安装 conda 或删除环境激活行 |

### Git 冲突处理

如果远程仓库有新提交导致推送失败:

```bash
# 进入备份目录
cd $BACKUP_DIR

# 查看冲突状态
git status

# 使用 rebase 解决冲突
git pull --rebase origin main

# 如果有冲突,手动解决后:
git add .
git rebase --continue

# 推送到远程
git push origin main
```

### 权限和安全问题

#### SSH 私钥权限

确保 SSH 私钥权限正确:

```bash
# 设置正确的权限
chmod 600 ~/.ssh/id_rsa
chmod 700 ~/.ssh

# 验证权限
ls -la ~/.ssh/id_rsa
# 应该显示: -rw------- (只有所有者可读写)
```

#### StrictHostKeyChecking 警告

当前脚本使用 `-o StrictHostKeyChecking=no` 可能存在安全风险。

**生产环境建议:**

```bash
# 移除不安全选项
export GIT_SSH_COMMAND='ssh -i "$HOME/.ssh/id_rsa"'

# 首次手动连接以添加主机密钥
ssh -i ~/.ssh/id_rsa git@github.com

# 或使用已知主机文件
export GIT_SSH_COMMAND='ssh -i "$HOME/.ssh/id_rsa" -o UserKnownHostsFile=~/.ssh/known_hosts'
```

#### 敏感信息泄露检查

定期检查备份仓库,确保没有泄露敏感信息:

```bash
# 搜索可能包含敏感信息的文件
find $BACKUP_DIR -type f -name "*.env" -o -name "*.key" -o -name "*.pem"

# 检查日志中是否包含敏感信息
grep -i "password\|secret\|token" ~/backup_log.txt

# 使用 git history 检查是否曾提交过敏感文件
cd $BACKUP_DIR
git log --all --full-history --source -- "*.env" "*.key" "*.pem"
```

## 贡献指南

### 如何报告问题

如果你遇到问题或发现 bug,请通过 GitHub Issues 报告:

1. **使用清晰的标题**: 简要描述问题
2. **提供环境信息**:
   ```bash
   uname -a                    # 系统信息
   bash --version              # Bash 版本
   fd --version                # fd 版本
   git --version               # Git 版本
   conda --version             # Conda 版本(如适用)
   ```
3. **提供错误日志**: 附上 `~/backup_log.txt` 中的相关错误信息
4. **清晰描述复现步骤**: 详细说明如何重现问题

### 如何提交改进建议

我们欢迎任何改进建议:

1. **功能建议**: 通过 Issue 提出新功能想法
2. **Bug 修复**: 通过 Pull Request 提交代码修复
3. **文档改进**: 帮助改进文档的准确性和完整性
4. **性能优化**: 提出或实现性能改进方案

### 开发环境设置

1. **Fork 仓库**:
   - 点击 GitHub 页面上的 "Fork" 按钮
   - 克隆你的 fork:
     ```bash
     git clone https://github.com/YourUsername/auto-backup-crontab.git
     cd auto-backup-crontab
     ```

2. **创建特性分支**:
   ```bash
   git checkout -b feature/my-feature
   ```

3. **本地测试**:
   ```bash
   # 修改配置以适应你的环境
   vim auto_backup_crontab.sh

   # 测试脚本
   bash auto_backup_crontab.sh

   # 查看结果
   tail -f ~/backup_log.txt
   ```

4. **提交更改**:
   ```bash
   git add .
   git commit -m "feat: add my feature"
   git push origin feature/my-feature
   ```

5. **创建 Pull Request**: 在 GitHub 上创建 PR,描述你的更改

### 代码风格规范

#### Shell 脚本代码风格

- **缩进**: 使用 4 个空格,不使用 Tab
- **变量命名**: 使用大写加下划线: `MY_VARIABLE`
- **函数命名**: 使用小写加下划线: `my_function`
- **注释**: 使用 `#` 进行注释,重要逻辑必须添加注释

```bash
# 好的示例
MY_VAR="value"

my_function() {
    # 这是一个有用的注释
    local local_var="local value"
    echo "$local_var"
}
```

#### 注释规范

- **文件头注释**: 描述脚本用途和作者
- **函数注释**: 说明函数参数和返回值
- **复杂逻辑注释**: 解释难以理解的代码

```bash
#!/bin/bash
#
# Auto Backup Crontab Script
# Author: Your Name
# Description: Automated backup script with file filtering and Git integration
#

# ===========================================
# Function: backup_files
# Parameters: $1 - source directory, $2 - destination directory
# Returns: 0 on success, 1 on failure
# ===========================================
backup_files() {
    local src_dir="$1"
    local dest_dir="$2"

    # 复制文件,排除特定目录
    rsync -av --exclude="node_modules" "$src_dir/" "$dest_dir/"
}
```

#### 提交信息规范 (Conventional Commits)

使用以下格式的提交信息:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型 (type):**
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 重构
- `test`: 测试相关
- `chore`: 构建/工具相关

**示例:**

```bash
# 功能添加
git commit -m "feat: add support for excluding specific file types"

# Bug 修复
git commit -m "fix: resolve conda environment export failure on CentOS"

# 文档更新
git commit -m "docs: update installation instructions for Windows users"
```

## 技术细节

### 核心组件

1. **文件同步模块**: 使用 `fd` + `rsync` 组合
2. **Git 管理模块**: 自动化 add/commit/push/gc
3. **Conda 环境模块**: 环境检测和 YAML 导出
4. **日志记录模块**: 所有操作记录到日志文件

### 依赖关系

```
auto_backup_crontab.sh
├── fd (文件查找)
├── rsync (文件同步)
├── git (版本控制)
├── conda (环境管理,可选)
└── bash (执行环境)
```

### 工作流程

```
[定时触发] → [加载环境] → [检查依赖] → [文件扫描] → [文件同步]
    ↓                                                              ↓
[日志记录] ← [Git提交] ← [Conda导出] ← [Conda环境检测] ← [文件筛选]
    ↓
[Git推送] → [仓库维护] → [完成]
```

## 关键文件路径

- **主脚本**: `/data4/user4/caozh/bin/auto_backup_crontab.sh`
- **备份目录**: `/data4/user4/caozh/my_script_backup`
- **日志文件**: `/data4/user4/caozh/backup_log.txt`
- **Conda 备份目录**: `/data4/user4/caozh/my_script_backup/conda_envs`

## 安全配置建议

### 1. SSH 密钥保护

```bash
# 确保 SSH 私钥权限正确
chmod 600 ~/.ssh/id_rsa
chmod 700 ~/.ssh

# 生产环境建议移除 StrictHostKeyChecking=no
export GIT_SSH_COMMAND='ssh -i "$HOME/.ssh/id_rsa"'
```

### 2. 敏感文件保护

- 检查排除列表是否包含所有敏感目录
- 建议添加 `--exclude ".env"` 和 `--exclude "*.key"`
- 定期检查备份仓库,确保没有泄露敏感信息

```bash
# 添加到 EXCLUDES 数组
EXCLUDES=(
    # ... 其他排除项 ...
    --exclude ".env"       # 环境变量文件
    --exclude "*.key"      # 密钥文件
    --exclude "*.pem"      # PEM 格式密钥
    --exclude ".secrets"   # 密钥目录
)
```

### 3. 日志文件管理

- 定期清理或轮转日志文件,避免占用过多磁盘空间
- 建议在脚本中添加日志大小检查逻辑

```bash
# 在脚本开头添加日志清理逻辑
if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(du -m "$LOG_FILE" | cut -f1)
    if [ "$LOG_SIZE" -gt 100 ]; then
        # 保留最后 1000 行
        tail -n 1000 "$LOG_FILE" > "${LOG_FILE}.tmp"
        mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
fi
```

## 性能和维护建议

### 1. 性能考虑

- **备份耗时**: 取决于文件数量和网络速度
- **时间窗口**: 可以设置备份时间避免网络高峰
- **大量文件**: 对于大量文件,考虑分批备份

**优化建议:**

```bash
# 只在工作日执行备份
0 2 * * 1-5 /bin/bash /path/to/auto_backup_crontab.sh

# 或使用更精确的时间窗口
0 2 * * * /bin/bash /path/to/auto_backup_crontab.sh
```

### 2. 维护建议

- **定期清理**: 执行 `git gc` 手动清理仓库(脚本已包含 `git gc --auto`)
- **磁盘检查**: 定期检查磁盘空间使用情况
- **日志轮转**: 设置日志轮转策略

```bash
# 手动执行仓库清理
cd $BACKUP_DIR
git gc --aggressive --prune=now

# 检查磁盘使用
df -h
du -sh $BACKUP_DIR
```

### 3. 监控和告警

- **监控脚本**: 可以添加监控脚本来检查备份是否成功
- **通知机制**: 建议设置邮件或消息通知(如备份失败时)

**监控脚本示例:**

```bash
#!/bin/bash
# backup_monitor.sh - 监控备份是否成功

LOG_FILE="$HOME/backup_log.txt"
THRESHOLD_HOURS=24

# 检查日志最后修改时间
if [ -f "$LOG_FILE" ]; then
    LAST_RUN=$(stat -c %Y "$LOG_FILE")
    CURRENT_TIME=$(date +%s)
    DIFF_HOURS=$(( (CURRENT_TIME - LAST_RUN) / 3600 ))

    if [ "$DIFF_HOURS" -gt "$THRESHOLD_HOURS" ]; then
        # 发送告警(这里使用 echo,实际可以使用 mail 或其他通知工具)
        echo "WARNING: Backup has not run in $DIFF_HOURS hours"
    fi
fi
```

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 作者

caozh

## 致谢

感谢以下开源项目:
- [fd](https://github.com/sharkdp/fd) - 快速文件搜索工具
- [rsync](https://rsync.samba.org/) - 文件同步工具
- [git](https://git-scm.com/) - 版本控制系统
- [conda](https://conda.io/) - 包和环境管理系统

## 更新日志

### 版本历史

- **v1.0.0** (2026-03-15)
  - 初始版本发布
  - 支持文件筛选和同步
  - 集成 Git 版本控制
  - Conda 环境导出功能
  - Crontab 定时任务支持

## 相关资源

- [Git 文档](https://git-scm.com/doc)
- [fd 使用指南](https://github.com/sharkdp/fd#usage)
- [rsync 手册](https://linux.die.net/man/1/rsync)
- [Conda 文档](https://docs.conda.io/en/latest/)
- [Crontab 快速参考](https://crontab.guru/)
