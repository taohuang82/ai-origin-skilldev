# 组件结构与样式挂载点（HTML + CSS）

> 内置于 iscit-req2proto：与 `rules.md` 验收清单配套。可与 TinyVue 映射类名（`tv-*`）并存。

## 约定

- class 命名使用 `ux-*` 前缀，避免与业务样式冲突。
- 页面必须使用 CSS 变量（来自 tokens）集中控制颜色/间距/字号。

## 1) 页面壳（App Shell）

推荐结构（T 型布局）：

- `.ux-app`
  - `.ux-sidebar`（固定宽度区域，内部具体导航内容可空）
  - `.ux-main`
    - `.ux-topbar`（可选）
    - `.ux-content`（必须，左右 padding=24）

`.ux-content` 内按模块组织：

- `.ux-pageHeader`
- `.ux-card`（承载 filters/table 等）

## 2) Page Header（标题区 + 操作）

- `.ux-pageHeader`
  - `.ux-pageHeader__title`（标题）
  - `.ux-pageHeader__actions`（按钮区，右对齐）
    - `.ux-btn.ux-btn--primary`（最多一个）
    - `.ux-btn.ux-btn--secondary`
    - `.ux-btn.ux-btn--ghost` / `.ux-btn.ux-btn--text`

## 3) Button（按钮）

### 类型

- 主按钮：`.ux-btn.ux-btn--primary`（背景必须 `#191919`）
- 次按钮：`.ux-btn.ux-btn--secondary`
- 幽灵：`.ux-btn.ux-btn--ghost`
- 文本：`.ux-btn.ux-btn--text`

### 按钮区规则

- `.ux-buttonRow`：按钮横向排列，间距使用 tokens（默认 8 或 16）
- 超过 3 个操作时，使用 `.ux-btn.ux-btn--text` 的“更多”承接

## 4) Card（卡片）

- `.ux-card`
  - `.ux-card__header`（可选）
  - `.ux-card__body`（默认 padding=24）

## 5) Filters（筛选区）

- `.ux-filters`
  - `.ux-field`
    - `.ux-field__label`（无冒号）
    - `.ux-field__control`

控件可用基础元素模拟：

- input：`.ux-input`
- select：`.ux-select`

## 6) Table（表格）

外层容器必须预留“过滤/分页/排序”的结构位置：

- `.ux-tableBlock`
  - `.ux-tableBlock__toolbar`（可选：综合搜索/过滤入口）
  - `.ux-tableWrap`（横向溢出时滚动）
    - `table.ux-table`
  - `.ux-pagination`（分页区）

约定：

- 表头高度 40px：`.ux-table thead th` 需满足 `height: var(--ux-table-header-h);`
- 空值文本使用 `--`：`.ux-emptyCell`
- 操作列：`.ux-table__actions`，最多展示 3 个操作，其余放 `.ux-more`

## 7) Modal（弹窗）

纯 HTML+CSS 模式下，建议用 `dialog` 语义标签（或 div 结构），但必须体现：

- 遮罩：`.ux-mask`（rgba(0,0,0,0.30)）
- 固定头/脚：`.ux-modal__header`、`.ux-modal__footer`
- 仅内容滚动：`.ux-modal__body { overflow:auto; }`

结构：

- `.ux-mask`（覆盖全屏）
  - `.ux-modal`（宽度按 400/550/700/900 档位）
    - `.ux-modal__header`（标题/关闭）
    - `.ux-modal__body`
    - `.ux-modal__footer`（按钮右对齐，间距 8）

## 8) Drawer（抽屉）

结构：

- `.ux-mask`（模态抽屉才出现）
- `.ux-drawer`
  - `.ux-drawer__header`
  - `.ux-drawer__body`（仅 body 滚动）
  - `.ux-drawer__footer`

宽度按 500/600/700/960 档位。
