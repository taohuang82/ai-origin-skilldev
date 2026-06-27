---
element_id: integration-external
parent_domain: integration
parent_element_id: integration
---

# integration-external 设计规范

## 适用条件

- 依赖外部系统/三方 API。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/integration.md` 的 `## §5.2 外部系统`

## 执行步骤

### build 模式

1. 外部服务清单、容错/熔断/超时/降级。

### modify 模式

1. 仅改命中外部依赖。

### incremental 模式

1. Read 基线 §5.2 → DELTA。
2. **既有契约禁止改**

**增量边界**：外部依赖 | 容错 | **契约不变**

## 质量检查点

- 超时重试明确
- 有降级方案
- 分节标题字面量 `## §5.2 外部系统`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/integration/integration-external.md`
