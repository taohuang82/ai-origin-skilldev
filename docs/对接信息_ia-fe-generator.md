# 对接信息_ia-fe-generator

## 【0】SKILL.md 关键字段

- spec_compliance: `v1.3.0`
- engine/ENGINE-VERSION: `2.1.1`

---

## 【A】config.yaml

```yaml
skill_name: "ia-fe-generator"
spec_compliance: "v1.3.0"

output_folder_base: "workspace/requirements"
input_folder_base: "workspace/raw_requirements"  # 存放用户提供的原始需求文档(Word/PDF/HTML等)
biz_knowledge_library: "docs/biz_kl"

input_doc_type: "用户对话输入 + 原始需求文档"
output_doc_type: "FE"

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

# v1.2.0 扩展注册表
# 启用变化点路由层(Layer 3.5),用于 tp-incremental-build workflow
extension_registry:
  atomic_changes: "registry/atomic-change-registry.yaml"
  change_element_mapping: "registry/change-element-mapping.yaml"
  dependency_graph: "registry/dependency-graph.yaml"

standards:
  builtin_dir: "standards/"
  extend_index: "docs/extend-rule/INDEX.md"

context:
  ongoing_file: "workspace/ongoing.md"
  raw_requirements_dir: "workspace/raw_requirements"  # 明确原始需求文档存储路径
```

---

## 【B】registry/ 下每一个 .yaml

### registry/workflow-registry.yaml

```yaml
workflows:
  # 场景1: 评审修改(最高优先级)
  - id: "fe-review-modify"
    name: "FE 评审修改"
    priority: 80
    input_signature:
      required:
        - id: "FE_HISTORICAL"
          reason: "必须有目标 FE 文档(已完成状态)。"
        - id: "REVIEW_COMMENTS"
          reason: "必须有评审意见。"
      excluded:
        - id: "FE_DOC_INPROGRESS"
          reason: "存在进行中 FE 时优先走续接恢复。"
      optional: []
    trigger_keywords: ["评审修改", "根据评审意见", "修改FE", "按意见改"]
    orchestration_file: "orchestration/o-review-modify.md"
    element_sequence: []
    status: "planned"  # 骨架版本,待实现

  # 场景2: 优化需求增量构建
  - id: "tp-incremental"
    name: "TP 优化需求 FE 构建"
    priority: 60
    input_signature:
      required:
        - id: "USER_DIALOG_INPUT"
          reason: "用户描述优化需求内容。"
        - id: "FE_HISTORICAL"
          reason: "必须有历史 FE 作为增量基线。"
      excluded:
        - id: "FE_DOC_INPROGRESS"
          reason: "存在进行中 FE 时优先走续接恢复。"
        - id: "REVIEW_COMMENTS"
          reason: "存在评审意见时属于 review-modify 场景。"
      optional:
        - id: "RAW_REQUIREMENTS_DOC"
          reason: "可选:用户可提供优化需求的详细文档。"
    trigger_keywords: ["优化需求", "1-n", "在现有FE基础上"]
    orchestration_file: "orchestration/o-tp-incremental.md"
    element_sequence: []
    status: "active"

  # 场景3: 专题需求新建构建
  - id: "tp-new-build"
    name: "TP 专题需求 FE 构建"
    priority: 40
    input_signature:
      required:
        - id: "USER_DIALOG_INPUT"
          reason: "用户描述专题需求内容(必需)。"
      excluded:
        - id: "FE_HISTORICAL"
          reason: "存在历史 FE 时优先走增量构建。"
        - id: "FE_DOC_INPROGRESS"
          reason: "存在进行中 FE 时自动续接恢复(由 workflow-engine 处理)。"
        - id: "REVIEW_COMMENTS"
          reason: "存在评审意见时属于 review-modify 场景。"
      optional:
        - id: "RAW_REQUIREMENTS_DOC"
          reason: "可选:用户可提供原始需求文档(Word/PDF/HTML),系统会智能抽取要素信息。"
    trigger_keywords: ["创建FE", "生成FE", "特性需求文档", "创建特性需求", "新建FE"]
    orchestration_file: "orchestration/o-tp-new-build.md"
    element_sequence:
      - element_id: "original-requirement"
        optional: false
      - element_id: "business-background"
        optional: false
      - element_id: "requirement-type"
        optional: false
      - element_id: "business-process"
        optional: false
      - element_id: "business-function"
        optional: false
      - element_id: "user-interaction"
        optional: false
      - element_id: "non-functional-req"
        optional: false
      - element_id: "glossary"
        optional: false
    status: "active"

  # 场景4-5: AP/AI专题需求(待实现)
  - id: "ap-new-build"
    name: "AP 专题需求 FE 构建"
    priority: 40
    requirement_type: "AP"
    orchestration_file: "orchestration/o-ap-new-build.md"
    status: "planned"

  - id: "ai-new-build"
    name: "AI 专题需求 FE 构建"
    priority: 40
    requirement_type: "AI"
    orchestration_file: "orchestration/o-ai-new-build.md"
    status: "planned"
```

