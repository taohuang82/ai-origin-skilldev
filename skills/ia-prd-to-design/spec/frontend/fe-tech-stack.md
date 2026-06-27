---
element_id: fe-tech-stack
parent_domain: frontend
parent_element_id: frontend
---

# fe-tech-stack 设计规范

## 适用条件

- CHANGE_SCOPE 含 frontend。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/frontend.md` 的 `## §4.1 技术选型`

## 执行步骤

### build 模式

1. 框架/UI/状态/路由/构建工具选型。

### modify 模式

1. 仅改命中栈项。

### incremental 模式

1. Read 基线 §4.1 → DELTA。

**增量边界**：FE 栈 | 调整 | 构建一致

## 质量检查点

- 版本明确
- 与 API TS 对齐
- 分节标题字面量 `## §4.1 技术选型`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/frontend/fe-tech-stack.md`
