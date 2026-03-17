# 安装前检查清单

> 在运行 `./install.sh` 之前，请先确认以下环境条件。

## 1. OpenClaw 版本检查

```bash
openclaw --version
```

**要求**: 0.9.0+

如果版本过低，需要先升级 OpenClaw。

## 2. 必需功能检查

### 2.1 Heartbeat

检查 `~/.openclaw/openclaw.json`:

```json
{
  "agents": {
    "<your-agent>": {
      "heartbeat": {
        "enabled": true,
        "every": "30m"
      }
    }
  }
}
```

如果 heartbeat 未启用，人格化系统的 `light` 模式无法工作。

### 2.2 MemorySearch

检查 `~/.openclaw/openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "enabled": true
      }
    }
  }
}
```

如果 memorySearch 未启用，长期文档的语义检索无法工作。

### 2.3 Cron 支持

检查 cron 任务是否可创建:

```bash
openclaw cron list
```

如果 cron 不可用，日常维护任务无法自动执行。

## 3. 目标 Agent 检查

确认目标 agent 已经创建:

```bash
openclaw agents list
```

如果 agent 不存在，需要先创建:

```bash
openclaw agent create <agent-name>
```

## 4. 现有文档整理建议

### 4.1 需要整理的文档

在安装之前，建议先把以下文档里的核心规则按新分层整理：

| 原文档 | 需要提取的内容 | 目标位置 |
|-------|-------------|---------|
| `MEMORY.md` | 跨任务长期硬规则 | 保留在 `MEMORY.md` |
| `MEMORY.md` | 行业/平台认知 | 迁移到 `memory/world.md` |
| `MEMORY.md` | 自我认知/常见跑偏 | 迁移到 `memory/self.md` |
| `MEMORY.md` | 表达控制规律 | 迁移到 `memory/expression.md` |
| `AGENTS.md` | 执行规则/边界/禁止 | 保留在 `AGENTS.md` |
| `AGENTS.md` | 工具优先级/Skill 入口 | 保留在 `AGENTS.md` |
| `USER.md` | 用户长期偏好 | 保留在 `USER.md` |
| `IDENTITY.md` | 人格底色 | 保留在 `IDENTITY.md` |

### 4.2 整理原则

- **不要删旧** - 先复制到新位置，确认新结构 OK 了再考虑清理
- **不确定的先放 inbox** - `memory/inbox/` 里待验证
- **分清主次** - 大文档层是主，人格补充层是补

### 4.3 整理顺序建议

1. 先备份现有 workspace
2. 创建新文档结构（install.sh 会帮你）
3. 人工把旧文档里的内容归类到新位置
4. 运行一次 `normal` 模式维护验证

## 5. 安装后验证

安装完成后，运行以下命令验证:

```bash
# 检查文件是否都创建了
ls -la memory/
ls -la skills/personhood-document-maintainer/

# 测试 skill 是否可用
openclaw skills list | grep personhood
```

## 6. 常见问题

**Q: 我的 OpenClaw 版本比较老，能用吗？**
A: 建议升级到 0.9.0+。老版本可能缺少 heartbeat、memorySearch 等功能。

**Q: memorySearch 需要额外配置吗？**
A: 默认使用 OpenClaw 内置的向量检索。如果使用 Cloudflare Gateway，需要确保网络可达。

**Q: 安装后发现有问题怎么办？**
A: 使用 `./install.sh --agent <name> --uninstall` 卸载，然后重新整理文档后再安装。

---

*检查完成后再运行安装脚本*
