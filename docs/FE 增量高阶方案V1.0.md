## FE 增量方案完整规格 v1.0

> 适用：ia-fe-generator Skill 的 incremental 模式（tp-incremental-build workflow）  
> 遵循：设计文档 Skill 构建规范 v1.2.0 / 引擎 v2.1.0  
> 与 PRD 增量方案在架构上同构、术语对齐

---

### 一、定位与边界

**做什么**：基于已完成的基线 FE 文档 + 业务的一句话需求，通过对话挖掘业务方案细节，产出增量 FE 文档（DELTA 标注）。

**不做什么**：

- 不读 PRD（FE 阶段对 PRD 切干净）
- 不重做需求类型判定时的工程化分析（业务侧只用业务语言）
- 不做实施级拆 Story（那是 PRD 阶段的事）

**与 PRD 增量同构**：

|共享|FE 独有|PRD 独有|
|---|---|---|
|5 步执行流程|业务语言原子变化点（18 个）|工程语言原子变化点（26 个）|
|两条铁律|不读 PRD 文档|读 FE 文档作为上游 artifact|
|ImpactPoint 数据结构|业务方案对话挖掘|影响点结构化分析|
|DELTA 格式|||
|变化点路由层四步流程|||

---

### 二、整体流程

```
【输入】
  业务一句话需求（用户对话） + 基线 FE 文档（已 completed）

      ↓

【ChangeRouter 四步流程】（Phase 1.5）
  Step 1：原子变化点识别（关键词初筛 → LLM 语义匹配 → 用户确认）
  Step 2：要素影响汇聚（certain/likely/conditional）
  Step 3：always_affected_in 要素强制补全
  Step 4：dependency-graph 安全网校验

      ↓ effective_sequence + 初始 ImpactPoint 列表

【要素循环执行】（Phase 2，incremental 模式）
  对每个受影响 FE 要素：
    1. 读基线 FE 对应章节
    2. 读本要素相关原子变化点
    3. 对话挖掘（沿用 build 模式的提问内核，但聚焦变更）
    4. 生成 DELTA 标注的增量内容

      ↓

【影响点汇总 + 草案输出】（Phase 3）
  影响点清单（modify + forbid 按 kind 分组）
  增量 FE 文档草案

      ↓

【人工确认】

      ↓

【最终增量 FE 文档】
```

---

### 三、两条铁律（与 PRD 增量共享）

**铁律一：有理有据**——每条结论必须来自需求原文 / 基线 FE 引用 / 用户澄清回答。  
**铁律二：随时暂停**——证据不足时必须暂停询问，绝不猜测。暂停格式与 PRD 增量方案一致。

详见 `docs/增量PRD分析Skill.md` 第三节，本 FE 方案直接复用。

---

### 四、原子变化点完整清单（18 个）

#### 4.1 PR 类——业务流程变化（8 个）

|id|name|description_zh|detection_keywords|例子|
|---|---|---|---|---|
|PR-01|流程节点新增|在业务流程中增加新步骤/环节/活动|增加步骤、新增环节、加一步、增加活动|"审批前增加部门预审环节"|
|PR-02|流程节点删除/合并|去掉或合并某个流程步骤|去掉步骤、删除环节、简化流程、合并|"去掉部门预审，直接走总监审批"|
|PR-03|流程顺序调整|调整流程节点的执行顺序|调整顺序、流程顺序、放到前面、放到后面|"把付款放到发货之前"|
|PR-04|角色调整|流程中执行某节点的角色变化|换角色、改角色、执行人变化|"审批人从部门主管改为项目经理"|
|PR-05|活动输入变化|某步骤的输入信息字段或来源变化|增加输入、改输入、新增字段、改数据来源|"申请提交时增加预算编码字段"|
|PR-06|活动输出变化|某步骤的输出结果或状态变更逻辑变化|输出变化、状态变化、产出|"审批通过后新增同步到 ERP"|
|PR-07|业务规则新增/修改|业务规则增加、调整阈值或废弃|新增规则、规则调整、阈值、改规则|"审批阈值从 5 万改为 10 万"|
|PR-08|异常处理新增/调整|异常分支或异常处理逻辑变化|异常处理、驳回、撤回、超时、退回|"新增审批超时 24 小时自动转交"|

