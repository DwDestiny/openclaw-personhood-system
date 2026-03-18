# Agent Bootstrap Kit — 通用智能体启动包规格说明书

**版本：** v1.0.0  
**位置：** `~/.openclaw/agent-bootstrap-kit/`  
**目标：** 新智能体一键完成"记忆体系 + 人格文档 + 通用技能 + 安全体系 + 定时任务"全套配置

---

## 1. 设计原则

1. **零侵入** — 不覆盖已有自定义文件（IDENTITY.md、USER.md、memory/）
2. **可审计** — 每一步都有记录，可重复执行
3. **可演进** — kit 本身独立版本管理，可单独更新
4. **通用化** — 所有模板变量化，不硬编码任何智能体名字
5. **幂等性** — 重复执行不破坏已有配置

---

## 2. 包结构

```
agent-bootstrap-kit/
├── SKILL.md                          # 技能定义（本 kit 的使用说明）
├── README.md                         # 使用文档
├── scripts/
│   └── install.sh                   # 主安装脚本（bash，可独立运行）
├── templates/
│   ├── personality/
│   │   ├── soul.md                  # 安全 rail + 核心准则（通用）
│   │   ├── agents.md                 # 工作规范（通用）
│   │   ├── identity.md.template      # 身份模板（变量替换）
│   │   ├── heartbeat.md.template     # 心跳巡检模板
│   │   └── memory-layers.md          # 记忆层级规范（通用）
│   ├── memory/
│   │   ├── memory-template.md         # 每日 memory 文件模板
│   │   └── memfile-boilerplate.md    # 新 daily log 开头格式
│   ├── skills/
│   │   └── manifest.txt              # 技能安装清单（命令列表）
│   ├── security/
│   │   └── security-layers.md        # 安全体系说明
│   └── cron/
│       ├── daily-distill.cron.template
│       └── weekly-evolution.cron.template
├── config/
│   └── agent-cron-map.json           # 各智能体 cron 时间错位配置
└── docs/
    ├── ARCHITECTURE.md               # 设计文档
    └── CHANGELOG.md
```

---

## 3. 模板变量系统

安装脚本对以下变量做替换：

| 变量 | 说明 | 示例 |
|------|------|------|
| `{{AGENT_ID}}` | 智能体 ID | `mia`, `elena` |
| `{{AGENT_NAME}}` | 智能体名字 | `Mia`, `Elena` |
| `{{CRON_BASE}}` | cron 基础时间（分） | `10`, `25`, `40`, `55` |
| `{{INSTALL_DATE}}` | 安装日期 | `2026-03-18` |

---

## 4. 文件分类策略

### 4.1 全局通用（直接复制，不替换）
- `templates/personality/soul.md` — 安全 rail，核心准则
- `templates/personality/agents.md` — 工作规范
- `templates/personality/memory-layers.md` — 记忆层级规范
- `templates/security/security-layers.md` — 安全体系说明

### 4.2 模板文件（变量替换后复制）
- `identity.md.template` → `IDENTITY.md`（替换名字、emoji）
- `heartbeat.md.template` → `HEARTBEAT.md`（替换 agent 名）

### 4.3 不覆盖文件（已有则跳过）
- `MEMORY.md` — 已有则保留
- `USER.md` — 已有则保留
- `memory/YYYY-MM-DD.md` — 已有日志保留

### 4.4 新建目录（不存在的则创建）
- `memory/` — 每日日志目录
- `memory/projects/` — 项目记忆目录
- `memory/inbox/` — 临时归档目录

---

## 5. 技能安装清单

### 5.1 Essential（必需，装到 `~/.openclaw/workspace/skills/`）
| 技能 | 来源 | 用途 |
|------|------|------|
| `tuanziguardianclaw` | 本地 `~/.openclaw/workspace/skills/tuanziguardianclaw/` | 安全监控内核 |
| `clawdefender` | `~/.agents/skills/clawdefender-1/` | 输入扫描 |
| `skill-vetter` | `~/.agents/skills/skill-vetter-1.0.0/` | 技能安装前审查 |
| `openclaw-memory-maintainer` | `~/.openclaw/workspace/skills/openclaw-memory-maintainer/` | 记忆维护 |
| `proactive-agent-lite` | `~/.openclaw/workspace/skills/proactive-agent-lite/` | 主动记忆架构 |
| `self-improving` | `~/.agents/skills/self-improving-1.1.3/` | 自我反思 |
| `find-skills` | `~/.openclaw/workspace/skills/find-skills/` | 技能发现 |

### 5.2 General（通用，装到 `~/.openclaw/workspace/skills/`）
| 技能 | 来源 | 用途 |
|------|------|------|
| `web_search` | 内置 | 联网搜索 |
| `openclaw-minimax-router` | 本地 | MiniMax 搜索/图片 |
| `image-generation` | 本地 | 生图 |
| `social-content` | `~/.agents/skills/social-content-generator-0.1.0/` | 社媒内容 |
| `brainstorming` | `~/.agents/skills/brainstorming-0.1.0/` | 创意工作流 |
| `writing-plans` | `~/.agents/skills/writing-plans-0.1.0/` | 写作规划 |
| `coding-agent` | 内置（`openclaw-bundled/coding-agent/`）| 代码任务 |
| `github` | 内置 | GitHub 操作 |
| `gmail` | `~/.openclaw/workspace/skills/gmail/` | 邮件 |
| `pinchtab-browser` | `~/.agents/skills/pinchtab-browser/` | 浏览器自动化 |
| `feishu-*` 系列 | `~/.openclaw/workspace/skills/feishu-*/` | 飞书全家桶 |

