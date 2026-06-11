# 对接信息_ia-fe-to-prd

---

## 【0】SKILL.md 关键值

- `spec_compliance`: `v1.3.0`
- `engine/ENGINE-VERSION`: `2.1.1`

---

## 【A】config.yaml

```yaml
skill_name: "ia-fe-to-prd"
spec_compliance: "v1.3.0"

output_folder_base: "workspace/design"
input_folder_base: "workspace/requirements"
biz_knowledge_library: "docs/biz_kl"

input_doc_type: "FE"
output_doc_type: "PRD"

default_filename: "{output_doc_type}-{project_name}-{date}.md"
date_format: "YYYYMMDD"

engine:
  workflow_engine: "engine/workflow-engine.md"
  element_runner: "engine/element-runner.md"
  standards_loader: "engine/standards-loader.md"

registry:
  workflows: "registry/workflow-registry.yaml"
  element_types: "registry/element-type-registry.yaml"
  spec_templates: "registry/spec-template-registry.yaml"
  input_types: "registry/input-type-registry.yaml"
  standards: "registry/standards-registry.yaml"

# v1.2.0 扩展注册表（按需声明）
extension_registry:
  dependency_graph: "registry/dependency-graph.yaml"
  atomic_changes: "registry/atomic-change-registry.yaml"
  change_element_mapping: "registry/change-element-mapping.yaml"

# ── 上游Skill依赖（v1.2.0 第六章）──
upstream_dependencies:
  - skill_id: "ia-fe-generator"
    min_contract_version: "1.0.0"
    consumed_chapters:
      - source_chapter: "业务流程 → 活动明细"
        used_by_elements: ["app-architecture", "info-architecture", "feature-spec"]
      - source_chapter: "业务功能 → 功能清单"
        used_by_elements: ["app-architecture", "feature-spec"]
      - source_chapter: "用户交互 → 页面清单"
        used_by_elements: ["ui-prototype"]

standards:
  builtin_dir: "standards/"
  extend_index: "docs/extend-rule/INDEX.md"

# ── 可选Skill依赖（不可用时不阻断主流程，降级策略在Spec中定义）──
optional_skill_dependencies:
  - skill_id: "iscit-req2proto"
    purpose: "生成HTML可交互原型"
    required_for_elements: ["ui-prototype"]
    availability_check: "Skill调用前由element-runner Phase 4探测"

context:
  ongoing_file: "workspace/ongoing.md"
```

---

## 【B】registry/ 下所有 .yaml 文件

### registry/element-type-registry.yaml

```yaml
element_types:
  - id: "product-positioning"
    name: "定位与目标"
    chapter_no: 1
    chapter_no_cn: "一"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "1.1", name: "用户和干系人" }
      - { l2_no: "1.2", name: "痛点和价值" }
      - { l2_no: "1.3", name: "范围和边界" }
      - { l2_no: "1.4", name: "产品目标" }
    belongs_to: ["TP", "AP", "AI"]
    optional: false
    backend_only: false
    description: "用户和干系人、痛点和价值、范围和边界、产品目标。"

  - id: "app-architecture"
    name: "应用架构"
    chapter_no: 2
    chapter_no_cn: "二"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "2.1", name: "应用架构图" }
      - { l2_no: "2.2", name: "系统边界" }
      - { l2_no: "2.3", name: "特性分类/特性/子特性" }
    belongs_to: ["TP", "AP"]
    optional: false
    backend_only: false
    description: "应用架构图、系统边界、特性分类/特性/子特性。"

  - id: "ui-prototype"
    name: "界面原型"
    chapter_no: 3
    chapter_no_cn: "三"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "3.1", name: "页面清单" }
      - { l2_no: "3.2", name: "页面功能规格" }
      - { l2_no: "3.3", name: "菜单结构" }
      - { l2_no: "3.4", name: "Pageflow" }
      - { l2_no: "3.5", name: "兼容性要求" }
      - { l2_no: "3.6", name: "交互原型" }
    belongs_to: ["TP", "AP", "AI"]
    optional: false
    backend_only: false
    description: "页面清单、页面功能规格、菜单结构、Pageflow、兼容性要求、交互原型。"

  - id: "info-architecture"
    name: "信息架构"
    chapter_no: 4
    chapter_no_cn: "四"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "4.1", name: "业务对象/逻辑实体" }
      - { l2_no: "4.2", name: "实体关系图" }
      - { l2_no: "4.3", name: "实体详情" }
      - { l2_no: "4.4", name: "实体状态流转" }
      - { l2_no: "4.5", name: "数据样例" }
    belongs_to: ["TP", "AP"]
    optional: false
    backend_only: false
    description: "业务对象/逻辑实体、实体关系图、实体详情、实体状态流转、数据样例。"

  - id: "feature-spec"
    name: "功能特性"
    chapter_no: 5
    chapter_no_cn: "五"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "5.1", name: "子特性基本信息" }
      - { l2_no: "5.2", name: "特性分类" }
      - { l2_no: "5.3", name: "子特性详细规格" }
    belongs_to: ["TP", "AP", "AI"]
    optional: false
    backend_only: false
    description: "子特性基本信息、特性分类、子特性详细规格。"

  - id: "permission-design"
    name: "权限设计"
    chapter_no: 6
    chapter_no_cn: "六"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "6.1", name: "角色定义" }
      - { l2_no: "6.2", name: "功能权限矩阵" }
      - { l2_no: "6.3", name: "数据权限规则" }
    belongs_to: ["TP", "AP"]
    optional: false
    backend_only: false
    description: "角色定义、功能权限矩阵、数据权限规则。"

  - id: "integration-design"
    name: "集成设计"
    chapter_no: 7
    chapter_no_cn: "七"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "7.1", name: "集成点" }
      - { l2_no: "7.2", name: "API" }
      - { l2_no: "7.3", name: "MQS" }
      - { l2_no: "7.4", name: "数据集成" }
    belongs_to: ["TP", "AP", "AI"]
    optional: true
    backend_only: false
    description: "集成点、API、MQS、数据集成。"

  - id: "config-design"
    name: "配置设计"
    chapter_no: 8
    chapter_no_cn: "八"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "8.1", name: "用户配置项" }
      - { l2_no: "8.2", name: "IT管理配置项" }
    belongs_to: ["TP", "AP"]
    optional: true
    backend_only: false
    description: "用户配置项与 IT 管理配置项。"

  - id: "scenario-solution"
    name: "场景解决方案"
    chapter_no: 9
    chapter_no_cn: "九"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "9.1", name: "场景清单" }
      - { l2_no: "9.2", name: "解决方案集成图" }
      - { l2_no: "9.3", name: "场景详细描述" }
    belongs_to: ["TP", "AP", "AI"]
    optional: false
    backend_only: false
    description: "场景清单、解决方案集成图、场景详细描述。"

  - id: "nfr"
    name: "非功能需求"
    chapter_no: 10
    chapter_no_cn: "十"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "10.1", name: "性能要求" }
      - { l2_no: "10.2", name: "埋点要求" }
      - { l2_no: "10.3", name: "安全隐私" }
      - { l2_no: "10.4", name: "易用性" }
      - { l2_no: "10.5", name: "可维护性" }
    belongs_to: ["TP", "AP", "AI"]
    optional: false
    backend_only: false
    description: "性能要求、埋点要求、安全隐私、易用性、可维护性。"

  - id: "story-design"
    name: "Story 设计"
    chapter_no: 11
    chapter_no_cn: "十一"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "11.1", name: "Story 清单" }
    belongs_to: ["TP", "AP", "AI"]
    optional: false
    backend_only: false
    always_affected_in: ["modify", "incremental"]
    description: "Story 清单（详情在独立文件）。"
```