### registry/element-type-registry.yaml

```yaml
element_types:
  # 基础信息要素
  - id: "original-requirement"
    name: "原始需求"
    chapter_no: 1
    chapter_no_cn: "一"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "1.1", name: "原始需求来源记录" }
      - { l2_no: "1.2", name: "原始需求描述" }
      - { l2_no: "1.3", name: "关键信息提取矩阵" }
    belongs_to: ["TP", "AP", "AI"]
    optional: false
    backend_only: false
    always_affected_in: ["incremental"]
    description: "需求发起人提供的原始需求说明,支持文档导入(Word/PDF/HTML)或对话输入,标准化格式整理。"
    dual_input_mode: true

  - id: "business-background"
    name: "业务背景"
    chapter_no: 2
    chapter_no_cn: "二"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "2.1", name: "现状和痛点" }
      - { l2_no: "2.2", name: "目标和价值" }
      - { l2_no: "2.3", name: "业务范围" }
    belongs_to: ["TP", "AP", "AI"]
    optional: false
    backend_only: false
    description: "现状痛点、目标价值、业务范围的结构化梳理。"

  - id: "requirement-type"
    name: "需求类型"
    chapter_no: 3
    chapter_no_cn: "三"
    chapter_label_style: "chinese"
    sub_elements: []
    belongs_to: ["TP", "AP", "AI", "IT"]
    optional: false
    backend_only: true                    # ⚠️ 关键：仅写 frontmatter，不写正文
    always_affected_in: ["incremental"]
    description: "TP/AP/AI/IT类型定性,确定后续功能模块路径。"

  # TP类型专用要素
  - id: "business-process"
    name: "业务流程"
    chapter_no: 4
    chapter_no_cn: "四"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "4.1", name: "业务流程图" }
      - { l2_no: "4.2", name: "活动总览" }
      - { l2_no: "4.3", name: "活动明细" }
      - { l2_no: "4.4", name: "角色清单" }
      - { l2_no: "4.5", name: "输入信息" }
      - { l2_no: "4.6", name: "输出结果" }
      - { l2_no: "4.7", name: "业务规则" }
      - { l2_no: "4.8", name: "外部依赖记录" }
    belongs_to: ["TP"]
    optional: false
    backend_only: false
    description: "流程概览、活动明细、角色职责、输入输出、业务规则、异常处理。"

  - id: "business-function"
    name: "业务功能"
    chapter_no: 5
    chapter_no_cn: "五"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "5.1", name: "功能清单" }
      - { l2_no: "5.2", name: "功能详细描述" }
      - { l2_no: "5.3", name: "业务权限矩阵" }
    belongs_to: ["TP"]
    optional: false
    backend_only: false
    description: "功能清单、功能描述、业务权限矩阵。"

  - id: "user-interaction"
    name: "用户交互"
    chapter_no: 6
    chapter_no_cn: "六"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "6.1", name: "页面清单" }
      - { l2_no: "6.2", name: "页面流转图" }
      - { l2_no: "6.3", name: "页面低保真草图" }
    belongs_to: ["TP"]
    optional: false
    backend_only: false
    description: "页面清单、页面流转、页面低保真草图。"

  # 公共要素
  - id: "non-functional-req"
    name: "非功能要求"
    chapter_no: 7
    chapter_no_cn: "七"
    chapter_label_style: "chinese"
    sub_elements:
      - { l2_no: "7.1", name: "性能要求" }
      - { l2_no: "7.2", name: "信息安全" }
      - { l2_no: "7.3", name: "个人隐私保护" }
    belongs_to: ["TP", "AP", "AI", "IT"]
    optional: true
    backend_only: false
    description: "性能要求、信息安全、个人隐私保护。"

  - id: "glossary"
    name: "概念术语"
    chapter_no: 8
    chapter_no_cn: "八"
    chapter_label_style: "chinese"
    sub_elements: []
    belongs_to: ["TP", "AP", "AI", "IT"]
    optional: false
    backend_only: false
    always_affected_in: ["incremental"]
    description: "业务术语、技术术语的定义与使用场景。"
```

### registry/change-element-mapping.yaml

