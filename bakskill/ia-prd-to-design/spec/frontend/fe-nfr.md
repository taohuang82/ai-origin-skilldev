---
element_id: fe-nfr
parent_domain: frontend
parent_element_id: frontend
---

# fe-nfr 设计规范

> 本要素已整合原 `fe-i18n`（国际化）子要素，`fe-i18n` 作为 alias 路由至本要素。国际化作为 §4.7 内部子分段输出，不再单独成节。

## 适用条件

- 前端性能 / 安全 / 可访问性诉求。
- PRD 含多语言 / 国际化要求。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/frontend.md` 的 `## §4.7 非功能设计`
- 国际化内容作为 §4.7 内部子分段（支持语言、文案键清单、格式化规则）输出，不再使用独立标题 `## §4.7 非功能设计（国际化）`。

## 执行步骤

### build 模式

1. 性能预算、安全头、A11y 要点。
2. 支持语言、文案 Key 清单、格式化规则。

### modify 模式

1. 仅改命中 NFR 项。
2. 国际化：仅改命中 Key。

### incremental 模式

1. Read 基线 §4.7 → DELTA。

**增量边界**：FE NFR | 指标 | 可度量 | i18n 文案 Key（Key 禁止改）

## 质量检查点

- 指标可验证
- 与架构 NFR 不冲突
- 国际化：Key 命名规范、默认语言明确
- 分节标题字面量 `## §4.7 非功能设计`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/frontend/fe-nfr.md`
