---
element_id: config-dict
parent_domain: config
parent_element_id: config
---

# config-dict 设计规范

## 适用条件

- PRD 枚举/字典/码表。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/config.md` 的 `## §6.2 数据字典`

## 执行步骤

### build 模式

1. 字典 Key、值域、翻译、引用方。

### modify 模式

1. 仅改命中字典。

### incremental 模式

1. Read 基线 §6.2 → DELTA。
2. **Key 禁止改**

**增量边界**：字典 | 键值 | **Key 禁止改**

## 质量检查点

- 与 data 枚举一致
- Key 唯一
- 分节标题字面量 `## §6.2 数据字典`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/config/config-dict.md`