### registry/change-element-mapping.yaml

```yaml
# change-element-mapping.yaml
# v1.2.0 Layer 3.5 - 原子变化点到 PRD 要素的影响映射
#
# impact_level：
#   certain     - 一定影响，必须执行
#   likely      - 通常影响，默认执行（用户可跳过）
#   conditional - 条件影响，根据 condition 判断或交由用户决定

change_element_mappings:

  # ─── UI 类 ────────────────────────────────────────
  - change_id: "UI-01"
    affects:
      - element_id: "ui-prototype"
        impact_level: "certain"
        reason: "新增按钮直接影响页面规格"
      - element_id: "feature-spec"
        impact_level: "certain"
        reason: "新增按钮对应新增子特性或子特性扩展"
      - element_id: "permission-design"
        impact_level: "likely"
        reason: "新按钮通常需要权限控制"
      - element_id: "scenario-solution"
        impact_level: "likely"
        reason: "新按钮对应的操作可能形成新场景"

  - change_id: "UI-02"
    affects:
      - element_id: "ui-prototype"
        impact_level: "certain"
        reason: "新增页面直接影响页面清单和流转图"
      - element_id: "app-architecture"
        impact_level: "certain"
        reason: "新页面对应新子特性，影响架构"
      - element_id: "feature-spec"
        impact_level: "certain"
        reason: "新页面需要新子特性详细规格"
      - element_id: "permission-design"
        impact_level: "certain"
        reason: "新页面需要权限分配"
      - element_id: "scenario-solution"
        impact_level: "likely"
        reason: "新页面可能引入新场景"

  - change_id: "UI-03"
    affects:
      - element_id: "ui-prototype"
        impact_level: "certain"
        reason: "字段增减影响页面规格"
      - element_id: "info-architecture"
        impact_level: "certain"
        reason: "字段增减通常对应实体属性增减"
      - element_id: "feature-spec"
        impact_level: "likely"
        reason: "可能影响子特性的字段说明"

  - change_id: "UI-04"
    affects:
      - element_id: "ui-prototype"
        impact_level: "certain"
        reason: "布局调整直接影响页面规格"

  - change_id: "UI-05"
    affects:
      - element_id: "ui-prototype"
        impact_level: "certain"
        reason: "流转关系调整影响 Pageflow"
      - element_id: "scenario-solution"
        impact_level: "likely"
        reason: "页面流转影响场景串联"

  # ─── DA 类 ────────────────────────────────────────
  - change_id: "DA-01"
    affects:
      - element_id: "info-architecture"
        impact_level: "certain"
        reason: "新增实体直接影响实体清单和 ER 图"
      - element_id: "feature-spec"
        impact_level: "certain"
        reason: "新实体需要 CRUD 子特性"
      - element_id: "scenario-solution"
        impact_level: "likely"
        reason: "新实体可能引入新场景"

  - change_id: "DA-02"
    affects:
      - element_id: "info-architecture"
        impact_level: "certain"
        reason: "字段新增影响实体详情表"
      - element_id: "ui-prototype"
        impact_level: "likely"
        reason: "新字段通常对应页面显示"
      - element_id: "feature-spec"
        impact_level: "likely"
        reason: "新字段可能影响验收标准"

  - change_id: "DA-03"
    affects:
      - element_id: "info-architecture"
        impact_level: "certain"
        reason: "字段修改/删除影响实体详情"
      - element_id: "ui-prototype"
        impact_level: "likely"
      - element_id: "feature-spec"
        impact_level: "likely"
      - element_id: "integration-design"
        impact_level: "conditional"
        condition: "若该字段曾用于外部接口参数映射"
        reason: "可能需要更新接口字段"

  - change_id: "DA-04"
    affects:
      - element_id: "info-architecture"
        impact_level: "certain"
        reason: "关系变更直接影响 ER 图和实体详情外键标注"
      - element_id: "feature-spec"
        impact_level: "likely"
      - element_id: "permission-design"
        impact_level: "conditional"
        condition: "若涉及数据权限范围"

  - change_id: "DA-05"
    affects:
      - element_id: "info-architecture"
        impact_level: "certain"
        reason: "状态变更影响状态流转图"
      - element_id: "feature-spec"
        impact_level: "certain"
        reason: "新状态通常需要新功能或现有功能扩展"
      - element_id: "ui-prototype"
        impact_level: "likely"

  # ─── LG 类 ────────────────────────────────────────
  - change_id: "LG-01"
    affects:
      - element_id: "feature-spec"
        impact_level: "certain"
        reason: "新业务规则直接写入子特性的业务规则列表"
      - element_id: "scenario-solution"
        impact_level: "likely"

  - change_id: "LG-02"
    affects:
      - element_id: "feature-spec"
        impact_level: "certain"
      - element_id: "config-design"
        impact_level: "conditional"
        condition: "若调整阈值是可配置项"

  - change_id: "LG-03"
    affects:
      - element_id: "feature-spec"
        impact_level: "certain"
      - element_id: "info-architecture"
        impact_level: "conditional"
        condition: "若新计算逻辑需要新字段"

  - change_id: "LG-04"
    affects:
      - element_id: "permission-design"
        impact_level: "certain"
      - element_id: "feature-spec"
        impact_level: "likely"
      - element_id: "scenario-solution"
        impact_level: "likely"

  # ─── PR 类 ────────────────────────────────────────
  - change_id: "PR-01"
    affects:
      - element_id: "feature-spec"
        impact_level: "certain"
        reason: "新流程节点对应新子特性"
      - element_id: "scenario-solution"
        impact_level: "certain"
        reason: "流程节点新增直接影响场景串联"
      - element_id: "permission-design"
        impact_level: "likely"
      - element_id: "ui-prototype"
        impact_level: "likely"

  - change_id: "PR-02"
    affects:
      - element_id: "feature-spec"
        impact_level: "certain"
      - element_id: "scenario-solution"
        impact_level: "certain"
      - element_id: "ui-prototype"
        impact_level: "likely"

  - change_id: "PR-03"
    affects:
      - element_id: "scenario-solution"
        impact_level: "certain"
      - element_id: "feature-spec"
        impact_level: "likely"

  - change_id: "PR-04"
    affects:
      - element_id: "feature-spec"
        impact_level: "certain"
        reason: "异常分支增加新的验收标准"
      - element_id: "scenario-solution"
        impact_level: "certain"

  - change_id: "PR-05"
    affects:
      - element_id: "permission-design"
        impact_level: "certain"
      - element_id: "feature-spec"
        impact_level: "likely"
      - element_id: "scenario-solution"
        impact_level: "likely"

  # ─── IN 类 ────────────────────────────────────────
  - change_id: "IN-01"
    affects:
      - element_id: "integration-design"
        impact_level: "certain"
      - element_id: "app-architecture"
        impact_level: "certain"
        reason: "新增外部依赖影响系统边界表"
      - element_id: "feature-spec"
        impact_level: "likely"
        reason: "可能引入新的集成型子特性"
      - element_id: "scenario-solution"
        impact_level: "likely"

  - change_id: "IN-02"
    affects:
      - element_id: "integration-design"
        impact_level: "certain"

  - change_id: "IN-03"
    affects:
      - element_id: "integration-design"
        impact_level: "certain"

  - change_id: "IN-04"
    affects:
      - element_id: "integration-design"
        impact_level: "certain"
      - element_id: "nfr"
        impact_level: "likely"
        reason: "降级策略可能涉及可用性指标"

  # ─── NF 类 ────────────────────────────────────────
  - change_id: "NF-01"
    affects:
      - element_id: "nfr"
        impact_level: "certain"
      - element_id: "app-architecture"
        impact_level: "conditional"
        condition: "若性能要求变化导致架构方案调整（如增加缓存层）"

  - change_id: "NF-02"
    affects:
      - element_id: "nfr"
        impact_level: "certain"
      - element_id: "info-architecture"
        impact_level: "likely"
        reason: "脱敏规则可能新增字段标注"
      - element_id: "permission-design"
        impact_level: "likely"

  - change_id: "NF-03"
    affects:
      - element_id: "nfr"
        impact_level: "certain"
      - element_id: "integration-design"
        impact_level: "conditional"
        condition: "若 SLA 变更影响外部依赖处理策略"
```

