# 轻量设计模式 编排文件
# workflow_id: design-lightweight-incremental
# 不使用 Subagent，主会话串行执行

## 设计原则
1. **代码优先**：先扫描代码识别模式，再决定是否加载 spec
2. **按需规范**：仅对代码中无模式的全新要素加载 spec + standards
3. **无 Subagent**：全部在主会话执行，串行逐域
4. **按需读取**：每个 Phase 只读取其当前步骤所需的文件，禁止预加载全量注册表
5. **不设计代码和 SQL**：设计产出聚焦于架构、数据模型、接口契约、业务流程等设计决策，不生成具体代码实现和 SQL 语句
6. **单一产物**：轻量模式只生成一个设计文件 `{DESIGN_DIR}/design.md`，禁止拆分为 `architecture.md`、`data.md`、`backend.md`、`frontend.md`、`integration.md`、`config.md` 等独立文件

---

## Phase 0：解析上下文

1. 读取 `config.yaml` 和 `SKILL.md` 路径约定，建立 `output_folder_base`、`input_folder_base`、`context.ongoing_file`、`runtime_dimensions` 等基础变量。
2. 读取 `workspace/ongoing.md`，解析 `VERSION`、`FEATURE_SUBDIR`，推导 `DESIGN_DIR`、`PRD_FILE`、`STORY_FILE`。
3. 读取 `PRD_FILE` 作为设计输入，用于后续变化点识别与 conditional 评估。
4. 基于 PRD 的交付分层、功能/UI/API 表述与工程目录事实，确定 `CHANGE_SCOPE`。
5. 按 `config.yaml` 的 `runtime_dimensions.execution_profile_fields` 派生 `execution_profile`。
6. 若是增量模式（`design-lightweight-incremental`），还需解析 `BASELINE_DESIGN_DIR`。

---

## Phase 1：确定执行要素集合（effective_sequence）

> 核心逻辑：**第一层 —「设计哪些要素」**，复用已有注册表，主会话直接消费。

主会话直接消费三张已有注册表（不通过 Subagent 中转）：

```text
Step 1.1 变化点识别
  读取 registry/atomic-change-registry.yaml
  Read PRD_FILE → 对照 atomic-change-registry.yaml 的 detection_keywords
  → 输出 matched_changes[] （如 IA-01、FS-02、FS-03）
  → 若匹配为空，提示用户手动指定变化点

Step 1.2 变化点 → 要素映射
  读取 registry/change-element-mapping.yaml
  → 按 matched_changes[] 中每个 change_id 查找 affects[]
  → 输出 raw_affected_elements[] (含 impact_level: certain / likely / conditional)

Step 1.3 合并去重 + conditional 评估
  - certain: 直接纳入
  - likely: 默认纳入（用户可在 Phase 2 跳过）
  - conditional: 主会话评估 condition → 纳入或跳过
  → 输出 confirmed_affected_elements[]

Step 1.4 级联扩散
  读取 registry/dependency-graph.yaml
  → 以 confirmed_affected_elements[] 为起点，沿 impact_edges 扩散
  → 输出 cascade_elements[]（级联新增的要素 + cascade_reason）
  → 合并 confirmed_affected_elements[] + cascade_elements[] → effective_sequence
  → 去重，按 domain group + order 排序
```

---

## Phase 2：代码信号扫描 + 执行档位分类

> 核心逻辑：**第二层 —「怎么设计这个要素」**，仅对 `effective_sequence` 中的要素做代码扫描。

```text
读取 registry/code-signal-registry.yaml

FOR each element_id IN effective_sequence:
  1. 查 code-signal-registry → 获取 scan 指令
     - 若 element_id 在 code-signal-registry 中无 scan 条目：
       → 读取 registry/element-registry.yaml 查 composite_of 字段
       → 若为复合要素：档位 = composite_of 子要素中最低档位，不再做独立代码扫描
       → 若非复合要素且无 scan 条目：强制 no_match
       → 跳到下一个 element_id
  2. 用 Glob 扫描目标文件是否存在
  3. 对存在的文件，Read 关键内容提取信号
  4. 记录扫描结果：
     - FOUND: 所有信号文件都存在
     - PARTIAL: 部分存在
     - EMPTY: 都没找到
```

基于扫描结果对每个要素判定执行档位：

