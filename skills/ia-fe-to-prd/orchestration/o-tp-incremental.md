# o-tp-incremental
# workflow_id: tp-incremental-build
# 对应 workflow-registry 中 id: tp-incremental-build
# 实现:PRD 增量高阶方案 V3.0 第九章七步流程
# 规范:设计文档 Skill 构建规范 v1.3.0

## ⚠️ 双文档强制约束

> 本编排文件执行期间,输出有且只有两个新文档:
> - 一个新版本 PRD 文档(主产物)
> - 一个独立 Story 文件(只含本次新增 Story,不复制基线 Story)
>
> Phase 1 Action 1 创建新版本 PRD 文档,Phase 2.5 创建独立 Story 文件。
> 所有要素执行结果由 element-runner Phase 6 追加写入 PRD 文档(含 DELTA 标注块)。
> 基线 PRD(context.base_doc_path)只读。基线 Story 文件不修改、不复制。
> 禁止另建任何中间稿、过程稿、阶段稿、临时稿。

## 前置说明

本编排文件由 workflow-engine 命中 tp-incremental-build 后调用。
本编排实现 PRD 增量高阶方案 V3.0 的七步流程,严格遵循规范 v1.3.0 §3.4.1 的编排模板。
所有要素执行细节由 element-runner 调用对应 Spec 完成。

**章节信息来源约束**(v1.2.0/v1.3.0 强制):本文件不得包含任何硬编码的章节编号映射。
所有 chapter_info 字段必须从 `registry/element-type-registry.yaml` 动态读取。

**story-design 特殊性**:story-design 是 always_affected 要素,但**不在 Phase 2 要素循环中执行**,由 Phase 2.5 单独触发(全局收口)。

---

## Phase 0: 续接恢复检查

若 `inventory.PRD_DOC_INPROGRESS` 存在,且其 frontmatter `workflow_id == "tp-incremental-build"`:
- 读取 `stepsCompleted`、`last_element`、`impact_analysis`(已存)
- 提示用户:
  ```
  检测到上次未完成的增量 PRD 文档,上次完成到「{last_element}」。
  本次已识别原子变化点: {triggered_changes}
  剩余执行要素: {remaining_elements}
    [C] 从「{first_remaining_element}」继续
    [N] 放弃,重新开始(新建)
    [Q] 退出
  ```
- 用户选 C:跳至 Phase 2,使用已记录的 effective_sequence(剔除 stepsCompleted)
- 用户选 N:询问是否归档当前进行中文档,然后进入 Phase 1
- 用户选 Q:终止

否则进入 Phase 1。

---

## Phase 1: 初始化(新建增量场景)

### Action 1: 定位基线 PRD,检测可选 FE,创建新版本 PRD 文档

1. 读取 `workspace/ongoing.md`,提取:
   - `current_version`(本次新版本号)
   - `project_name`
   - `prd.base_version`(基线版本号)
2. 定位基线 PRD:
   - 路径模式:`workspace/design/{base_version}/PRD-{project_name}-*.md`
   - 状态过滤:frontmatter `status == "completed"`
   - 多个候选:按 `last_updated` 降序展示编号列表,让用户选择
   - 仅一个:直接使用
3. 验证基线 PRD frontmatter:
   - `workflow_id` 应为 `tp-new-build` 或 `tp-incremental-build`
   - `requirement_type` 应为 `TP`
   - 验证不通过 → 暂停报错并退出
4. **检测新版本 FE 是否存在**(可选输入):
   - 路径模式:`workspace/requirements/{current_version}/FE-{project_name}-*.md`
   - 状态过滤:frontmatter `status == "completed"`
   - 存在 → `fe_doc_available = true`,提取路径
   - 不存在 → `fe_doc_available = false`,提示用户:
     ```
     ⚠️ 本次新版本未发现 FE 文档,将由对话挖掘兜底证据来源
     (V3.0 §1.2 问题五:FE 缺位)
     [C] 继续(不依赖 FE)  [Q] 退出先补 FE
     ```
