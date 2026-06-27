---
element_id: arch-feature-toggle
parent_domain: architecture
parent_element_id: architecture
---

# arch-feature-toggle 设计规范

## 适用条件

- PRD 含灰度/特性开关/AB 诉求。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/architecture.md` 的 `## §1.4 特性开关`

## 执行步骤

### build 模式

1. 输出开关 Key、默认值、作用范围、回滚策略。

### modify 模式

1. 仅改命中开关。

### incremental 模式

1. Read 基线 §1.4 → DELTA。

**增量边界**：特性开关 | 新增开关 | Key 命名规范

## 质量检查点

- 开关有回滚说明
- 与 config 交叉引用一致
- 分节标题字面量 `## §1.4 特性开关`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/architecture/arch-feature-toggle.md`
