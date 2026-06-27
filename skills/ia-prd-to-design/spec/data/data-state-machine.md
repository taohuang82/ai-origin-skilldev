---
element_id: data-state-machine
parent_domain: data
parent_element_id: data-model
---

# data-state-machine 设计规范

## 适用条件

- PRD 有状态流转/审批；无则 ⏭️。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/data.md` 的 `## §2.3 状态机设计`

## 执行步骤

### build 模式

1. 状态枚举 INT4+注释。
2. stateDiagram-v2+领域事件。
3. 非法转移→错误码引用。

### modify 模式

1. 仅改命中状态机。

### incremental 模式

1. Read 基线 §2.3 → DELTA。
2. **枚举值禁止改**

**增量边界**：状态机 | 节点/转移 | **枚举禁止改**

## 质量检查点

- diagram 完整
- 与表 status 一致
- 分节标题字面量 `## §2.3 状态机设计`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/data/data-state-machine.md`