### 5.3 Optional（按需安装，不自动装）
| 技能 | 来源 |
|------|------|
| `security-auditor` | 代码安全审计 |
| `healthcheck` | 主机安全加固 |
| `data-analyst` | 数据分析 |
| `SEO` | SEO 优化 |
| `frontend-design` | 前端设计 |

---

## 6. 安全体系

### 6.1 层级说明

```
第一层：tuanziguardianclaw（卫士虾核心内核）
  ├─ 职责：最高权限安全层，监控/拦截所有危险操作
  ├─ 能力令牌系统
  ├─ Skill 沙箱
  └─ 实时审计日志

第二层：clawdefender（输入扫描器）
  ├─ 职责：所有外部输入（网页/邮件/飞书/文件）
  ├─ 检测：提示词注入、命令注入、SSRF、路径遍历、凭证泄露

第三层：skill-vetter（技能安装审查）
  ├─ 职责：新 skill 安装前必须审查
  └─ 检查：权限范围、可疑模式、敏感 API

第四层（可选）：security-auditor + healthcheck
  ├─ 职责：代码安全审计 + 主机安全加固
  └─ 触发：按需手动调用，不自动运行
```

### 6.2 卫士虾激活规则（写入 SOUL.md）
- 所有危险操作（见安全准则）必须经过卫士虾确认
- 卫士虾规则优先于所有其他 skill

---

## 7. 定时任务配置

### 7.1 cron 时间错位策略

新智能体安装时，从预分配时间池选取，避免冲突：

**日蒸馏时间池（按 `cron_base` 分配）：**
```
0 → 08:10  (eric)
1 → 10:25  (elena)
2 → 14:40  (main)
3 → 21:30  (mia)
```

**周提升时间池（周日凌晨，间隔 20 分钟）：**
```
0 → 周日 02:00 (main)
1 → 周日 02:20 (mia)
2 → 周日 02:40 (eric)
3 → 周日 03:00 (elena)
```

### 7.2 cron 模板

**日蒸馏 cron 模板：**
```
CRON_BASE=10  → cron 10 8 * * *     (日 distillation 08:10)
CRON_BASE=25  → cron 25 10 * * *    (日 distillation 10:25)
CRON_BASE=40  → cron 40 14 * * *    (日 distillation 14:40)
CRON_BASE=55  → cron 55 21 * * *    (日 distillation 21:55)
```

**周提升 cron 模板：**
```
SLOT=0 → cron 0 2 * * 0     (周日 02:00)
SLOT=1 → cron 20 2 * * 0    (周日 02:20)
SLOT=2 → cron 40 2 * * 0    (周日 02:40)
SLOT=3 → cron 0 3 * * 0     (周日 03:00)
```

---

## 8. 记忆体系

### 8.1 记忆层级规范

```
Layer 1: memory/YYYY-MM-DD.md（日常过程记录）
  - 原始对话日志
  - 临时想法
  - 待确认事项
  - append-only，不做删改

Layer 2: MEMORY.md（长期记忆）
  - 仅主会话加载
  - 业务决策、内容策略、项目状态
  - 禁忌、重要教训
  - 提炼后写入，不照搬日常

Layer 3: memory/projects/*.md（项目记忆）
  - 按项目归档的上下文
  - 索引在 MEMORY.md 中维护

Layer 4: memory/inbox/（临时归档）
  - 待处理事项
  - 有价值但还没整理的内容
```

### 8.2 每日 memory 文件模板

文件头格式：
```markdown
# 2026-03-18 日志

## 今日完成
-

## 待确认
-

## 重要决策
-

## 明日计划
-
```

---

## 9. 安装流程

### 9.1 正常安装（新智能体）

```bash
bash ~/.openclaw/agent-bootstrap-kit/scripts/install.sh <agent_id> [--name <名字>] [--cron-base <0-3>]
```

执行步骤：
1. 验证 agent workspace 存在
2. 安装 essential skills（软链接到 workspace/skills/）
3. 安装 general skills（如不存在）
4. 复制 personality 模板（变量替换）
5. 创建 memory/ 目录结构
6. 创建 cron 任务（日蒸馏 + 周提升）
7. 写 bootstrap.done 标记
8. 输出安装报告

### 9.2 修复安装（已有智能体）

```bash
bash install.sh <agent_id> --repair
```

- 不覆盖 IDENTITY.md、USER.md、MEMORY.md
- 不覆盖 memory/*.md
- 只补充缺失的模板文件和安全 skill
- 重新生成 cron 任务（保留已有任务 ID，只更新时间）

### 9.3 验证安装

```bash
bash install.sh <agent_id> --verify
```

检查项：
- skills 目录完整
- 模板文件存在
- cron 任务已创建
- bootstrap.done 存在

---

## 10. 与 OpenClaw 官方 agent-creator 的关系

```
用户需求 → agent-creator（官方流程） → bootstrap-kit（深度配置）
                 ↓
        创建 workspace
        配置 openclaw.json
        绑定渠道
                 ↓
        调用 bootstrap-kit
                 ↓
        一键完成：记忆+人格+技能+安全+cron
```

**bootstrap-kit 依赖 agent-creator 先创建好 workspace，不自己调用 `openclaw agents add`。**

---

## 11. 限制与风险

1. **skill 源依赖** — 如果 `~/.agents/skills/` 中的 skill 被删除，安装会失败
2. **cron 冲突** — 新智能体必须选择未占用的 cron slot（由 config/agent-cron-map.json 管控）
3. **已有 cron 不删** — 安装脚本只添加任务，不删除已有 cron
4. **卫士虾配置** — 当前卫士虾配置是全局的，新智能体共享同一份

---

## 12. 后续演进方向

- v1.1：支持飞书机器人绑定（`openclaw-feishu-agent-bind` 集成）
- v1.2：支持自定义 skill 组合（manifest override）
- v1.3：支持从已有智能体导出配置作为新包模板