| 档位 | 判定条件 | 处理策略 |
|------|---------|---------|
| `pattern_match` | 所有 scan 条目均为 FOUND，且至少一个 grep/extract 得到 SIGNAL_CONFIRMED | 从代码直接推断，不加载 spec |
| `partial_match` | 所有 scan 条目均为 FOUND 但无 SIGNAL_CONFIRMED；或部分 FOUND | 从代码推断为主，按需读 spec 的"关键约束"章节 |
| `no_match` | 所有 scan 条目均为 EMPTY | 完整加载 spec + standards，走标准流程 |

展示分类结果并等待用户确认（增量模式额外展示"不涉及"要素）：

```text
✅ 要素执行计划就绪

━━━ 第一层：影响判定 ━━━
  变化点: IA-01 (新增实体), FS-02 (新增查询), FS-03 (业务逻辑)
  受影响的子要素: 8 个
  级联扩散: 3 个
  effective_sequence 共: 11 个

━━━ 第二层：执行档位 ━━━
📋 代码可推断（共 N 个）：
  1. be-api              → 从 Controller 推断 REST 模式
  2. fe-page-structure   → 从 router 配置推断
  ...

🔄 部分参照（共 M 个）：
  3. data-cache          → 有 redis 依赖但无缓存注解，需确认策略
  ...

🆕 完全新增（共 K 个）：
  4. integration-mq      → 项目无 MQ，加载 spec + standards
  ...

⏭️ 不涉及：
  - arch-deployment      → 无部署拓扑变更
  - be-schedule          → 无定时任务诉求
  ...

[C] 开始执行  [B] 调整档位  [Q] 退出
```

- 用户选 `[C]`：冻结 `effective_sequence` + 档位分类，进入档位检查（见下方）
- 用户选 `[B]`：交互式调整某个要素的档位（如将 partial_match 提升为 no_match 强制读 spec）
  - 每次调整后重新计算复合要素档位（取子要素中最低档位）
  - 重新统计 no_match 要素数量并触发档位检查告警（若仍 ≥3）
  - 用户可连续调整多个要素，全部调整完成后再统一确认
- 用户选 `[Q]`：退出

### 档位检查：no_match 告警

用户确认 `[C]` 后、进入 Phase 3 前，主会话检查 no_match 要素占比：

```text
IF no_match 要素数 >= 3:
  输出：

  ⚠️  上下文压力告警

  本次轻量模式有 {K} 个要素需要完整加载 spec + standards
  （{列出 no_match 要素名及所属域}）

  完整加载 spec 意味着主会话需要同时持有 {K} 份完整规范文本 +
  所有设计产出正文，上下文压力可能超过单次会话承载能力。

  建议切换到标准模式（design-incremental-build），由 8 个
  Subagent 并行分担上下文压力，各 Subagent 独立加载对应域的 spec。

  [L] 坚持轻量模式（主会话串行，注意上下文管理）
  [S] 停止轻量模式，改用标准模式（Subagent 并行，推荐）
  【SHIFT_SWITCH_INSTRUCTION】
    如果用户选 [S]：
      → 轻量编排停止继续执行，并输出标准模式重启提示
      → 提示用户重新发起标准增量设计请求，或显式指定 design-incremental-build
      → 不写入 lightweight_override 等 engine 专属运行态字段
      → 不直接跳转 o-design-incremental-build.md，避免跨编排隐式状态传递
```

### 进度标记协议

用户确认继续执行后，Phase 3 每完成一个域，主会话输出简要进度标记，格式：

```text
[N/M] {domain_name} 域完成 | {done} 要素: {list} | 下一域: {next_domain}
```

示例：

```text
[1/7] architecture 域完成 | 3 要素: arch-tech-stack, arch-code-structure, arch-common-lib | 下一域: data
[2/7] data 域完成 | 2 要素: data-table, data-cache | 下一域: api
...
```

> 设计意图：主会话串行执行缺少 Subagent 隔离边界，进度标记帮助用户感知进度并在出错时快速定位域。

---

## Phase 2.5：实现方案澄清

> 核心逻辑：在 **读完 PRD**（Phase 0）且 **完成代码信号扫描**（Phase 2）之后、进入 Phase 3 具体设计之前，**默认进入**本 Phase，针对实现路径存在歧义或多种可行选择的高风险决策进行一次性澄清，或者代码模糊有冲突的情况。