```yaml
# change-element-mapping.yaml
# FE Skill v1.2.0 Layer 3.5 - 变化点到 FE 要素的影响映射
#
# impact_level:
#   certain     - 一定影响,自动加入 effective_sequence
#   likely      - 通常影响,默认加入但可跳过
#   conditional - 条件影响,根据 condition 判断或交由用户决定

change_element_mappings:

  # ─── PR 类映射 ────────────────────────────────────
  - change_id: "PR-01"
    affects:
      - element_id: "business-process"
        impact_level: "certain"
        reason: "流程图、活动总览、活动明细新增节点"
      - element_id: "business-function"
        impact_level: "likely"
        reason: "新节点通常对应新功能"
      - element_id: "user-interaction"
        impact_level: "conditional"
        condition: "新节点需要 UI 承载"
        reason: "若新节点为人工操作,需要新页面"

  - change_id: "PR-02"
    affects:
      - element_id: "business-process"
        impact_level: "certain"
      - element_id: "business-function"
        impact_level: "likely"
        reason: "节点对应功能可能下线"
      - element_id: "user-interaction"
        impact_level: "conditional"
        condition: "节点对应页面是否仍保留"

  - change_id: "PR-03"
    affects:
      - element_id: "business-process"
        impact_level: "certain"
        reason: "流程图重排"
      - element_id: "business-function"
        impact_level: "conditional"
        condition: "顺序变化是否影响功能描述操作步骤"
      - element_id: "user-interaction"
        impact_level: "conditional"
        condition: "顺序变化是否影响页面流转"

  - change_id: "PR-04"
    affects:
      - element_id: "business-process"
        impact_level: "certain"
        reason: "角色清单调整"
      - element_id: "business-function"
        impact_level: "certain"
        reason: "业务权限矩阵必然调整"

  - change_id: "PR-05"
    affects:
      - element_id: "business-process"
        impact_level: "certain"
        reason: "输入子要素更新"
      - element_id: "business-function"
        impact_level: "likely"
        reason: "功能描述涉及的输入信息变化"
      - element_id: "user-interaction"
        impact_level: "likely"
        reason: "输入字段变化通常对应页面字段变化"

  - change_id: "PR-06"
    affects:
      - element_id: "business-process"
        impact_level: "certain"
        reason: "输出子要素更新"
      - element_id: "business-function"
        impact_level: "likely"
      - element_id: "user-interaction"
        impact_level: "conditional"
        condition: "输出是否在页面呈现"

  - change_id: "PR-07"
    affects:
      - element_id: "business-process"
        impact_level: "certain"
        reason: "业务规则子要素更新"
      - element_id: "business-function"
        impact_level: "likely"
        reason: "功能描述可能引用规则"

  - change_id: "PR-08"
    affects:
      - element_id: "business-process"
        impact_level: "certain"
        reason: "活动明细异常处理字段更新"
      - element_id: "business-function"
        impact_level: "likely"
      - element_id: "user-interaction"
        impact_level: "conditional"
        condition: "异常处理是否需要新页面"

  # ─── FN 类映射 ────────────────────────────────────
  - change_id: "FN-01"
    affects:
      - element_id: "business-function"
        impact_level: "certain"
        reason: "功能清单/描述新增"
      - element_id: "business-process"
        impact_level: "certain"
        reason: "新功能通常对应新业务活动"
      - element_id: "user-interaction"
        impact_level: "certain"
        reason: "新功能必有页面承载"

  - change_id: "FN-02"
    affects:
      - element_id: "business-function"
        impact_level: "certain"
        reason: "功能描述调整"
      - element_id: "business-process"
        impact_level: "conditional"
        condition: "是否触达活动级变化"
      - element_id: "user-interaction"
        impact_level: "likely"
        reason: "操作步骤变化通常涉及页面"

  - change_id: "FN-03"
    affects:
      - element_id: "business-function"
        impact_level: "certain"
        reason: "功能清单删除"
      - element_id: "business-process"
        impact_level: "certain"
        reason: "对应活动同步下线"
      - element_id: "user-interaction"
        impact_level: "certain"
        reason: "对应页面同步下线"

  - change_id: "FN-04"
    affects:
      - element_id: "business-function"
        impact_level: "certain"
        reason: "业务权限矩阵更新"
      - element_id: "business-process"
        impact_level: "likely"
        reason: "角色清单可能调整"

  # ─── UI 类映射 ────────────────────────────────────
  - change_id: "UI-01"
    affects:
      - element_id: "user-interaction"
        impact_level: "certain"
        reason: "页面清单+流转+低保真新增"
      - element_id: "business-function"
        impact_level: "likely"
        reason: "新页面通常对应新功能或扩展"
      - element_id: "business-process"
        impact_level: "conditional"
        condition: "新页面是否对应新活动"

  - change_id: "UI-02"
    affects:
      - element_id: "user-interaction"
        impact_level: "certain"
        reason: "低保真草图更新"
      - element_id: "business-function"
        impact_level: "likely"
        reason: "字段变化常涉及功能描述"
      - element_id: "business-process"
        impact_level: "likely"
        reason: "输入信息可能同步变化"

  - change_id: "UI-03"
    affects:
      - element_id: "user-interaction"
        impact_level: "certain"
        reason: "页面流转更新"
      - element_id: "business-process"
        impact_level: "likely"
        reason: "流转变化通常映射流程顺序"

  - change_id: "UI-04"
    affects:
      - element_id: "user-interaction"
        impact_level: "certain"
        reason: "页面清单+流转更新"
      - element_id: "business-function"
        impact_level: "likely"
        reason: "对应功能可能下线"

  # ─── NF 类映射 ────────────────────────────────────
  - change_id: "NF-01"
    affects:
      - element_id: "non-functional-req"
        impact_level: "certain"
        reason: "性能要求子要素更新"

  - change_id: "NF-02"
    affects:
      - element_id: "non-functional-req"
        impact_level: "certain"
        reason: "信息安全 + 个人隐私保护 子要素更新"
```