5. 生成新版本 PRD 文档名:`PRD-{project_name}-{今日 YYYYMMDD}.md`
6. **创建唯一新文档**(路径:`workspace/design/{current_version}/{filename}`),写入初始 frontmatter:

   ```yaml
   workflow_id: "tp-incremental-build"
   requirement_type: "TP"
   requirement_nature: "优化需求"
   project_name: "{project_name}"
   version: "{current_version}"
   base_doc: "{基线 PRD 相对路径}"
   fe_doc: "{新版本 FE 路径或空字符串}"
   fe_doc_available: true | false
   status: "in_progress"
   stepsCompleted: []
   last_element: ""
   last_updated: ""
   requirement_register: []              # Phase 1.0 RR 登记后写入
   impact_analysis:
     triggered_changes: []               # AtomicChange 运行时实例
     effective_sequence: []              # 路由结果
     impact_points: []                   # ImpactPoint 累积(无 kind 字段)
   story_doc_path: ""                    # Phase 2.5 创建后写入
   ```

7. 将路径赋值给 context:
   - `context.output_doc_path` = 新版本 PRD 路径
   - `context.base_doc_path` = 基线 PRD 路径
   - `context.fe_doc_path` = 新版本 FE 路径(或空字符串)
   - `context.fe_doc_available` = bool
8. 同步更新 `ongoing.md.prd.current_path` = 新文档路径

### Phase 1.0: 原始需求登记(RR 登记)

> 实现 V3.0 第九章 Step 1.0

**输入**:用户对增量诉求的业务描述

**处理**:

1. 引导用户输入:
   ```
   请用一句话或一段话描述本次 PRD 增量诉求(业务语言即可)。
   若有多条需求,请分条列出,我会逐条编号。
   例如:
     1. 审批前增加部门预审环节(新功能)
     2. 审批阈值从 5 万改为 10 万(逻辑调整)
     3. 增加批量导出功能(新功能)
     4. 新增 ERP 成(新系统集成)
   ```

2. 若 `fe_doc_available == true`,提示:
   ```
   检测到新版本 FE 文档:{fe_doc_path}
   是否直接从 FE 提取 RR?
     [Y] 是,自动提取(我会从 FE §1 原始需求章节读取 RR 并展示)
     [N] 否,由你手动输入
   ```
   选 Y → 读取 FE §1.1 原始需求来源表 / §1.2 RR 描述,直接生成 RR 列表
   选 N → 进入手动输入流程

3. 把每条需求结构化为 RR 运行时实例:

   ```yaml
   - id: "RR-{序号}"
     description: "原文一字不改"
     source: "对话输入 | FE §1.2 RR-NN"
     status: "待分析"
   ```

4. 写入 `context.impact_analysis.requirement_register`,同时写入 PRD frontmatter `requirement_register` 字段

**暂停触发**:
- 单条需求过于模糊 → 暂停询问具体改什么

---

## Phase 1.5: 变化点路由(四步流程)

> 实现 V3.0 第九章 Step 1.1 ~ Step 4 + 规范 v1.3.0 §3.5.3 四步流程

### Step 1.1: 子变化点识别(ChangeRouter Step 1)

**输入**:RR 列表 + 基线 PRD 文档 + 可选新版本 FE 文档

**处理**:对**每条 RR** 单独识别其原子变化点

1. **关键词初筛**:用每个变化点的 detection_keywords(读自 `registry/atomic-change-registry.yaml`)与 RR.description 做模糊匹配
2. **LLM 语义匹配**:基于候选条目的 description_zh 和 examples,从候选中精选最匹配的 1~N 个变化点
3. **证据收集**:每个识别出的变化点必须能引用以下之一作为 evidence,并标注 evidence_source:
   - `fe_doc`:新版本 FE 文档对应章节 + 引用片段(仅当 fe_doc_available)
   - `baseline_prd`:基线 PRD 文档对应章节 + 引用片段
   - `dialog`:用户当前 RR 描述原文片段
4. **用户确认**:同一 RR 命中多个变化点时列出选项让用户选