### registry/atomic-change-registry.yaml

```yaml
# atomic-change-registry.yaml
# v1.2.0 Layer 3.5 变化点路由层 - 原子变化点目录
# 由 orchestration/o-incremental-build.md 在变化点识别阶段读取
#
# 业务域分类（6 类）：
# UI - User Interface 用户界面
# DA - Data 数据
# LG - Logic 业务逻辑
# PR - Process 流程
# IN - Integration 集成
# NF - Non-Functional 非功能

atomic_changes:

  # ─── UI 类（用户界面变更）────────────────────────────
  - id: "UI-01"
    name: "新增按钮/操作入口"
    category: "UI"
    description_zh: "用户描述：在某个页面增加一个按钮或操作入口（如导出按钮、批量操作）"
    detection_keywords: ["增加按钮", "新增按钮", "加一个按钮", "添加操作", "新增入口", "增加导出", "批量操作"]
    examples:
      - "在订单列表页加一个'批量导出'按钮"
      - "审批列表页增加'转交'操作"
    status: "active"

  - id: "UI-02"
    name: "新增页面"
    category: "UI"
    description_zh: "用户描述：增加一个全新的页面（如详情页、统计页）"
    detection_keywords: ["新增页面", "加一个页面", "新页面", "增加页面"]
    examples:
      - "增加订单详情页"
      - "新增数据统计页"
    status: "active"

  - id: "UI-03"
    name: "页面字段增减"
    category: "UI"
    description_zh: "用户描述：在某个页面增加或减少表单字段、显示字段"
    detection_keywords: ["增加字段", "新增字段", "去掉字段", "页面增加", "表单加", "字段调整"]
    examples:
      - "申请表单增加'优先级'字段"
      - "订单列表去掉'备注'列"
    status: "active"

  - id: "UI-04"
    name: "页面布局/样式调整"
    category: "UI"
    description_zh: "用户描述：调整页面布局、样式、交互方式"
    detection_keywords: ["布局调整", "样式调整", "改版", "界面优化"]
    examples:
      - "把申请表单改为分步骤填写"
    status: "active"

  - id: "UI-05"
    name: "页面流转关系变更"
    category: "UI"
    description_zh: "用户描述：调整页面之间的跳转关系"
    detection_keywords: ["页面跳转", "流转调整", "跳转关系"]
    examples:
      - "提交后直接跳到详情页，不再回到列表页"
    status: "active"

  # ─── DA 类（数据变更）─────────────────────────────────
  - id: "DA-01"
    name: "新增实体"
    category: "DA"
    description_zh: "用户描述：增加一个全新的业务对象（如新增'供应商'实体）"
    detection_keywords: ["新增实体", "增加实体", "新增对象", "新业务对象"]
    examples:
      - "增加供应商实体"
      - "新增审批记录实体"
    status: "active"

  - id: "DA-02"
    name: "实体字段新增"
    category: "DA"
    description_zh: "用户描述：在已有实体上增加属性字段"
    detection_keywords: ["增加字段", "新增字段", "实体加", "属性增加"]
    examples:
      - "订单实体增加'紧急程度'字段"
    status: "active"

  - id: "DA-03"
    name: "实体字段修改/删除"
    category: "DA"
    description_zh: "用户描述：修改字段类型、改名或删除字段"
    detection_keywords: ["字段改", "改字段类型", "删除字段", "去掉字段"]
    examples:
      - "把'金额'字段类型从 Integer 改为 Decimal"
    status: "active"

  - id: "DA-04"
    name: "实体关系变更"
    category: "DA"
    description_zh: "用户描述：调整实体间的关联关系（一对多变多对多等）"
    detection_keywords: ["关系调整", "关联变化", "多对多", "一对多"]
    examples:
      - "用户和角色从一对多改为多对多"
    status: "active"

  - id: "DA-05"
    name: "实体状态流转变更"
    category: "DA"
    description_zh: "用户描述：调整实体的状态机（增加状态、改变流转条件）"
    detection_keywords: ["状态流转", "新增状态", "状态变化", "状态机"]
    examples:
      - "订单增加'待发货'状态"
    status: "active"

  # ─── LG 类（业务逻辑变更）─────────────────────────────
  - id: "LG-01"
    name: "业务规则新增"
    category: "LG"
    description_zh: "用户描述：增加新的业务规则（如准入规则、计算规则、校验规则）"
    detection_keywords: ["新增规则", "增加规则", "新规则", "规则补充"]
    examples:
      - "增加'金额>10万必须二级审批'的规则"
    status: "active"

  - id: "LG-02"
    name: "业务规则修改"
    category: "LG"
    description_zh: "用户描述：调整已有业务规则的阈值或条件"
    detection_keywords: ["改规则", "规则调整", "阈值调整"]
    examples:
      - "把审批阈值从 5 万改为 10 万"
    status: "active"

  - id: "LG-03"
    name: "计算逻辑变更"
    category: "LG"
    description_zh: "用户描述：调整金额、数量、日期等计算公式"
    detection_keywords: ["计算逻辑", "公式调整", "算法变化"]
    examples:
      - "折扣计算改为按累计金额阶梯"
    status: "active"

  - id: "LG-04"
    name: "权限规则变更"
    category: "LG"
    description_zh: "用户描述：调整角色对功能的访问权限"
    detection_keywords: ["权限调整", "角色权限", "访问权限", "权限变化"]
    examples:
      - "增加'部门主管'可以查看全部数据的权限"
    status: "active"

  # ─── PR 类（流程变更）────────────────────────────────
  - id: "PR-01"
    name: "新增流程节点"
    category: "PR"
    description_zh: "用户描述：在业务流程中增加一个新环节（如增加预审）"
    detection_keywords: ["新增环节", "增加节点", "增加步骤", "增加预审"]
    examples:
      - "审批前增加'部门预审'环节"
    status: "active"

  - id: "PR-02"
    name: "流程节点删除/合并"
    category: "PR"
    description_zh: "用户描述：去掉或合并某个流程环节"
    detection_keywords: ["去掉环节", "合并步骤", "简化流程"]
    examples:
      - "去掉'部门预审'环节，直接走总监审批"
    status: "active"

  - id: "PR-03"
    name: "流程顺序调整"
    category: "PR"
    description_zh: "用户描述：调整流程节点的执行顺序"
    detection_keywords: ["顺序调整", "流程顺序", "节点顺序"]
    examples:
      - "把'付款'放到'发货'之前"
    status: "active"

  - id: "PR-04"
    name: "异常分支新增"
    category: "PR"
    description_zh: "用户描述：增加异常处理分支（如驳回、撤回、超时处理）"
    detection_keywords: ["异常处理", "驳回", "撤回", "超时", "退回"]
    examples:
      - "增加审批超时 24 小时自动转交的逻辑"
    status: "active"

  - id: "PR-05"
    name: "角色变更/职责调整"
    category: "PR"
    description_zh: "用户描述：调整流程中执行某节点的角色"
    detection_keywords: ["换角色", "改角色", "职责调整", "角色变化"]
    examples:
      - "审批人从'部门主管'改为'项目经理'"
    status: "active"

  # ─── IN 类（集成变更）────────────────────────────────
  - id: "IN-01"
    name: "新增外部系统集成"
    category: "IN"
    description_zh: "用户描述：增加与新的外部系统对接"
    detection_keywords: ["新增集成", "对接", "集成新系统", "新增接口"]
    examples:
      - "增加与 SAP 的对接，同步订单数据"
    status: "active"

  - id: "IN-02"
    name: "集成方式调整"
    category: "IN"
    description_zh: "用户描述：调整集成方式（API 改为 MQS 等）"
    detection_keywords: ["集成方式", "改为接口", "改为消息队列", "改异步"]
    examples:
      - "实时 API 调用改为消息队列异步"
    status: "active"

  - id: "IN-03"
    name: "接口字段/参数变更"
    category: "IN"
    description_zh: "用户描述：调整外部接口的入参出参"
    detection_keywords: ["接口字段", "参数调整", "接口字段变化"]
    examples:
      - "订单接口增加'渠道'入参"
    status: "active"

  - id: "IN-04"
    name: "集成异常处理变更"
    category: "IN"
    description_zh: "用户描述：调整外部系统不可用时的降级、重试策略"
    detection_keywords: ["重试", "降级", "异常处理", "失败处理"]
    examples:
      - "外部系统失败由阻断改为降级处理"
    status: "active"

  # ─── NF 类（非功能变更）──────────────────────────────
  - id: "NF-01"
    name: "性能要求变更"
    category: "NF"
    description_zh: "用户描述：调整响应时间、并发、吞吐量等性能指标"
    detection_keywords: ["性能", "响应时间", "并发", "吞吐量"]
    examples:
      - "响应时间从 3 秒收紧到 1 秒"
    status: "active"

  - id: "NF-02"
    name: "安全/合规要求变更"
    category: "NF"
    description_zh: "用户描述：调整加密、脱敏、合规要求"
    detection_keywords: ["安全", "加密", "脱敏", "合规", "GDPR"]
    examples:
      - "增加 GDPR 合规要求"
    status: "active"

  - id: "NF-03"
    name: "可用性/可靠性要求变更"
    category: "NF"
    description_zh: "用户描述：调整 SLA、RTO、RPO"
    detection_keywords: ["可用性", "SLA", "RTO", "RPO", "宕机"]
    examples:
      - "可用性从 99.9% 提升到 99.99%"
    status: "active"
```

