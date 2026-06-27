---
name: ia-story-enricher
description: |
  Story Linkback Subagent — 产出 story.md
domain: story
element_id: story
permission:
  question: "allow"
---

# Story Linkback Subagent

> 结构对齐 `subagents/_template.md`。

## ⛔ 强制步骤清单（执行前必读，禁止跳过任何一步）

本 Subagent 共 **4 个步骤**，必须**顺序执行、逐项完成**，不存在"隐式跳过"：

| 步骤 | 名称 | 强制 | 说明 |
|------|------|------|------|
| Step 0 | 规范加载 | ✅ 强制 | 读取 spec/m-us-design-linkback.md |
| Step 1 | US 识别与批处理 | ✅ 强制 | 全量识别 US，按 US_BATCH_SIZE 分批 |
| Step 2 | 映射与写回 | ✅ 强制 | 按 §4.5.1 建立章节映射，按 §4.5.2 格式写回引用到 story.md |
| Step 3 | 完成协议 | ✅ 强制 | 输出 DONE/SKIPPED 状态 |

## §1 元信息

| 字段 | 值 |
|------|-----|
| TDD 章节 | Story 设计引用回填 |
| 落盘文件 | `{DESIGN_DIR}/story.md` |
| 注册表 | `element-registry` 中 `parent_element_id == story` |

## §2 全局约束（继承，禁止删改）

- 设计输出原则：抽象设计、不落代码；结论导向、不落分析稿
- 产出禁码：禁止 SQL / 可执行代码块
- 增量从简：仅展开 ✨新增 / 🔧修改；未变部分不另注
- frontmatter：Story 目标文件（story.md）可写入约定字段；禁止写入 design artifact frontmatter
- 汇总块：必须返回 `## 汇总输入（供 design.md 合并）`
- C/B/S/Q：**禁止** Subagent 输出

## §3 输入契约（由 orchestration Prompt 注入）

| 变量 | 必填 | 说明 |
|------|------|------|
| `EXECUTION_MODE` | ✅ | build / modify / incremental |
| `element_ids[]` | ✅ | （见 orchestration Prompt） |
| `SPEC_ROOT` / `STANDARDS_ROOT` | ✅ | 路径根 |
| `DESIGN_DIR` | ✅ | |
| `STORY_FILE` | ✅ | |
| `US_BATCH_SIZE` | 条件 | 批处理大小；优先取 Prompt 注入，否则取 `config.yaml.runtime_defaults.us_batch_size`，最终默认 `4` |
| `output_doc_path` | ✅ | |
| `force_read[]` | 按域 | 见下 |
| `executed_sub_elements[]` | ✅（返回） | Task 结束时回传；供轻量后置校验 |

**force_read[] 默认**：

  - {DESIGN_DIR}/design.md
  - {STORY_FILE}
  - {DESIGN_DIR}/backend-api.md / data.md / backend.md / frontend.md / integration.md / config.md / ai.md / architecture.md / overall-design.md / shared-context.md（**存在则必读**，作为 §4.5.0 引用对象提取的来源）
  - ia-prd-to-design/reference/story-structure.md（存在则必读）

## §4 Story 专属规范（执行 SSOT）

### 4.1 触发与跳过

- **执行**：`STORY_FILE` 存在且可读。
- **跳过**：无 US 载体文件时跳过，不报错。

### 4.2 产出边界与禁码（强制）

- 仅输出 US 与设计文档的索引关联。
- 写回 `story.md` 时禁止粘贴具体代码或 SQL。
- 不新增或修改各要素设计正文。
- 仅将已产出的设计文件中可定位章节/接口路径/表名/实体名/方法名等索引到 `story.md`；接口名、表名、字段名、方法名属于索引对象，不属于实现细节，应当写入引用。

### 4.3 写回边界（强制）

- 仅允许更新各 US 的「设计引用」和「设计缺口/待确认」段落。
- 禁止改写既有 US 的 ID、标题、需求背景、验收标准。
- 「设计引用」小节若已存在则原地更新；否则插在该 US 块末尾（下一 US 之前）。
- 每条 US 必须至少具备「设计引用」或「设计缺口/待确认」之一。

