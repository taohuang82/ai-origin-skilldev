---
name: iscit-req2proto
description: >-
  将供应链业务需求转换为可交互的 HTML 原型页面；内置 ISC IT / DXP UX 规范（栅格、弹窗、抽屉、表格、文案与主按钮色），
  并内置 **TP 交易列表** 专用参考 `references/tp-ux/`（可选 **左侧 nav-menu + 主区** 电子流壳；可选 **主区顶部多 Tab**；查询条件表单 + 表格左：序号/选择/操作/业务列），与 TinyVue 视觉体系对齐以便后续转 Vue3。
  支持语言描述或草图识别两种输入方式，生成符合 TinyVue 视觉规范的交易类(tp)或分析类(ap)原型，数据存储于 localStorage 提供逼真体验。

  模板与结构案例（assets、references/tp-ux/examples、references/dxp-ux/examples）仅存在于本 skill 目录 iscit-req2proto 内；
  禁止在用户业务项目根目录下检索 examples 或案例作为本技能的参考来源。
  执行时以 SKILL 正文「执行总则」为纲：先定位 skill 根再 Read；tp 默认读 tp-ux 样例（查询表单+左序表）；仅 dxp-ux 的 list-page 须四层列表模式；产出写入用户工程 output/。
  当用户提到需求原型、页面原型、供应链页面设计、交互原型、UI 原型、req2proto 时使用此技能。
---

# ISC 需求转原型（iscit-req2proto）

将供应链业务需求快速转化为可交互的 HTML 原型页面，无需任何技术背景即可使用。  
**DXP UX** 已融入本技能：弹窗/抽屉/栅格等默认可遵守 `references/dxp-ux/` 下的规则与 tokens。**交易类列表页**默认以 **`references/tp-ux/`** 为结构主参考（与 DXP 四层 `list-page` 区分）；用户明确要求 DXP 四层列表时再切换读 `dxp-ux/examples` 的 `list-page`。不单独增加「是否 DXP」询问项，由需求描述与路由表判定。

## 执行总则（全局一条线）

下文所有「读」与「禁止」均围绕下表，**先读本节再执行 Step 0～5**。

| 维度 | 约定 |
|------|------|
| **skill 根目录** | 记为 `<iscit-req2proto>`（与本 `SKILL.md` 同级）。**先** `Glob **/iscit-req2proto/SKILL.md`，取其**所在目录**；ISC-Q 仓库内亦可用 `skills/iscit-req2proto/...`（从**仓库根**起）。 |
| **读什么** | **tp**：在 `<iscit-req2proto>` 下 Read **`references/tp-ux/examples/EXAMPLES_MAP.md`** → 选定 **1 个** `references/tp-ux/examples/<目录>/` 的 `index.html` + `styles.css` → **`references/tp-ux/rules.md`** → `assets/template-tp.html` → `references/dxp-ux/rules.md`（弹窗/抽屉等）+ `references/dxp-ux/components.md` + `references/dxp-ux/ux-tokens.json` + `references/tinyvue-spec.md`（见 Step 3）。若用户明确要求 **DXP 四层列表**，则样例改读 **`references/dxp-ux/examples/EXAMPLES_MAP.md`** 并按其选 `list-page` 等。**ap**：Read `references/dxp-ux/examples/EXAMPLES_MAP.md` → 选定示例目录 + `assets/template-ap.html` + 同上 dxp/tinyvue 必读清单。 |
| **禁止** | **不得**在用户业务工程根下用 `assets/`、`references/`、`examples/` 等路径查找本技能模板/案例（会 `File not found` 或误用用户仓库里的无关 `examples`）。**不得**在未定位 `<iscit-req2proto>` 时虚构模板文件。 |
| **样例与布局** | **tp 默认**：`references/tp-ux/examples/`（`EXAMPLES_MAP` 选目录）；表格 **自左向右** 须为 **序号 → 选择（多选/单选）→ 操作 → 业务列**，见 `tp-ux/rules.md` 与 **`e-flow-approval-page` / `list-query-table-page`** 等样例。**仅当**选用 `dxp-ux` 的 **`list-page`** 时，才强制 **四层列表模式**（顶栏操作→筛选含设置→表体→底部分页），见 `dxp-ux/examples/EXAMPLES_MAP.md`。 |
| **写什么** | 仅将 `proto-<功能名>.html` 写入 **用户业务工作区** 项目根下的 `prototypes/`（与 skill 目录无关）。 |

