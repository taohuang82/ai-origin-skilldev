---
element_id: be-export
parent_domain: backend
parent_element_id: backend-impl
---

# be-export 设计规范

## 适用条件

- PRD 含导出/报表/大批量下载。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/backend.md` 的 `## §3.6 导出设计`

## 执行步骤

### build 模式

1. 导出格式、异步任务、限流、文件存储策略。

### modify 模式

1. 仅改命中导出场景。

### incremental 模式

1. Read 基线 §3.6 → DELTA。

**增量边界**：导出 | 新增导出 | 格式向后兼容

## 质量检查点

- 有限流
- 有权限点
- 分节标题字面量 `## §3.6 导出设计`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/backend/be-export.md`
