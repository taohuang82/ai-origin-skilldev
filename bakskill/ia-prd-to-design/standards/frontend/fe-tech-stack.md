---
standard_id: "fe-tech-stack"
domain: "frontend"
---

# fe-tech-stack

**规范分段**：`fe-tech-stack`

### 规范条文

# 技术选型规范（§4.1 · `fe-tech-stack`）

对应要素：**技术选型**。仅在 **0-1 / 新建前端工程**且需在设计上固化栈选型或与方案对齐时展开。

---

## 适用性（强制）

| 情形 | 处理 |
| ---- | ---- |
| 全新前端工程或首轮前端详细设计 | 须评估并按模板输出 |
| 迭代需求、技术栈未变且文档已固化 | **省略整节**，执行摘要：`⏭️ 已评估，本次不适用` + 原因 |

---

## 项目框架约束（重要）

生成技术方案时**必须**遵守（与落盘 `frontend.md` 中「编码约束」一致）：

### Vue 版本与写法

- **允许**：Vue 3 **Composition API**，API 从 **`vue-demi`** 引入（`ref`、`reactive`、`computed`、`watch`、`onMounted` 等）。
- **禁止**：Vue 2 **Options API**（`data()`、`methods`、`computed` 选项对象形式等）。

### 构建与工程形态

- **构建工具**：**webpack**（linkjs 微组件框架内置打包；后续可能升级为 vite，以脚手架为准）。
- **方案粒度**：技术方案中**忽略**具体打包、loader、脚手架命令等实现细节，只描述与设计相关的栈结论。

### 与总体文档的关系

- 与 `prd.md`、`architecture.md`（若存在）、前端工程 `docs/init/ARCHITECTURE.md`（若存在）一致；不得与组织强制脚手架冲突。
- **禁止**在方案中粘贴完整可运行工程配置源码；用表格与条目描述即可。

---

## 编写要求（补充）

- 写明：Vue 与 Composition API 约定、`vue-demi`、UI/微组件体系、状态方案、**一级路由目录策略**（见 `fe-route-design`）、目录与模块边界。
- 已有统一模板或强制栈时，以引用路径为主，本节列差异与例外。

## 输出骨架
# §4.1 技术选型（写入 `frontend.md`）

> 对应二级标题：`## §4.1 技术选型`。迭代或未变更栈时**删除整节**。

---

## 变更概要

{本分节 ✨ 新增 / 🔧 修改条目计数与一句话摘要}

---

## 框架选型摘要

| 维度 | 选型说明 |
| ---- | -------- |
| Vue | Vue 3；仅 Composition API；API 自 **`vue-demi`** 引入 |
| 禁止项 | 不使用 Vue 2 Options API（`data` / `methods` 等选项式写法） |
| 微组件 / UI | linkjs 及团队约定组件库 |
| 状态与组合式 | ref/reactive/composable；跨页约定（如 Store）按工程惯例 |
| 构建 | webpack（linkjs 内置）；方案不展开打包细节 |
| 服务与路由 | 见「编码约束」：`useService()`、一级页面目录、外部路由注册 |
| 依据文档 | `docs/init/`、`prd.md`、`architecture.md`（若存在）、脚手架说明路径 |

---

### 与脚手架差异或例外

| 项 | 说明 |
| -- | ---- |
| | |