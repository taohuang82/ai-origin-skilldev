---
element_id: fe-page-structure
parent_domain: frontend
parent_element_id: frontend
---

# fe-page-structure 设计规范

## 适用条件

- PRD 有页面/路由/布局。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/frontend.md` 的 `## §4.2 路由信息设计`

## 执行步骤

### build 模式

1. 页面清单+路由表+布局+守卫。

### modify 模式

1. 仅改命中页面/路由。

### incremental 模式

1. Read 基线 §4.2 → DELTA。
2. URL 不 breaking

**增量边界**：页面布局 | 路由 | **URL 兼容**

## 质量检查点

- PRD 页面全覆盖
- 布局清晰
- 分节标题字面量 `## §4.2 路由信息设计`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/frontend/fe-page-structure.md`
