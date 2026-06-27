---
element_id: be-class
parent_domain: backend
parent_element_id: backend-impl
---

# be-class 设计规范

## 适用条件

- backend-api 已落盘；需 DDD 类设计。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。

## 输出归属

- 聚合到 `{DESIGN_DIR}/backend.md` 的 `## §3.2 类设计`

## 执行步骤

### build 模式

1. Application/Domain/Infrastructure 类清单。
2. 职责+抽象方法签名+依赖。
3. 包路径对齐 arch-code-structure。

### modify 模式

1. 仅改命中类。

### incremental 模式

1. Read 基线 §3.2 → DELTA。
2. **public 签名禁止改**

**增量边界**：类设计 | 新增/扩展 | **签名禁止改**

## 质量检查点

- API 有类落点
- 禁 Java 代码块
- 分节标题字面量 `## §3.2 类设计`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/backend/be-class.md`
