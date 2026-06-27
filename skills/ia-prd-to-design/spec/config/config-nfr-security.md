---
element_id: config-nfr-security
parent_domain: config
parent_element_id: config
---

# config-nfr-security 设计规范

## 适用条件

- 安全/NFR 与配置交叉（加密/审计/限流）。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/config.md` 的 `## §6.4 安全与非功能`

## 执行步骤

### build 模式

1. 安全策略、加密、审计、限流阈值。

### modify 模式

1. 仅改命中策略。

### incremental 模式

1. Read 基线 §6.4 → DELTA。

**增量边界**：安全 NFR | 策略 | 合规

## 质量检查点

- 可审计
- 密钥不入库明文
- 分节标题字面量 `## §6.4 安全与非功能`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/config/config-nfr-security.md`
