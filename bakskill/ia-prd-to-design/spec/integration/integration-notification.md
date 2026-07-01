---
element_id: integration-notification
parent_domain: integration
parent_element_id: integration
---

# integration-notification 设计规范

## 适用条件

- PRD 含通知/消息触达。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/integration.md` 的 `## §5.3 通知`

## 执行步骤

### build 模式

1. 渠道、模板、触发条件、幂等。

### modify 模式

1. 仅改命中通知。

### incremental 模式

1. Read 基线 §5.3 → DELTA。

**增量边界**：通知 | 模板/渠道 | 模板版本

## 质量检查点

- 触发与 backend 事件一致
- 渠道可配置
- 分节标题字面量 `## §5.3 通知`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/integration/integration-notification.md`
