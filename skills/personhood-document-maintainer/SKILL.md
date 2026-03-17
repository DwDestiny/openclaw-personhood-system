---
name: personhood-document-maintainer
description: 维护人格化长期文档与全局记忆分层。只要任务涉及更新 `MEMORY.md`、`USER.md`、`IDENTITY.md`、`memory/world.md`、`memory/self.md`、`memory/expression.md`、`memory/inbox/`，或者用户提到“整理文档架构”“维护全局记忆”“更新人格文档”“把新认知归档到正确文档”“清理文档边界”“把最近经验沉淀进去”，就必须使用这个 skill。它负责判断什么值得沉淀、该写到哪一层、哪些内容该升级/降级/合并/暂存，而不是在日常执行中随手乱写长期文档。
---

# Personhood Document Maintainer

## 目标

这个 skill 负责维护人格化长期文档体系。

它不替代 OpenClaw 原生 memorySearch、session-memory、heartbeat 或 cron，而是站在这些机制之上，把新信息分流到正确文档，并保持文档边界清晰。

## 何时使用

在以下场景必须使用：
- 用户要求“记住这个”“整理这些规则”“更新全局记忆文档”
- 需要维护 `MEMORY.md`、`USER.md`、`IDENTITY.md`
- 需要维护 `memory/world.md`、`memory/self.md`、`memory/expression.md`
- 需要把 recent daily / session-memory 结果升级进长期文档
- heartbeat、日总结、周总结要做全局文档维护
- 需要清理错放内容、重复规则、过时规则
- 高认知输入任务需要留下可蒸馏原料

## 输入文档

默认读取：
- `AGENTS.md`
- `USER.md`
- `IDENTITY.md`
- `MEMORY.md`
- `memory/world.md`
- `memory/self.md`
- `memory/expression.md`
- `memory/inbox/`

按需读取：
- 最近的 `memory/YYYY-MM-DD.md`
- 必要的 session-memory 产物
- 相关任务日志或研究产物

## 分流规则

- `AGENTS.md`：执行规则、工作边界、工具规范、skill 优先级、禁止事项
- `USER.md`：用户长期偏好、关系边界、稳定沟通期待
- `IDENTITY.md`：人格底色、角色定位、稳定气质
- `MEMORY.md`：跨任务长期硬规则与高优先级稳定经验
- `memory/world.md`：外部世界认知
- `memory/self.md`：自我认知
- `memory/expression.md`：表达与情绪控制
- `memory/inbox/`：待验证候选
- `memory/YYYY-MM-DD.md`：daily 原始过程

## 工作模式

### `capture`

用于高认知输入任务尾部挂钩。

适用场景：
- Twitter 刷帖 / 复盘
- 热点搜索
- 资料研究
- 竞品观察
- 长时间信息采样

动作：
1. 提炼这轮任务形成了哪些新判断、新认知、新问题。
2. 区分哪些已经稳定，哪些只是候选。
3. 默认先把可蒸馏原料写入 `memory/inbox/` 或当天 `memory/YYYY-MM-DD.md`。
4. 不在 `capture` 模式里做大规模长期文档重写。

### `light`

用于 heartbeat 高频轻量维护。

动作：
1. 扫描最近新增原料。
2. 发现明显可升级或明显冲突的内容。
3. 轻量更新，或继续留在 `inbox`。

### `normal`

用于日总结常规维护。

动作：
1. 判断哪些候选已经足够稳定。
2. 升级到 `memory/world.md`、`memory/self.md`、`memory/expression.md`、`MEMORY.md` 等对应层。
3. 清理轻度重复与错放内容。

### `deep`

用于周总结或专项整理。

动作：
1. 做结构级清理与合并。
2. 降级过时内容。
3. 检查是否有内容应升级到 `USER.md` 或 `IDENTITY.md`。
4. 校正文档边界漂移。

## 工作流

1. 先判断当前是 `capture`、`light`、`normal` 还是 `deep` 模式。
2. 再判断新信息值不值得升入长期文档。
3. 再判断它属于世界、自我、表达、用户、身份、总规则中的哪一层。
4. 如果还不稳定，先进入 `memory/inbox/` 或 daily。
5. 如果已经稳定，再更新对应长期文档。
6. 清理重复、错放、过时内容，保持边界清晰。
7. 维护完成后，简短说明本轮升了什么、没升什么、为什么。

## 维护原则

- 不把 daily 流水账直接贴进长期文档
- 不把单次用户命令误写成用户画像
- 不把一次性情绪误写成长期表达规律
- 不把人格底色和表达控制混写
- 不为了显得勤奋而过度写入
- 不确定放哪时，先放 `memory/inbox/`

## 触发建议

- 高频 heartbeat：调用 `light`
- 日总结：调用 `normal`
- 周总结：调用 `deep`
- Twitter 刷帖 / 热点搜索 / 研究类任务尾部：调用 `capture`
- 重要纠偏后：按需调用 `normal` 或 `deep`

## 参考

- 详细方法论：`docs/personhood/document-maintenance-methodology.md`
- 方案总文档：`docs/personhood/openclaw-personhood-system-v1.md`
- 前置层说明：`docs/personhood/pre-hook-methodology.md`
- capture 挂钩规则：`docs/personhood/capture-hook-selection-rules.md`
- skill 规格：`docs/personhood/document-maintenance-skill-spec.md`
