# personhood-installer

> 一句话安装 OpenClaw 人格化成长系统到目标 agent

## 触发条件

- 用户提到"安装人格化系统"、"部署 personhood"、"配置人格成长"
- 用户提到"一键配置"、"初始化人格"
- 用户说"把人格化系统装到 xxx"

## 完整工作流

本 skill 覆盖安装全流程，无需人工介入。AI 只需要一句指令就能跑完。

### 步骤 1: 环境检查 (AI 执行)

依次执行以下命令并记录结果：

```bash
# 1. 检查 OpenClaw 版本
openclaw --version

# 2. 读取 openclaw.json 检查配置
cat ~/.openclaw/openclaw.json | grep -E "(heartbeat|memorySearch|<目标agent>)" -A2 -B1

# 3. 确认 cron 目录存在
ls -la ~/.openclaw/cron/ 2>/dev/null || echo "cron 目录不存在"
```

**判断规则**:
- 版本 < 0.9.0 → 记录警告，继续安装
- heartbeat 未启用 → 记录警告，继续安装（light 模式不可用但其他功能正常）
- memorySearch 未启用 → 记录警告，继续安装（语义检索受限）
- agent 不存在 → **报错退出**，提示用户先创建: `openclaw agent create <name>`
- cron 目录不存在 → 自动创建

### 步骤 2: 定位安装包

```bash
# 依次查找包位置
for path in \
  ~/.openclaw/personhood-package \
  ~/.openclaw/workspace-mia/personhood-package \
  $(pwd)/../personhood-package; do
  if [[ -d "$path" ]]; then
    echo "PACKAGE_PATH=$path"
    break
  fi
done
```

如果找不到包，报错。

### 步骤 3: 创建目录结构

```bash
# 在目标 workspace 创建目录
TARGET_WS=~/.openclaw/workspace-<目标agent>
mkdir -p "$TARGET_WS/memory/inbox"
mkdir -p "$TARGET_WS/skills/personhood-document-maintainer"
mkdir -p "$TARGET_WS/docs/personhood"
```

### 步骤 4: 复制文件

```bash
# 复制模板到 memory/
cp "$PACKAGE_PATH/templates/world.md" "$TARGET_WS/memory/world.md"
cp "$PACKAGE_PATH/templates/self.md" "$TARGET_WS/memory/self.md"
cp "$PACKAGE_PATH/templates/expression.md" "$TARGET_WS/memory/expression.md"
cp "$PACKAGE_PATH/templates/inbox-README.md" "$TARGET_WS/memory/inbox/README.md"

# 复制 skill
cp "$PACKAGE_PATH/skills/personhood-document-maintainer/SKILL.md" \
   "$TARGET_WS/skills/personhood-document-maintainer/SKILL.md"

# 复制文档
cp "$PACKAGE_PATH/docs/"*.md "$TARGET_WS/docs/personhood/"
```

### 步骤 5: 配置 cron

检查是否有 `openclaw cron` 命令可用。如果可用，添加任务；否则输出手动添加指令。

### 步骤 6: 验证安装

```bash
# 检查关键文件都存在
for f in \
  "$TARGET_WS/memory/world.md" \
  "$TARGET_WS/memory/self.md" \
  "$TARGET_WS/memory/expression.md" \
  "$TARGET_WS/memory/inbox/README.md" \
  "$TARGET_WS/skills/personhood-document-maintainer/SKILL.md"; do
  if [[ -f "$f" ]]; then
    echo "OK: $f"
  else
    echo "MISSING: $f"
  fi
done
```

## 输出要求

安装完成后，输出：

```
✅ 人格化系统安装完成！

【已创建】
- memory/world.md
- memory/self.md  
- memory/expression.md
- memory/inbox/
- skills/personhood-document-maintainer/
- docs/personhood/

【已配置 cron】
- <agent>-memory-daily-distill (每日 23:30)
- <agent>-agent-self-evolution (每周日 02:00)
- <agent>-capability-evolver (每周日 02:20)

【环境警告】
- <如有>

【下一步】
- 可以运行一次 normal 模式维护初始化内容
- 查看 docs/personhood/ 了解方案详情
```

## 错误处理

- **环境检查失败**: 输出具体缺少什么、怎么修复，然后退出
- **文件已存在**: 默认跳过（不覆盖），除非用户加了 --force
- **权限问题**: 输出需要手动执行的命令

## 边界

本 skill 只负责**全新安装**。不负责：
- 卸载（用 --uninstall 参数）
- 升级（先卸载再安装）
- 迁移旧数据（用户自己整理）

## 包路径

包应该放在一个 AI 能自动找到的位置。

**默认路径**: `~/.openclaw/workspace-mia/personhood-package/`

AI 在执行时，应该按以下顺序查找包：
1. `~/.openclaw/personhood-package/`
2. `~/.openclaw/workspace-mia/personhood-package/`
3. 当前 workspace 的上一级 `../personhood-package/`

如果都找不到，报错提示用户把包放到正确位置。