#### 4.2 FN 类——业务功能变化（4 个）

|id|name|description_zh|detection_keywords|例子|
|---|---|---|---|---|
|FN-01|功能新增|增加一个完整的业务功能|新增功能、加功能、增加|"增加批量导出功能"|
|FN-02|功能描述调整|已有功能的操作步骤、范围调整|改功能、调整功能、操作步骤|"导出功能增加按时间筛选"|
|FN-03|功能下线|去掉某个已有功能|去掉功能、下线、移除|"下线手工补录功能"|
|FN-04|业务权限变化|角色对功能的访问权限调整|权限调整、角色权限、访问权限|"增加部门主管查看全部数据的权限"|

#### 4.3 UI 类——用户交互变化（4 个）

|id|name|description_zh|detection_keywords|例子|
|---|---|---|---|---|
|UI-01|页面新增|新增一个完整页面|新增页面、加页面、新页面|"新增订单详情页"|
|UI-02|页面字段/控件调整|在已有页面增/删字段、按钮、控件|加字段、改字段、加按钮、控件调整|"申请表单增加优先级字段"|
|UI-03|页面流转变化|调整页面之间的跳转关系|流转调整、跳转关系、页面跳转|"提交后直接跳详情页"|
|UI-04|页面下线|移除某个已有页面|下线页面、删页面、不需要页面|"下线手工补录页"|

#### 4.4 NF 类——非功能变化（2 个）

|id|name|description_zh|detection_keywords|例子|
|---|---|---|---|---|
|NF-01|性能要求变化|调整响应时间、并发、吞吐等指标|性能、响应、并发、吞吐|"响应时间从 3 秒收紧到 1 秒"|
|NF-02|安全/隐私要求变化|调整加密、脱敏、合规要求|安全、加密、脱敏、合规|"增加 GDPR 合规要求"|

---

### 五、原子变化点 → FE 要素影响映射

完整 mapping。说明：每个 affects 项至少含 element_id + impact_level；conditional 必填 condition。

|change_id|受影响要素|impact_level|说明|
|---|---|---|---|
|**PR-01**|business-process|certain|流程图、活动总览、活动明细新增节点|
||business-function|likely|新节点通常对应新功能|
||user-interaction|conditional / 新节点需要 UI 承载||
|**PR-02**|business-process|certain||
||business-function|likely|节点对应功能可能下线|
||user-interaction|conditional / 节点对应页面是否仍保留||
|**PR-03**|business-process|certain|流程图重排|
||business-function|conditional / 顺序变化是否影响功能描述操作步骤||
||user-interaction|conditional / 顺序变化是否影响页面流转||
|**PR-04**|business-process|certain|角色清单调整|
||business-function|certain|业务权限矩阵必然调整|
|**PR-05**|business-process|certain|输入子要素|
||business-function|likely|功能描述涉及的输入信息变化|
||user-interaction|likely|输入字段变化通常对应页面字段变化|
|**PR-06**|business-process|certain|输出子要素|
||business-function|likely||
||user-interaction|conditional / 输出是否在页面呈现||
|**PR-07**|business-process|certain|业务规则子要素|
||business-function|likely|功能描述可能引用规则|
|**PR-08**|business-process|certain|活动明细异常处理字段|
||business-function|likely||
||user-interaction|conditional / 异常处理是否需要新页面||
|**FN-01**|business-function|certain|功能清单/描述新增|
||business-process|certain|新功能通常对应新业务活动|
||user-interaction|certain|新功能必有页面承载|
|**FN-02**|business-function|certain|功能描述调整|
||business-process|conditional / 是否触达活动级变化||
||user-interaction|likely|操作步骤变化通常涉及页面|
|**FN-03**|business-function|certain|功能清单删除|
||business-process|certain|对应活动同步下线|
||user-interaction|certain|对应页面同步下线|
|**FN-04**|business-function|certain|业务权限矩阵|
||business-process|likely|角色清单可能调整|
|**UI-01**|user-interaction|certain|页面清单+流转+低保真|
||business-function|likely|新页面通常对应新功能或扩展|
||business-process|conditional / 新页面是否对应新活动||
|**UI-02**|user-interaction|certain|低保真|
||business-function|likely|字段变化常涉及功能描述|
||business-process|likely|输入信息可能同步变化|
|**UI-03**|user-interaction|certain|页面流转|
||business-process|likely|流转变化通常映射流程顺序|
|**UI-04**|user-interaction|certain|页面清单+流转|
||business-function|likely|对应功能可能下线|
|**NF-01**|non-functional-req|certain|性能要求子要素|
|**NF-02**|non-functional-req|certain|信息安全 + 个人隐私保护 子要素|

