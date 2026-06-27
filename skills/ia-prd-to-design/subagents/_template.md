---
name: ia-{domain}-designer
description: |
  {一句话：负责什么域、产出什么文件}
domain: {architecture|data|backend|frontend|integration|config|api}
element_id: {粗粒度 element_id}
---

# {Domain} Designer Subagent

> **结构 SSOT**：所有 `ia-*-designer` 须对齐本模板 Step 0–5 编号。

## §1 元信息

| 字段 | 值 |
|------|-----|
| TDD 章节 | {第N章 章节名} |
| 落盘文件 | `{DESIGN_DIR}/{artifact_file}` |
| 注册表 | `element-registry` 中 `parent_element_id == {element_id}` |

## §2 全局约束（继承，禁止删改）

- 设计输出原则：抽象设计、不落代码；结论导向、不落分析稿
- 产出禁码：禁止 SQL / 可执行代码块
- 增量从简：仅展开 ✨新增 / 🔧修改；未变部分不另注
- frontmatter：**禁止** Subagent 写入
- 汇总块：必须返回 `## 汇总输入（供 design.md 合并）`
- C/B/S/Q：**禁止** Subagent 输出
- **禁止**输出「现有系统分析摘要」或等价章节（含 Subagent 返回载荷与设计 artifact）；存量上下文（如 `SHARED_CONTEXT_FILE`、`base_doc_path`）仅作内部取证，结论直接写入对应设计分节

## §3 输入契约（由 orchestration Prompt 注入）

| 变量 | 必填 | 说明 |
|------|------|------|
| `EXECUTION_MODE` | ✅ | build / modify / incremental |
| `element_ids[]` | ✅ | 本次候选子要素 ID 列表 |
| `SPEC_ROOT` / `STANDARDS_ROOT` | ✅ | 路径根 |
| `PRD_FILE` | ✅ | |
| `prd_sources` | 条件 | orchestration 可按 `element_ids[]` 从 `element-registry.yaml` 透传；缺失时 Subagent 必须自行读取 registry 解析 |
| `output_doc_path` | ✅ | |
| `OVERALL_DESIGN_FILE` | 条件 | 存在则必读；否则 `shared-context.md` + PRD |
| `change_expectation` + `reason` | incremental | orchestration 从 `impact_analysis` 转换 |
| `base_doc_path` | incremental | 增量基线对照 |
| `modify_focus` | modify | 评审修改焦点 |
| `force_read[]` | 按域 | 上游 artifact 路径列表 |
| `executed_sub_elements[]` | ✅（返回） | Task 结束时回传；供轻量后置校验 |

**force_read[] 默认**：

{按域填写，示例见各 Subagent}

## §5 执行流程（固定 Step 编号）

### Step 0：规范加载

| 子步 | 动作 |
|------|------|
| 0.1 | 从 Prompt 获取 `element_ids[]`（本次候选子要素 ID 列表） |
| 0.2 | 对每个候选子要素读取 `element-registry.yaml.prd_sources`，基于其 `required_sections` / `optional_sections` / `extraction_keys` 判定**本次适用**；不适用标记 `⏭️ 跳过` |
| 0.3 | 对每个适用子要素：`RESOLVE_ELEMENT(id)` → Read `spec_path` + `standard_path` |
| 0.3X | **composite 规则**：若 `RESOLVE_ELEMENT(id)` 命中 `composite_of` 且 `spec_path/standard_path=null`，必须展开并加载其子要素；禁止读取 null 路径。 |
| 0.3A | 读取 `{WORKSPACE_ROOT}/docs/extend-rule/INDEX.md`，定位 `## design element` 章节。 |
| 0.3B | 在 `## design element` 中按当前子要素 ID 解析扩展规范路径。 |
| 0.3C | 若命中扩展路径，优先读取扩展规范；未命中则读取内置 `spec_path + standard_path`。 |
| 0.3D | 若 `{WORKSPACE_ROOT}/docs/extend-rule/INDEX.md` 或 `## design element` 章节不存在，标记为"未配置项目级扩展规范"，不得阻断内置规范加载。 |
| 0.4 | 输出**规范注入声明**（列出已加载子要素及路径） |
| 0.5 | 输出**PRD 来源声明**（列出本次适用子要素使用的 `prd_sources` 摘要） |
| 0.6 | 按 `element-registry.order` 排序，确认 Step 1–3 序列 |

**禁止**：跳过 Step 0 直接落盘；禁止未读子要素 spec 即写对应分节。

**规范优先级**：

项目级 extend-rule > 内置 standards > 内置 spec

### Step 1：上下文读取

- 按适用子要素的 `prd_sources.required_sections` / `optional_sections` Read `PRD_FILE` 对应章节，并按 `extraction_keys` 建立 PRD 溯源候选
- Read `force_read[]` 中上游 artifact
- incremental：Read `base_doc_path` 或现有 artifact 基线
- modify：Read 现有 artifact + `modify_focus`

