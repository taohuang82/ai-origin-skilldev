---
module_id: "m-design-config"
implements: "config"
for_scenario: ["专题需求", "优化需求"]
for_type: ["TP", "AP", "AI"]
execution_mode: ["build", "modify", "incremental"]
status: "active"
---

# m-design-config — 配置与安全（配置域）

> **一句话说明**：在 `config.md` 固化配置分层、字典/错误码、权限矩阵与非功能（含前端 NFR 等与配置域交叉的节选）；条文见本包 `design-config`。

---

## 目标

**目标说明**

提供全链路 **可追溯** 的可运行参数与治理：运行时配置 Key、Lookup/配置平台强约束、唯一错误码、RBAC + 数据范围、观测性与安全红线；并保持与 **`integration`**、**前端 §4.7** 的边界自述。

**输出物**

- `config.md` 内含 §6.1〜§6.n 等价结构（以实际编排章节为准）：字典、错误码、权限矩阵、扩展配置项与非功能摘录。

**成功标准**

- 权限点为 API 与前端的单一事实来源；新增错误码不破坏既有语义；配置表 DDL 细则（`config_*`/`_temp`/`published_flag`）在适用场景下逐项满足。

---

## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|---------------------|------|
| `api-contract` | 注解权限码需在矩阵出现 |
| （可选）`frontend` | 路由 meta 与 `v-if` 权限引用矩阵 |

---

## 约束

### 格式规范

| standard_id | 规范说明 |
|-------------|---------|
| `design-config` | config-app-config, config-dict, config-error-code, config-nfr-security, config-permission |

### 设计约束

| 约束编号 | 级别 | 规则 | 验证方法 |
|----------|------|------|----------|
| `DC-CFG-001` | `MUST` | 权限矩阵单行定义，`frontend`/`backend` 只引用不透传 | Phase 5 |
| `DC-CFG-002` | `MUST` | `config-error-code` / `dict` 两处格式若共存须标注适用系统 | Review |
| `DC-CFG-003` | `MUST_NOT` | 仅输出配置与安全设计说明，禁止直接输出可执行具体代码（含完整方法体、脚本、SQL） | Review |

---

## 要素映射

| 子要素目录 | 说明 |
|------------|------|
| `config-app-config` | 分层、Lookup、大数据量配置表 DDL、观测与前端 NFR 摘录整合 |
| `config-dict` | 运维侧字典编码 `App.SubApp.*` |
| `config-error-code` | Jalor/`APP-*` 两套格式并陈（均以原文分段保留）|
| `config-nfr-security` | 摘录版 NFR |
| `config-permission` | RBAC/Jalor/数据权限/前后端联动 |

---

## 执行步骤

1. **`[自动]`**：罗列本次新增动态配置与环境变量。
2. **`[自动]`**：错误码增量 + i18n 键。
3. **`[自动]`**：矩阵与路由/注解对齐。
4. **`[交互]`**：与用户确认与 `frontend.md`§4.7、`integration` 兜底边界。

### incremental 模式

**Step 1:** `[自动]` 读取基线 config.md，定位受影响的字典/权限/配置/NFR 章节，
提取 baseline_state。

**Step 2:** `[自动]` 对 element_changes 生成 DELTA 块和 DIP，遵循以下约束：

| 子域 | 增量核心动作 | 强制边界约束 |
|------|------------|------------|
| 数据字典 | 新增/调整键值映射 | **既有键值 Key 禁止修改** |
| 权限矩阵 | 矩阵行列增减；权限点标识符新增 | — |
| 配置项清单 | 新增配置项 | — |
| 非功能与安全 | 调整性能指标或脱敏规则 | — |

---

## 输出骨架

```markdown
## {章节} 配置与安全
### （按标准分段）字典 / 错误码 / 权限 / 运行时配置 / 非功能与安全
```