---

### 六、always_affected 要素

yaml

```yaml
# element-type-registry.yaml 需添加 always_affected_in 字段
- id: "original-requirement"
  always_affected_in: ["incremental"]   # 每次都要追加新需求来源到矩阵
- id: "requirement-type"
  always_affected_in: ["incremental"]   # 每次都重判类型（关键词可能因新需求变化）
- id: "glossary"
  always_affected_in: ["incremental"]   # 每次都扫描新出现的术语
```

---

### 七、依赖图（cascade 安全网）

yaml

```yaml
impact_edges:
  - source: "business-process"
    targets:
      - element: "business-function"
        impact_type: "direct"
        reason: "业务活动是功能清单的来源，活动变化必然影响功能"
      - element: "user-interaction"
        impact_type: "indirect"
        reason: "流程变化可能引发页面调整"

  - source: "business-function"
    targets:
      - element: "user-interaction"
        impact_type: "direct"
        reason: "功能必有页面承载，功能变化常对应页面变化"
      - element: "business-process"
        impact_type: "indirect"
        reason: "功能下线时对应活动需同步处理"

  - source: "user-interaction"
    targets:
      - element: "business-function"
        impact_type: "indirect"
        reason: "页面字段/操作变化反推功能描述需要更新"
      - element: "business-process"
        impact_type: "indirect"
        reason: "页面流转变化可能反映流程顺序调整"
```

---

### 八、五步执行流程详解

> 与 PRD 增量方案 5 步同构，但 Step 4 的"对照基线"在 FE 阶段是"对照基线 FE + 对话挖掘细节"。

#### Step 1：识别原子变化点

- 输入：业务一句话需求
- 处理：关键词初筛（detection_keywords）→ LLM 语义匹配（description_zh + examples）→ 用户确认
- 暂停触发：① 同一句话命中多个变化点；② 命中置信度低；③ 描述超出 18 个变化点范围
- 输出：AtomicChange 列表（含 evidence、confidence）

#### Step 2：影响汇聚

- 输入：Step 1 的变化点列表
- 处理：对每个变化点，从 change-element-mapping 读出受影响要素，按 impact_level 处理：
    - certain：直接加入 effective_sequence
    - likely：加入但标记可跳过，进入 Step 4 由用户决定
    - conditional：根据 condition 判断或暂停询问
- 输出：候选 effective_sequence

#### Step 3：always_affected 强制补全

- 强制将 original-requirement、requirement-type、glossary 加入 effective_sequence
- 它们在每次 incremental 都执行，与变化点识别结果无关

#### Step 4：dependency-graph 安全网校验

- 遍历 impact_edges，对 effective_sequence 中已有元素，扩展其 direct 影响要素
- 输出警告："以下要素通过依赖图被检测出可能影响：[...]，是否加入？"
- 用户确认后形成最终 effective_sequence

#### Step 5：要素循环执行 + 对话挖掘 + 影响点生成

- 按 effective_sequence 顺序，对每个 element 调 element-runner（mode=incremental）
- 每个 element 的 spec 在 incremental 分支：
    1. 读基线 FE 对应章节
    2. 读 context.impact_analysis 中本 element 相关的变化点
    3. 针对每个变化点对话挖掘细节（沿用 build 模式提问内核，聚焦变化部分）
    4. 生成 DELTA 标注的增量内容
- 同时累积 ImpactPoint 列表（modify + forbid）