## 资源路径与 Read 约定（必读）

本 skill 资产与用户业务工程**不在同一路径**。落实「执行总则」表格后，按序操作：

1. **定位**：`Glob **/iscit-req2proto/SKILL.md` → 得到 `<iscit-req2proto>`。
2. **Read**：使用 `<iscit-req2proto>/assets/...`、`<iscit-req2proto>/references/...` 等**带 skill 根**的路径；禁止仅用 `assets/template-tp.html` 相对用户工程根。
3. **找不到 skill 树**：请用户打开含 `skills/iscit-req2proto` 的工作区或同步 skill；禁止在用户工程内创建假 `assets` 代替读取。
4. **产出路径**：仅在用户工程根下确保 `prototypes/` 存在并写入 `proto-*.html`。

## DXP UX 与 TinyVue 的关系（无额外选项）

- **交易类 (tp)**：**列表 + 查询表单** 的布局与 **表格左三列顺序** 以 **[references/tp-ux/rules.md](references/tp-ux/rules.md)** 与 **`references/tp-ux/examples/`** 为准（查询区主按钮可用信息蓝 **#1677FF**，与 TinyVue 常见交易页一致）。Modal/Drawer、栅格间距、空值 `--`、中文文案等仍以 **[references/dxp-ux/rules.md](references/dxp-ux/rules.md)** 为补充验收。**整页主按钮**若与 DXP 主色 **#191919**（`ux-tokens.json`）并存，在说明中标注层级（查询区 vs 全局）。
- **TinyVue 映射**：色彩体系中信息/链接强调、状态色等仍参考 **[references/tinyvue-spec.md](references/tinyvue-spec.md)**；**DXP 四层 list-page** 场景下主 CTA 仍以 DXP 为准；**TP 查询表单**场景下查询主按钮可按 tp-ux 使用蓝色主按钮。
- **分析类 (ap)**：深色大屏视觉以 **tinyvue-spec 分析类** 为主；若页面含表格/弹窗/抽屉，其**结构与档位**仍应尽量符合 `references/dxp-ux/rules.md` 对应条目。
- **参考示例**：**tp** 见 `references/tp-ux/examples/` 与 `references/tp-ux/examples/EXAMPLES_MAP.md`；**DXP 四层 list-page** 及其他形态见 `references/dxp-ux/examples/EXAMPLES_MAP.md`（路径均相对 `<iscit-req2proto>`）。

## 工作流程

### Step 0：确定操作场景

首先使用 AskQuestion 工具询问用户：

**问题** — 您要做什么？

- **新增页面**：从零开始创建一个新的原型页面
- **更新现有页面**：对已有的原型页面进行修改

如果用户选择**新增页面** → 进入 Step 1。

如果用户选择**更新现有页面** → 请用户输入要修改的 HTML 文件名（位于 `output/` 目录下），然后使用 Read 工具读取该文件内容，确认文件存在后，直接跳到 Step 3 让用户描述修改需求。

### Step 1：确定页面类型（仅新增页面）

使用 AskQuestion 工具向用户提问：

**问题 1** — 页面类型：

- **交易类 (tp)**：表单、列表、订单管理等操作页面 → 浅色风格；**列表页默认按 tp-ux（查询表单 + 左序表格）**，并联 DXP 规则用于弹窗/抽屉等
- **分析类 (ap)**：数据大屏、监控看板等展示页面 → 深色科技感；**大屏视觉以 TinyVue ap 为主，组件结构参考 DXP**

### Step 2：确定输入方式（仅新增页面）

**问题 2** — 需求输入方式：

- **语言描述**：用户用自然语言描述页面需求
- **草图识别 + 语言描述**：用户上传 UI 草稿图片，模型通过多模态能力识别后结合语言描述生成原型

