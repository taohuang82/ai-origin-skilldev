---
element_id: fe-component
parent_domain: frontend
parent_element_id: frontend
---

# fe-component 设计规范

## 适用条件

- PRD 有组件/字段级 UI 诉求。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/frontend.md` 的 `## §4.4 组件与字段`

## 执行步骤

### build 模式

1. 组件清单、Props 抽象、复用关系。

### modify 模式

1. 仅改命中组件。

### incremental 模式

1. Read 基线 §4.4 → DELTA。

**增量边界**：组件 | 新增/改 | 既有 Props 兼容

## 质量检查点

- 与 page-structure 一致
- 字段与 PRD 对齐
- 分节标题字面量 `## §4.4 组件与字段`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/frontend/fe-component.md`
