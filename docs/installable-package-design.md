# Installable Package Design

## 目标

把 OpenClaw 人格化成长系统做成一个可迁移、可重复执行、可在升级后快速回补的安装包，而不是只在单个 workspace 里手工维护。

## 设计原则

- 不改 OpenClaw 内置记忆引擎与检索引擎
- 不依赖长期手工操作
- 升级 OpenClaw 后可以一键回补到目标架构
- 共享框架与 agent 个性化内容必须分离

## 为什么不直接改系统提示词源码

OpenClaw 系统提示词由运行时动态组装，包含工具、文档、工作区文件注入、心跳、运行时信息等固定部分。

因此不建议直接修改 OpenClaw npm 包里的内置系统提示词源码，原因有三点：
- 升级后容易被覆盖
- 维护成本高
- 不利于产品化迁移

更稳的做法是：
- 通过工作区引导文件注入人格化架构
- 通过工作区文档分层控制长期行为
- 通过可重复执行脚本在升级后重新补齐目标状态

## 安装包内容

### 共享框架层

- `docs/personhood/openclaw-personhood-system-v1.md`
- `docs/personhood/pre-hook-methodology.md`
- `docs/personhood/post-hook-methodology.md`
- `docs/personhood/capture-hook-selection-rules.md`
- `docs/personhood/cron-hooking-plan.md`
- `docs/personhood/weekly-evolution-and-skill-improvement.md`
- `templates/personhood/world.md`
- `templates/personhood/self.md`
- `templates/personhood/expression.md`
- `templates/personhood/inbox-README.md`
- `scripts/install_personhood_layer.sh`

### Agent 个性层

每个 agent 自己维护：
- `AGENTS.md`
- `USER.md`
- `IDENTITY.md`
- `SOUL.md`
- 已有 `MEMORY.md` 与 daily memory
- 该 agent 的 `world/self/expression` 初始内容

## 一键回补脚本职责

脚本应负责：
- 检查目标 workspace 是否存在
- 检查核心大文档是否存在
- 创建缺失的 `memory/world.md`
- 创建缺失的 `memory/self.md`
- 创建缺失的 `memory/expression.md`
- 创建缺失的 `memory/inbox/README.md`
- 可选：把建议的 `AGENTS.md` / `HEARTBEAT.md` 段落追加或提示人工合并
- 输出下一步人工整理建议

## 脚本边界

脚本不应该：
- 粗暴覆盖已有 `AGENTS.md`、`USER.md`、`IDENTITY.md`、`MEMORY.md`
- 直接抹掉旧记忆
- 假设所有 agent 都有完全相同的人设
- 直接修改 OpenClaw 安装目录内置源码

## 升级后的恢复策略

当 OpenClaw 升级导致默认模板或系统提示词组装逻辑变化时：

1. 不先改 OpenClaw npm 安装目录源码
2. 重新执行一键回补脚本
3. 检查工作区引导文件是否仍然符合人格化分层
4. 检查 heartbeat / cron / session-memory 是否仍能承接这套结构
5. 必要时只更新共享框架层文档与脚本

## 迁移路径

### 对已有 agent

1. 扫描现有大文档与 memory 文件
2. 创建新的精炼子人格文档
3. 从旧文档中人工整理首批 `world/self/expression` 内容
4. 对齐 `AGENTS.md` / `HEARTBEAT.md`
5. 验证运行

### 对新 agent

1. 创建基础 workspace
2. 运行安装脚本
3. 初始化 agent 个性层文档
4. 完成首轮 persona / user / memory 整理
5. 启用日常蒸馏维护

## 验证标准

- 新文档存在且职责清晰
- 原有大文档未被粗暴覆盖
- 方案不依赖改 OpenClaw 内置源码
- 升级后可通过脚本恢复到人格化架构
- 能迁移到 `main`、`mia`、`eric` 等其他 agent
