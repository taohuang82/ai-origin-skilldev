---
module_id: "m-design-api"
implements: "api-contract"
for_scenario: ["专题需求", "优化需求"]
for_type: ["TP", "AP", "AI"]
execution_mode: ["build", "modify", "incremental"]
status: "active"
---

# m-design-api — 后端接口契约

> **一句话说明**：在 **`backend-api.md`** 中对齐 REST `/uiapi`/`/services`/`/publicservices` 前缀下的接口契约、分页、权限双层模型与 Jalor；条文与模板见本包 `design-api-contract`（独立于 **backend-impl** 要素）。

---

## 目标

**目标说明**

把 PRD 功能规格条目（TC / FR）**逐条可追溯**映射为 HTTP API：清单、契约表、示例 JSON、双层权限与增量标注；不改变既有错误码语义。

**输出物**

- `backend-api.md` / 团队约定名下的 API 契约主文件，`config.md`/`dict-error`/权限章节仅交叉引用不重定义全集。

**成功标准**

- 每条写操作声明幂等与认证；与方法语义表一致（GET 幂等等）；PRD 溯源列无悬空。

---

## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|---------------------|------|
| `data-model` | 分页/枚举字段语义一致 |

**必要输入**

- PRD 「功能规格」与 Story 条目；如涉及存量改动，须提供影响面说明位。

---

## 约束

### 格式规范

| standard_id | 规范说明 |
|-------------|---------|
| `design-api-contract` | `be-api` 规范 + 契约模板全文 |

### 设计约束

| 约束编号 | 级别 | 规则 | 验证方法 |
|----------|------|------|----------|
| `DC-API-001` | `MUST` | UI/Public/Private 路径前缀与设计规范一致 | path grep |
| `DC-API-002` | `MUST` | Jalor 第一层 + 第二层数据权限在详设表中成对出现 | checklist |
| `DC-API-003` | `MUST_NOT` | 不得在路径中夹带 `/v1` 层级 | Regex |
| `DC-API-004` | `MUST_NOT` | 仅输出接口设计与契约说明，禁止直接输出可执行具体代码（含完整方法体、脚本、SQL） | Review |

---

## 要素映射

| 子要素目录 | 说明 |
|------------|------|
| `be-api` | REST/Jalor/OpenAPI/YAML 摘录、分页结构、双层权限 |

---

## 执行步骤

1. **`[自动]`**：从 Story/PRD 提取接口草稿表。
2. **`[自动]`**：逐接口展开请求/响应/错误/权限段落。
3. **`[交互]`**：与用户确认兼容性（存量 🔧）。
4. **`[自动]`**：同步「实现逻辑」最少步骤占位供 backend 细化。

### incremental 模式

**Step 1:** `[自动]` 读取基线 backend-api.md，定位受影响的接口清单和错误码章节，
提取 baseline_state。

**Step 2:** `[自动]` 对 element_changes 中每个变化点，生成 DELTA 块和 DIP，遵循以下约束：

| 子域 | 增量核心动作 | 强制边界约束 |
|------|------------|------------|
| API 清单 | 新增接口或修改入参出参 | **既有接口路径和必填参数禁止删除（向后兼容）** |
| 错误码体系 | 新增错误码 | **既有错误码编号禁止修改**；新增需全局唯一 |

**Step 3:** `[自动]` compatibility_note 须说明 API 版本兼容策略（纯新增 / 参数可选扩展 / 需版本号切换）。

**Step 4:** `[交互]` 若涉及修改既有接口的入参/出参，暂停确认影响范围。

**boundary_constraints 模板**（接口示例）：

```yaml
boundary_constraints:
  - target: "{HTTP Method} {既有接口路径}"
    reason: "外部系统/前端已依赖，接口契约不可变"
    consequence: "修改既有接口参数将导致调用方失败"
    evidence: "基线 backend-api.md §{章节}"
```

---

## 输出骨架

```markdown
## {章节} 后端接口契约

### 变更概要
### 接口清单
### 通用约定
### 接口详细设计
```