### registry/atomic-change-registry.yaml

```yaml
# atomic-change-registry.yaml
# FE Skill v1.2.0 Layer 3.5 - 原子变化点目录
# 由 orchestration/o-tp-incremental.md Phase 1.5 Step 1 读取
#
# FE 阶段业务域分类(4 类,刻意区别于 PRD 阶段):
# PR - Process       业务流程
# FN - Function      业务功能
# UI - User Interface 用户交互
# NF - Non-Functional 非功能

atomic_changes:

  # ─── PR 类(业务流程变化,8 个)──────────────────────
  - id: "PR-01"
    name: "流程节点新增"
    category: "PR"
    description_zh: "在业务流程中增加新步骤/环节/活动"
    detection_keywords: ["增加步骤", "新增环节", "加一步", "增加活动", "新增节点", "增加预审"]
    examples:
      - "审批前增加部门预审环节"
      - "提交后新增系统校验步骤"
    status: "active"

  - id: "PR-02"
    name: "流程节点删除/合并"
    category: "PR"
    description_zh: "去掉或合并某个流程步骤"
    detection_keywords: ["去掉步骤", "删除环节", "简化流程", "合并步骤", "去掉预审"]
    examples:
      - "去掉部门预审,直接走总监审批"
    status: "active"

  - id: "PR-03"
    name: "流程顺序调整"
    category: "PR"
    description_zh: "调整流程节点的执行顺序"
    detection_keywords: ["调整顺序", "流程顺序", "放到前面", "放到后面", "顺序变化"]
    examples:
      - "把付款放到发货之前"
    status: "active"

  - id: "PR-04"
    name: "角色调整"
    category: "PR"
    description_zh: "流程中执行某节点的角色变化"
    detection_keywords: ["换角色", "改角色", "执行人变化", "角色变更", "审批人改"]
    examples:
      - "审批人从部门主管改为项目经理"
    status: "active"

  - id: "PR-05"
    name: "活动输入变化"
    category: "PR"
    description_zh: "某步骤的输入信息字段或来源变化"
    detection_keywords: ["增加输入", "改输入", "新增字段", "改数据来源", "输入变化"]
    examples:
      - "申请提交时增加预算编码字段"
    status: "active"

  - id: "PR-06"
    name: "活动输出变化"
    category: "PR"
    description_zh: "某步骤的输出结果或状态变更逻辑变化"
    detection_keywords: ["输出变化", "状态变化", "产出", "输出结果"]
    examples:
      - "审批通过后新增同步到 ERP"
    status: "active"

  - id: "PR-07"
    name: "业务规则新增/修改"
    category: "PR"
    description_zh: "业务规则增加、调整阈值或废弃"
    detection_keywords: ["新增规则", "规则调整", "阈值", "改规则", "规则变更"]
    examples:
      - "审批阈值从 5 万改为 10 万"
    status: "active"

  - id: "PR-08"
    name: "异常处理新增/调整"
    category: "PR"
    description_zh: "异常分支或异常处理逻辑变化"
    detection_keywords: ["异常处理", "驳回", "撤回", "超时", "退回", "超时自动"]
    examples:
      - "新增审批超时 24 小时自动转交"
    status: "active"

  # ─── FN 类(业务功能变化,4 个)──────────────────────
  - id: "FN-01"
    name: "功能新增"
    category: "FN"
    description_zh: "增加一个完整的业务功能"
    detection_keywords: ["新增功能", "加功能", "增加", "增加一个功能", "批量功能"]
    examples:
      - "增加批量导出功能"
    status: "active"

  - id: "FN-02"
    name: "功能描述调整"
    category: "FN"
    description_zh: "已有功能的操作步骤、范围调整"
    detection_keywords: ["改功能", "调整功能", "操作步骤", "功能范围"]
    examples:
      - "导出功能增加按时间筛选"
    status: "active"

  - id: "FN-03"
    name: "功能下线"
    category: "FN"
    description_zh: "去掉某个已有功能"
    detection_keywords: ["去掉功能", "下线", "移除", "废弃功能"]
    examples:
      - "下线手工补录功能"
    status: "active"

  - id: "FN-04"
    name: "业务权限变化"
    category: "FN"
    description_zh: "角色对功能的访问权限调整"
    detection_keywords: ["权限调整", "角色权限", "访问权限", "权限变化"]
    examples:
      - "增加部门主管查看全部数据的权限"
    status: "active"

  # ─── UI 类(用户交互变化,4 个)──────────────────────
  - id: "UI-01"
    name: "页面新增"
    category: "UI"
    description_zh: "新增一个完整页面"
    detection_keywords: ["新增页面", "加页面", "新页面", "增加页面"]
    examples:
      - "新增订单详情页"
    status: "active"

  - id: "UI-02"
    name: "页面字段/控件调整"
    category: "UI"
    description_zh: "在已有页面增/删字段、按钮、控件"
    detection_keywords: ["加字段", "改字段", "加按钮", "控件调整", "新增按钮", "去掉字段"]
    examples:
      - "申请表单增加优先级字段"
      - "审批列表加批量审批按钮"
    status: "active"

  - id: "UI-03"
    name: "页面流转变化"
    category: "UI"
    description_zh: "调整页面之间的跳转关系"
    detection_keywords: ["流转调整", "跳转关系", "页面跳转", "跳转变化"]
    examples:
      - "提交后直接跳详情页"
    status: "active"

  - id: "UI-04"
    name: "页面下线"
    category: "UI"
    description_zh: "移除某个已有页面"
    detection_keywords: ["下线页面", "删页面", "不需要页面", "移除页面"]
    examples:
      - "下线手工补录页"
    status: "active"

  # ─── NF 类(非功能变化,2 个)────────────────────────
  - id: "NF-01"
    name: "性能要求变化"
    category: "NF"
    description_zh: "调整响应时间、并发、吞吐等指标"
    detection_keywords: ["性能", "响应", "并发", "吞吐", "响应时间"]
    examples:
      - "响应时间从 3 秒收紧到 1 秒"
    status: "active"

  - id: "NF-02"
    name: "安全/隐私要求变化"
    category: "NF"
    description_zh: "调整加密、脱敏、合规要求"
    detection_keywords: ["安全", "加密", "脱敏", "合规", "GDPR", "个人信息保护"]
    examples:
      - "增加 GDPR 合规要求"
    status: "active"
```

