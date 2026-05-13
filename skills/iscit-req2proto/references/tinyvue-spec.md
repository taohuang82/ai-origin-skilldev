# TinyVue 视觉规范速查

生成 HTML 原型时，遵循以下规范以确保后续可无缝转为 Vue 3 + TinyVue 组件代码。

## 色彩体系

### 交易类 (tp) — 浅色主题

| 用途       | 色值      | 说明               |
|------------|-----------|-------------------|
| 主色       | #1476FF   | 链接、信息强调、导航活跃态（**页面主操作按钮**见文末 DXP 对齐） |
| 成功       | #00B42A   | 成功提示、通过状态   |
| 警告       | #FF7D00   | 警告提示            |
| 危险       | #F53F3F   | 错误、删除操作       |
| 背景-页面  | #F2F3F5   | 页面底色            |
| 背景-卡片  | #FFFFFF   | 卡片/面板背景       |
| 文字-主要  | #1D2129   | 标题、正文          |
| 文字-次要  | #4E5969   | 辅助说明            |
| 文字-禁用  | #C9CDD4   | 禁用状态            |
| 边框       | #E5E6EB   | 分割线、边框        |
| 主按钮(DXP) | #191919   | 页面级主操作（Filled）；hover `#2B2B2B` / active `#0F0F0F` |

### 分析类 (ap) — 深色主题

| 用途       | 色值               | 说明               |
|------------|-------------------|-------------------|
| 主色       | #1476FF            | 高亮数据、活跃元素   |
| 辅助色1    | #00B42A            | 正向指标            |
| 辅助色2    | #F53F3F            | 负向指标/告警       |
| 背景-主    | #0A1629            | 大屏背景            |
| 背景-面板  | rgba(6,30,60,0.85) | 面板/卡片背景       |
| 文字-主要  | #FFFFFF            | 标题                |
| 文字-次要  | rgba(255,255,255,0.65) | 辅助文字        |
| 边框/网格  | rgba(255,255,255,0.1)  | 分割线           |

## 字体

```css
font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Microsoft YaHei", sans-serif;
```

| 场景       | 字号    | 字重  |
|------------|---------|------|
| 大标题     | 20px    | 600  |
| 页面标题   | 16px    | 600  |
| 正文       | 14px    | 400  |
| 辅助文字   | 12px    | 400  |
| 数据大屏数字| 28-48px | 700  |

## 间距

| 场景         | 值     |
|--------------|--------|
| 页面内边距   | 24px   |
| 卡片间距     | 16px   |
| 表单项间距   | 16px   |
| 按钮间距     | 8px    |

## 圆角

| 元素   | 值    |
|--------|------|
| 按钮   | 4px  |
| 卡片   | 8px  |
| 输入框 | 4px  |
| 大屏面板| 8px |

## 组件映射

生成 HTML 时使用原生元素 + CSS 类模拟 TinyVue 组件，便于后续替换。

| TinyVue 组件       | HTML 原型实现                     |
|--------------------|---------------------------------|
| TinyButton         | `<button class="tv-btn">`        |
| TinyInput          | `<input class="tv-input">`       |
| TinySelect         | `<select class="tv-select">`     |
| TinyTable          | `<table class="tv-table">`       |
| TinyForm           | `<form class="tv-form">`         |
| TinyDialog / Modal | `<div class="tv-modal">`         |
| TinyTabs           | `<div class="tv-tabs">`          |
| TinyTag            | `<span class="tv-tag">`          |
| TinyPagination     | `<div class="tv-pagination">`    |
| TinyDatePicker     | `<input type="date" class="tv-date">` |
| TinySwitch         | `<label class="tv-switch">`      |
| TinyCard           | `<div class="tv-card">`          |

## 布局规范

### 交易类 (tp) 页面布局

```
┌──────────────────────────────────┐
│  顶部导航栏 (56px, 白底)          │
├──────────────────────────────────┤
│  面包屑 + 页面标题                │
├──────────────────────────────────┤
│  搜索/筛选区 (tv-card)            │
├──────────────────────────────────┤
│  操作按钮栏                       │
├──────────────────────────────────┤
│  数据表格 (tv-table)              │
├──────────────────────────────────┤
│  分页 (tv-pagination)             │
└──────────────────────────────────┘
```

