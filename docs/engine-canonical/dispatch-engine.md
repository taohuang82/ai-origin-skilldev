# dispatch-engine（调度循环模板）

## 引擎元信息

```yaml
engine_version: "2.3.0"
spec_compliance: "v1.5.0"
```

## 职责声明

本文件是**被 orchestration 在 Phase 0 结束后调用的统一调度循环模板**，完全业务无感知。承接 orchestration 传入的配置参数，执行 Phase 1~4（选要素→建 DAG→波次调度→后处理→确认）。所有业务差异通过参数注入，本模板不硬编码任何 Skill/要素/文档类型。

**强制约束**：
- 禁止硬编码要素名单、章节映射、Skill 名称（全从参数和 registry 读取）。
- 禁止代写要素正文（必须经 element-runner）。
- 禁止读 spec/*.md（只有 element-runner 读 spec）。
- 禁止在 subAgent 返回 ASK 后、用户确认前继续派发其下游。

---

## 入参（由 orchestration 在 Phase 0 结束时组装）

```yaml
# ── 路径 ──
output_path: ""                    # 输出文档/基线路径（orchestration Phase 0 已确定）

# ── 选要素 ──
emerge_stage: ""                   # 0→1: "FE"/"PRD"/"TDD"（过滤 emerge_stage==此值 或 evolve_stages 含此值）
select_all: false                  # true=遍历全 25 要素（Asset 0→1 用）
selected_elements: []              # 1→n: ChangeRouter 已预选的要素 ID 列表（非空时跳过 Phase1 选要素步骤）

# ── artifact 模式 ──
artifact_mode: "shared"            # shared=单文档串行 / dedicated=多文件可并行

# ── 上游数据源 ──
upstream_sources: []                # upstream 解析时按 stage 分源读取
  # - stage: "FE"                  # via_element 的 emerge_stage==FE 时
  #   doc_path: "workspace/requirements/{version}/fe.md"
  # - stage: "PRD"                 # via_element 的 emerge_stage==PRD 时
  #   doc_path: "workspace/requirements/{version}/prd.md"  # 或 "自身"（从 output_path 读已产节）
  #   artifact_mapping: {}          # dedicated 模式下 via_element → artifact 文件的映射
  #     Aggregate: "data.md"
  #     Entity: "data.md"

# ── 调度行为 ──
require_backfill: false             # 是否支持回填（PRD=true, FE=false）
require_evolve: false               # 是否有 evolve 要素（PRD=true, FE=false）
execution_dispatch: "inline"        # 全局默认 dispatch（inline / subagent）

# ── 后处理步骤 ──
post_generation_steps: []           # Phase 3 按此列表顺序执行，可用类型见 Phase 3 说明
  # - "chapter_numbering"          # 按执行序列给节标题加序号前缀（文档类）
  # - "instance_numbering"         # 按类型分配连续编号并回写文档（文档类）
  # - "merge_summaries"            # 合并汇总输入 → 文档收尾（文档类）
  # - "consistency_check"          # 跨要素一致性检查（全部）
  # - "set_status_completed"       # frontmatter.status = completed（文档类）
  # - "build_cross_references"     # 重建 _index（资产类）
  # - "backfill_lineage"           # 回填 lineage.triggered_by（资产类）
  # - "archive_version"            # 归档 V0（资产类）
  # - "build_design_index"         # 汇总 design.md（TDD）
  # - "update_ongoing"             # 更新 ongoing.md（全部）
  # - "output_completion"           # 输出完成提示（全部）

# ── 实例编号前缀（仅 instance_numbering 步骤使用）──
instance_prefixes: {}
  # Role: "ROLE"
  # Domain: "DM"

# ── 收尾 ──
skill_namespace: ""                 # ongoing.md 中的命名空间（"fe" / "prd"）
workflow_hint: ""                   # ongoing.md.workflow_hint 值
completion_template: ""             # SKILL.md 完成提示模板
```

---

## Phase 1：选要素 + 建 DAG

1. **选要素**（三模式，由入参决定）：
   - 若 `selected_elements` 非空（1→n）→ 直接使用此列表，跳过筛选。
   - 若 `select_all == true`（Asset 0→1）→ 遍历 element-type-registry 全部要素。
   - 否则（0→1 文档 Skill）→ 遍历 element-type-registry，选 `emerge_stage == emerge_stage 参数` **或** `evolve_stages 含 emerge_stage 参数` 者。
   - **禁止写死要素名单或数量**。
2. **过滤可执行**：对每个要素查 spec-template-registry；无 active 记录 → 告警跳过。
3. **读配置**：取每要素的 spec_file / standards_refs / artifact / execution / depends_on / upstream。
4. **建 DAG（Kahn 拓扑排序）**：
   - 以要素集合为节点集，以各要素 `depends_on` 为有向边（被依赖者 → 依赖者），构建有向无环图。
   - **Kahn 算法**：
     1. 计算每个节点的入度（= `depends_on` 中属于当前要素集合的数量）。
     2. 入度为 0 的节点入队。
     3. 循环：出队一个节点，加入执行序列；将其所有下游节点的入度减 1，若降为 0 则入队。
     4. 队列空时结束。若执行序列长度 < 要素集合长度 → 存在环，报错中断。
   - **波次标注**：同一轮入队的节点属于同一波次。
   - **禁止**：不得忽略/覆盖/编造 `depends_on` 关系；不得用要素名字面顺序替代拓扑排序结果。
   - **输出**：打印实际推导出的执行序列（含波次）。

---

## Phase 2：波次调度循环

FOR EACH wave IN 波次列表：
  就绪要素 = wave 中 depends_on 全完成的要素

  **按 artifact_mode 决定执行策略**：
  - `shared`：FOR EACH element IN 就绪要素（串行）→ 执行单要素流程
  - `dedicated`：按 `artifact_target.file` 分组 → 同组串行，不同组可并行（Agent 工具并行派发 subAgent；inline 模式下退化为串行）

  **单要素执行流程**：
  1. **依赖门**：确认 element.depends_on 中每个要素已完成且已被用户确认；未满足 → 暂停等待。
  2. **解析 upstream**（据 upstream_sources 参数按 stage 分源读取）：
     - via_element 的 emerge_stage 对应 upstream_sources 中某条的 stage → 从对应 doc_path（或 artifact_mapping 中的文件）读取
     - via_element 与已产要素同阶段 → 从 output_path（或对应 dedicated artifact）读取已产节
  3. **组装派发参数**：
     ```
     { element_id, spec_path, standards_refs, execution_mode: "build",
       artifact_target: { scope, file, heading: element.name_cn },
       upstream_payload, interaction: { allowed: element.execution.interactive },
       chapter_info: { name_cn: element.name_cn, fields_order: <schema>, backend_only: false } }
     ```
  4. **按 dispatch 执行**（dispatch = element.execution.dispatch，缺省继承 execution_dispatch）：

     **分支 A：dispatch = "subagent"**
     使用 Agent 工具调用 subAgent：
     - `subagent_type`: 不填（默认通用类型）
     - `description`: "{emerge_stage}-{element_id} 要素执行"
     - `prompt`: 按 element-runner.md Step 0 的参数结构组织完整派发参数 + 关键约束：
       ```
       你是 element-runner subAgent。请严格按照 engine/element-runner.md 的 Step 0~5 执行。

       ## 派发参数
       element_id        : "{element_id}"
       spec_path         : "{spec_path}"
       standards_refs    : {standards_refs}
       execution_mode    : "build"
       artifact_target   :
         scope           : "{scope}"
         file            : "{file}"
         heading         : "{element.name_cn}"
       upstream_payload  : {upstream_payload JSON}
       interaction       :
         allowed         : {element.execution.interactive}
         resume_token    : ""
         answer          : ""
       chapter_info      :
         name_cn         : "{element.name_cn}"
         fields_order    : {fields_order}
         backend_only    : false

       ## 关键约束
       - 先 Read engine/element-runner.md 获取完整执行流程
       - 按 Step 1→2→3→4→5 顺序执行，不可跳步
       - [交互] 步必须返回 ## 待确认，禁止自行补全
       - 写入前必须先 Read artifact_target.file 取最新内容
       - 返回 DONE + 质量自检报告 + 汇总输入
       ```

     **分支 B：dispatch = "inline"**
     主 agent 直接按 element-runner.md 的 Step 0~5 流程执行本要素，不调用 Agent 工具：
     - **Step 1**：Read `spec_path` 加载规格；按 standards_refs 加载 standards。
     - **Step 2**：读取 `upstream_payload`（已在本步骤2解析好）；若 incremental/mode 则读现有节。
     - **Step 3**：按 spec `## 执行步骤` 中 `execution_mode: build` 分支写作正文。遇 `[交互]` 步必须停止、输出 `## 待确认`、结束本次回复。
     - **Step 4**：质量自检（空内容 / 占位符 / 字段顺序 / 设计约束 MUST）。
     - **Step 5**：Read 输出文档 → Edit 追加本要素节 → Read 验证。产出质量自检报告 + 汇总输入。

     **inline 模式下同样受以下约束**：
     - 禁止跳过 `[交互]` 步；遇交互必须停下问用户。
     - 写入前必须先 Read 输出文档取最新内容。
     - 只写本要素节，禁止越界写其他要素的内容。
     - 质量自检不通过则就地补正，不可跳过。

  5. **接收返回 + 逐要素确认**：
     - `## 待确认` → 主 agent 与用户确认 → RESUME；**未确认前禁止派发下游**。
     - `DONE`（interactive=true）→ 向用户展示结果并取得"继续"确认后推进。
     - `DONE`（interactive=false）→ 直接继续。
  6. **[条件] 回填**：若 `require_backfill == true`，按该要素 spec 的回填步骤回填上游空关系（落单端）；主 agent 记录回填项。
  7. **[条件] evolve 要素**：若 `require_evolve == true` 且该要素是 evolve 类型 → 仅写 stage_increments.{emerge_stage} 字段。
  8. **后置校验** + **写 frontmatter**（stepsCompleted += element_id）+ 收集 `## 汇总输入`。

---

## Phase 3：后处理（按 post_generation_steps 列表执行）

> 所有后处理步骤由入参 `post_generation_steps` 列表驱动，按序执行列表中声明的步骤。不在列表中的步骤不执行。

### 可用步骤类型

| type | 说明 | 适用 |
|------|------|------|
| `chapter_numbering` | 按执行序列给节标题加序号前缀：`## {name_cn}` → `## {i} {name_cn}`，序号从 1 递增，Read 后逐项 Edit 替换 | 文档类 |
| `instance_numbering` | 按 `instance_prefixes` 给各要素实例分配连续编号（如 ROLE-01），回写文档 | 文档类 |
| `merge_summaries` | 合并各要素 `## 汇总输入` → 文档收尾 | 文档类 |
| `consistency_check` | 跨要素一致性检查（关系字段引用的上游均存在；回填已落单端） | 全部 |
| `set_status_completed` | 写输出文档 frontmatter.status = "completed" | 文档类 |
| `build_cross_references` | 重建 _index/cross-references.yaml（扫 relations_held 单端→派生反向） | 资产类 |
| `backfill_lineage` | 回填 lineage.triggered_by | 资产类 |
| `archive_version` | 归档 V0 | 资产类 |
| `build_design_index` | 汇总 design.md 跨 artifact 索引 | TDD |
| `update_ongoing` | 更新 ongoing.md（据 skill_namespace + workflow_hint 参数） | 全部 |
| `output_completion` | 输出完成提示（据 completion_template 参数） | 全部 |

### 各 Skill 典型配置

| Skill | post_generation_steps |
|-------|----------------------|
| FE | `chapter_numbering`, `instance_numbering`, `merge_summaries`, `consistency_check`, `set_status_completed`, `update_ongoing`, `output_completion` |
| PRD | 同 FE |
| TDD | 同 FE + `build_design_index` |
| Asset | `consistency_check`, `build_cross_references`, `backfill_lineage`, `archive_version`, `update_ongoing`, `output_completion` |

---

## Phase 4：末尾一次汇总确认（始终有）

输出整体确认（变更总览 + 各要素摘要）：
```
── {emerge_stage} 生成完成，请整体确认 ──
  已生成：{各要素摘要}
  [C] 确认并结束   [B] 返修某要素   [S] 查看全文   [Q] 保存并退出
```
等用户整体确认（即便过程中已逐个确认，此步必有）。
