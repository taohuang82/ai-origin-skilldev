# 交易类（TP）需求 → tp-ux 结构样例路由

> 路径相对于 **`<iscit-req2proto>/references/tp-ux/examples/`**。  
> **定位 skill 根**、禁止在用户工程内查找案例等约定，与主 `SKILL.md`「执行总则」一致。  
> **与 dxp-ux 的分工**：需要 **DXP 四层列表**（顶栏操作 → 单行筛选含设置 → 表体 → 分页）时，改用 **`references/dxp-ux/examples/EXAMPLES_MAP.md`** 选择 `list-page` 等；本节仅覆盖 **TP 典型「查询条件表单 + 表格」**。

## 选用流程

1. 用户选择 **交易类 (tp)**，且页面为 **列表 + 条件查询**（表单栅格、申请单/合同/状态下拉等），**优先**在本表 **从上往下命中第一条最具体** 的目录。
2. Read：`<iscit-req2proto>/references/tp-ux/examples/<目录>/index.html` 与 `styles.css`。
3. 并联读：`<iscit-req2proto>/references/tp-ux/rules.md`（列序与查询区硬规则）。
4. 弹窗/抽屉/间距等仍建议 Read `references/dxp-ux/rules.md` 对应章节。

## 目录与关键词

| 目录 | 典型形态 | 关键词（命中则优先本 tp-ux 样例） |
|------|------------|-------------------------------------|
| `multi-tab-tp-page` | **主区顶部多 Tab**（`tablist` 切换 `tabpanel`）+ **Tab1**：可折叠「查询条件」+ 可选标题栏右侧图标 + 表单栅格 + **表区标题行**（左标题+导出 / 右图标）+ **左序列表格** + 分页；**Tab2**：KPI 卡片 + **柱状/趋势图占位**；其余 Tab 占位 | 多 Tab、多页签、页签切换、tablist、协同查询、SPART、主区 Tab、分析页、图表、KPI、第二个页签分析 |
| `e-flow-approval-page` | **左侧 nav-menu**（菜单顶筛 + 分组/高亮）+ **右侧** **可折叠「查询条件」页签条** + 表单栅格 + 表上导出 + **表列：序号 / 选择 / 操作 / 业务…** + 分页；表头可用浅蓝 | 电子流审批、电子流、审批流、左侧导航、nav-menu、侧栏菜单、aside、管理台、历史查询、创建申请、我的待办、我的申请、我已审批 |
| `list-query-table-page` | **无侧栏** 整页：**可折叠「查询条件」页签条** + 表单栅格 + 表上导出 + **左序列表格** + 分页 | 查询条件、筛选表单、申请单、合同号、单据状态、导出、ERP 列表、物料列表（表单筛）；**未**强调左侧主导航壳 |

## 默认回退（仅 tp）

- 交易类且为 **通用列表 + 表单查询**，**无**「左侧主导航 / 电子流」等关键词、且未命中 dxp-ux 的 `tree-table-page` / `logistics-map-page` 等时 → **`list-query-table-page`**。

## 何时仍选 dxp-ux 的 `list-page`

- 明确要求 **顶栏批量操作** + **单行关键字搜索** + **设置 icon 在筛选行** 的 DXP 四层模式 → 读 `references/dxp-ux/examples/EXAMPLES_MAP.md`，选 `list-page`。

## 与 isc-scenarios 的对应（辅助推断）

结合 [isc-scenarios.md](../../isc-scenarios.md)：

- 场景 1–7（采购/销售/库存/物流单证/供应商/计划/质检）以 **表单查询 + 表格** 为主、无「必须 DXP 顶栏+单行搜索」描述时 → 默认 **`list-query-table-page`**。
- 场景 8（全球运输监控）→ 仍选 **dxp-ux** `logistics-map-page`。
- 场景 9–12 分析看板 → 若在 **同一 TP 页** 内以 **第二个 Tab** 呈现图表而 **非整页深色大屏** → **`multi-tab-tp-page`**（Tab2）；若整页深色 KPI 大屏 → **ap** + dxp-ux / `template-ap`。
- **待办/审批队列** 若以 **卡片分区** 为主 → **dxp-ux** `todo-task-page`；若以 **表格队列 + 查询表单** 为主 → 默认 **`list-query-table-page`**；若同时含 **电子流 / 左侧 nav-menu 管理台壳** → **`e-flow-approval-page`**。

## 禁止

- 禁止在未 Read 选定目录下 `index.html` / `styles.css` 的情况下声称已参考 tp-ux。
- 禁止将 **TP 表列顺序**（序号、选择、操作在左）与 dxp-ux `list-page`（操作列在右、无独立序号列）混用同一页却不加说明。
