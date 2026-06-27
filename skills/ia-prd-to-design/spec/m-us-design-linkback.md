# US 与设计交付物索引关联（Story 设计引用回填）

本规范定义 `ia-story-enricher` 的调用契约（调用方式、输入/输出/校验）。
编排通过 `@ia-story-enricher` 调用 subagent 完成 US 关联；本规范须由各 workflow 在进入回填阶段前先加载。

---

## 触发条件

- 当编排进入 Story 设计引用回填阶段，且 `STORY_FILE` 存在且可读时执行。
- 若 `STORY_FILE` 不存在，则跳过本步骤，不报错。

---

## 调用方式

- 编排（orchestration）**直接通过 `@ia-story-enricher` 调用 subagent** 完成 US 与设计交付物的索引关联；编排本身不实现回填算法。
- 调用入口：`@ia-story-enricher`（对应 `subagent-registry.yaml` 中 `dispatch_via: orchestration-direct` 的条目）。
- 调用时机：在各 workflow 的 US 关联 Phase（如 `Phase 2B` / `Phase 3B` 等）内执行，须在 `design.md` 汇总生成之后调用。
- 调用契约（输入/输出/校验）见下文；执行细则、写回规则、映射策略由 `ia-story-enricher` subagent 自身承载。
- workflow 命中本阶段时，须**先加载本规范**（列入各 workflow 的「强制读取」），再发起调用。

---

## Subagent 输入契约

| 输入 | 必填 | 说明 |
|------|------|------|
| `DESIGN_DIR` | 是 | 设计目录根路径 |
| `STORY_FILE` | 是 | US 载体文件，默认 `{DESIGN_DIR}/story.md` |
| `US_BATCH_SIZE` | 否 | 批处理大小；未注入时由 subagent 内部按默认值处理 |
| `EXECUTION_MODE` | 是 | `build` / `modify` / `incremental` |
| `{DESIGN_DIR}/design.md` | 否 | 设计总览输入，存在则可用 |
| `{DESIGN_DIR}/{design_artifacts 各值}` | 否 | 各设计要素文件，存在则可用 |
| `{DESIGN_DIR}/shared-context.md` | 否 | 增量场景常见的补充上下文，存在则可用 |

> 说明：subagent 在执行时需要读取哪些文件、如何进行映射与写回，以 `ia-story-enricher` subagent 自身规则为准。

---

## Subagent 输出契约

| 输出 | 说明 |
|------|------|
| `{DESIGN_DIR}/story.md` | 原地更新后的 US 设计引用结果 |
| `DONE: story.md updated` | 标准完成消息 |
| `DONE: story.md design linkback` | 历史兼容完成消息（可选） |

---

## 校验规则（编排侧）

1. **文件校验**：若执行本步骤，`{DESIGN_DIR}/story.md` 必须可读且可写。
2. **结果校验**：subagent 结束后，必须检测到 `story.md` 有更新或存在可解释的“无变更”结果（由编排按实际策略处理）。
3. **消息校验**：完成消息应为 `DONE: story.md updated`（允许兼容旧文案）。
4. **职责边界校验**：spec 不承载执行算法；编排仅负责按「调用方式」发起 `@ia-story-enricher` 调用与轻量校验，回填算法以 `ia-story-enricher` subagent 自身为准。若规则冲突，以 subagent 自身规则为准。
