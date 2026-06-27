---
element_id: integration-mq
parent_domain: integration
parent_element_id: integration
---

# integration-mq 设计规范

## 适用条件

- PRD 含 MQ/异步事件。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/integration.md` 的 `## §5.1 消息队列`

## 执行步骤

### build 模式

1. Topic/Tag/Group/Schema+幂等重试。

### modify 模式

1. 仅改命中 MQ。

### incremental 模式

1. Read 基线 §5.1 → DELTA。
2. **Topic 名禁止改**

**增量边界**：MQ | Topic/Schema | **Topic 禁止改**

## 质量检查点

- Schema 完整
- 消费方明确
- 分节标题字面量 `## §5.1 消息队列`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/integration/integration-mq.md`
