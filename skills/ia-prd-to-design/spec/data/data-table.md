---
element_id: data-table
parent_domain: data
parent_element_id: data-model
---

# data-table 设计规范

## 适用条件

- PRD「业务对象/实体」≥1；或增量命中表结构。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/data.md` 的 `## §2.1 数据表设计`

## 执行步骤

### build 模式

1. 实体→表映射；变更概要+表清单（E00x 锚点）。
2. Mermaid erDiagram。
3. 逐表字段/索引/约束（按输出骨架）。
4. `[交互]` 存量表改动须确认兼容。

### modify 模式

1. 仅改 modify_focus 命中的表/字段/索引。

### incremental 模式

1. Read 基线 §2.1 → DELTA。
2. **主键/外键禁止改**；新字段 nullable/默认值。
3. DIP compatibility_note。
4. `[交互]` 确认索引与迁移。

**增量边界**：物理表 | 表/字段/索引 | **PK/FK 禁止改**

## 质量检查点

- E00x 锚点完整
- 审计六项
- erDiagram 非空
- 无 SQL 代码块
- 分节标题字面量 `## §2.1 数据表设计`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/data/data-table.md`