### registry/dependency-graph.yaml

```yaml
# dependency-graph.yaml
# FE Skill v1.2.0 Layer 3.5 - FE 要素级联影响图
# Phase 1.5 Step 4 作为安全网,扩展 effective_sequence 的下游影响

impact_edges:
  - source: "business-process"
    targets:
      - element: "business-function"
        impact_type: "direct"
        reason: "业务活动是功能清单的来源,活动变化必然影响功能"
      - element: "user-interaction"
        impact_type: "indirect"
        reason: "流程变化可能引发页面调整"

  - source: "business-function"
    targets:
      - element: "user-interaction"
        impact_type: "direct"
        reason: "功能必有页面承载,功能变化常对应页面变化"
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

### registry/input-type-registry.yaml

```yaml
input_types:
  - id: "USER_DIALOG_INPUT"
    name: "用户对话输入"
    description: "FE 新建和增量构建的核心输入源。通过对话式发现收集需求信息。"
    detect_rules:
      - type: "dialog_input"
        path: ""
        condition: "always_true"
    provision_guide: "用户直接描述需求内容即可,或提供原始需求文档路径。"

  - id: "RAW_REQUIREMENTS_DOC"
    name: "原始需求文档"
    description: "可选输入。提供后系统抽取要素信息,经用户确认后写入FE。"
    detect_rules:
      - type: "dir_not_empty"
        path: "workspace/raw_requirements"
        condition: "filter_extensions=docx,pdf,html,md"
      - type: "user_specified_path"
        path: "user_message"
        condition: "exists_and_extension_in=docx,pdf,html,md"
    provision_guide: |
      提供原始需求文档的两种方式:
      1. 上传文档到 workspace/raw_requirements/,系统会自动检测
      2. 直接告诉我文档路径(如"D:/docs/需求文档.docx")
      若无文档或不想提供,直接描述需求即可。
    supported_formats: ["docx", "pdf", "html", "md"]

  - id: "FE_DOC_INPROGRESS"
    name: "进行中的 FE 文档"
    description: "续接恢复场景的关键判据。"
    detect_rules:
      - type: "frontmatter_field"
        path: "workspace/requirements/{current_version}/FE-*.md"
        condition: "status == 'in_progress'"
    provision_guide: "系统检测到未完成的 FE 文档,可续接上次进度继续执行。"

  - id: "FE_HISTORICAL"
    name: "历史已完成 FE"
    description: "增量构建和评审修改场景的基线 FE 输入。"
    detect_rules:
      - type: "frontmatter_field"
        path: "workspace/requirements/*/FE-*.md"
        condition: "status == 'completed' AND project_name == ongoing.project_name"
    provision_guide: "提供历史 FE 路径,或说明要基于哪个历史版本做增量构建或评审修改。"

  - id: "REVIEW_COMMENTS"
    name: "评审意见"
    description: "评审修改场景的必要输入。"
    detect_rules:
      - type: "dialog_input"
        path: "user_message"
        condition: "matches_keywords=[补充,增加,修改,调整,删除,根据评审意见,按以下意见修改] OR matches_chapter_pattern"
      - type: "annotation_marker"
        path: "user_provided_doc"
        condition: "contains_pattern==文本==[^n]"
    provision_guide: "直接在对话中描述修改意见,或提供带 ==高亮==[^n] 标注的评审文档。"
