# Document Maintenance Skill Spec

## 定位

这是一个专门维护人格化长期文档的 skill。

它的职责不是替代 OpenClaw 原生 memorySearch，也不是替代 session-memory，而是基于现有 daily memory、session-memory 产物、长期文档，执行分流、提炼、升级、降级和去重。

## 输入来源

- 当前工作区的 `MEMORY.md`
- `USER.md`
- `IDENTITY.md`
- `memory/world.md`
- `memory/self.md`
- `memory/expression.md`
- 最近的 daily memory
- 必要时少量 session-memory 产物
- 当前未处理的 `memory/inbox/` 候选

## 核心动作

1. 识别新认知是否值得沉淀
2. 判断应写入哪一层文档
3. 发现与旧认知冲突的内容
4. 决定保留、升级、降级、合并或删除
5. 保持文档职责边界清晰

## 输出要求

- 更新相应文档
- 简短记录本轮维护结论
- 明确写出本轮升了什么、没升什么、为什么

## 推荐触发方式

- 心跳任务：轻量触发
- 日总结：常规触发
- 周总结：深度触发
- 重要纠偏后：按需触发

## 不建议的触发方式

- 每个小任务结束都强制触发
- 每次对话后都重写长期文档
- 在上下文还没沉淀时频繁改人格底层文档
- 把高频 workflow 发现、skill 缺失判断、skill 优化判断混进文档维护 skill

## 成功标准

- 长期文档更清晰，而不是更臃肿
- 新认知能放对地方
- 错放内容会被逐步清走
- 文档层次越来越稳定