### registry/dependency-graph.yaml

```yaml
# dependency-graph.yaml
# 用途：定义要素之间的级联影响关系
# 在 v1.2.0 中作为：
#   1. modify 模式的影响范围分析依据
#   2. incremental 模式变化点路由的"安全网"（详见规范 3.5.3 节 Step 4）
#
# ⚠️ v1.2.0 变更说明：
# - 旧版的 incremental_impact_rules（A-F 工程抽象）已删除
# - 增量变化点的核心路由逻辑迁移到 atomic-change-registry + change-element-mapping
# - 本文件仅保留 impact_edges，作为级联影响校验

impact_edges:
  - source: "product-positioning"
    targets:
      - element: "app-architecture"
        impact_type: "direct"
        reason: "产品目标与范围变更会直接影响模块边界和特性划分。"
      - element: "nfr"
        impact_type: "indirect"
        reason: "成功标准变化可能影响性能、可用性等目标。"

  - source: "app-architecture"
    targets:
      - element: "info-architecture"
        impact_type: "direct"
        reason: "特性边界变化会影响实体归属。"
      - element: "feature-spec"
        impact_type: "direct"
        reason: "子特性编号体系来源于应用架构。"
      - element: "permission-design"
        impact_type: "direct"
        reason: "权限矩阵基于子特性清单。"
      - element: "integration-design"
        impact_type: "direct"
        reason: "系统依赖表是集成设计的输入。"
      - element: "scenario-solution"
        impact_type: "indirect"
        reason: "子特性分布变化会影响场景串联。"

  - source: "info-architecture"
    targets:
      - element: "feature-spec"
        impact_type: "direct"
        reason: "实体操作说明依赖实体定义。"
      - element: "scenario-solution"
        impact_type: "direct"
        reason: "场景表中的操作实体来自信息架构。"
      - element: "integration-design"
        impact_type: "indirect"
        reason: "字段调整可能影响接口参数映射。"

  - source: "feature-spec"
    targets:
      - element: "permission-design"
        impact_type: "direct"
        reason: "权限矩阵需要与子特性同步。"
      - element: "scenario-solution"
        impact_type: "direct"
        reason: "场景串联依赖子特性清单。"
      - element: "story-design"
        impact_type: "direct"
        reason: "Story 直接从功能特性与验收标准拆分。"

  - source: "permission-design"
    targets:
      - element: "scenario-solution"
        impact_type: "indirect"
        reason: "角色权限变更会影响场景中的执行角色边界。"

  - source: "integration-design"
    targets:
      - element: "scenario-solution"
        impact_type: "indirect"
        reason: "外部系统调用步骤会影响场景链路。"

  - source: "nfr"
    targets:
      - element: "story-design"
        impact_type: "direct"
        reason: "非功能特性是 NFR Story 的直接来源。"
```

