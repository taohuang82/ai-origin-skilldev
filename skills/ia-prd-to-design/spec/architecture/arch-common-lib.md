---
element_id: arch-common-lib
parent_domain: architecture
parent_element_id: architecture
---

# arch-common-lib 设计规范

## 适用条件

- 存在跨项目复用二方/三方库诉求。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/architecture.md` 的 `## §1.6 公共库`

## 执行步骤

### build 模式

1. 列出公共库清单、版本、使用边界、禁止事项。

### modify 模式

1. 仅改命中库条目。

### incremental 模式

1. Read 基线 §1.6 → DELTA。

**增量边界**：公共库 | 新增库 | 版本锁定策略

## 质量检查点

- 库有用途说明
- 许可证/安全约束
- 分节标题字面量 `## §1.6 公共库`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/architecture/arch-common-lib.md`
