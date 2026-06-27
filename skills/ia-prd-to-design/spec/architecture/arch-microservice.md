---
element_id: arch-microservice
parent_domain: architecture
parent_element_id: architecture
---

# arch-microservice 设计规范

## 适用条件

- 系统需微服务/模块边界划分；别名 arch-service-topology。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/architecture.md` 的 `## §1.3 微服务划分`

## 执行步骤

### build 模式

1. 输出服务清单：名称、职责、依赖、数据归属。
2. 绘制服务依赖关系。

### modify 模式

1. 仅改命中服务边界。

### incremental 模式

1. Read 基线 §1.3 → DELTA。
2. **既有服务名称禁止修改**

**增量边界**：微服务 | 边界调整 | **服务名禁止改**

## 质量检查点

- 每个服务有明确数据归属
- 依赖无环或说明
- 分节标题字面量 `## §1.3 微服务划分`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/architecture/arch-microservice.md`
