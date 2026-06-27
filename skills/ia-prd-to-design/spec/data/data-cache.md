---
element_id: data-cache
parent_domain: data
parent_element_id: data-model
---

# data-cache 设计规范

## 适用条件

- PRD/NFR 明示缓存；无则 ⏭️。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/data.md` 的 `## §2.2 缓存设计`

## 执行步骤

### build 模式

1. 盘点缓存对象与访问模式。
2. Key 清单+属性（TTL/结构/一致性）。
3. 穿透/击穿/雪崩策略。

### modify 模式

1. 仅改命中 Key。

### incremental 模式

1. Read 基线 §2.2 → DELTA。
2. **Key 命名规则禁止改**

**增量边界**：缓存 | Key/TTL | **命名规则禁止改**

## 质量检查点

- Key 规范
- TTL 有依据
- 分节标题字面量 `## §2.2 缓存设计`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/data/data-cache.md`
