---
element_id: arch-tech-stack
parent_domain: architecture
parent_element_id: architecture
---

# arch-tech-stack 设计规范

## 适用条件

- build / design-new-build；PRD 或团队约束要求技术栈决策。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/architecture.md` 的 `## §1.1 技术选型`

## 执行步骤

### build 模式

1. 汇总语言/框架/中间件/DB/缓存选型及版本。
2. 每项须有 PRD 或规范依据；无则 `[交互]` 确认。

### modify 模式

1. 仅改 modify_focus 命中条目。

### incremental 模式

1. Read 基线 §1.1 → DELTA。
2. 已发布栈项变更须 compatibility_note。

**增量边界**：技术选型 | 调整栈项 | 禁止 silent 降级

## 质量检查点

- 选型表完整
- 与 PROJECT_TYPE 一致或声明例外
- 分节标题字面量 `## §1.1 技术选型`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/architecture/arch-tech-stack.md`
