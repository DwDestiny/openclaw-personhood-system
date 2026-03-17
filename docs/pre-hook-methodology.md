# Pre-Hook Methodology

## 定位

这里的“前置层”不再指一个额外运行的 hook，而是指：利用 OpenClaw 已经自动注入的大文档，在其中显式要求继续读取三份人格补充总文档。

它不负责 daily 注入，不负责额外上下文打捞，也不负责重复调用记忆检索。

## 前置层只做什么

只做一件事：
- 通过 `AGENTS.md`、`HEARTBEAT.md` 等已自动注入文档，要求读取 `memory/world.md`、`memory/self.md`、`memory/expression.md`

## 前置层不做什么

- 不强制读取今天/昨天 daily memory
- 不额外做上下文补全动作
- 不单独设计新的 pre-hook 检索链
- 不和 OpenClaw 自带的上下文截断、会话历史、memorySearch 重复

## 默认输入分工

### OpenClaw 自带

- 当前会话上下文
- 历史截断逻辑
- memorySearch / 向量检索
- 已自动注入的大文档

### 我们补充

- `memory/world.md`
- `memory/self.md`
- `memory/expression.md`

## 方法论目标

目标不是让智能体在开始前“知道越多越好”，而是让它在不膨胀上下文的前提下，稳定拿到最需要的人格补充层。

也就是说：
- 上下文归 OpenClaw 自己管
- 检索归 OpenClaw 自己管
- 我们只管把长期人格补充文档接进去

## 当前推荐落点

- 在 `AGENTS.md` 里声明三份总文档为默认必读补充层
- 在 `HEARTBEAT.md` 里声明心跳维护也应补读这三份文档
- 不再把前置层实现成额外 daily/context 注入逻辑
