---
element_id: config-error-code
parent_domain: config
parent_element_id: config
---

# config-error-code 设计规范

## 适用条件

- 需定义/引用错误码。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/config.md` 的 `## §6.3 错误码`

## 执行步骤

### build 模式

1. 错误码分层、HTTP 映射、中英文描述。

### modify 模式

1. 仅改命中错误码。

### incremental 模式

1. Read 基线 §6.3 → DELTA。
2. **已发布码禁止改语义**

**增量边界**：错误码 | 新增 | **语义不变**

## 质量检查点

- 与 be-api 引用一致
- 分层命名
- 分节标题字面量 `## §6.3 错误码`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/config/config-error-code.md`