### registry/workflow-registry.yaml

```yaml
workflows:
  - id: "prd-resume"
    name: "续接恢复"
    priority: 100
    input_signature:
      required:
        - id: "PRD_DOC_INPROGRESS"
          reason: "存在进行中的 PRD 文档。"
      excluded: []
      optional:
        - id: "FE_DOC_ANY"
          reason: "可选加载 FE 上下文辅助续写。"
    trigger_keywords: ["继续", "resume", "从上次继续", "接着做"]
    orchestration_file: "orchestration/o-init-build.md"
    resume_mode: true
    element_sequence: []
    status: "active"

  - id: "review-modify"
    name: "PRD 评审修改"
    priority: 80
    input_signature:
      required:
        - id: "PRD_HISTORICAL"
          reason: "必须有目标 PRD 文档（已完成状态的历史 PRD，供本次修改）。"
        - id: "REVIEW_COMMENTS"
          reason: "必须有评审意见（文字描述或带标注文档均可，o-review-modify 内部区分）。"
      excluded:
        - id: "PRD_DOC_INPROGRESS"
          reason: "存在进行中 PRD 时优先走续接恢复。"
      optional:
        - id: "FE_DOC_ANY"
          reason: "可选提供 FE 作为修改时的上游上下文。"
    trigger_keywords: ["评审修改", "根据评审意见", "修改PRD", "按意见改", "有评审标注"]
    orchestration_file: "orchestration/o-review-modify.md"
    element_sequence: []
    status: "planned"  # 骨架版本,待实现

  - id: "tp-incremental-build"
    name: "TP 增量 PRD 设计"
    priority: 60
    input_signature:
      required:
        - id: "PRD_HISTORICAL"
          reason: "必须有历史 PRD 作为增量基线。"
      excluded:
        - id: "PRD_DOC_INPROGRESS"
          reason: "存在进行中 PRD 时优先走续接恢复。"
        - id: "REVIEW_COMMENTS"
          reason: "存在评审意见时属于 review-modify 场景。"
      optional:
        - id: "FE_DOC_COMPLETED"
          reason: "可选:新版本 FE 文档存在时作为业务事实证据;缺位时由对话挖掘兜底(V3.0 §1.2 问题五:FE 缺位)。"
        - id: "FE_DOC_ANY"
          reason: "可选:任意状态 FE 也可作为参考上下文。"
    trigger_keywords: ["增量设计", "优化需求", "1-n", "在现有PRD基础上", "增量PRD"]
    orchestration_file: "orchestration/o-tp-incremental.md"
    element_sequence: []
    requirement_type: "TP"
    requirement_nature: "优化需求"
    status: "active"

  - id: "tp-new-build"
    name: "TP 专题需求 PRD 设计"
    priority: 40
    input_signature:
      required:
        - id: "FE_DOC_COMPLETED"
          reason: "必须有已完成的 FE 文档。"
      excluded:
        - id: "PRD_HISTORICAL"
          reason: "存在历史 PRD 时优先走增量设计。"
        - id: "PRD_DOC_INPROGRESS"
          reason: "存在进行中 PRD 时优先走续接恢复。"
        - id: "REVIEW_COMMENTS"
          reason: "存在评审意见时属于 review-modify 场景。"
      optional: []
    trigger_keywords: ["创建PRD", "生成PRD", "产品方案设计", "需求转PRD", "新建PRD"]
    requirement_type: "TP"
    requirement_nature: "专题需求"
    orchestration_file: "orchestration/o-init-build.md"
    # element_sequence 已删除 - 改为由 orchestration 根据 element-type-registry 动态计算
    status: "active"

  - id: "ap-new-build"
    name: "AP 专题需求 PRD 设计"
    priority: 40
    input_signature:
      required:
        - id: "FE_DOC_COMPLETED"
          reason: "必须有已完成的 FE 文档。"
      excluded:
        - id: "PRD_HISTORICAL"
          reason: "存在历史 PRD 时优先走增量设计。"
        - id: "PRD_DOC_INPROGRESS"
          reason: "存在进行中 PRD 时优先走续接恢复。"
        - id: "REVIEW_COMMENTS"
          reason: "存在评审意见时属于 review-modify 场景。"
      optional: []
    trigger_keywords: ["创建PRD", "生成PRD", "产品方案设计", "需求转PRD", "新建PRD"]
    requirement_type: "AP"
    requirement_nature: "专题需求"
    orchestration_file: "orchestration/o-init-build.md"
    # element_sequence 已删除 - 改为由 orchestration 根据 element-type-registry 动态计算
    status: "planned"
```

### registry/spec-template-registry.yaml