**暂停触发**(规范 v1.3.0 §3.5.3 强制约束):
- 同一 RR 命中多个变化点且无法消歧
- 命中置信度为 low / medium:必须暂停澄清,不得自动通过
- RR 描述明显超出 26 个变化点的覆盖范围

**输出**:AtomicChange 运行时实例列表:

```yaml
- id: "{CATEGORY-NN}"             # 如 PR-01, LG-01, UI-02
  source_requirement: "RR-{xx}"
  evidence: "证据原文片段"
  evidence_source: "fe_doc | baseline_prd | dialog"
  confidence: "high | medium | low"
  open_question: ""                # confidence 非 high 时填
```

写入 `context.impact_analysis.triggered_changes`。

**强制约束**:confidence 为 medium 或 low 必须暂停,不得进入 Step 2。

### Step 2: 影响汇聚(ChangeRouter Step 2)

**输入**:Step 1.1 的 AtomicChange 列表

**处理**:对每个变化点,从 `registry/change-element-mapping.yaml` 读 affects 列表,按 impact_level 处理:
- `certain` → 加入 candidate_sequence
- `likely` → 加入但标记 `optional_skippable=true`
- `conditional` → 检查 condition(可从证据判断 → 按结果决定;否则暂停询问)

**特殊处理:story-design 排除**:
- 即便有变化点 affects story-design(理论上不会出现,因为映射表已按 V3.0 §6 规则不让普通变化点直接 affects story-design),也强制从 candidate_sequence 中排除
- story-design 由 Phase 2.5 单独触发

**输出**:候选 effective_sequence,每项保留 `source_changes` 来源跟踪。

### Step 3: always_affected 强制补全(ChangeRouter Step 3)

**处理**:扫描 `registry/element-type-registry.yaml`,找出所有 `always_affected_in` 含 `"incremental"` 的 element_id:
- 预期结果:`["story-design"]`(本 Skill 唯一)

**特殊处理:不加入 Phase 2 sequence**:
- story-design 虽是 always_affected,但**不加入 effective_sequence**(它由 Phase 2.5 单独触发)
- 设置标记 `context.story_design_pending = true`,供 Phase 2.5 检查

### Step 4: 依赖图安全网校验(ChangeRouter Step 4)

**处理**:对 effective_sequence 做闭包扩展(规范 v1.3.0 §3.5.3 Step 4):

1. 遍历 `registry/dependency-graph.yaml` 的 impact_edges
2. 对 effective_sequence 中已有的每个 element,取出该 element 作为 source 的所有 **direct** targets(**排除 story-design**)
3. 凡 target 不在 effective_sequence 中的,归入"安全网额外发现"清单
4. 输出警告并由用户确认是否加入

   ```
   🛡️ 依赖图安全网校验
   当前 effective_sequence:
     - product-positioning (cascade,通过用户主动声明)
     - app-architecture (primary, IN-01)
     - feature-spec (primary, LG-01 PR-04)
     - permission-design (cascade, feature-spec → permission-design direct)
     ...

   依赖图发现可能受影响但未在路由结果中的要素:
     - scenario-solution ← 来源 feature-spec(indirect),原因:功能变化可能影响场景

   是否加入 effective_sequence?
     [Y] 全部加入
     [S] 选择性加入(逐项确认)
     [N] 跳过
   ```

5. 根据用户选择更新 effective_sequence
6. **按 element-type-registry 的 chapter_no 升序排序** effective_sequence
7. 写入新版本 PRD 的 frontmatter:

   ```yaml
   impact_analysis:
     requirement_register: [...]
     triggered_changes:
       - id: "LG-01"
         source_requirement: "RR-01"
         evidence: "..."
         evidence_source: "dialog"
         confidence: "high"
         open_question: ""
     effective_sequence:
       - element_id: "..."
         impact_level: "certain | likely | conditional"
         source_changes: ["LG-01"]
     cascade_warnings:
       - element_id: "scenario-solution"
         reason: "依赖图安全网识别"
         added_by_user: true
     impact_points: []
   story_design_pending: true   # Phase 2.5 处理标记
   ```

