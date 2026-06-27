---
element_id: config-permission
parent_domain: config
parent_element_id: config
---

# config-permission 设计规范

## 适用条件

- PRD 含权限/角色/数据权限。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/config.md` 的 `## §6.5 权限`

## 执行步骤

### build 模式

1. 权限矩阵、角色、资源点、与 API 双层模型对齐。

### modify 模式

1. 仅改命中权限点。

### incremental 模式

1. Read 基线 §6.5 → DELTA。

**增量边界**：权限 | 矩阵 | 标识符稳定

## 质量检查点

- 与 backend-api 权限列一致
- 矩阵无空壳
- 分节标题字面量 `## §6.5 权限`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/config/config-permission.md`