### 分析类 (ap) 页面布局

```
┌──────────────────────────────────┐
│  标题栏 (大屏标题 + 时间)          │
├────────┬────────┬────────────────┤
│  KPI卡 │  KPI卡 │     KPI卡      │
├────────┴────────┼────────────────┤
│  主图表区域      │   辅助图表      │
│  (地图/大图)     │   排行/趋势     │
├─────────────────┼────────────────┤
│  详细数据表格    │   状态/告警     │
└─────────────────┴────────────────┘
```

## CSS 基础类（tp 模板必备）

```css
.tv-btn {
  height: 32px; padding: 0 16px; border: 1px solid #E5E6EB;
  border-radius: 4px; font-size: 14px; cursor: pointer;
  background: #fff; color: #1D2129; transition: all 0.2s;
}
.tv-btn:hover { border-color: #1476FF; color: #1476FF; }
/* 主 CTA：与内置 DXP UX 一致（#191919），非链接强调色 */
.tv-btn-primary { background: #191919; color: #fff; border-color: #191919; }
.tv-btn-primary:hover { background: #2B2B2B; border-color: #2B2B2B; }
.tv-btn-primary:active { background: #0F0F0F; border-color: #0F0F0F; }
.tv-btn-danger { color: #F53F3F; border-color: #F53F3F; }

.tv-input, .tv-select, .tv-date {
  height: 32px; padding: 0 12px; border: 1px solid #E5E6EB;
  border-radius: 4px; font-size: 14px; outline: none; transition: border 0.2s;
}
.tv-input:focus, .tv-select:focus { border-color: #1476FF; }

.tv-table { width: 100%; border-collapse: collapse; font-size: 14px; }
.tv-table th { background: #F7F8FA; color: #4E5969; font-weight: 600;
  text-align: left; padding: 12px 16px; border-bottom: 1px solid #E5E6EB; }
.tv-table td { padding: 12px 16px; border-bottom: 1px solid #E5E6EB; color: #1D2129; }
.tv-table tr:hover { background: #F2F3F5; }

.tv-card { background: #fff; border-radius: 8px; padding: 20px;
  box-shadow: 0 1px 4px rgba(0,0,0,0.05); }

.tv-tag { display: inline-block; padding: 2px 8px; border-radius: 4px;
  font-size: 12px; }
.tv-tag-success { background: #E8FFEA; color: #00B42A; }
.tv-tag-warning { background: #FFF7E8; color: #FF7D00; }
.tv-tag-danger { background: #FFECE8; color: #F53F3F; }
.tv-tag-info { background: #E8F3FF; color: #1476FF; }

.tv-modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.30);
  display: flex; align-items: center; justify-content: center; z-index: 1000; }
.tv-modal { background: #fff; border-radius: 8px; padding: 24px;
  min-width: 480px; max-width: 720px; }
```

## 与内置 DXP UX 对齐（iscit-req2proto）

本技能在 `references/dxp-ux/` 并入 **ISC IT / DXP** 可验收规则，**不增加单独交互选项**，生成时默认遵守。

| 维度 | 约定 |
|------|------|
| 主操作按钮 | 背景 `#191919`，文字 `#FFFFFF`，hover/active 见 `ux-tokens.json` |
| 分页当前页 | `.tv-pagination button.active` 背景/边框 `#191919`；hover `#2B2B2B`；非当前页悬停边框 `#191919`、文字 `#333333` |
| 信息/链接强调 | 仍可使用上表 **#1476FF**（与「主按钮」区分） |
| 弹窗遮罩 | `rgba(0,0,0,0.30)`；宽度档位 400/550/700/900 等见 `references/dxp-ux/rules.md` |
| 交易类 tp | 栅格 24、gutter、offset、表格与文案规则以 `rules.md` 为准 |
| 分析类 ap | 深色主题以本页「分析类」色彩为主；若含 Modal/Table，结构档位对齐 DXP |

详见 `references/dxp-ux/rules.md`、`components.md`、`ux-tokens.json`。