Step 1 和 Step 2 可合并为一次 AskQuestion 提问。

### Step 3：获取需求并生成原型

根据用户选择的场景走对应分支：

#### 分支 A：语言描述场景

1. 请用户描述页面需求（功能、字段、交互流程）
2. **样例路由（必做）**：
   - **tp**：Read `<iscit-req2proto>/references/tp-ux/examples/EXAMPLES_MAP.md`，按关键词 **自上而下命中最具体** 的一条，选定 **唯一** `references/tp-ux/examples/<目录>/`，再 Read 该目录 `index.html` + `styles.css`；并联 Read **`references/tp-ux/rules.md`**。无更具体命中时默认 **`list-query-table-page`**（见 tp-ux EXAMPLES_MAP「默认回退」）；含 **电子流 / 左侧 nav-menu 管理台壳** 时优先 **`e-flow-approval-page`**。若用户 **明确要求 DXP 四层列表**（顶栏操作、单行筛选含设置、无独立「查询条件」大表单），则改 Read **`references/dxp-ux/examples/EXAMPLES_MAP.md`** 并选 **`list-page`**（或表中更具体目录），再 Read 对应 `index.html` + `styles.css`；**选中 `list-page`** 时须落实 **四层列表模式**（见 dxp-ux EXAMPLES_MAP「list-page 专区」）。
   - **ap**：Read `<iscit-req2proto>/references/dxp-ux/examples/EXAMPLES_MAP.md`，选定 **唯一** `references/dxp-ux/examples/<目录>/`，再 Read `index.html` + `styles.css`。
3. 根据 tp/ap 类型读取 **skill 内** 对应模板（路径均相对于 `<iscit-req2proto>`，禁止从用户工程根解析）：
   - tp → Read `<iscit-req2proto>/assets/template-tp.html` — 样式与 `tv-*` 参考
   - ap → Read `<iscit-req2proto>/assets/template-ap.html` — 大屏参考
4. **必须同时读取**（同样在 `<iscit-req2proto>/references/...` 下）：
   - `references/tinyvue-spec.md` — TinyVue 与 tp/ap 色彩/组件映射
   - **tp 时**：`references/dxp-ux/rules.md`（Modal/Drawer/栅格/表格通用项）、`references/dxp-ux/components.md`、`references/dxp-ux/ux-tokens.json`；已选 dxp **`list-page`** 时再全量对齐 DXP 列表规则
   - **ap 时**：`references/dxp-ux/rules.md`、`references/dxp-ux/components.md`、`references/dxp-ux/ux-tokens.json`
5. 结合 `references/isc-scenarios.md` 推断字段、状态与操作；**tp** 场景编号与 **tp-ux** 样例目录对应见 `references/tp-ux/examples/EXAMPLES_MAP.md`；**ap** 与 dxp-ux 对应见 `references/dxp-ux/examples/EXAMPLES_MAP.md`。

#### 分支 B：草图识别 + 语言描述场景

当用户选择此方式后，**必须立即**用以下话术引导用户上传草图：

> 请将您的 UI 草稿图片通过以下任一方式发给我：
> - **拖拽**：把图片文件直接拖到下方对话框
> - **粘贴**：截图后在对话框中 Ctrl+V 粘贴
> - **附件按钮**：点击对话框左侧的 📎 按钮选择图片文件
>
> 支持手绘草图、白板拍照、Axure/Figma 截图等，格式支持 PNG、JPG、JPEG、WebP。
> 上传后您还可以补充文字说明。

用户上传图片后的处理流程：

1. 使用 Read 工具读取用户提供的图片文件路径，触发多模态识别
2. 从草图中提取：页面布局结构、组件类型与位置、文字标注、交互意图
3. 将识别结果汇总后回复用户确认，格式如下：
   > **草图识别结果：**
   > - 布局：（描述整体结构）
   > - 包含组件：（列出识别到的表单/表格/按钮等）
   > - 文字标注：（列出识别到的文字）
   > - 我的理解：（用一句话总结页面用途）
   >
   > 以上理解是否正确？您还有什么补充吗？
