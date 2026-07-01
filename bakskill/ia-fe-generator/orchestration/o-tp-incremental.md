# o-tp-incremental
# workflow_id: tp-incremental
# 对应 workflow-registry 中 id: tp-incremental
# 实现:FE 增量高阶方案 V2.0 第九章六步流程
# 规范:设计文档 Skill 构建规范 v1.3.0

## ⚠️ 单一文档强制约束

> 本编排文件执行期间,输出有且只有一个新版本 FE 文档。
> - Phase 1 Action 1 创建唯一新版本 FE 文档,路径写入 context.output_doc_path
> - 所有要素执行结果由 element-runner Phase 6 追加写入该文档(含 DELTA 标注块)
> - 基线 FE(context.base_doc_path)只读,不修改
> - 禁止另建任何中间稿、过程稿、阶段稿、临时稿

## 前置说明

本编排文件由 workflow-engine 命中 tp-incremental 后调用。
本编排实现 FE 增量高阶方案 V2.0 的六步流程,严格遵循规范 v1.3.0 §3.4.1 的编排模板。
所有要素执行细节由 element-runner 调用对应 Spec 完成。

**章节信息来源约束**(v1.2.0/v1.3.0 强制):本文件不得包含任何硬编码的章节编号映射。
所有 chapter_info 字段必须从 `registry/element-type-registry.yaml` 动态读取。

---

## Phase 0: 续接恢复检查

