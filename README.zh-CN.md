# OpenClaw 人格化成长系统

[English](./README.md) | **中文**

一个可安装、可迁移、可长期维护的 OpenClaw 智能体人格化与长期认知分层系统。

它的目标不是让智能体“记得更多”，而是让智能体随着时间推移，变得更稳定、更自洽、更像一个有连续性的人。

![系统架构](./assets/images/architecture.png)

## 这个包解决什么问题

很多 agent workspace 跑久了，都会遇到同一类问题：

- daily memory 一直在长，但没人持续蒸馏
- 长期规则、人格认知、临时观察混在一起，边界越来越乱
- 智能体虽然记了很多东西，但没有明显变得更稳定、更像人
- 一旦升级 OpenClaw 或重建 workspace，手工维护的结构很容易丢

这套包就是把这件事做成一个分层、可恢复、可复用的系统。

## 核心思路

不是把所有东西都继续堆进 `MEMORY.md`，而是在 OpenClaw 原有文档层之上，补三层长期文档和一层候选区：

- `memory/world.md`：外部世界认知
- `memory/self.md`：自我认知
- `memory/expression.md`：表达与情绪控制认知
- `memory/inbox/`：待验证的候选认知，不应该过早升级进长期文档

它们和 OpenClaw 原有文件一起工作：

- `AGENTS.md`
- `USER.md`
- `IDENTITY.md`
- `MEMORY.md`
- `memory/YYYY-MM-DD.md`

## 它怎么工作

![工作流](./assets/images/workflow.png)

这个包包含两个核心 skill：

### `personhood-installer`

一键安装入口，用来把整套系统装进目标 OpenClaw workspace。

### `personhood-document-maintainer`

长期文档维护主 skill，用来持续维护这套分层结构。

它支持四种维护模式：

![维护模式](./assets/images/maintenance-modes.png)

| 模式 | 常见触发时机 | 目标 |
|------|--------------|------|
| `capture` | 高认知任务结束后 | 把原料先留在 daily 或 inbox |
| `light` | heartbeat | 轻量扫描和小纠偏 |
| `normal` | 每日蒸馏 | 升级稳定认知，清理文档边界 |
| `deep` | 每周进化 | 做更深度的整理、合并、降级与重构 |

## 安装方式

```bash
git clone https://github.com/DwDestiny/openclaw-personhood-system.git
cd openclaw-personhood-system
./install.sh --agent mia
```

安装前建议先看 `docs/pre-install-checklist.md`。

## 安装参数

```bash
./install.sh --agent <agent-name> [options]

参数：
  --agent <name>      目标 agent（必选）
  --workspace <path>  目标 workspace 路径
  --dry-run           只预演，不实际写文件
  --force             覆盖已存在文件
  --skip-cron         跳过 cron 配置生成
  --verbose           输出更详细日志
  --uninstall         卸载当前安装内容
```

## Cron 设计

这套包默认围绕三个周期任务设计：

| 任务 | 时间 | 作用 |
|-----|------|------|
| daily distill | 每天 23:30 | 常规文档维护 |
| self evolution | 周日 02:00 | 深度人格整理 |
| capability evolver | 周日 02:20 | 独立的周级能力进化 |

这样可以把“人格维护”和“能力进化”分开，不混在一次任务里做。

## 仓库导览

- `install.sh`：安装 / 卸载入口
- `manifest.json`：包元信息
- `skills/personhood-installer/`：安装 skill
- `skills/personhood-document-maintainer/`：文档维护 skill
- `templates/`：初始分层记忆模板
- `docs/`：方法论、架构、hook 规则、cron 设计
- `assets/images/`：README 中使用的配图

## 文档导航

- `docs/overview.md`：整体方案总览
- `docs/installable-package-design.md`：为什么要做成可安装包，而不是直接改系统提示词
- `docs/document-maintenance-methodology.md`：长期文档维护方法论
- `docs/document-maintenance-skill-spec.md`：文档维护 skill 规格说明
- `docs/pre-hook-methodology.md`：任务前怎么判断要不要挂钩
- `docs/post-hook-methodology.md`：任务后怎么判断该走 `capture` / `light` / `normal` / `deep`
- `docs/capture-hook-selection-rules.md`：哪些任务适合挂 `capture`
- `docs/cron-hooking-plan.md`：cron 接线方案
- `docs/weekly-evolution-and-skill-improvement.md`：人格演化与能力进化的周级分工

## 兼容性

- OpenClaw 0.9.0+
- 支持 `mia`、`main`、`eric`、`elena` 以及自定义 agent
- 运行在 OpenClaw 的 heartbeat、memory search、session-memory、cron 机制之上

## 为什么它重要

很多智能体系统的问题，不是“记忆太少”，而是“记忆结构太乱”。

这套包要解决的是这个缺口：

- 不只是记更多
- 而是记得更有边界
- 不只是多几份笔记
- 而是形成可维护的人格化架构
- 不只是当前机器上的临时技巧
- 而是可以公开、可迁移、可复用的安装包

## License

本仓库采用 [MIT License](./LICENSE)。
