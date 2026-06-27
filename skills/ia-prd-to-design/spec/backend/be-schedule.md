---
element_id: be-schedule
parent_domain: backend
parent_element_id: backend-impl
---

# be-schedule 设计规范

## 适用条件

- PRD 含定时/批处理任务。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/backend.md` 的 `## §3.7 定时任务`

## 执行步骤

### build 模式

1. Cron/调度平台、任务清单、幂等与告警。

### modify 模式

1. 仅改命中任务。

### incremental 模式

1. Read 基线 §3.7 → DELTA。

**增量边界**：定时任务 | 新增任务 | 既有 Cron 慎改

## 质量检查点

- 幂等说明
- 失败重试策略
- 分节标题字面量 `## §3.7 定时任务`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/backend/be-schedule.md`