```yaml
spec_templates:
  - id: "m-prd-ppo"
    spec_file: "spec/m-prd-ppo.md"
    implements: "product-positioning"
    for_scenario: ["专题需求"]
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    status: "active"

  - id: "m-prd-tp-app"
    spec_file: "spec/m-prd-tp-app.md"
    implements: "app-architecture"
    for_scenario: ["专题需求"]
    for_type: ["TP"]
    execution_mode: ["build", "modify", "incremental"]
    status: "active"

  - id: "m-prd-prototype"
    spec_file: "spec/m-prd-prototype.md"
    implements: "ui-prototype"
    for_scenario: ["专题需求"]
    for_type: ["TP", "AP"]
    execution_mode: ["build", "modify", "incremental"]
    status: "active"

  - id: "m-prd-tp-info"
    spec_file: "spec/m-prd-tp-info.md"
    implements: "info-architecture"
    for_scenario: ["专题需求"]
    for_type: ["TP"]
    execution_mode: ["build", "modify", "incremental"]
    status: "active"

  - id: "m-prd-tp-feature"
    spec_file: "spec/m-prd-tp-feature.md"
    implements: "feature-spec"
    for_scenario: ["专题需求"]
    for_type: ["TP"]
    execution_mode: ["build", "modify", "incremental"]
    status: "active"

  - id: "m-prd-tp-permission"
    spec_file: "spec/m-prd-tp-permission.md"
    implements: "permission-design"
    for_scenario: ["专题需求"]
    for_type: ["TP"]
    execution_mode: ["build", "modify", "incremental"]
    status: "active"

  - id: "m-prd-integration"
    spec_file: "spec/m-prd-integration.md"
    implements: "integration-design"
    for_scenario: ["专题需求"]
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    status: "active"

  - id: "m-prd-config"
    spec_file: "spec/m-prd-config.md"
    implements: "config-design"
    for_scenario: ["专题需求"]
    for_type: ["TP", "AP"]
    execution_mode: ["build", "modify", "incremental"]
    status: "active"

  - id: "m-prd-tp-scenario"
    spec_file: "spec/m-prd-tp-scenario.md"
    implements: "scenario-solution"
    for_scenario: ["专题需求"]
    for_type: ["TP"]
    execution_mode: ["build", "modify", "incremental"]
    status: "active"

  - id: "m-prd-nfr"
    spec_file: "spec/m-prd-nfr.md"
    implements: "nfr"
    for_scenario: ["专题需求"]
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    status: "active"

  - id: "m-prd-story"
    spec_file: "spec/m-prd-story.md"
    implements: "story-design"
    for_scenario: ["专题需求", "优化需求"]
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    status: "active"

  - id: "m-prd-ap-info"
    spec_file: "spec/m-prd-ap-info.md"
    implements: "info-architecture"
    for_scenario: ["专题需求"]
    for_type: ["AP"]
    execution_mode: ["build"]
    status: "planned"

  - id: "m-prd-ai-feature"
    spec_file: "spec/m-prd-ai-feature.md"
    implements: "feature-spec"
    for_scenario: ["专题需求"]
    for_type: ["AI"]
    execution_mode: ["build"]
    status: "planned"
```

### registry/input-type-registry.yaml

```yaml
input_types:

  - id: "FE_DOC_COMPLETED"
    name: "已完成的 FE 文档"
    description: "PRD 新建和增量设计的核心输入。完成态 FE 是进入 init_build 或 incremental_build 的必要条件。"
    detect_rules:
      - type: "frontmatter_field"
        path: "workspace/requirements/{current_version}/FE-*.md"
        condition: "status == 'completed'"
    provision_guide: "请先完成 FE 文档，或明确提供完成态 FE 文档路径。"

  - id: "FE_DOC_ANY"
    name: "FE 文档（任意状态）"
    description: "评审修改场景下可选加载的 FE 上下文。status != completed 时匹配此项。"
    detect_rules:
      - type: "file_exists"
        path: "workspace/requirements/{current_version}/FE-*.md"
        condition: "any_status"
    provision_guide: "当前版本的 FE 文档尚未完成，只能提供有限上下文参考。"

  - id: "PRD_DOC_INPROGRESS"
    name: "进行中的 PRD 文档"
    description: "续接恢复场景（intent=resume）的关键判据，也是 init_build 场景最高优先级条件。"
    detect_rules:
      - type: "frontmatter_field"
        path: "workspace/design/{current_version}/PRD-*.md"
        condition: "status == 'in_progress'"
    provision_guide: "系统检测到未完成的 PRD 文档，可续接上次进度继续执行。"

  - id: "PRD_HISTORICAL"
    name: "历史已完成 PRD"
    description: "增量设计场景的基线 PRD 输入，评审修改场景的目标 PRD。"
    detect_rules:
      - type: "frontmatter_field"
        path: "workspace/design/*/PRD-*.md"
        condition: "status == 'completed' AND project_name == ongoing.project_name"
    provision_guide: "提供历史 PRD 路径，或说明要基于哪个历史版本做增量设计或评审修改。"

  - id: "REVIEW_COMMENTS"
    name: "评审意见"
    description: "评审修改场景的必要输入。文字意见或带标注文档均可。"
    detect_rules:
      - type: "dialog_input"
        path: "user_message"
        condition: "matches_keywords=[补充,增加,修改,调整,删除,根据评审意见,按以下意见修改] OR matches_chapter_pattern"
      - type: "annotation_marker"
        path: "user_provided_doc"
        condition: "contains_pattern==文本==[^n]"
    provision_guide: |
      评审意见提供方式：
      1. 文字描述：直接在对话中描述修改意见
      2. 标注文档：提供带 ==高亮==[^n] 脚注标注格式的评审文档
```

### registry/standards-registry.yaml

```yaml
# standards-registry.yaml
# 职责：内嵌规范和扩展规范的统一索引，只声明"有什么规范"，内容在各 standards/*.md 文件中。
# 设计约定：
#   - 只登记实际存在的规范文件（与 standards/ 目录文件保持一致）
#   - applicable_elements 不在此声明；由 spec/m-*.md 的 body "## 约束 → ### 格式规范" 表格引用
#   - 规范文件缺失时 standards-loader 应提示警告，不阻断流程
#   - 扩展规范（来自 workspace/extend-rule/INDEX.md）由 standards-loader 运行时动态追加，不在此列

standards:

  # ─── 当前已落地的内嵌规范 ────────────────────────────────────────────
  # 其余规范按需创建（standards/ 目录下补充文件后，同步在此追加对应记录）

  - id: "app-arch"
    name: "应用架构图规范"
    type: "builtin"
    file: "standards/app-arch-standard.md"
    description: "架构图 Mermaid graph TB 语法规范，四层结构（应用系统模块-特性分类-特性-子特性），节点命名规则。"

  - id: "er-diagram"
    name: "ER 图规范"
    type: "builtin"
    file: "standards/er-diagram-standard.md"
    description: "erDiagram 语法规范，关联关系符号规范，实体命名规则，主外键标注要求。"

  # ─── 待创建的规范（status=planned，文件不存在时暂不加载）──────────────
  # 以下规范留作扩展，实际创建文件后将 planned 条目移到上方 builtin 区

  # - id: "entity-detail"
  #   name: "实体详情规范"
  #   type: "builtin"
  #   file: "standards/entity-detail-standard.md"
  #   status: "planned"

  # - id: "feature-spec"
  #   name: "功能特性规范"
  #   type: "builtin"
  #   file: "standards/feature-spec-standard.md"
  #   status: "planned"

  # - id: "permission"
  #   name: "权限设计规范"
  #   type: "builtin"
  #   file: "standards/permission-standard.md"
  #   status: "planned"
```

---

## 【C】orchestration/

### 文件列表

- o-init-build.md
- o-review-modify.md
- o-tp-incremental.md

### build 类（仅列名，不贴正文）

- o-init-build.md
- o-review-modify.md

### 增量类（含 incremental）：o-tp-incremental.md

```markdown
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
```

---

## 【D】spec/

### m-*.md 文件名列表

- _template.md
- m-prd-config.md
- m-prd-integration.md
- m-prd-nfr.md
- m-prd-ppo.md
- m-prd-prototype.md
- m-prd-story.md
- m-prd-tp-app.md
- m-prd-tp-feature.md
- m-prd-tp-info.md
- m-prd-tp-permission.md
- m-prd-tp-scenario.md

