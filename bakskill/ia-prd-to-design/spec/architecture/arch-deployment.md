---
element_id: arch-deployment
parent_domain: architecture
parent_element_id: architecture
---

# arch-deployment 设计规范

## 适用条件

- 存在部署/环境/拓扑诉求（容器、K8s、多环境）。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/architecture.md` 的 `## §1.2 部署架构`

## 执行步骤

### build 模式

1. 输出部署拓扑图（Mermaid 或文字拓扑）。
2. 说明各环境差异与配置注入点。

### modify 模式

1. 仅改命中部署节点/环境。

### incremental 模式

1. Read 基线 §1.2 → DELTA。

**增量边界**：部署 | 调整拓扑 | 生产拓扑变更须评审

## 质量检查点

- 拓扑与 PRD 容量/NFR 一致
- 环境命名规范
- 分节标题字面量 `## §1.2 部署架构`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/architecture/arch-deployment.md`