4. 用户确认或补充后，先按 **分支 A 第 2～5 步** 完成样例路由（tp 读 **tp-ux** EXAMPLES_MAP；ap 读 **dxp-ux** EXAMPLES_MAP）与必读文件清单，再结合草图识别结果生成原型

### Step 4：生成 HTML 文件

生成规则：

- **单文件输出**：每个需求生成 1 个独立的 HTML 文件，所有 CSS/JS 内联
- **结构来源**：页面分区与模块组合须体现 Step 3 所选 **examples 样例** 与 **tp/ap 模板** 的合并结果；禁止输出与已选样例形态明显冲突的版式（例如列表需求却生成无表单的纯地图页），除非用户明确要求
- **`list-page` 四层模式（仅 dxp-ux）**：当 **dxp-ux** EXAMPLES_MAP 选定 **`list-page`** 时，列表页 **只能** 使用 **顶栏操作列 → 筛选区（设置 icon 在本区）→ 表格内容区（仅表体）→ 底部 pager 区** 四层纵向结构（可选 `ux-tabs` 在最上）；**禁止**合并为无分区大杂烩、禁止把分页塞进表头、禁止把设置 icon 挪到表头代替筛选区。细则见 `references/dxp-ux/examples/EXAMPLES_MAP.md`「list-page 专区」。
- **tp-ux 列表（默认 tp）**：当选用 **`list-query-table-page`**、**`e-flow-approval-page`**、**`multi-tab-tp-page`** 或其他 tp-ux 目录时：无侧栏样例为 **查询条件区 → 表上轻量操作条 → 表体 → 底部分页**；**`e-flow-approval-page`** 在 **整页最外** 增加 **左侧 `tp-navMenu` + 右侧 `tp-main`**；**`multi-tab-tp-page`** 在 **主区顶** 增加 **`role="tablist"` 多页签**，各 `tabpanel` 内再按需放查询区+表格或分析图表。**`multi-tab-tp-page` 的 Tab1** 查询区 **顶部左侧** 须有 **「查询条件」** 条（浅蓝；**chevron 与文案间距 16px**；**同一行最右** 可有固定/布局/设置等 icon，点击不触发展开）；点击 **文案+chevron 区** 可 **收起/展开** 表单与查询/重置；表区可有 **左标题+导出 / 右图标** 行。**含表格的 Tab** 列序须符合 **`tp-ux/rules.md`**：**序号 → 选择 → 操作 → 业务列**；**不要求** DXP 四层，**禁止**在未选 `list-page` 时强行套四层却把操作列留在最右侧。
- **数据存储**：所有交互数据使用浏览器 `localStorage` 存取，提供逼真的 CRUD 体验
- **视觉与 UX**：遵循 TinyVue 规范，并 **默认满足** `references/dxp-ux/rules.md`（交易类 tp 全量；分析类 ap 按上文说明）
- **主按钮**：**DXP 四层 list-page** 或整页全局主 CTA 背景色 **#191919**，hover/active 使用 `ux-tokens.json` 中 `color.primary` 档位。**TP 查询条件区**内「查询」主按钮可按 **`tp-ux`** 使用信息蓝 **#1677FF**（见 `tp-ux/examples/*/styles.css`）
- **文件命名**：`proto-<简短功能名>.html`，存放在 **用户业务工作区** 项目根目录下的 `output/` 文件夹（与 skill 资产路径无关）
- **语言**：界面文字使用中文

#### 交付前自检（全局）

输出 `proto-*.html` 前逐项确认：