### 容器型要素：spec/m-prd-tp-feature.md（implements: feature-spec）— 截取"前置条件"和"输出骨架"

#### ## 前置条件

```markdown
## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|----------------------|------|
| `app-architecture` | FR 编号和子特性清单来自应用架构章节，本章节只引用 |
| `info-architecture` | 实体操作说明依赖实体清单（引用实体名称和属性） |

**必要输入**

- PRD要素: `PRD应用架构-子特性清单`（FR编号体系、子特性描述）
- FE要素链:
  - `FE需求类型-TP类(活动明细表格-操作内容字段)`
  - `FE需求类型-TP类(活动明细表格-业务规则字段)`
  - `FE需求类型-TP类(活动明细表格-输出结果字段)`
  - `FE业务流程-业务活动`（活动明细的操作内容、业务规则、输出结果）
  - `FE业务流程-输出`（输出结果，推导实体操作类型）
  - `FE业务流程-业务规则`（业务规则编号）
```

#### ## 输出骨架

```markdown
## 输出骨架

```markdown
## 五、功能特性

### 5.1 子特性基本信息

| 功能编号 | 功能名称 | 功能说明 |
|----------|----------|----------|

> 说明：直接引用应用架构章节的子特性清单，功能编号格式 FR-{特性分类}-{特性}-{序号}

### 5.2 特性分类

| 特性分类编号 | 特性分类名称 | 所属特性清单 | 子特性编号范围 |
|-------------|------------|------------|--------------|

### 5.3 子特性详细规格

> ⚠️ 以下每个子特性均包含5个必填规格项，不得遗漏任何一个。

#### FR-01-01-001 [子特性名称]

**UIUX操作说明**（≥3步，用户视角）

1. 用户 ...
2. 系统 ...
3. 用户 ...

**实体操作说明**

| 实体名称 | 操作类型（INSERT/UPDATE/SELECT/DELETE） |
|----------|--------------------------------------|

**集成点说明**（无集成请写"无外部集成"）

| 外部系统 | 调用场景 |
|----------|---------|

**业务规则**（引用FE业务规则编号）

| 规则编号 | 规则类型 | 规则描述 |
|----------|----------|---------|

**验收标准**（≥1条）

- AC1: Given [...] / When [...] / Then [...]
- AC2: Given [...] / When [...] / Then [...]

---

#### FR-01-01-002 [子特性名称]

[同上结构，为每个子特性生成完整规格]

---

[... 为所有N个子特性依次生成规格，直到全部完成 ...]
```
```

### 叶子型要素：spec/m-prd-tp-info.md（implements: info-architecture）— 截取"前置条件"和"输出骨架"

#### ## 前置条件

```markdown
## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|----------------------|------|
| `app-architecture` | 实体归属（属于哪个特性分类/特性）和场景边界依赖应用架构 |

**必要输入**

- FE要素链:
  - `FE需求类型-TP类(活动明细表格-输入信息/输出结果字段)`（核心，推导实体属性）
  - `FE业务流程-业务活动`（活动明细的输入/输出对象）
  - `FE业务流程-输入`（输入信息字段）
  - `FE业务流程-输出`（输出结果字段）
  - `FE业务流程-业务规则`（业务规则字段）
  - `FE非功能要求-信息安全`（可选，涉及敏感数据时）
  - `FE非功能要求-个人隐私保护`（可选，涉及隐私数据时）
  - `FE用户交互-页面低保真`（可选，用于属性可见性推导）
```

#### ## 输出骨架

```markdown
## 输出骨架

```markdown
## 四、信息架构

### 4.1 业务对象/逻辑实体

| 实体编号 | 实体名称 | 实体说明 | 对应业务对象 | 主键 |
|----------|----------|----------|-------------|------|

### 4.1.1 实体遗漏检查结论

**检查项** | **检查结果** | **补充实体清单**
中间状态对象 | [有/无] | [如有，列出补充实体名称]
配置对象 | [有/无] | [如有，列出补充实体名称]
外部系统映射对象 | [有/无] | [如有，列出补充实体名称]
角色专属对象 | [有/无] | [如有，列出补充实体名称]

> 说明：记录Step 2四类遗漏检查的结论，补充的实体需追加到4.1逻辑实体清单表格

### 4.2 实体关系图

```erDiagram
  ENTITY_A ||--o{ ENTITY_B : "关系描述"
  ...

### 4.3 实体详情

> ⚠️ 每个实体属性表格严格9列，列名和顺序固定如下：

#### [实体名称]（E001）

| 属性编号 | 属性名称 | 属性类型 | 是否主键 | 是否外键 | 是否必填 | 默认值 | 业务规则 | 示例值 |
|---------|---------|---------|---------|---------|---------|-------|---------|-------|
| A001    | [字段名] | String  | 是      | 否      | 是      | —     | [规则]   | [真实值] |
| A002    | [字段名] | Integer | 否      | 是(→E002) | 是  | —     | —       | [真实值] |

### 4.4 实体状态流转

```stateDiagram-v2
  [*] --> DRAFT
  DRAFT --> SUBMITTED
  ...

### 4.5 数据样例

```json
{
  "entity_id": "真实业务值",
  ...
}
```
```
```

---

## 【E】样例输出文档

选取最完整文档：`workspace/design/I20260423/PRD-资源标签管理和资源调度系统-20260512.md`

### (1) Frontmatter（YAML 块）

