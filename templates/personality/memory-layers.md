# 记忆层级规范

## 层级说明

```
Layer 1: memory/YYYY-MM-DD.md  （日常过程记录，append-only）
Layer 2: MEMORY.md              （长期记忆，主会话加载）
Layer 3: memory/projects/*.md   （项目记忆）
Layer 4: memory/inbox/          （待处理归档）
```

## Layer 1 — Daily Log

**文件：** `memory/YYYY-MM-DD.md`  
**写入时机：** 立即写，不拖延  
**写入内容：**
- 当日关键决策（是什么、为什么）
- 用户确认的新偏好/规则
- 任务状态（进行中/已完成/卡点）
- 重要上下文（项目进展、风险点）

**禁止写入：**
- 未验证结论
- 敏感密钥明文
- 心理活动、无来源猜测

## Layer 2 — 长期记忆

**文件：** `MEMORY.md`（主会话才加载，其他 agent 不应访问）  
**写入时机：** 从 daily log 提炼后写入  
**写入内容：**
- 业务决策和策略
- 稳定的用户偏好和禁忌
- 项目长期状态
- 重要教训（错误+原因）

**禁止写入：**
- 原始对话记录
- 临时想法
- 日常流水账

## Layer 3 — 项目记忆

**文件：** `memory/projects/<project-name>.md`  
**写入时机：** 项目有实质进展或重大决策时  
**维护：** 在 MEMORY.md 中维护项目索引

## Layer 4 — Inbox

**目录：** `memory/inbox/`  
**用途：** 有价值但还没整理的内容暂存  
**处理：** 每周蒸馏时整理或删除

## 升级规则

| 触发条件 | 动作 |
|---------|------|
| 用户明确说"记住" | 当日写入 daily log，立即提炼到 MEMORY.md |
| 同一类型判断出现 3 次 | 提炼为 MEMORY.md 中的稳定规则 |
| 任务跨多日 | 创建 `memory/projects/<task>.md` |
| 经验/教训/纠偏 | 立即写入 MEMORY.md，不等 daily log |
