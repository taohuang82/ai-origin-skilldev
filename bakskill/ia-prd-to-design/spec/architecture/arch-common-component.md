---
element_id: arch-common-component
parent_domain: architecture
parent_element_id: architecture
---

# arch-common-component 设计规范

## 适用条件

- 存在跨特性复用公共组件（UI/服务组件）。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/architecture.md` 的 `## §1.7 公共组件`

## 执行步骤

### build 模式

1. 列出组件清单、接口契约、复用条件。

### modify 模式

1. 仅改命中组件。

### incremental 模式

1. Read 基线 §1.7 → DELTA。

**增量边界**：公共组件 | 新增组件 | 接口向后兼容

## 质量检查点

- 组件职责单一
- 与 fe/backend 引用一致
- 分节标题字面量 `## §1.7 公共组件`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/architecture/arch-common-component.md`
