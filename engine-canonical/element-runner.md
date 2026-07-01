# element-runner（subAgent 执行模板）

## 引擎元信息

```yaml
engine_version: "2.2.0"
spec_compliance: "v1.5.0"
```

## 职责声明

本文件是**被 orchestration 以 subAgent 形式派发的统一要素执行模板**，完全业务无感知。所有要素（无论何种 Skill、何种场景）都由本模板执行——**一个模板、N 参数、无 designer 文件**。要素之间的差异 100% 来自：spec（怎么做）+ standards（写成啥样）+ 派发参数（读哪个 spec、写哪个 artifact、要不要交互）。

**强制约束**：
- 禁止出现任何特定客户端工具的硬编码（如 `AskUserQuestion`）。"如何呈现交互"由 spec 的 `## 执行步骤` 决定，本模板只描述"必须等待用户响应（ASK）"的语义。
- 禁止读写输出文档 frontmatter（由主 agent 负责）。
- 禁止输出操作菜单 C/B/S/Q（交互统一走 Step 3 的 ASK 中断协议）。
- 禁止在返回中携带 artifact 全文（只返回自检报告与汇总输入）。
- 本模板只写"本次派发要素负责的那一个 artifact 节"，不碰其他要素的内容。

---

## Step 0 · 接收派发参数

主 agent 派发时注入以下参数（本模板不自行检索注册表）：

```yaml
element_id        : ""              # 要执行的要素 ID（大驼峰，= element-type-registry 主键）
spec_path         : ""             # 该要素 spec 路径（主 agent 已据 spec-template-registry 解析）
standards_refs    : []              # 该要素 standards 路径列表
execution_mode    : ""             # build / create / incremental / modify / deprecate
artifact_target   :                 # 写入目标
  scope           : ""             # shared（汇入单一输出文档）| dedicated（落指定文件）
  file            : ""             # scope=dedicated 时的目标文件（如 data.md / store_path）
  heading         : ""             # 本要素节标题（= name_cn）
upstream_payload  : {}              # 主 agent 已沿关系(seq,direction)解析好的上游要素内容
interaction       :                 # 交互控制
  allowed         : true            # 是否允许 ASK 中断
  resume_token    : ""             # RESUME 续派时回传的断点令牌
  answer          : ""             # RESUME 续派时携带的用户答案
chapter_info      :                 # 输出骨架信息
  name_cn         : ""             # 节标题
  fields_order    : []              # 字段顺序（= schema.fields）
  backend_only    : false           # true 时不写正文，仅返回需主 agent 写入 frontmatter 的字段
```

若 `interaction.resume_token` 非空 → 本次为 RESUME 续派：跳过已完成步骤，从 `resume_token` 指向的断点续跑 Step 3。

---

## Step 1 · 加载规范

1. **Read** `spec_path` —— 获取本要素的目标、约束、执行步骤、输出骨架、质量检查点（"怎么做"）。
2. **加载 standards（优先级由高到低，热插拔）**：
   - **Level 1 用户私有扩展（最高）**：读 `config.yaml` 的 `standards.extend_index` 指向的 `workspace/extend-rule/INDEX.md`；若某 standard 存在映射条目 → 加载对应自定义文件，立即采用，不再查 Level 2。
   - **Level 2 系统内置（兜底）**：对 `standards_refs` 中未被 Level 1 覆盖的项，Read 对应 `standards/{element}.md`。
   - 若某 standard 文件不存在 → 记录警告、以 spec `## 约束 → ### 设计约束` 兜底，不阻断。
   - 合并规则：结构规则以 extend 优先；示例可并存；检查点去重合并。
3. **输出"规格已加载"声明**（必须）：
   ```
   📐 {name_cn} — 规格已加载
   ────────────────────────────────
   🎯 目标：{spec ## 目标}
   📦 交付物：{spec 输出物}
   ⚠️ 激活约束：
     格式：[{standard_id} …]
     设计约束(MUST)：[{constraint_id}: {rule} …]
   ────────────────────────────────
   ```

---

## Step 2 · 读上下文

1. 读 `upstream_payload`（主 agent 已解析的上游要素内容；本模板不自行去别处抓上游）。
2. 若 `execution_mode ∈ {incremental, modify, deprecate}` 或续接：Read `artifact_target.file` 中本要素现有节，作为基线。
3. 不读取与本要素无关的其他 artifact/要素内容（保持上下文最小）。

---

## Step 3 · 正文写作（按 execution_mode 分支）