```

### registry/standards-registry.yaml

```yaml
# standards-registry.yaml
# 用途：standard_id → 系统内置规范文件路径的映射
# standards-loader Level 2 依赖本文件

standards:
  - id: "mermaid-flowchart"
    name: "Mermaid 业务流程图规范"
    file_path: "standards/mermaid-flowchart-standard.md"
    description: "业务流程 Mermaid flowchart TD 格式规范，适用于 business-process 要素"
    version: "1.0.0"

  - id: "mermaid-page-flow"
    name: "Mermaid 页面流转图规范"
    file_path: "standards/mermaid-page-flow-standard.md"
    description: "页面跳转关系 Mermaid graph TD 格式规范，适用于 user-interaction 要素"
    version: "1.0.0"

# ── 说明 ──────────────────────────────────────────────────────
# 当前阶段，mermaid 规范的核心规则已内嵌于各 Spec 的 ## 约束 → ### 设计约束 章节中。
# standards-loader 若未找到 file_path 对应文件，element-runner Phase 3 将以 Spec
# 内置设计约束兜底，不终止执行。
# 待 standards/*.md 规范文件创建后，standards-loader 将优先加载本地文件。
```

### registry/spec-template-registry.yaml

```yaml
# spec-template-registry.yaml
# 用途：element_id + requirement_type + execution_mode → spec 文件路径的三维映射
# element-runner Phase 1 依赖本文件进行 Spec 定位