---

## Phase 2: 要素循环执行(排除 story-design)

> 实现 V3.0 第九章 Step 5 + Step 6;严格遵循规范 v1.3.0 §3.4.1 Phase 2 模板

### 2.1 执行计划展示与用户确认(V3.0 Step 5.1)

向用户输出:

```
✅ 增量影响域分析完成

原始需求:
  RR-01: "审批前增加部门预审环节"
  RR-02: "审批阈值从 5 万改为 10 万"
  RR-03: "新增 ERP 集成"

触发原子变化点:
  RR-01 → LG-01(high), PR-01(high)
  RR-02 → LG-02(high)
  RR-03 → IN-01(high)

受影响要素(按章节顺序,排除 story-design):
  2. app-architecture(primary,IN-01)
  3. ui-prototype(cascade,from LG-01 direct)
  4. info-architecture(cascade,from LG-01 direct)
  5. feature-spec(primary,LG-01 LG-02 PR-01)
  6. permission-design(cascade,from feature-spec direct)
  7. integration-design(primary,IN-01)
  8. scenario-solution(primary,PR-01)
  10. nfr(可选 likely,用户在 Step 4 确认)

不涉及要素:product-positioning(无变化点)、config-design(条件未触发)
🟢 story-design 由 Phase 2.5 单独触发(全局收口)

[C] 开始执行  [B] 重做 ChangeRouter  [Q] 退出
```

收到 C 后进入 2.2 要素循环。

### 2.2 要素循环 + ImpactPoint 累积

```text
FOR each item IN effective_sequence:  # 已排除 story-design

  element_id = item.element_id

  IF element_id 已在 stepsCompleted 中:
    跳过
    CONTINUE

  IF element_id == "story-design":     # 双重保险
    跳过(Phase 2.5 处理)
    CONTINUE

  # 1. 从 element-type-registry 读取 chapter_info
  e = element_type_registry.lookup(element_id)
  chapter_info = {
    l1_no               : e.chapter_no_cn,
    element_name        : e.name,
    sub_elements        : e.sub_elements,
    chapter_label_style : e.chapter_label_style
  }

  # 2. 过滤本要素相关的变化点
  element_changes = []
  FOR each change IN context.impact_analysis.triggered_changes:
    mapping = change_element_mapping.lookup(change.id)
    IF element_id IN [a.element_id for a in mapping.affects]:
      element_changes.append({
        change_id: change.id,
        source_requirement: change.source_requirement,
        user_description: RR-NN 的 description,
        impact_level: affect.impact_level,
        trigger_type: "primary"
      })

  # 3. 调用 element-runner,传入 incremental 模式
  调用 element-runner 传入:
    element_id      : element_id
    execution_mode  : "incremental"
    context         : {
      workflow_id       : "tp-incremental-build",
      requirement_type  : "TP",
      input_doc_path    : "",
      output_doc_path   : context.output_doc_path,
      base_doc_path     : context.base_doc_path,
      fe_doc_path       : context.fe_doc_path,
      fe_doc_available  : context.fe_doc_available,
      chapter_info      : chapter_info,
      impact_analysis   : {
        requirement_register: context.impact_analysis.requirement_register,
        triggered_changes   : context.impact_analysis.triggered_changes,
        effective_sequence  : context.impact_analysis.effective_sequence,
        element_changes     : element_changes
      },
      change_type       : ""
    }

  # 4. 处理返回控制信号
  # ⚠️ v1.2.1 显式挂起规则:
  # element-runner 输出操作菜单后,FOR 循环必须挂起,本次响应立即终止。
  C    → 继续下一要素
  B    → 重跑当前要素
  Q    → 保存退出
  SKIP → 记录跳过日志,继续下一要素

END FOR
```

---

## Phase 2.5: Story 全局收口(V3.0 Step 7)

> 实现 V3.0 第九章 Step 7 "Story 全局收口"