```yaml
---
workflow_id: "tp-incremental-build"
requirement_type: "TP"
requirement_nature: "优化需求"
project_name: "资源标签管理和资源调度系统"
version: "I20260423"
base_doc: "workspace/design/I20260423/PRD-资源标签管理和资源调度系统-20260424.md"
fe_doc: "workspace/requirements/I20260423/FE-资源标签管理和资源调度系统-20260512.md"
fe_doc_available: true
status: "completed"
stepsCompleted: ["app-architecture", "ui-prototype", "info-architecture", "feature-spec", "permission-design", "scenario-solution", "nfr"]
last_element: "nfr"
last_updated: "2026-05-12"
created_date: "2026-05-12"
requirement_register:
  - id: "RR-01"
    description: "在资源查看界面新增【导出】按钮，可以导出全量的资源信息，包括标签（包括：资源列表查询页增强导出功能 + 个人标签查询页新增导出按钮）"
    source: "FE §1.2 RR-01"
    status: "已分析"
  - id: "RR-02"
    description: "增加标签后台管理能力，包括标签定义（要打哪些标签）、对象定义（给什么对象打标签）；这样扩展性好点（完整方案：标签类型定义管理 + 对象定义管理）"
    source: "FE §1.2 RR-02"
    status: "已分析"
impact_analysis:
  triggered_changes:
    - id: "UI-01"
      source_requirement: "RR-01"
      evidence: "FE §6.3 P003/P004新增导出按钮（导出Excel全量、导出我的标签信息）"
      evidence_source: "fe_doc"
      confidence: "high"
      open_question: ""
    - id: "LG-02"
      source_requirement: "RR-01"
      evidence: "FE §5.2 FR-004导出功能逻辑调整（导出字段扩展）"
      evidence_source: "fe_doc"
      confidence: "high"
      open_question: ""
    - id: "DA-01"
      source_requirement: "RR-02"
      evidence: "FE §5.1新增FR-005标签类型定义管理、FR-006对象定义管理；新增实体：标签类型、标签值、对象定义"
      evidence_source: "fe_doc"
      confidence: "high"
      open_question: ""
    - id: "LG-01"
      source_requirement: "RR-02"
      evidence: "FE §4.7新增BR-022~BR-031业务规则"
      evidence_source: "fe_doc"
      confidence: "high"
      open_question: ""
    - id: "UI-02"
      source_requirement: "RR-02"
      evidence: "FE §6.1新增P006标签类型定义管理页、P007对象定义管理页"
      evidence_source: "fe_doc"
      confidence: "high"
      open_question: ""
  effective_sequence:
    - element_id: "app-architecture"
      impact_level: "certain"
      source_changes: ["UI-02"]
      trigger_type: "primary"
      optional_skippable: false
    - element_id: "ui-prototype"
      impact_level: "certain"
      source_changes: ["UI-01", "UI-02"]
      trigger_type: "primary"
      optional_skippable: false
    - element_id: "info-architecture"
      impact_level: "certain"
      source_changes: ["DA-01"]
      trigger_type: "primary"
      optional_skippable: false
    - element_id: "feature-spec"
      impact_level: "certain"
      source_changes: ["UI-01", "UI-02", "DA-01", "LG-01", "LG-02"]
      trigger_type: "primary"
      optional_skippable: false
    - element_id: "permission-design"
      impact_level: "certain"
      source_changes: ["UI-01", "UI-02"]
      trigger_type: "primary"
      optional_skippable: false
    - element_id: "scenario-solution"
      impact_level: "likely"
      source_changes: ["UI-01", "UI-02", "DA-01", "LG-01"]
      trigger_type: "cascade"
      cascade_from: ["feature-spec"]
      cascade_reason: "功能变化可能影响场景串联"
      optional_skippable: true
    - element_id: "nfr"
      impact_level: "likely"
      source_changes: []
      trigger_type: "cascade"
      cascade_from: ["feature-spec"]
      cascade_reason: "导出功能增强可能影响性能指标"
      optional_skippable: true
  cascade_warnings:
    - element_id: "scenario-solution"
      reason: "依赖图安全网识别：feature-spec → scenario-solution (direct)"
      added_by_user: true
    - element_id: "nfr"
      reason: "导出全量数据可能影响响应时间指标"
      added_by_user: true
  impact_points:
    - id: "IP-app-architecture-001"
      source_requirement: "RR-02"
      source_change: "UI-02"
      trigger_type: "primary"
      cascade_rule: ""
      element: "app-architecture"
      baseline_ref: "基线 PRD §2.3 特性分类总览"
      baseline_state: "基线包含4个特性分类（TC-01~TC-04）、12个特性（F0101~F0403）、34个子特性（FR-01-01-001~FR-04-03-001）"
      action: "新增"
      target_state: "新增1个特性分类（TC-05标签定义管理）、2个特性（F0501标签类型定义管理、F0502对象定义管理）、13个子特性（FR-05-01-001~008、FR-05-02-001~005）"
      target_state_evidence: "fe_doc"
      in_scope:
        - "TC-05 标签定义管理特性分类"
        - "F0501 标签类型定义管理特性"
        - "F0502 对象定义管理特性"
        - "FR-05-01-001~008 子特性（标签类型定义管理）"
        - "FR-05-02-001~005 子特性（对象定义管理）"
---
```

### (2) 标题行（grep '^#' 完整结果）

```
# PRD - 资源标签管理和资源调度系统 - 增量版本
## 二、应用架构
### 2.1 应用架构图
### 2.2 系统边界
### 2.3 特性分类/特性/子特性
#### 2.3.1 特性分类总览
#### 2.3.2 特性清单
#### 2.3.3 子特性清单
## 三、信息架构
### 4.1 业务对象/逻辑实体
### 4.2 实体关系图
### 4.3 实体详情
#### E014 标签类型定义
#### E015 标签值
#### E016 对象定义
## 四、界面原型
### 3.1 页面清单
### 3.2 页面功能规格
#### P001 标签数据导入页
#### P002 标签版本管理页
#### P003 资源列表查询页
#### P004 人员详情页
#### P005 资源手动新增页
#### P006 标签类型定义管理页（新增）
#### P007 对象定义管理页（新增）
### 3.3 菜单结构
### 3.4 Pageflow
### 3.5 兼容性要求
### 3.6 原型文件
## 五、功能特性
### 5.1 子特性基本信息
### 5.2 特性分类
### 5.3 子特性详细规格
#### FR-05-01-001 新增标签类型
#### FR-05-01-002 配置标签类型属性
#### FR-05-01-003 定义标签值体系
#### FR-05-01-004 发布标签类型
#### FR-05-01-005 启用/禁用标签类型
#### FR-05-01-006 查询标签类型
#### FR-05-01-007 编辑标签类型
#### FR-05-01-008 删除标签类型
#### FR-05-02-001 新增对象定义
#### FR-05-02-002 启用/禁用对象定义
#### FR-05-02-003 查询对象定义
#### FR-05-02-004 编辑对象定义
#### FR-05-02-005 删除对象定义
#### FR-04-01-004 导出Excel（全量）
#### FR-04-03-002 导出我的标签信息
## 六、权限设计
### 6.1 角色定义
### 6.2 功能权限矩阵
#### TC-01 标签维护管理
#### TC-02 资源上架管理
#### TC-03 数据集成管理
#### TC-04 资源查询管理
#### TC-05 标签定义管理
#### TC-04 资源查询管理（修改）
### 6.3 数据权限规则
## 七、集成设计
## 八、配置设计
## 九、场景解决方案
### 9.1 IT系统角色
### 9.2 集成点清单
### 9.3 场景解决方案
### 9.4 场景流程图
#### 标签定义管理流程（新增）
## 十、非功能特性清单
### 10.1 性能特性 (Performance)
### 10.2 安全特性 (Security)
### 10.3 可用性特性 (Availability)
### 10.4 可维护性特性 (Maintainability)
### 10.5 兼容性特性 (Compatibility)
### 10.6 易用性特性 (Usability)
### 10.7 DFX特性汇总表
```

---

## 【F】

### (1) output-contract.yaml

(不存在)

### (2) manifest 产出搜索

未发现 manifest 产出