### 提问规则

- **一次只问一个问题**。必须在当前问题得到用户明确答复后，才能进入下一个问题。
- 每个问题必须包含以下三部分：
  - **目的**：为什么要问这个问题，不做澄清对后续设计有何影响。
  - **限制条件**：当前代码仓库已暴露的约束、PRD 已声明的约束、已确定的 `effective_sequence` / 档位分类。
  - **成功标准**：用户的回答需要明确到什么程度（选择 A/B/C、确认推荐、或补充关键参数）。
- 每轮最多提出 1 个问题；累计最多 3 轮。超过 3 轮仍未收敛时，主会话使用推荐方案并显式告知用户。
- 澄清结果以 `<!-- CLARIFICATION: ... -->` 注释形式写入 `design.md` 对应章节。

### 方案提出格式

对每个问题，主会话按以下结构输出：

```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
实现方案澄清 [第 {n}/3 轮]

观察事实：
  - 代码层面：{从 Phase 2 扫描得到的关键事实}
  - PRD 层面：{PRD 中触发歧义的具体描述}
  - 约束：{effective_sequence 与档位分类结果}

问题：{一句话澄清问题}

方案 A：{名称 + 一句话描述}
  优点：...
  缺点：...
  适用场景：...

方案 B：{名称 + 一句话描述}
  优点：...
  缺点：...
  适用场景：...

方案 C（可选）：{名称 + 一句话描述}
  优点：...
  缺点：...
  适用场景：...

推荐：方案 {A/B/C}，理由：...

[A] 方案 A  [B] 方案 B  [C] 方案 C  [R] 补充信息  [S] 跳过，使用推荐
```

### 与 Phase 3 的衔接

- 用户选择方案后，主会话将选择结果转换为 Phase 3 的设计约束：
  - 影响 `pattern_match` / `partial_match` 要素的推断方向。
  - 决定 `no_match` 要素是否需要调整 spec 加载范围。
  - 决定跨域级联要素的实现顺序。
- 若用户选择「跳过」，主会话记录推荐方案并继续，不阻断流程。
- 澄清结论作为 `CLARIFICATION` 元数据写入 `design.md` 顶部 frontmatter 或对应章节末尾，供 Phase 4 索引。

> 设计意图：轻量模式依赖代码推断，容易在「沿用旧模式」与「引入新模式」之间产生歧义。本 Phase 在主会话执行设计前强制收敛关键实现选择，避免 Phase 3 产出后因方案分歧返工。

---

## Phase 3：串行逐域设计

按以下域顺序串行执行每个域：architecture → data → api → backend → frontend → integration → config。每完成一个域，按 §进度标记协议 输出进度行。

> 注：本顺序与 `subagent-registry.yaml` 中声明的域顺序一致，但轻量模式不读取也不调用 `subagent-registry.yaml`，避免触发 Subagent 派发。

### 每个要素的执行协议：

#### 3.1 pattern_match（代码可推断）

```text
Step A: 读取代码文件（已在 Phase 1 扫描时缓存到上下文）
Step B: 从代码模式推断设计：
        - 技术选型：提取版本号、框架名
        - API 设计：提取路径模式、参数命名、响应格式
        - 数据表：提取命名规范、字段类型、索引模式
        - 等...
        - 若代码信号与 PRD 要求存在明显不一致，参考 code-signal-registry 的 `spec_load_trigger` 描述，决定是否降级加载 spec
Step C: 将本要素设计分节直接写入 `{DESIGN_DIR}/design.md`（首个域用 Write 初始化 frontmatter，后续域用 Read → StrReplace/Edit 追加），每节末尾追加 `<!-- DELTA: ... -->` 块
Step D: 记录本要素 DIP（Design Impact Point）临时编号
Step E: 轻量自检：
        - 空内容扫描
        - 占位符扫描（[待补充]、TODO、XXX、待确认、示例值）
```

#### 3.2 partial_match（部分参照）