### 4.4 US 识别与批处理（强制）

- US 起始行优先匹配 `## US-xxx` / `## US xxx` / `### US-xxx` 等，按“编号 + 标题层级”唯一定位。
- 必须先识别全部 US 的 `us_id`、标题与区块范围，再按 `US_BATCH_SIZE` 分批处理。
- 每批完成后立即写回 `story.md`，避免一次性改写失败。

### 4.5 多文件映射规则（强制）

- 引用必须带 `文件名 + 可定位章节标题 + 具体可定位对象`；可定位对象指接口路径（如 `POST /api/orders`）、表名（如 `t_order`）、实体名、方法名、配置项 key 等可在设计文件中直接检索到的具名条目，禁止只写到 §分节编号范围或主题描述。
- 每条 US 建议 2～4 条引用，单行优先；避免复制大段正文或复述需求本文。
- 同一 US 内重复章节需去重合并；避免跨 US 粘贴同一大段引用句。
- 若证据不足，追加 `### 设计缺口/待确认`，仅描述缺口与建议补充章节，禁止臆造实现细节。
- 按 US 语义对照 §4.5.1 选取优先章节；引用格式遵循 §4.5.2。

#### 4.5.0 引用对象提取（强制，覆盖 build / modify / incremental）

无论何种 `EXECUTION_MODE`，建立 US → 设计引用映射时必须执行以下提取动作：

1. 按 §4.5.1 选定优先章节与可选补充文件后，**实际打开对应要素聚合文件**（`backend-api.md` / `data.md` / `backend.md` / `frontend.md` / `integration.md` / `config.md` / `ai.md` / `architecture.md` 等，存在则必读），不得仅凭 §4.5.1 表中的 §分节编号范围直接照抄。
2. 在对应章节内提取与本 US 直接相关的具名条目：接口路径、表名/实体名、字段名、方法/类名、MQ topic / 事件名、配置项 key、字典 code、错误码等。
3. 将提取到的具名条目写入引用行（格式见 §4.5.2），而非只写章节标题或主题词。
4. 若要素聚合文件缺失或对应章节无具名条目，回退到「章节标题 + 关键词」粒度，并在 `### 设计缺口/待确认` 注明缺少具名条目。

#### 4.5.1 章节映射表

按 US 关注点选取 `design.md` 摘要章节，必要时补充要素聚合文件分节：

| US 关注点 | 优先引用章节 | 可选补充引用 |
| --- | --- | --- |
| 服务边界/部署/技术栈/代码与模块拓扑 | `## 顶层架构与全局规范（greenfield only）` | `architecture.md` 内 `## §1.1`～`## §1.7` 等分节（与本次变更相关的节） |
| 数据实体/字段 | `## 数据存储与模型` | `data.md` 内 `## §2.1` / `## §2.2` / `## §2.3` 等分节 |
| 接口契约 | `## API 契约` | `backend-api.md` 对应接口章节 |
| 后端流程/规则 | `## 后端处理逻辑` | `backend.md` 内 `## §3.2`～`## §3.7` 等分节 |
| AI 模型/Prompt/RAG | `## AI 能力设计（AI only）` | `ai.md` 内对应分节 |
| 前端页面/交互 | `## 前端展现与交互` | `frontend.md` 内 `## §4.1`～`## §4.7` 等分节（按需） |
| 外部系统/MQ/消息/回调/通知 | `## 异步处理与系统集成` | `integration.md` 内对应分节（如外部对接、MQ、通知等） |
| 字典/错误码/权限矩阵/配置项/NFR 安全 | `## 配置、字典、安全与权限` | `config.md` 内 `## §6.1`～`## §6.5` 等分节 |
| 约束/风险 | `## 设计缺口与待确认` | `shared-context.md` 的待确认项 |
| 跨模块决策（方向级） | `## 架构决策` | `overall-design.md` 的 `arch_decisions`、受影响上下文章节 |

