# Cron Hooking Plan

## 目标

把现有 cron / 定时任务分成三类：
- 需要挂 `capture`
- 需要挂 `light` / `normal` / `deep`
- 不需要挂人格化维护

原则不是“全部任务都接”，而是只接会带来认知增量或本来就承担维护职责的任务。

## Mia 当前任务挂接建议

### 应挂 `capture`

#### `daily-ai-topic-research`

原因：
- 明显属于外部资料搜索与话题研究
- 会形成对 AI 趋势、选题价值、受众兴趣的判断

建议：
- 任务尾部追加一次 `personhood-document-maintainer capture`
- 至少把值得后续蒸馏的判断写入 daily 或 `memory/inbox/`

#### `ai-news-morning-briefing`

原因：
- 持续接收头部 AI 账号动态
- 容易形成对模型、产品、趋势的世界认知

建议：
- 任务尾部调用 `capture`
- 沉淀“哪些更新值得持续关注、哪些只是噪音”

#### `twitter-high-frequency-engagement`

原因：
- 高频接触热点原帖、评论区与真人互动场
- 不只是执行，还会形成平台判断和内容判断

建议：
- 任务尾部调用 `capture`
- 从搜索方向、候选原帖、互动结果中提炼认知原料

#### `twitter-daily-review`

原因：
- 本身就是高密度复盘与方法沉淀任务
- 会形成明确的平台与写法认知

建议：
- 任务尾部调用 `capture`
- 然后由当晚或次日的 `normal` 维护决定是否正式升级

#### `twitter-three-day-review`

原因：
- 这是典型的深度认知输入任务
- 会形成较高可信度的方法论候选

建议：
- 任务尾部调用 `capture`
- 并优先标记哪些结论已经接近长期稳定

### 应挂维护模式

#### `mia-memory-daily-distill`

建议改为：
- 统一调用 `personhood-document-maintainer normal`
- 替代旧的“只蒸馏到 MEMORY.md”思路

#### `mia-agent-self-evolution`

建议改为：
- 继续保留，但职责收口为“周级人格/认知深度维护”
- 核心对齐 `personhood-document-maintainer deep`
- 不再同时承担 skill 发现、skill 创建、skill 优化这条能力进化线

#### `mia-capability-evolver`

建议改为：
- 不做泛泛的 nightly 自我复盘
- 收口为“周级能力进化 / skill 发现 / skill 优化”专项入口
- 与 `personhood-document-maintainer` 分层，不再混做长期文档主维护
- 一旦发现缺 workflow 或缺 skill，统一进入 `skill-creator` 流程

#### heartbeat poll

建议：
- 统一调用 `personhood-document-maintainer light`

### 暂不需要挂

以下任务默认不需要额外挂人格化维护：
- 纯发送型任务
- 纯上传 / 纯发布 / 纯渲染型任务
- 不产生明显新认知的机械执行任务

## 推荐迁移顺序

1. 先改 `mia-memory-daily-distill`，切到 `normal`
2. 再给 `twitter-high-frequency-engagement`、`twitter-daily-review`、`twitter-three-day-review` 补 `capture`
3. 再给 `daily-ai-topic-research`、`ai-news-morning-briefing` 补 `capture`
4. 最后再考虑是否收敛 `mia-agent-self-evolution` 与 `deep` 的职责边界

## 边界提醒

- `capture` 的职责是留原料，不是强行改长期文档
- `normal` 负责日常升级
- `deep` 负责结构性整理
- 一个任务即使挂了 `capture`，也不代表每次都会产生可升级内容
- 如果某任务长期没有认知增量，应取消挂钩，避免制造噪音