```text
Step A: 读取代码文件（已缓存）
Step B: 按需加载 spec_path 的 "## 关键约束" 或 "## 必须满足" 章节（非全文）
        - 若代码信号与 PRD 要求存在明显不一致，参考 code-signal-registry 的 `spec_load_trigger` 描述，决定是否提升为完整规范驱动
Step C: 参照代码模式 + spec 关键约束产出设计
Step D: 将本要素设计分节直接写入 `{DESIGN_DIR}/design.md`，追加 `<!-- DELTA: ... -->` 块
Step E: 记录本要素 DIP 临时编号
Step F: 轻量自检（同 pattern_match）
```

#### 3.3 no_match（完全新增）

```text
Step A: 完整 Read spec_path + standard_path
Step B: 读取 registry/element-registry.yaml 查找本要素的 prd_sources，Read PRD_FILE 对应章节
Step C: 按 spec 执行步骤产出设计
Step D: 将本要素设计分节直接写入 `{DESIGN_DIR}/design.md`，追加 `<!-- DELTA: ... -->` 块
Step E: 记录本要素 DIP 临时编号
Step F: 完整自检（对照 spec 质量检查点 + 空内容 + 占位符扫描）
```

> 核心规则：轻量模式是「单一 design.md」模式。所有域的设计产出必须合并写入 `{DESIGN_DIR}/design.md`，禁止为单个域或单个子要素生成独立文件。

### 单一 design.md 写入规则

- **唯一产物**：轻量模式只产出 `{DESIGN_DIR}/design.md`，不生成独立的 `architecture.md`、`data.md`、`backend-api.md`、`backend.md`、`frontend.md`、`integration.md`、`config.md`
- **合并写入**：所有子要素按域顺序追加到同一个 `design.md`，不得拆文件
- 首个域/子要素：Write `design.md` 并初始化 YAML frontmatter
- 后续域/子要素：Read `design.md` → StrReplace/Edit 追加新章节
- 每个子要素分节末尾追加 `<!-- DELTA: ... -->` 块
- **章节连续编号**：`design.md` 中所有一级标题（`#`）和二级标题（`##`）必须按顺序连续编号（如 1、2、3、4...），不得出现跳号或编号间隙。各要素写入时按追加顺序自动递增编号，禁止预留编号位

---

## Phase 3.5：设计-代码一致性校验

> 核心逻辑：设计完成后，对存量要素（pattern_match / partial_match）做**设计产出与代码实际一致性校验**，确保设计文档中的表名、API 路径、类名、配置项等与代码仓库中的实际定义一致。不一致时以代码为准自动修正设计文档；**当校验结果存在疑问或无法自动判定时，必须向用户提问确认，禁止直接猜测修正**。

**加载 `spec/m-design-code-consistency-check.md`**，按该规范执行校验；编排不在此重复声明校验协议、校验维度表、修正规则等细节。

编排仅保留以下与 Phase 上下文耦合的要点：

### 校验范围

仅对 `effective_sequence` 中档位为 `pattern_match` 或 `partial_match` 的要素执行校验；`no_match` 要素（全新新增）无存量代码可对照，跳过。

### 校验疑问判定

在校验过程中，遇到以下任一情况时，主会话必须暂停自动修正，向用户提出澄清问题：

1. **同一设计事实对应多个代码候选**：例如设计中的 API 路径在代码中命中多个 Controller 方法，或表名在多个 schema/模块中同时存在。
2. **代码事实与设计意图语义冲突**：例如 PRD 要求新增字段，但代码中同名实体已存在且字段含义不同；或设计推断的缓存键前缀与现有代码命名风格不一致。
3. **缺少关键物理事实无法校验**：例如设计文档声明了某张表/某个接口，但代码中无法找到对应物理定义，且无法确认是"尚未实现"还是"命名不一致"。
4. **校验规则本身存在歧义**：例如 spec 中的校验维度对当前场景无明确判定标准，需用户确认以哪一方为准。
5. **自动修正可能影响已有功能**：例如修改存量 API 路径、表字段类型或配置项可能导致兼容性风险。

### 向用户提问规则

- **一次只问一个问题**，待用户明确答复后再继续校验流程。
- 每个问题必须包含：
  - **疑问点**：具体是哪个要素、哪个事实存在疑问。
  - **当前发现**：代码中扫描到的候选事实或冲突描述。
  - **设计值**：当前设计文档中的值。
  - **建议处理方案**：包括以代码为准、以设计为准、补充新事实、或标记为待确认。
  - **需要用户确认的内容**：明确让用户选择或补充。
