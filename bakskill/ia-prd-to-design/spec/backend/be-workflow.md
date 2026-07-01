---
element_id: be-workflow
parent_domain: backend
parent_element_id: backend-impl
---

# be-workflow 设计规范

## 适用条件

- PRD 含审批/工作流引擎诉求。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/backend.md` 的 `## §3.8 工作流`

## 执行步骤

### build 模式

1. 流程定义、节点、候选人规则、与状态机关联。

### modify 模式

1. 仅改命中流程。

### incremental 模式

1. Read 基线 §3.8 → DELTA。

**增量边界**：工作流 | 流程调整 | 在途实例兼容

## 质量检查点

- 与 state-machine 对齐
- 节点有权限
- 分节标题字面量 `## §3.8 工作流`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/backend/be-workflow.md`
