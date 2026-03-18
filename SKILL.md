---
name: agent-bootstrap-kit
description: >
  OpenClaw 智能体通用启动包。一键完成"记忆体系 + 人格文档 + 通用技能 +
  安全体系 + 定时任务"全套配置。新建子智能体时使用。
  
  触发条件：用户提到"新建智能体"、"创建新 agent"、"一键配置"、
  "通用启动包"、"新智能体初始化"。
  
  也适用于：修复已有智能体的记忆体系、补充缺失的 skill、
  重新生成 cron 任务、整理不规范的工作区。
---

# 🤖 Agent Bootstrap Kit — 通用智能体启动包

> 版本：v1.0.0  
> 位置：`~/.openclaw/agent-bootstrap-kit/`  
> 适用场景：新智能体初始化 / 已有智能体修复

---

## 核心能力

1. **人格文档体系** — SOUL.md / AGENTS.md / IDENTITY.md / HEARTBEAT.md
2. **记忆系统** — 四层记忆体系 + 每日 memory 文件模板
3. **通用技能** — 安全系 + 通用 skill（20+ 个）
4. **安全体系** — 四层防御（卫士虾 + clawdefender + skill-vetter）
5. **定时任务** — 日蒸馏 + 周提升，槽位自动错开

---

## 使用场景

### 场景 1：新智能体初始化

**前提：** workspace 已创建（通过 `openclaw agents add <agent_id>`）

```bash
bash ~/.openclaw/agent-bootstrap-kit/scripts/install.sh mia --name Mia
```

自动完成：
- 安装 20+ 个通用 skill（软链接）
- 复制人格模板（SOUL.md / AGENTS.md / IDENTITY.md / HEARTBEAT.md）
- 创建 memory/ 目录结构
- 生成今日 memory 文件
- 创建日蒸馏 cron（日 08:10-21:55 随机错开）
- 创建周提升 cron（周日 02:00-03:00 错开）
- 写入 bootstrap.done 标记

### 场景 2：修复已有智能体

```bash
bash ~/.openclaw/agent-bootstrap-kit/scripts/install.sh mia --repair
```

- 不覆盖已有文件（IDENTITY.md / USER.md / MEMORY.md / memory/*.md）
- 只补充缺失的模板和安全 skill
- 重新生成 cron 任务（保留已有任务 ID，只更新时间）

### 场景 3：验证安装状态

```bash
bash ~/.openclaw/agent-bootstrap-kit/scripts/install.sh mia --verify
```

检查：
- workspace 目录
- 核心文件（SOUL.md / AGENTS.md / IDENTITY.md / bootstrap.done）
- skills 数量
- cron 任务数量
- memory 目录

### 场景 4：自定义 cron 时间

```bash
bash ~/.openclaw/agent-bootstrap-kit/scripts/install.sh mia \
  --name Mia \
  --cron-base 2 \
  --slot 1
```

| 参数 | 说明 | 可选值 |
|------|------|--------|
| `--cron-base` | 日蒸馏槽位（决定具体时间） | 0-3 |
| `--slot` | 周提升槽位 | 0-3 |

**槽位时间表：**

日蒸馏：
- 槽位 0 → 08:10
- 槽位 1 → 10:25
- 槽位 2 → 14:40
- 槽位 3 → 21:55

周提升：
- 槽位 0 → 周日 02:00
- 槽位 1 → 周日 02:20
- 槽位 2 → 周日 02:40
- 槽位 3 → 周日 03:00

---

## 包结构

```
~/.openclaw/agent-bootstrap-kit/
├── scripts/
│   └── install.sh          # 主安装脚本
├── templates/
│   ├── personality/        # 人格文档模板
│   ├── memory/             # 记忆文件模板
│   ├── security/           # 安全体系说明
│   └── cron/               # cron 模板
├── config/
│   └── agent-cron-map.json # cron 槽位分配
└── docs/
    └── SPEC.md             # 完整规格说明书
```

---

## 模板变量

安装脚本会自动替换以下变量：

| 变量 | 说明 | 示例 |
|------|------|------|
| `{{AGENT_ID}}` | 智能体 ID | `mia` |
| `{{AGENT_NAME}}` | 智能体名字 | `Mia` |
| `{{INSTALL_DATE}}` | 安装日期 | `2026-03-18` |
| `{{CRON_BASE}}` | 日蒸馏槽位 | `2` |
| `{{CRON_SLOT}}` | 周提升槽位 | `1` |

---

## 技能清单（自动安装）

**安全系（essential）：**
- `tuanziguardianclaw` — 卫士虾核心内核
- `clawdefender` — 输入扫描
- `skill-vetter` — 技能安装审查
- `openclaw-memory-maintainer` — 记忆维护
- `proactive-agent-lite` — 主动记忆架构
- `self-improving` — 自我反思
- `find-skills` — 技能发现

**通用系：**
- `web_search` — 联网搜索
- `openclaw-minimax-router` — MiniMax 搜索/图片
- `image-generation` — 生图
- `social-content` — 社媒内容
- `brainstorming` — 创意工作流
- `pinchtab-browser` — 浏览器自动化
- `feishu-*` — 飞书全家桶（chat/history/cron-reminder/screenshot/send-file）
- `github` — GitHub 操作
- `gmail` — 邮件

---

## 与 agent-creator 的关系

```
agent-creator（官方流程） → bootstrap-kit（深度配置）
         ↓
   创建 workspace
   配置 openclaw.json
         ↓
   调用 bootstrap-kit
         ↓
   一键完成：记忆+人格+技能+安全+cron
```

**bootstrap-kit 依赖 workspace 已存在，不自己调用 `openclaw agents add`。**

---

## 文件覆盖策略

| 文件 | 已有时 | 不存在时 |
|------|--------|---------|
| SOUL.md | 跳过 | 创建 |
| AGENTS.md | 跳过 | 创建 |
| IDENTITY.md | 跳过（repair 模式覆盖） | 创建 |
| HEARTBEAT.md | 跳过（repair 模式覆盖） | 创建 |
| MEMORY.md | 不覆盖 | 创建（空模板） |
| memory/*.md | 不覆盖 | 创建 |
| bootstrap.done | 覆盖 | 创建 |
| skills/* | 跳过已有 | 创建软链接 |

---

## 升级

kit 本身独立于 OpenClaw 更新：

```bash
cd ~/.openclaw/agent-bootstrap-kit && git pull
```

或直接替换 `scripts/install.sh` 和 `templates/` 目录。

---

## 限制

1. 不管理 `openclaw.json` 配置（由 agent-creator 或手动处理）
2. 不处理飞书机器人绑定（用 `openclaw-feishu-agent-bind` skill）
3. 不处理 `openclaw agents add`（需先手动执行）
4. 如果 skill 来源目录被删除，对应 skill 会跳过安装

---

## 后续版本路线图

- v1.1：集成飞书机器人绑定
- v1.2：支持自定义 skill 组合（manifest override）
- v1.3：从已有智能体导出配置作为包模板