- 对 `MISSING_PHYSICAL_FACT` 类疑问，优先询问用户是否掌握缺失事实；若用户无法提供，则保留原设计值并追加 `<!-- MISSING_PHYSICAL_FACT: 待人工确认，原因: {reason} -->` 注释。
- 对 `多候选` 类疑问，必须列出所有候选并给出推荐，由用户选择。
- 对 `语义冲突` 类疑问，必须说明冲突影响，由用户决定以哪一方为准或是否需要调整 PRD/设计。

### 校验后的 design.md 写入规则

- 修正内容通过 Read → StrReplace 直接更新 `design.md` 对应章节
- 被修正的段落末尾追加 `<!-- FIXED: 校验修正，以代码为准，原值: {original_value} -->` 注释
- 经用户确认后修正的段落末尾追加 `<!-- CONFIRMED_FIXED: 经用户确认修正，原值: {original_value} -->` 注释
- 补充的存量信息段落末尾追加 `<!-- STOCK: 存量信息，来自代码 -->` 注释
- 未识别到存量物理事实且用户无法补充的要素，在其设计章节末尾追加 `<!-- MISSING_PHYSICAL_FACT: 未从代码中提取到 {fact_id}，原因: {reason}，需人工确认 -->` 注释
- 不修改 `<!-- DELTA: ... -->` 块（DELTA 记录的是本次增量变更，不受校验影响）

### 校验输出

全部要素校验完成后，按 spec 中的校验报告模板输出结果，并额外汇总本次校验中向用户提问的数量与结论。用户交互选项：

- `[C]`：冻结校验结果，进入 Phase 4 汇总
- `[R]`：重新执行全部校验（重新扫描代码并比对）
- `[M]`：交互式选择某个要素，手动查看代码与设计差异并逐项修正
- `[P]`：提供缺失的物理事实（如上传 DDL 文件、OpenAPI 契约、API 文档路径或手工输入表名/API 路径）

---

## Phase 4：汇总与索引

在全部要素完成后：

1. 读取 `design.md` 各章节标题与 `<!-- DELTA: ... -->` 块
2. 将各要素临时 DIP 编号统一重编为全局连续序号
3. 在 `design.md` 顶部或独立索引章节生成：
   - 摘要（变更说明）
   - 影响点索引表（全局 DIP 编号 + 关联要素 + DELTA 摘要）

> 汇总与索引同样写入 `{DESIGN_DIR}/design.md`，不另起文件。

---

## Phase 4B：US 与设计交付物索引关联（条件执行）

1. 若 `{DESIGN_DIR}/story.md` **不存在**，跳过本 Phase。
2. 若存在，**加载 `spec/m-us-design-linkback.md`**，按该规范执行 US 索引回链；编排不在此重复声明。

---

## Phase 5：完成收尾

1. 加载 `spec/m-design-complete.md` 完成统一收尾。
2. 更新 `workspace/ongoing.md` 状态。
3. 更新 `design.md` frontmatter：`status: completed`、`last_updated`。
4. 确认 `{DESIGN_DIR}` 下没有除 `design.md` 外的其他设计分域文件；若发现独立分域文件，合并或删除后重编索引。
5. 输出操作菜单：

```text
✅ 轻量设计完成

产出文件（唯一）：
  {DESIGN_DIR}/design.md（轻量模式单一设计产物，禁止拆分）

要素识别：
  受影响: {affected_count} 个要素
  变化点: {matched_changes[]}（增量模式）
  级联扩散: {cascade_count} 个（增量模式）
  不涉及: {excluded_count} 个（增量模式）

模式统计：
  📋 代码推断：{N} 个要素
  🔄 部分参照：{M} 个要素
  🆕 规范驱动：{K} 个要素

校验结果：
  ✅ 一致：{consistent_count} 个
  🔧 已修正：{fixed_count} 个
  ⚠️ 无存量代码对照：{no_code_count} 个

[C] 继续  [B] 修改某个域  [S] 重试  [Q] 完成退出
```

> 菜单语义说明：本菜单是轻量模式完成后的操作选择，`[C]` 表示继续后续流程（如继续与下游 skill 交互），`[B]` 表示返回修改某个域，`[S]` 表示重试当前步骤，`[Q]` 表示结束本次会话。
