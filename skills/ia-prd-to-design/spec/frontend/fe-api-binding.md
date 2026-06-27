---
element_id: fe-api-binding
parent_domain: frontend
parent_element_id: frontend
---

# fe-api-binding 设计规范

## 适用条件

- frontend 需消费 backend-api。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/frontend.md` 的 `## §4.5 接口与数据`

## 执行步骤

### build 模式

1. 接口绑定表：页面/组件 → API → 字段映射。

### modify 模式

1. 仅改命中绑定。

### incremental 模式

1. Read 基线 §4.5 → DELTA。

**增量边界**：API 绑定 | 字段映射 | 契约一致

## 质量检查点

- 每个 API 有消费方
- 类型与契约一致
- 分节标题字面量 `## §4.5 接口与数据`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/frontend/fe-api-binding.md`