**说明**：`## 架构决策` 承载已确认的方向级结论（含 `arch_decisions`）；`## 顶层架构与全局规范（greenfield only）` 仅在有 `architecture.md` 时出现在 `design.md`，承载第 1 章细化架构摘要。二者分工不同，按 US 语义择一或并列引用。

#### 4.5.2 引用写法模板

每个 US 至少 2～4 条引用，**每条必须落到具体可定位对象**（接口路径 / 表名 / 实体名 / 方法名 / 配置项 key 等），示例：

```markdown
### 设计引用
- 接口契约：`backend-api.md` → `## POST /api/orders`（创建订单接口，入参 OrderCreateDTO）
- 数据设计：`data.md` → `## §2.1 t_order 表`（新增 `payment_status` 字段）
- 后端实现入口：`backend.md` → `## §3.4 OrderService.createOrder`（订单创建主流程方法）
- 集成对接：`integration.md` → `## MQ: order.created`（订单创建事件 topic）
```

锚点定位采用「章节标题 + 具体对象名」，不强依赖 Markdown 自动锚点格式。若引用了要素聚合文件，优先同时给出 `design.md` 对应摘要章节。禁止只写 `backend.md → ## §3.x（后端处理逻辑）` 这类仅到分节编号 + 主题词的粗粒度引用。

### 4.6 增量模式 DIP → US 映射协议（incremental 专属）

在 `design-incremental-build` 的 Story 回填阶段，按以下规则执行：

1. 建立 US → DIP 映射：依据 DIP 的 `source_prd_change` 反查 PrdChange 的 `source_story`。
2. 映射依赖全量 DIP 视野：仅在各要素 DIP 收齐后启动。
3. 提取可定位索引：从 DIP 的 `element`、`baseline_ref`、`target_state` 提取文件名、章节与关键对象。
4. 去重合并：同一 US 被多个 DIP 指向同一章节时合并为一条。
5. 无 `source_story` 的 DIP（常见 type_b/type_c）不参与 US 回填，仅体现在 `design.md` 影响点索引。

### 4.7 路径与文件操作约束

- 仅允许原地更新 `story.md`；禁止新建按 US 拆分的文件或目录。
- 路径解析相对 `WORKSPACE_ROOT` / `DESIGN_DIR`，禁止将 Skill 目录当业务根路径。

## §5 执行流程

### Step 0：规范加载

读取 `spec/m-us-design-linkback.md` 获取输入/输出/校验契约；执行规则以本文件 §4 为准。

### Step 1：US 识别与批处理

- 按 §4.4 先完成 US 全量识别。
- 再按 `US_BATCH_SIZE` 分批处理并批次落盘。

### Step 2：映射与写回（强制）

- 按 US 语义对照 §4.5.1 建立章节映射，按 §4.5.2 格式写回引用。
- 按 §4.2～§4.5 完成索引回填与缺口补充。
- 严格遵守写回边界与禁码要求。

> ⏭️ Step 2 完成后，进入 Step 3 完成协议。

### Step 3：完成协议

- 成功写回后最终输出优先使用：`DONE: story.md updated`。
- 为兼容既有编排，允许同时附带：`DONE: story.md design linkback`。

### Step 4：通用流程与返回

除上文 Story 专属约束外，其余步骤遵循 `_template.md`：上下文读取 → 适用性裁剪 → 正文写作 → 质量自检（强制逐项输出 ✅/❌）→ 返回协议。

## §6 子要素加载表

| sub-id | spec_path | standard_path | output heading |
|--------|-----------|---------------|----------------|
| — | 见 Prompt `element_ids[]` | — | — |


## §7 orchestration-direct 说明

- orchestration 在指定 Phase 前台 Task 直派
- story.md 不存在时跳过
- story-enricher 仅更新 story.md 索引段

## 附录 A：incremental 义务

- artifact 分节内须含 `<!-- DELTA: change=..., chapter=story, op=..., level=... -->`
- 每条 DELTA 关联至少一个 DIP（字段同 SKILL.md DesignImpactPoint）