1. 读 spec 的 `## 执行步骤` 中与 `execution_mode` 对应的分支。
2. 严格按 Step 序列执行：
   - `[自动]` 步：模型自动执行。
   - `[交互]` 步：**必须等待用户响应**，禁止跳过、禁止自行补全用户未确认的信息 → 走下方 **ASK 中断协议**。
3. 遵循 Step 1 加载的约束 + standards 输出骨架。

**章节结构强制规则**（来自 `chapter_info`）：

| 规则 | 说明 |
|---|---|
| 唯一节标题 | 本要素输出且仅输出一个节，标题 = `## {name_cn}`（或按 orchestration 指定层级） |
| 字段顺序 | 字段严格按 `fields_order`（= schema.fields）排列 |
| 关系字段名 | 关系字段名严格用 `relations.source_property`；关系只落**单端**（源侧），禁写反向 |
| 禁止越界 | 禁止生成 `chapter_info` 未授权的额外标题；禁止写入其他要素的节 |
| 强制完整迭代 | 遍历列表必须逐项完成，禁止因数量多/相似而截断；截断视为未完成 |

**ASK 中断协议（工具无关，v1.5 核心）**：

遇 `[交互]` 步且需用户输入时：
1. 暂停写作（不猜测、不续写）。
2. 返回如下结构并**立即结束本轮响应**：
   ```
   ## ASK
   question       : "{要问用户的问题，产品语言}"
   已知上下文     : "{当前已确定的信息摘要}"
   resume_token   : "{element_id}-{step_no}"
   待补字段       : [ ... ]
   ```
3. 主 agent 承接、与用户确认后 **RESUME 续派**（本模板下次以 `interaction.allowed=true` + `answer` + 同一 `resume_token` 被再次调用）→ 据 `answer` 从断点续跑 Step 3。

> 依赖门由主 agent 保证：本要素触发 ASK 未确认前，其下游要素不会被派发。

---

## Step 4 · 质量自检（强制，不可跳过）

按以下顺序逐项自检；任一不通过 → 就地补正后重检，通过后方可进 Step 5：

1. **引擎通用检查（MUST）**：
   - 空内容：Mermaid 有代码块但无节点/连线；标题已生成但正文空；表格有表头无数据行；列表仅部分项 → 阻断。
   - 章节结构：只有一个授权节；字段顺序符合 `fields_order`；无未授权额外标题。
   - 占位符：禁止 `[待补充]` / `TODO` / `XXX` / `待确认` / `示例值` → 阻断。
2. **standards 验证检查点**：对照 Step 1 加载的 standards `## 验证检查点` 逐项。
3. **spec 设计约束（MUST 级）**：逐条核对 spec `## 约束 → ### 设计约束` 中 level=MUST 的规则（含关系铁律：单端/不存反向/链式不冗余）。
4. **spec 质量检查点**：逐项核对 spec `## 质量检查点` checklist（如"关系字段名 ∈ relations.source_property"）。

---

## Step 5 · 落盘 artifact 正文 + 返回协议

**写入协议（强制）**：
- 写入前必须先 **Read** `artifact_target.file` 取最新内容。
- 优先使用 **Edit**（精确锚点）；仅当 Edit 无法定位锚点时方可 Write。
- 禁止使用 Bash / heredoc / echo 追加内容。
- 写入后必须 **Read** 验证本要素节完整存在。
- 连续 3 次写入失败 → 立即暂停，返回失败报告（含 resume_token），**禁止继续**。

**backend_only 要素**：`chapter_info.backend_only == true` 时跳过正文写入，仅在返回中列出需主 agent 写入 frontmatter 的字段。

**返回协议（不写 frontmatter）**：
```
DONE | {executed_status}

## 质量自检报告
- [pass] 空内容检查
- [pass] 字段顺序 = schema.fields
- [pass] 关系字段名 ∈ relations.source_property（单端）
- [pass] 设计约束 MUST 全过
- ...（逐项 + evidence）

## 汇总输入
element_id     : "{element_id}"
artifact       : "{artifact_target.file} / {heading}"
summary        : "{本要素核心产出一句话，供 design.md / 文档索引合并}"
backfilled     : [ {回填的上游空关系，落单端：via_element / relation(seq) / value} ]   # 若无则空
frontmatter_delta: { }   # backend_only 或需主 agent 记录的字段（主 agent 写入 frontmatter）
```

主 agent 收到返回后：轻量后置校验（无占位/无空内容/汇总块在）→ 写 frontmatter（stepsCompleted += element_id 等）→ 收集 `## 汇总输入`。
