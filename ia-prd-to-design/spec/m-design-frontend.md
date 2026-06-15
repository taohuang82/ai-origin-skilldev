---
module_id: "m-design-frontend"
implements: "frontend"
for_scenario: ["专题需求", "优化需求"]
for_type: ["TP", "AP", "AI"]
execution_mode: ["build", "modify", "incremental"]
status: "active"
---

# m-design-frontend — 前端方案

> **一句话说明**：在 `frontend.md` §4.x 结构中交付技术选型、路由、布局、组件/字段、接口与数据、交互逻辑与非功能增补；条文见本包 `design-frontend`（含 **`fe-component` 增补**，见 `ELEMENT-SPEC-SOURCE-MAP.md`）。

---

## 目标

**目标说明**

在用户可修改的前端工程中，产出与 **backend-api.md**/**config.md** 对齐的：**一级目录路由策略**、`useService` 网络契约、Vue3 + `vue-demi` Composition、布局与字段级 UI 规格，以及交互状态/反馈规范和 DFX/UEM/i18n 增量。

**输出物**

- `frontend.md` 中含 §4.1〜§4.7 等同名二级标题段落（可按 orchestration `chapter_info` 重编号）。

**成功标准**

- 未写路由 `router` 源码；不写裸 `axios` 堆砌；章节依赖顺序：**§4.2 路由 → §4.3 布局 → §4.4/组件 → §4.5 → §4.6**；§4.7 与 `config.md` 边界清晰。

---

## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|---------------------|------|
| `api-contract` | URL/方法与前端声明一致 |
| `config` | 权限矩阵、错误码对齐 |

---

## 约束

### 格式规范

| standard_id | 规范说明 |
|-------------|---------|
| `design-frontend` | 七子要素 + `fe-component` 恢复条文、`er-diagram`(无则不加载) |

### 设计约束

| 约束编号 | 级别 | 规则 | 验证方法 |
|----------|------|------|----------|
| `DC-FE-001` | `MUST_NOT` | 禁止 Options API 与 `/v`/二级 path 文案 | grep |
| `DC-FE-002` | `MUST` | 接口依赖表仅指向已定 backend-api | 对照 |
| `DC-FE-003` | `MUST_NOT` | 仅输出前端设计与交互说明，禁止直接输出可执行具体代码（含完整方法体、脚本、SQL） | Review |

---

## 要素映射

| 子要素目录 | 说明 |
|------------|------|
| `fe-tech-stack` | Vue3、webpack、脚手架边界 |
| `fe-route-design` | 一级目录、外部注册、Query/detail |
| `fe-layout` | Layout 分区与稿对齐 |
| `fe-component` | Page/Container/Component 拆分与通信（增补） |
| `fe-component-field` | 复用声明 + Props/表格列/表单/枚举 |
| `fe-api-data` | useService、`get/post`、并发与映射 |
| `fe-interaction-logic` | 状态、`Message`/`Dialog`、脏检查 |
| `fe-nfr` | §4.7 与配置域边界 |

---

## 执行步骤

1. `$[自动]$`：一页一表清点路由与 §4.x 占位。
2. `$[自动]$`：对齐接口表与后端清单。
3. `$[交互]$`：高保真/设计文档缺口确认。
4. `$[自动]$`：回填 DFX 与影响范围模板。

### incremental 模式

**Step 1:** `[自动]` 读取基线 frontend.md，定位受影响的页面/组件/交互章节，
提取 baseline_state。

**Step 2:** `[自动]` 对 element_changes 生成 DELTA 块和 DIP，遵循以下约束：

| 子域 | 增量核心动作 | 强制边界约束 |
|------|------------|------------|
| 页面清单与布局 | 新增/调整页面路由和布局 | — |
| 已有组件复用 | 盘点可复用组件 | — |
| 新增组件设计 | Props/Emits/Slots 定义 | — |
| 页面交互 | 新增/调整交互流程和接口依赖声明 | — |

**Step 3:** `[交互]` 若新增页面对应的后端接口尚未在 backend-api.md 中定义，暂停确认。

---

## 输出骨架

```markdown
## {章节} 前端方案

### §4.1 技术选型
### §4.2 路由信息设计
### §4.3 布局结构
### §4.4 组件与字段（含拆分原则 — fe-component）

### §4.5 接口与数据

### §4.6 交互逻辑

### §4.7 非功能设计
```