- [ ] 已从 `<iscit-req2proto>` Read 过 **EXAMPLES_MAP**（tp 为 **tp-ux**；ap 或 DXP 列表为 **dxp-ux**）、所选 **example 的 index+styles**、**template-tp 或 template-ap**、**tp 时另含 tp-ux/rules.md**、以及 **tinyvue-spec + dxp-ux rules/components/tokens**（与 Step 3 清单一致）。
- [ ] **未**在用户项目内误用 `examples` / `assets` 作为 skill 参考来源。
- [ ] **tp 默认（tp-ux 所选目录）**：若为 **`multi-tab-tp-page`**，**tablist** 仅一个选中、`tabpanel` 切换正确，Tab1 查询折叠与表格列序符合规则，Tab2 为分析/图表区；若为电子流壳，**侧栏 + 主区** 正确；**查询条件**折叠条 **chevron 与文案 16px**（无右侧工具图标时整行可仅左组）；含表 Tab 列 **序号 → 选择 → 操作 → 业务**；分页在表下。
- [ ] 若路由为 **dxp-ux `list-page`**：**顶栏操作 → 筛选区（含设置 icon）→ 表体 → 底部 pager** 四层顺序正确，且分页不在表头、设置不在表头。
- [ ] 产出路径为 **用户工程** `output/proto-*.html`，CSS/JS 单文件内联。

### Step 5：预览

生成完成后，使用 AskQuestion 工具询问用户：

**问题** — 原型已生成，是否立即预览？

- **是，打开浏览器预览**
- **否，继续修改需求**

如果用户选择**是**，使用 Shell 工具执行以下命令在默认浏览器中打开 HTML 文件：

```bash
start "" "<html文件的绝对路径>"
```

例如：`start "" "D:\project\output\proto-order.html"`

如果用户选择**否**，回到 Step 1 继续修改需求。

## 关键约束

1. 用户是无技术背景的业务人员，交互要简单直接，不使用技术术语。
2. 每次对话必须先完成 Step 1 和 Step 2（**仅**交易类/分析类 + 输入方式；**无**独立 DXP 选项）。
3. 交付 HTML 须可被后续转为 Vue 3 + TinyVue；**tp 列表**满足 **tp-ux** 列序与查询区约定，并联 DXP 弹窗/抽屉等规则。
4. **读 skill、写用户工程**：模板与案例只从 `<iscit-req2proto>` 读；`output/` 只在用户业务工程根下创建（见「执行总则」）。

## 参考资料

以下路径均相对于 **`<iscit-req2proto>/`**（见「执行总则」与「资源路径与 Read 约定」）。

- `references/tinyvue-spec.md` — 色彩、组件、布局与 **DXP / TP 主按钮说明**
- `references/tp-ux/rules.md` — **tp** 查询表单 + **表格左：序号 / 选择 / 操作 / 业务列**
- `references/tp-ux/examples/EXAMPLES_MAP.md` — **tp** 需求→样例路由（**tp 列表先读此文件**）
- `references/tp-ux/examples/multi-tab-tp-page/` — **主区多 Tab**：Tab1 表单+表格；Tab2 KPI+图表占位；其余 Tab 占位
- `references/tp-ux/examples/e-flow-approval-page/` — **电子流审批**：左侧 `nav-menu` + 右侧查询条件 + 左序列表格 + 分页（浅蓝表头可选）
- `references/tp-ux/examples/list-query-table-page/` — **无侧栏** TP：查询条件 + 表上导出 + 左序列表格 + 分页
- `references/dxp-ux/rules.md` — 栅格、按钮、弹窗、抽屉、表格、文案
- `references/dxp-ux/components.md` — `ux-*` 类名与结构
- `references/dxp-ux/ux-tokens.json` — tokens
- `references/dxp-ux/examples/EXAMPLES_MAP.md` — **ap** 与 **DXP 四层 list-page** 等需求→样例路由
- `references/dxp-ux/examples/` — 结构样例根目录；每个子目录均为 `index.html` + `styles.css`（只读 skill、内联输出见 Step 4）：
  - `list-page/` — 四层列表（顶栏操作 / 筛选含设置 / 表体 / 底部分页）+ 可选 Tab
  - `tree-table-page/` — 左树右表
  - `todo-task-page/` — 待办/任务
  - `report-detail-page/` — 报告/详情只读
  - `overview-page/` — 总览/KPI 卡片
  - `logistics-map-page/` — 地图+侧边（含 `china-100000_full.json` 等数据文件时按需 Read）
- `references/isc-scenarios.md` — 10+ 典型场景及推断规则
- `assets/template-tp.html` — 交易类模板（已按 DXP 主按钮与遮罩透明度对齐）
- `assets/template-ap.html` — 分析类大屏模板
