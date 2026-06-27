---
element_id: be-sequence
parent_domain: backend
parent_element_id: backend-impl
---

# be-sequence 设计规范

## 适用条件

- 核心流程需多参与者时序。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/backend.md` 的 `## §3.3 时序设计`

## 执行步骤

### build 模式

1. sequenceDiagram：参与者/消息/异常。
2. 标注事务与外部调用。

### modify 模式

1. 仅改命中时序。

### incremental 模式

1. Read 基线 §3.3 → DELTA。

**增量边界**：时序 | 交互调整 | 外部契约不变

## 质量检查点

- diagram 非空
- 类名与 be-class 一致
- 分节标题字面量 `## §3.3 时序设计`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/backend/be-sequence.md`