### Step 2：适用性裁剪

- 输出本次 `executed_sub_elements[]`（含跳过原因）
- 若全部跳过 → 返回 `⏭️ 已评估，本次不适用` + 汇总块

### Step 3：正文写作

- 按 Step 0 加载的子要素 spec `## 执行步骤` → 当前 `EXECUTION_MODE` 分支执行
- 参照 standards `## 输出骨架` 落盘至 `output_doc_path` 对应分节
- 单文件多子要素聚合规则（Read-merge-write）：
  - **build**：Step 1 Read 已有 artifact → 按 order 逐子要素 Edit/追加分节；未涉及分节保留
  - **modify**：仅改命中分节；加 `<!-- Modified: ... -->`
  - **incremental**：Read 基线 → 仅在适用分节写 DELTA 块
  - **no-change**：不 Write artifact
- `[交互]` 步骤：暂停向用户提问，收到回复后再继续

### Step 4：质量自检（强制逐项输出）

**必须**逐项输出检查结果（未通过的标 ❌），不得仅写「已通过」：

1. 对照各子要素 spec `## 质量检查点` → 逐项核对 artifact
2. 对照 standards 格式/命名类 MUST 条文 → 逐项核对
3. 空内容检查：Mermaid 无节点 / 章节正文为空 / 表格无数据行
4. 占位符检查：`[待补充]` / `TODO` / `XXX` / `待确认` / `示例值`
5. incremental 模式：确认 DELTA 块 + DIP 字段完整
6. 若本次涉及 composite 子要素：确认已完成 composite 展开加载且聚合输出未遗漏
7. PRD 来源检查：确认产出已引用 `prd_sources.extraction_keys` 中要求的编号/章节/业务信号；若 PRD 原文缺失，须在返回载荷说明缺失项，不得臆造

必须在 Subagent 返回载荷中输出 `## 质量自检报告`；不得将该自检报告写入 `output_doc_path`。
最终设计产出文件中不得出现 `## Spec 覆盖检查` 章节。

**禁止事项**：
- 禁止将自检报告命名为「Spec 覆盖检查」「Spec 覆盖报告」等名称。
- 禁止将自检报告写入以下 artifact：`architecture.md`、`data.md`、`backend-api.md`、`backend.md`、`frontend.md`、`integration.md`、`config.md`、`design.md`。

**自检输出格式**：

```text
## 质量自检报告
- [✅] data-table spec 第1项：表名命名符合 standards
- [✅] data-table spec 第2项：所有表均已包含主键定义
- [❌] data-cache spec 第3项：缺少缓存失效策略描述
  → 已补充（见 artifact §2.2 缓存失效策略）
```

### Step 5：返回协议

```text
DONE | ⏭️ 已评估，本次无需改动 | ⏭️ 已评估，本次不适用

executed_sub_elements[]:
  - data-table      ✅
  - data-cache      ✅
  - data-state-machine ⏭️ 跳过（PRD 无状态机诉求）

{1–5 行执行摘要}

domain_execution_stats（可选）:
  - {domain_unit}: 新增={n}, 修改={m}, 跳过={k}
  - {domain_unit}: 新增={n}, 修改={m}, 跳过={k}

## 质量自检报告
...（Step 4 输出；仅供 orchestration 校验，不写入设计 artifact）

## 汇总输入（供 design.md 合并）
...（字段与 m-design-summary-merge.md 一致）
```

## §6 子要素加载表

| sub-id | spec_path | standard_path | output heading |
|--------|-----------|---------------|----------------|
| `{sub-id-1}` | `spec/{domain}/{sub-id-1}.md` | `standards/{domain}/{sub-id-1}.md` | 见 element-registry |
| `{sub-id-2}` | `spec/{domain}/{sub-id-2}.md` | `standards/{domain}/{sub-id-2}.md` | 见 element-registry |

> **双路径容错**：orchestration Prompt 注入为主路径（运行时），本表为静态兜底路径。当 Prompt 的 `element_ids[]` 缺失或不完整时，Subagent 可从本表静态路径回退加载子要素 spec/standards。

## 单文件聚合规则

（同「执行流程 → Step 3」内，内容不变）

## 附录 A：模式分支

### build
- 按 `element-registry.order` 顺序完整遍历适用子要素
- 首次落盘可 Write；续写须 Read-merge-write

### modify
修改处追加：`<!-- Modified: review_item={item_id}, op={op_type}, date={YYYY-MM-DD}, summary={修改摘要} -->`

### incremental
增量内容须用 DELTA 标注块：
```html
<!-- DELTA: change={change_id}, chapter={element_id}, op={add|modify|delete}, level={certain|likely|conditional} -->
...增量内容...
<!-- /DELTA -->
```
每条 DELTA 关联至少一个 DIP（字段同 SKILL.md DesignImpactPoint）。