### Action A: ImpactPoint 全局重编号

要素循环累积的 ImpactPoint 临时占位编号统一重编号为全局递增编号:

```python
counter = 1
FOR each ip IN context.impact_analysis.impact_points:
  ip.id = f"IP-{counter:03d}"        # IP-001, IP-002, ...
  counter += 1
```

### Action B: 跨要素全局一致性检查

执行以下检查:

- [ ] 新增页面(UI-02)对应的功能(FR-xxx)是否在 feature-spec 中定义
- [ ] 新增字段(DA-02)在 info-architecture 实体表中存在,且引用该字段的 feature 已同步
- [ ] 新增功能(LG-01)在 permission-design 权限矩阵中有对应行
- [ ] 新增集成(IN-01)在 app-architecture 上下文图中有对应节点
- [ ] 所有 ImpactPoint 满足规范 v1.3.0 §3.7.3:
  - 无 `kind` 字段
  - `target_state_evidence` 必填(取值 fe_doc | baseline_prd | dialog)
  - always_affected 的 IP(将由 Action C 生成)满足约束

发现不一致 → 暂停提示用户。

### Action C: 创建独立 Story 文件

> 实现用户决策方案 A:Story 文件仅含本次新增,不复制基线 Story

1. 生成 Story 文件名:`Story-{project_name}-{今日 YYYYMMDD}.md`
2. **创建独立 Story 文件**(路径:`workspace/design/{current_version}/{story filename}`),初始 frontmatter:

   ```yaml
   project_name: "{project_name}"
   version: "{current_version}"
   parent_prd: "{output_doc_path}"
   story_count: 0                        # Action D 完成后更新
   generated_at: "{today}"
   note: "本文件仅包含本次增量新增的 Story,不复制基线 Story。基线 Story 见 {baseline 路径}"
   ```

3. 路径写入 context:`context.story_doc_path` = Story 文件路径
4. 同步写入 PRD frontmatter `story_doc_path` 字段

### Action D: 调用 story-design 要素(全局收口)

```text
# 调用 element-runner,传入 story-design 要素
调用 element-runner 传入:
  element_id      : "story-design"
  execution_mode  : "incremental"
  context         : {
    workflow_id       : "tp-incremental-build",
    requirement_type  : "TP",
    output_doc_path   : context.output_doc_path,    # PRD 文档
    story_doc_path    : context.story_doc_path,     # 独立 Story 文件
    base_doc_path     : context.base_doc_path,      # 基线 PRD
    fe_doc_path       : context.fe_doc_path,
    fe_doc_available  : context.fe_doc_available,
    chapter_info      : {
      l1_no: "11",
      element_name: "Story 设计",
      sub_elements: [],
      chapter_label_style: "数字"
    },
    impact_analysis   : {
      requirement_register: context.impact_analysis.requirement_register,
      triggered_changes   : context.impact_analysis.triggered_changes,
      effective_sequence  : context.impact_analysis.effective_sequence,
      impact_points       : context.impact_analysis.impact_points   # 已全局重编号
    },
    baseline_story_index: { ... }   # 由 Action B 读取得到
  }
```

> **注意**:此次调用传入的 element_changes 字段为空(全局收口型不依赖单个变化点);
> impact_points 字段为关键输入(spec 内部 Step I-3 切分 Story 时使用)。

story-design spec 完成后:
- 将"PRD §11 Story 索引"DELTA 写入 context.output_doc_path
- 将本次新增 Story 完整描述写入 context.story_doc_path

### Action E: 输出影响点汇总草案

按规范 v1.3.0 §3.7.3 统一格式输出影响点清单:

```
=== 增量 PRD 影响域分析草案 ===

【一、原始需求】
RR-01: 描述 / 状态:已分析
RR-02: 描述 / 状态:已分析
RR-03: 描述 / 状态:已分析

【二、原子变化点】
RR-01 → LG-01(high, fe_doc), PR-01(high, fe_doc)
RR-02 → LG-02(high, dialog)
RR-03 → IN-01(high, fe_doc)

【三、受影响 PRD 要素总表】
要素 | 触发类型 | 触发变化点 | 改动摘要
app-architecture | primary | IN-01 | 上下文图追加 ERP
feature-spec | primary | LG-01 LG-02 PR-01 | 新增 FR-Purchase-PreApprove-001 + 修改 FR-Approve-002
story-design | always_affected | - | 新增 8 个 STORY-INC
...

【四、不涉及要素说明】
要素 | 不涉及原因 | 验证依据
product-positioning | 26 变化点中无 affects | V3.0 §6 映射表
config-design | conditional 未触发(LG-02 无需参数化) | -

【五、影响点清单】(统一列表,无 kind 字段;evidence_source=dialog 的项以 ⚠️ 标记)

IP-001 [primary, source_change=LG-01, source_requirement=RR-01]
  element: feature-spec
  baseline_ref: 基线 PRD §5
  baseline_state: "已有 FR-001 ~ FR-025"
  action: 新增
  target_state: "新增 FR-Purchase-PreApprove-001"
  target_state_evidence: fe_doc
  in_scope: [...]
  out_of_scope: [...]
  out_of_scope_reason: "..."
  boundary_constraints: [...]

IP-002 [...]
...

【六、Story 收口】
STORY-INC-011: FR-Purchase-PreApprove-001(同锚点合并 PR-01+LG-01)
STORY-INC-012: PG-009 批量导出
...

【七、追溯链路】
RR-01 → LG-01 → IP-001(feature-spec) → STORY-INC-011
RR-01 → PR-01 → IP-002(...) → STORY-INC-012
...

=== 待确认问题汇总 ===
(若有,集中列出)

请确认:
1. 分析结论是否准确?有无遗漏或错误?
2. 影响点的 in_scope / out_of_scope 划分是否准确?
3. Story 合并方案是否准确?
4. 边界约束是否完整?
5. evidence_source=dialog 的项是否需要再补证据?
```

强制获得明确确认后才能进入 Phase 3。

---

## Phase 3: 完成收尾

### Action A: 输出附录-影响点清单到新版 PRD

将 Phase 2.5 整理后的 ImpactPoint 列表写入新版 PRD 文档末尾的"附录:影响点清单"章节(规范 v1.3.0 统一列表格式):

```markdown
## 附录:影响点清单

### A.1 全部影响点(共 N 条)

| IP 编号 | 来源 RR | 来源变化点 | 触发类型 | 受影响要素 | action | baseline_ref |
|--------|--------|----------|---------|----------|--------|--------------|
| IP-001 | RR-01 | LG-01 | primary | feature-spec | 新增 | §5 |
| IP-002 | RR-01 | PR-01 | primary | feature-spec | 新增 | §5 |
| ... |

### A.2 影响点详情

(完整字段:source_requirement / source_change / trigger_type / cascade_rule / element / baseline_ref / baseline_state / action / target_state / target_state_evidence / in_scope / out_of_scope / out_of_scope_reason / boundary_constraints)
```

### Action B: 最终状态更新

由 element-runner Phase 6 在 story-design 完成时更新 frontmatter:

```yaml
status: "completed"
last_updated: "{today YYYY-MM-DD}"
```

同步更新 `ongoing.md.prd.current_path`。

### Action C: 输出完成提示

```text
✅ ia-fe-to-prd (incremental) 已完成

输出文件:
  - PRD: {context.output_doc_path}
  - Story: {context.story_doc_path}(本次新增 {N} 个 Story)
基线文档: {context.base_doc_path}
{当 fe_doc_available 时:}新版本 FE: {context.fe_doc_path}

原始需求(RR):
  - RR-01: ...
  - RR-02: ...
  - RR-03: ...

命中原子变化点:
  - LG-01, LG-02, PR-01, IN-01

执行要素数: {count}(不含 story-design 单独处理)
ImpactPoint 总数: {count}
Story 总数: {count}

建议下一步:
  - 评审 PRD 增量产物
  - 评审 Story 集合(开发团队认领)
```