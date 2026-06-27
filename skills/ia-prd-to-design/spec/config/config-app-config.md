---
element_id: config-app-config
parent_domain: config
parent_element_id: config
---

# config-app-config 设计规范

## 适用条件

- 存在应用级配置/Feature 配置。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/config.md` 的 `## §6.1 应用配置`

## 执行步骤

### build 模式

1. 配置项清单、分层、热更新策略。

### modify 模式

1. 仅改命中配置项。

### incremental 模式

1. Read 基线 §6.1 → DELTA。

**增量边界**：应用配置 | 项增减 | 环境隔离

## 质量检查点

- 敏感项加密
- 默认值明确
- 分节标题字面量 `## §6.1 应用配置`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/config/config-app-config.md`