若 `inventory.FE_DOC_INPROGRESS` 存在,且其 frontmatter `workflow_id == "tp-incremental"`:
- 读取 `stepsCompleted`、`last_element`、`impact_analysis`(已存)
- 提示用户:
  ```
  检测到上次未完成的增量 FE 文档,上次完成到「{last_element}」。
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

### Action 1: 定位基线 FE,创建新版本 FE 文档

1. 读取 `workspace/ongoing.md`,提取:
   - `current_version`
   - `project_name`
2. 定位基线 FE(对应 input_signature.required.FE_HISTORICAL):
   - 路径模式:`workspace/requirements/*/FE-{project_name}-*.md`
   - 状态过滤:frontmatter `status == "completed"`
   - 若发现多个基线候选:按 `last_updated` 降序展示编号列表,让用户选择
   - 若仅一个:直接使用
3. 验证基线 FE frontmatter:
   - `workflow_id` 应为 `tp-new-build` 或 `tp-incremental`
   - `requirement_type` 应为 `TP`
   - 验证不通过 → 暂停报错并退出
4. 生成新版本 FE 文档名:`FE-{project_name}-{今日 YYYYMMDD}.md`
5. **创建唯一新文档**(路径:`{output_folder_base}/{current_version}/{filename}`),写入初始 frontmatter:
   ```yaml
   workflow_id: "tp-incremental"
   requirement_type: "TP"
   requirement_nature: "优化需求"
   project_name: "{project_name}"
   base_doc: "{基线 FE 相对路径}"
   status: "in_progress"
   stepsCompleted: []
   last_element: ""
   last_updated: ""
   requirement_register: []              # Phase 1.0 RR 登记后写入
   impact_analysis:
     triggered_changes: []               # AtomicChange 运行时实例列表
     effective_sequence: []              # 路由结果
     impact_points: []                   # ImpactPoint 累积(无 kind 字段,统一结构)
   ```
6. 将文档路径赋值给 `context.output_doc_path`
7. 将基线 FE 路径赋值给 `context.base_doc_path`
8. 同步更新 `ongoing.md.fe.current_path` = 新文档路径

### Phase 1.0: 原始需求登记(RR 登记)

> 实现 V2.0 第九章 Step 1.0

**输入**:用户对增量诉求的业务描述

**处理**:

1. 引导用户输入:
   ```
   请用一句话或一段话描述本次增量诉求(业务语言即可)。
   若有多条需求,请分条列出,我会逐条编号。
   例如:
     1. 审批前增加部门预审环节
     2. 审批阈值从 5 万改为 10 万
     3. 增加批量导出功能
   ```

2. 把每条需求结构化为 RR 运行时实例:

   ```yaml
   - id: "RR-{序号}"          # 如 RR-01、RR-02
     description: "原文一字不改"
     source: "对话输入"
     status: "待分析"
   ```

3. 写入 `context.impact_analysis.requirement_register`,同时写入输出文档 frontmatter `requirement_register` 字段

**暂停触发**:

- 单条需求过于模糊(如"优化体验"无具体动作) → 暂停询问"该需求具体改什么"

---

## Phase 1.5: 变化点路由(四步流程)

> 实现 V2.0 第九章 Step 1.1 ~ Step 4 + 规范 v1.3.0 §3.5.3 四步流程

### Step 1.1: 原子变化点识别(ChangeRouter Step 1)

**输入**:RR 列表 + 基线 FE 文档

**处理**:对**每条 RR** 单独识别其原子变化点

1. **关键词初筛**:用每个变化点的 detection_keywords(读自 `registry/atomic-change-registry.yaml`)与 RR.description 做模糊匹配,得到候选 atomic_changes 列表
2. **LLM 语义匹配**:基于候选条目的 description_zh 和 examples,从候选中精选最匹配的 1~N 个变化点
3. **证据收集**:每个识别出的变化点必须能引用以下之一作为 evidence,并标注 evidence_source:
   - `baseline_fe`:基线 FE 文档对应章节 + 引用片段
   - `dialog`:用户当前 RR 描述原文片段
4. **用户确认**:同一 RR 命中多个变化点时列出选项让用户选

**暂停触发**(规范 v1.3.0 §3.5.3 强制约束):
- 同一 RR 命中多个变化点且无法消歧
- 命中置信度为"低"(low)
- 命中置信度为"中"(medium):必须暂停澄清,不得自动通过
- RR 描述明显超出 18 个变化点的覆盖范围

**输出**:AtomicChange 运行时实例列表,严格按规范 v1.3.0 §3.5.3 Step 1 Schema:

```yaml
- id: "{CATEGORY-NN}"             # 如 PR-01
  source_requirement: "RR-{xx}"
  evidence: "证据原文片段"
  evidence_source: "baseline_fe | dialog"
  confidence: "high | medium | low"
  open_question: ""                # confidence 非 high 时填,high 时置空
```

写入 `context.impact_analysis.triggered_changes`。

**强制约束**:confidence 为 medium 或 low 的实例,**必须暂停并向用户提问澄清**,不得进入 Step 2。所有实例 confidence=high 后方可继续。

### Step 2: 影响汇聚(ChangeRouter Step 2)

**输入**:Step 1.1 的 AtomicChange 列表

**处理**:对每个变化点,从 `registry/change-element-mapping.yaml` 读 affects 列表,按 impact_level 处理:

- `certain` → 直接加入 candidate_sequence
- `likely` → 加入但标记 `optional_skippable=true`,在 Step 5 由用户决定
- `conditional` → 检查 condition:
  - 条件可从证据判断 → 按结果决定
  - 条件无法判断 → 暂停询问

**输出**:候选 effective_sequence,每项保留 `source_changes` 来源跟踪。

格式:

```yaml
- element_id: "business-process"
  impact_level: "certain"
  source_changes: ["PR-01", "PR-07"]    # 触发本要素的所有变化点
  optional_skippable: false
```

### Step 3: always_affected 强制补全(ChangeRouter Step 3)

**处理**:扫描 `registry/element-type-registry.yaml`,找出所有 `always_affected_in` 含 `"incremental"` 的 element_id:
- 预期结果:`["original-requirement", "requirement-type", "glossary"]`

将这三个要素强制加入 effective_sequence(若已存在则不重复):

```yaml
- element_id: "original-requirement"
  impact_level: "certain"
  source_changes: []                    # always_affected 不来自具体变化点
  trigger_type: "always_affected"       # orchestration 内部标记,不传给 element-runner
```

> **注意**:此处 `trigger_type` 是 orchestration 内部标记,用于在 Phase 2 调用 element-runner 时区分;但传入 element-runner 的 context 中,ImpactPoint 的 `trigger_type` 严格遵循规范 v1.3.0 只取 `primary | cascade`。

### Step 4: 依赖图安全网校验(ChangeRouter Step 4)

**处理**:对 effective_sequence 做闭包扩展(规范 v1.3.0 §3.5.3 Step 4):

1. 遍历 `registry/dependency-graph.yaml` 的 impact_edges
2. 对 effective_sequence 中已有的每个 element,取出该 element 作为 source 的所有 **direct** targets
3. 凡 target 不在 effective_sequence 中的,归入"安全网额外发现"清单
4. 输出警告并由用户确认是否加入

```
🛡️ 依赖图安全网校验
当前 effective_sequence:
  - original-requirement (always_affected)
  - requirement-type (always_affected)
  - glossary (always_affected)
  - business-process (primary, PR-01 PR-07)
  - business-function (likely, PR-01 PR-07 cascade)

依赖图发现可能受影响但未在路由结果中的要素:
  - user-interaction ← 来源 business-function(direct),原因:功能必有页面承载

是否加入 effective_sequence?
  [Y] 全部加入
  [S] 选择性加入(逐项确认)
  [N] 跳过
```

**注意**:indirect 边不强制加入,仅作提示。

5. 根据用户选择更新 effective_sequence
6. **按 element-type-registry 的 chapter_no 升序排序** effective_sequence

7. 写入新版本 FE 的 frontmatter:

```yaml
impact_analysis:
  requirement_register: [...]
  triggered_changes:
    - id: "PR-07"
      source_requirement: "RR-02"
      evidence: "..."
      evidence_source: "dialog"
      confidence: "high"
      open_question: ""
  effective_sequence:
    - element_id: "..."
      impact_level: "certain | likely | conditional"
      source_changes: ["PR-07"]
  cascade_warnings:
    - element_id: "user-interaction"
      reason: "依赖图安全网识别"
      added_by_user: true
  impact_points: []        # Phase 2 累积
```

---

## Phase 2: 要素循环执行

> 实现 V2.0 第九章 Step 5.2;严格遵循规范 v1.3.0 §3.4.1 Phase 2 模板

### 2.1 执行计划展示与用户确认(V2.0 Step 5.1)

向用户输出:

```
✅ 增量影响域分析完成

原始需求:
  RR-01: "审批前增加部门预审环节"
  RR-02: "审批阈值从 5 万改为 10 万"

触发原子变化点:
  RR-01 → PR-01(high)
  RR-02 → PR-07(high)

受影响要素(按章节顺序):
  1. original-requirement(always_affected)
  2. requirement-type(always_affected)
  3. business-process(primary,触发 PR-01 + PR-07)
  4. business-function(cascade,触发自 business-process direct)
  5. (可选 likely 要素)user-interaction:已加入(用户在 Step 4 确认)
  8. glossary(always_affected)

不涉及要素:business-background、non-functional-req

[C] 开始执行  [B] 重做 ChangeRouter  [Q] 退出
```

收到 C 后进入 2.2 要素循环。

### 2.2 要素循环 + ImpactPoint 累积

```text
FOR each item IN effective_sequence:

  element_id = item.element_id

  IF element_id 已在 stepsCompleted 中:
    跳过(续接恢复时的剔重)
    CONTINUE

  # 1. 从 element-type-registry 读取 chapter_info
  e = element_type_registry.lookup(element_id)
  chapter_info = {
    l1_no               : e.chapter_no_cn,
    element_name        : e.name,
    sub_elements        : e.sub_elements,
    chapter_label_style : e.chapter_label_style,
    backend_only        : e.backend_only or false
  }

  # 2. 过滤本要素相关的变化点(传给 element-runner 的 element_changes)
  element_changes = []
  FOR each change IN context.impact_analysis.triggered_changes:
    mapping = change_element_mapping.lookup(change.id)
    IF element_id IN [a.element_id for a in mapping.affects]:
      affect = [a for a in mapping.affects if a.element_id == element_id][0]
      element_changes.append({
        change_id: change.id,
        source_requirement: change.source_requirement,
        user_description: RR-NN 的 description,
        impact_level: affect.impact_level,
        trigger_type: "primary"      # 由 Spec 决定(Spec 内部识别 always_affected 等情况)
      })

  # 3. 调用 element-runner,传入 incremental 模式
  调用 element-runner 传入:
    element_id      : element_id
    execution_mode  : "incremental"
    context         : {
      workflow_id       : "tp-incremental",
      requirement_type  : "TP",
      input_doc_path    : "",
      output_doc_path   : context.output_doc_path,    # 新版本 FE
      base_doc_path     : context.base_doc_path,       # 基线 FE(只读)
      chapter_info      : chapter_info,
      impact_analysis   : {
        requirement_register: context.impact_analysis.requirement_register,
        triggered_changes   : context.impact_analysis.triggered_changes,
        effective_sequence  : context.impact_analysis.effective_sequence,
        element_changes     : element_changes,        # 仅含本要素相关变化点
        delta_blocks_accumulated: context.impact_analysis.delta_blocks_accumulated   # 给 glossary 用
      },
      change_type       : ""
    }

  # 4. 处理返回控制信号
  # ⚠️ v1.2.1 显式挂起规则:
  # element-runner 输出操作菜单后,FOR 循环必须挂起,本次响应立即终止。
  # 禁止在同一响应中预判信号并继续循环。
  # 必须等待用户下一条消息到达,由消息内容决定信号值后再继续。
  C    → 继续下一要素(element-runner Phase 6 已更新 stepsCompleted)
  B    → 重跑当前要素
  Q    → 保存退出(status 保持 in_progress)
  SKIP → 记录跳过日志,继续下一要素

  # 5. 同步累积 DELTA 块到 context(给后续 glossary 用)
  context.impact_analysis.delta_blocks_accumulated.append(
    所有本次 element 写入新版 FE 的 DELTA 块原文
  )

END FOR
```

---

## Phase 2.5: 影响点汇总(V2.0 Step 6)

> 实现 V2.0 第九章 Step 6 "影响点汇总 + 草案输出"

### Action A: ImpactPoint 全局重编号

要素循环累积的 ImpactPoint 临时占位编号(如 `IP-business-process-001`)需统一重编号为全局递增编号:

```python
counter = 1
FOR each ip IN context.impact_analysis.impact_points:
  ip.id = f"IP-{counter:03d}"        # IP-001, IP-002, ...
  counter += 1
```

### Action B: 跨要素全局一致性检查

执行以下检查,对增量内容(DELTA 块内)做交叉一致性校验:

- [ ] 业务流程新增/调整角色,业务功能权限矩阵是否同步更新
- [ ] 新增功能编号(FR-xxx)是否在用户交互页面引用列出现
- [ ] 新增业务规则编号(BR-xxx)是否在功能描述中正确引用
- [ ] 概念术语表是否覆盖增量章节中新出现的专有名词
- [ ] 所有 ImpactPoint 满足规范 v1.3.0 §3.7.3:
  - 无 `kind` 字段
  - `out_of_scope` 和 `out_of_scope_reason` 必填
  - `target_state_evidence` 必填
  - always_affected 类型满足 `source_change == "" && trigger_type == "primary"`

发现不一致 → 暂停提示用户,等待确认修正。

### Action C: 输出影响点汇总草案

按规范 v1.3.0 §3.7.3 统一格式输出影响点清单(不分组),向用户展示:

```
=== 增量 FE 影响域分析草案 ===

【一、原始需求】
RR-01: 描述 / 状态:已分析
RR-02: 描述 / 状态:已分析

【二、原子变化点】
RR-01 → PR-01(high,evidence_source=dialog)
RR-02 → PR-07(high,evidence_source=baseline_fe)

【三、受影响 FE 要素总表】
要素 | 触发类型 | 触发变化点 | 改动摘要
original-requirement | always_affected | - | 追加 RR-01、RR-02
business-process | primary | PR-01 PR-07 | 新增 A02-pre 活动 + 修改 BR-审批阈值-001
...

【四、不涉及要素说明】
要素 | 不涉及原因 | 验证依据
business-background | 18 变化点中无 affects business-background | V2.0 §6 映射表
non-functional-req | 本次未涉及性能/安全调整 | -

【五、影响点清单】(统一列表,含 boundary_constraints 子字段;evidence_source=dialog 的项以 ⚠️ 标记)

IP-001 [primary, source_change=PR-07, source_requirement=RR-02]
  element: business-process
  baseline_ref: 基线 FE §4.7 业务规则 → BR-审批阈值-001
  baseline_state: "审批阈值 5 万元"
  action: 修改
  target_state: "审批阈值调整为 10 万元(target_state_evidence=dialog)" ⚠️
  in_scope:
    - "A02 采购申请审批活动"
    - "A05 出差申请审批活动"
  out_of_scope:
    - "A08 报销审批活动"
  out_of_scope_reason: "报销审批走的是 BR-报销阈值-002..."
  boundary_constraints:
    - target: "BR-报销阈值-002"
      reason: "业务规则边界"
      ...

IP-002 [...]
...

【六、追溯链路】
RR-02 → PR-07 → IP-001(business-process,A02 A05 in_scope,A08 out_of_scope)
RR-01 → PR-01 → IP-002, IP-003, ... 

=== 待确认问题汇总 ===
(若有,集中列出)

请确认:
1. 分析结论是否准确?有无遗漏或错误?
2. 影响点的 in_scope / out_of_scope 划分是否准确?
3. 边界约束是否完整?
4. evidence_source=dialog 的项是否需要再补证据?
```

强制获得明确确认后才能进入 Phase 3。

---

## Phase 3: 完成收尾

### Action A: 输出附录-影响点清单到新版 FE

将 Phase 2.5 整理后的 ImpactPoint 列表写入新版 FE 文档末尾的"附录:影响点清单"章节(规范 v1.3.0 统一列表格式,不分组,boundary_constraints 作为子字段嵌入):

```markdown
## 附录:影响点清单

### A.1 全部影响点(共 N 条)

| IP 编号 | 来源 RR | 来源变化点 | 触发类型 | 受影响要素 | action | baseline_ref |
|--------|--------|----------|---------|----------|--------|--------------|
| IP-001 | RR-02 | PR-07 | primary | business-process | 修改 | §4.7 BR-审批阈值-001 |
| IP-002 | RR-01 | PR-01 | primary | business-process | 新增 | §4 业务流程 |
| ... |

### A.2 影响点详情(逐 IP 详情)

#### IP-001

(完整字段:source_requirement / source_change / trigger_type / cascade_rule / element / baseline_ref / baseline_state / action / target_state / target_state_evidence / in_scope / out_of_scope / out_of_scope_reason / boundary_constraints)
```

### Action B: 最终状态更新

由 element-runner Phase 6 在最后一个要素完成时更新 frontmatter:

```yaml
status: "completed"
last_updated: "{today YYYY-MM-DD}"
```

清理 `ongoing.md`(可选):删除 `current_path` 字段,保留元信息用于历史追溯。

### Action C: 输出完成提示

参照 SKILL.md 完成提示模板,补充增量信息:

```text
✅ ia-fe-generator (incremental) 已完成

输出文件: {context.output_doc_path}
基线文档: {context.base_doc_path}
当前模式: tp-incremental / incremental

原始需求(RR):
  - RR-01: ...
  - RR-02: ...

命中原子变化点:
  - PR-01: 流程节点新增
  - PR-07: 业务规则新增/修改

执行要素数: {count}
ImpactPoint 总数: {count}
其中:含 boundary_constraints 子字段: {count}

建议下一步:
  ia-fe-to-prd {current_version}
```