spec_templates:

  # ── 原始需求（所有类型通用）──────────────────────────────────
  - implements: "original-requirement"
    for_type: ["TP", "AP", "AI", "IT"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-fe-original-requirement.md"
    status: "active"

  # ── 业务背景（TP/AP/AI 通用）─────────────────────────────────
  - implements: "business-background"
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-fe-business-background.md"
    status: "active"

  # ── 需求类型定性（所有类型通用）──────────────────────────────
  - implements: "requirement-type"
    for_type: ["TP", "AP", "AI", "IT"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-fe-requirement-type.md"
    status: "active"

  # ── 业务流程（TP 专用）───────────────────────────────────────
  - implements: "business-process"
    for_type: ["TP"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-fe-business-process.md"
    status: "active"

  # ── 业务功能（TP 专用）───────────────────────────────────────
  - implements: "business-function"
    for_type: ["TP"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-fe-business-function.md"
    status: "active"

  # ── 用户交互（TP 专用）───────────────────────────────────────
  - implements: "user-interaction"
    for_type: ["TP"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-fe-user-interaction.md"
    status: "active"

  # ── 非功能要求（所有类型通用）────────────────────────────────
  - implements: "non-functional-req"
    for_type: ["TP", "AP", "AI", "IT"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-fe-non-functional-req.md"
    status: "active"

  # ── 概念术语（所有类型通用）──────────────────────────────────
  - implements: "glossary"
    for_type: ["TP", "AP", "AI", "IT"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-fe-glossary.md"
    status: "active"
```

---

## 【C】orchestration/

文件列表:
- o-tp-incremental.md
- o-tp-new-build.md
- o-review-modify.md

### orchestration/o-tp-incremental.md (增量类,全文)

```markdown
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
```

### orchestration/o-review-modify.md (增量/修改类,全文)

```markdown
# o-review-modify

## 职责

负责根据评审意见对已完成FE进行局部修改编排。

## 初始化阶段

### Action 0: 验证输入

1. 检查必需输入 `FE_HISTORICAL` 存在
2. 检查必需输入 `REVIEW_COMMENTS` 存在
3. 读取目标FE文档和历史评审意见

### Action 1: 解析评审意见

分析评审意见涉及的章节和要素:
- 识别章节编号(如"第4章业务流程")
- 识别修改指令(补充/修改/调整/删除)
- 提取具体修改内容

### Action 2: 确认修改要素序列

根据评审意见,生成需要修改的要素列表。

## 要素执行循环

对需要修改的要素执行 `element-runner(mode="modify")`。

## 完成阶段

### Action A: 变更记录

记录修改历史和评审意见处理情况。

### Action B: 质量检查

验证修改后的章节完整性和语法正确性。

### Action C: 最终状态更新

更新FE文档的修改时间和版本号。

## 当前状态

骨架版本,待后续完整实现。
```

### orchestration/o-tp-new-build.md (build 类,只列名)

(不贴正文)

---

## 【D】spec/ 下 m-*.md 文件名列表

- m-fe-business-background.md
- m-fe-business-function.md
- m-fe-business-process.md
- m-fe-glossary.md
- m-fe-non-functional-req.md
- m-fe-original-requirement.md
- m-fe-requirement-type.md
- m-fe-user-interaction.md

### 容器型要素: spec/m-fe-business-function.md — 截取"## 前置条件"和"## 输出骨架"

#### ## 前置条件

```markdown
## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|----------------------|------|
| business-process | 业务流程活动总览表格已生成,角色清单已生成 |
| user-interaction(构思) | 功能描述需要引用页面信息(但user-interaction在后续执行,此处仅构思) |

**必要输入**

- 业务流程-活动总览表格
- 业务流程-活动明细
- 业务流程-角色清单
```

#### ## 输出骨架

```markdown
## 输出骨架

```markdown
## 五、业务功能

### 功能清单

| 功能编号 | 功能名称 | 功能说明 | 对应活动 | 优先级 |
|---------|---------|---------|---------|--------|
| FR-xxx | {功能名称} | {功能说明} | ACT-xxx | P0/P1/P2 |

### 功能详细描述

| 功能编号 | 功能名称 | 所属模块 | 核心功能点 | 操作步骤 | 涉及实体 | 业务规则 |
|---------|---------|---------|-----------|---------|---------|---------|
| FR-xxx | {功能名称} | {模块} | {功能点} | {步骤1-7} | {实体编号} | BR-xxx |

**FR-xxx: {功能名称}详细说明**

- **核心功能点**: {功能点描述}
- **操作步骤**:
  1. 用户在"{页面名称}"页面点击"{按钮名称}"按钮
  2. 系统弹出表单,用户填写"{字段名称}"字段
  3. ...
- **涉及实体**: {实体名称}(实体编号:Entity-xxx)
- **业务规则**: {规则编号BR-xxx列表}

(重复每个功能)

### 业务权限矩阵

| 角色 | FR-001(功能1) | FR-002(功能2) | FR-003(功能3) | ... |
|------|--------------|--------------|--------------|-----|
| 角色1 | 查看、编辑 | 查看 | 编辑、审批 | ... |
| 角色2 | 查看 | 查看、编辑、删除 | 查看 | ... |
| 角色3 | 编辑、审批 | 查看 | 查看、编辑 | ... |

> 注:本权限矩阵基于角色清单和功能清单设计,已获得用户逐角色确认。权限类型包括:查看、编辑、删除、审批、导出、打印。

> ⚠️ **特别说明**: 功能编号标注对应活动编号(ACT-xxx),便于追溯业务流程。功能描述的涉及实体和业务规则引用后续章节实体编号和规则编号。
```
```

### 叶子型要素: spec/m-fe-glossary.md — 截取"## 前置条件"和"## 输出骨架"

#### ## 前置条件

```markdown
## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|----------------------|------|
| original-requirement | 原始需求矩阵可能包含专有名词线索 |
| (全流程要素) | 术语追踪贯穿所有要素执行过程 |

**必要输入**

- 原始需求关键信息提取矩阵(可能包含专有名词线索)
- 全流程对话中出现的业务专有名词、新定义术语、缩写等
```

#### ## 输出骨架

```markdown
## 输出骨架

```markdown
## 八、概念术语

| 术语名称 | 术语定义 | 适用场景 | 来源章节 |
|---------|---------|---------|---------|
| {术语1} | {定义1} | {场景1} | {来源章节,如"4.业务流程-活动2"} |
| {术语2} | {定义2} | {场景2} | {来源章节,如"2.业务背景-现状痛点"} |
| {术语3} | {定义3} | {场景3} | {来源章节} |

> 注:本术语表通过实时追踪全流程对话中出现的未解释术语生成,每完成2-3个活动挖掘后做术语小结,对比业务知识库检查是否已定义,标注来源章节便于追溯。

> ⚠️ **特别说明**: 术语定义来源于用户对话确认,避免凭空编造。来源章节标注格式为"{章节编号}.{章节名称}-{具体位置}",便于追溯术语首次出现位置。
```
```

---

## 【E】样例输出文档

选取最完整文档: `workspace/requirements/I20260419/FE-资源调度管理系统-complete.md` (1219行)

### (1) Frontmatter

```yaml
---
document_version: V1
status: completed
stepsCompleted: [1, 2, 3, 4, 5, 6, 7]
completedDate: 2026-04-08
qualityScore: 优秀
requirement_id: RR-2026-003
author: 内审部门面向IT的业务代表
date: 2026-04-08
requirement_nature: 专题需求
requirement_type: 'TP'
---
```

### (2) 完整标题行(grep '^#')

```
# 原始需求文档 (版本 V1)
## 文档信息
## 一、业务背景
### 1.1 现状描述
### 1.2 痛点分析
### 1.3 业务机会
### 1.4 范围界定
## 二、业务目标
### 2.1 业务目标
### 2.2 成功标准
### 2.3 衡量指标
## 三、需求类型分析（后台信息）
### 3.1 需求类型识别
### 3.2 类型特征分析
### 3.3 设计约束提示（供PRD参考）
## 四、业务功能需求（一期：资源标签上架模块）
### 4.1 业务流程
#### 流程一：标签上架流程
#### 流程二：资源上架流程
### 4.2 参与角色
### 4.3 业务活动
### 4.4 业务规则
### 4.5 功能需求清单
#### 功能一：标签维护管理
#### 功能二：资源上架管理
#### 功能三：数据集成管理
#### 功能四：资源查询管理
## 五、界面设计
### 5.1 页面清单
### 5.2 页面流转关系
#### 标签上架流程页面流转
#### 资源上架流程页面流转
#### 个人用户页面流转
### 5.3 核心页面结构原型
#### P001 - 标签数据导入页
#### P002 - 标签版本管理页
#### P003 - 资源列表查询页
#### P004 - 人员详情页
#### P005 - 资源手动新增页
## 六、外部依赖识别
### 6.1 外部系统依赖
### 6.2 接口需求
#### 6.2.1 HR系统接口
#### 6.2.2 iData服务接口
#### 6.2.3 一站式平台接口
#### 6.2.4 项目立项管理系统接口
### 6.3 数据依赖关系
### 6.4 依赖风险与应对
## 七、非功能需求
### 7.1 性能需求
### 7.2 数据集成性能需求
### 7.3 安全需求
### 7.4 可用性需求
### 7.5 数据质量需求
### 7.6 约束条件
### 7.7 易用性需求
## 八、附录
### A. 相关文档
### B. 参考资料
## 九、关键业务概念说明
### 9.1 资源中心
### 9.2 三类标签详细说明
#### 9.2.1 审计专业能力方向
#### 9.2.2 审计项目经理等级
#### 9.2.3 审计任职资格
### 9.3 标签与人员关联规则
### 9.4 项目经历数据用途
### 9.5 权限矩阵详细说明
### 9.6 HR系统集成入库规则
### 9.7 标签导入失败处理流程
## 十、术语表
```

---

## 【F】

### (1) output-contract.yaml

```yaml
output_contract_version: "1.0.0"
skill_id: "ia-fe-generator"

frontmatter_schema:
  required_fields:
    - name: "workflow_id"
      type: "string"
      values: ["tp-new-build", "tp-incremental-build", "fe-review-modify"]
    - name: "requirement_type"
      type: "string"
      values: ["TP", "AP", "AI", "IT"]
    - name: "requirement_nature"
      type: "string"
      values: ["专题需求", "优化需求"]
    - name: "status"
      type: "string"
      values: ["in_progress", "completed"]
    - name: "stepsCompleted"
      type: "list[string]"
      description: "已完成的 element_id 列表"
    - name: "last_element"
      type: "string"
    - name: "last_updated"
      type: "string"
      format: "YYYY-MM-DD"

content_schema:
  guaranteed_chapters:
    - chapter_no: 1
      element_id: "original-requirement"
      sub_elements_guaranteed:
        - "原始需求来源记录"
        - "原始需求描述"
        - "关键信息提取矩阵"
    - chapter_no: 2
      element_id: "business-background"
      sub_elements_guaranteed:
        - "现状和痛点"
        - "目标和价值"
        - "业务范围"
    - chapter_no: 4
      element_id: "business-process"
      sub_elements_guaranteed:
        - "业务流程图"
        - "活动总览"
        - "活动明细"
        - "角色清单"
        - "输入信息"
        - "输出结果"
        - "业务规则"
        - "外部依赖记录"
    - chapter_no: 5
      element_id: "business-function"
      sub_elements_guaranteed:
        - "功能清单"
        - "功能详细描述"
        - "业务权限矩阵"
    - chapter_no: 6
      element_id: "user-interaction"
      sub_elements_guaranteed:
        - "页面清单"
        - "页面流转图"
        - "页面低保真草图"

versioning_policy:
  - "新增章节、新增字段：minor 版本递增"
  - "删除章节、删除字段、字段语义变更：major 版本递增"
  - "下游 Skill 的 min_contract_version 用 ^ 语义"
```

### (2) manifest 产出 grep 结果

未发现 manifest 产出
