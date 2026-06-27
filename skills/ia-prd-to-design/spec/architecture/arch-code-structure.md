---
element_id: arch-code-structure
parent_domain: architecture
parent_element_id: architecture
---

# arch-code-structure 设计规范

## 适用条件

- build 需约定包/模块/分层结构。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/architecture.md` 的 `## §1.5 代码结构`

## 执行步骤

### build 模式

1. 输出后端/前端目录结构与分层约定。
2. 与后续 be-class/fe 路径对齐。

### modify 模式

1. 仅改命中包路径规则。

### incremental 模式

1. Read 基线 §1.5 → DELTA。

**增量边界**：代码结构 | 调整分层 | 不破坏已生成代码路径

## 质量检查点

- 包命名与团队规范一致
- backend/frontend 分工程说明
- 分节标题字面量 `## §1.5 代码结构`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/architecture/arch-code-structure.md`
