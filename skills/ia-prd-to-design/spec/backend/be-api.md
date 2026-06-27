---
element_id: be-api
parent_domain: backend
parent_element_id: api-contract
---

# be-api 设计规范

## 适用条件

- PRD 命中 `element-registry.yaml` 中 `be-api.prd_sources` 的接口动作、TC/FR、请求/响应字段或权限点信号；依赖 data.md。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/backend-api.md` 的 `## §3.1 API 清单`

## 执行步骤

### build 模式

1. 按 `be-api.prd_sources.required_sections` / `optional_sections` 读取 PRD 章节，抽取 `extraction_keys` 中的 TC 编号、FR 编号、接口动作、请求字段、响应字段、权限点。
2. TC/FR→API 清单（路径/方法/幂等/认证）。
3. 契约表+示例 JSON。
4. Jalor/REST 前缀对齐。

### modify 模式

1. 仅改命中接口。

### incremental 模式

1. Read 基线 §3.1 → DELTA。
2. **路径/必填参数禁止破坏兼容**

**增量边界**：API | 入参出参 | **向后兼容**

## 质量检查点

- 幂等声明
- PRD 溯源：接口清单与详细设计必须能追踪到 `be-api.prd_sources.extraction_keys` 命中的 TC/FR 或 PRD 小节标题
- 错误码引用 config
- 分节标题字面量 `## §3.1 API 清单`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/backend/be-api.md`
