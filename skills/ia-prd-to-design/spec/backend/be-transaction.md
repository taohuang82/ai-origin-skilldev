---
element_id: be-transaction
parent_domain: backend
parent_element_id: backend-impl
---

# be-transaction 设计规范

## 适用条件

- 存在跨表/跨服务一致性诉求。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/backend.md` 的 `## §3.5 事务设计`

## 执行步骤

### build 模式

1. 事务边界、隔离级别、补偿/ Saga 策略。

### modify 模式

1. 仅改命中事务说明。

### incremental 模式

1. Read 基线 §3.5 → DELTA。

**增量边界**：事务 | 边界调整 | 不扩大锁范围无依据

## 质量检查点

- 与 sequence 一致
- 异常回滚明确
- 分节标题字面量 `## §3.5 事务设计`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/backend/be-transaction.md`
