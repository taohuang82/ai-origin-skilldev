# 对接信息_ia-prd-to-design

---

## 【0】SKILL.md 关键字段

- **spec_compliance**: `"v1.3.0"`
- **engine/ENGINE-VERSION**: `2.1.1`

---

## 【A】config.yaml

```yaml
# ── 文档类型声明 ────────────────────────────────────────────────
skill_name: "ia-prd-to-design-new"
spec_compliance: "v1.3.0"
input_doc_type: "PRD"
output_doc_type: "DESIGN"

# ── 输出/输入路径 ────────────────────────────────────────────────
output_folder_base: "workspace/design"
input_folder_base: "workspace/design"

# ── 输出文件名模板 ───────────────────────────────────────────────
default_filename: "{primary_artifact}"
date_format: "YYYYMMDD"

# ── 引擎挂载点（固定结构，禁止改动键名）─────────────────────────
engine:
  workflow_engine: "engine/workflow-engine.md"
  element_runner: "engine/element-runner.md"
  standards_loader: "engine/standards-loader.md"

# ── 标准注册表挂载点（固定 5 个，键名禁止改动）─────────────────
registry:
  workflows: "registry/workflow-registry.yaml"
  element_types: "registry/element-type-registry.yaml"
  spec_templates: "registry/spec-template-registry.yaml"
  input_types: "registry/input-type-registry.yaml"
  standards: "registry/standards-registry.yaml"

# ── Skill 扩展注册表（按需声明）─────────────────────────────────
extension_registry:
  dependency_graph: "registry/dependency-graph.yaml"
  atomic_changes: "registry/atomic-change-registry.yaml"
  change_element_mapping: "registry/change-element-mapping.yaml"

# ── 规范资产路径 ─────────────────────────────────────────────────
standards:
  builtin_dir: "standards/"
  extend_index: "docs/extend-rule/INDEX.md"

# ── Skill 扩展配置：多文件设计输出（键与 element-type-registry id 对齐）──
design_artifacts:
  architecture: "architecture.md"
  data-model: "data.md"
  api-contract: "backend-api.md"
  backend-impl: "backend.md"
  integration: "integration.md"
  config: "config.md"
  frontend: "frontend.md"

# ── 运行时上下文 ─────────────────────────────────────────────────
context:
  ongoing_file: "workspace/ongoing.md"
  biz_knowledge_library: "docs/biz_kl"
```

---

## 【B】registry/ 逐文件

### registry/element-type-registry.yaml

```yaml
element_types:
  - id: "architecture"
    name: "顶层架构"
    chapter_no: 1
    chapter_no_cn: "一"
    chapter_label_style: "chinese"
    belongs_to: ["TP", "AP", "AI"]
    optional: true
    description: "architecture.md：系统结构、技术栈、部署、模块边界（通常仅 greenfield 纳入 effective_sequence）。"
    status: "active"

  - id: "data-model"
    name: "数据与存储模型"
    chapter_no: 2
    chapter_no_cn: "二"
    chapter_label_style: "chinese"
    belongs_to: ["TP", "AP", "AI"]
    optional: false
    description: "data.md：表/索引/缓存/状态机等。"
    status: "active"

  - id: "api-contract"
    name: "后端接口契约"
    chapter_no: 3
    chapter_no_cn: "三"
    chapter_label_style: "chinese"
    belongs_to: ["TP", "AP", "AI"]
    optional: false
    description: "backend-api.md：API 清单、契约、错误约定。"
    status: "active"

  - id: "backend-impl"
    name: "后端实现要点"
    chapter_no: 4
    chapter_no_cn: "四"
    chapter_label_style: "chinese"
    belongs_to: ["TP", "AP", "AI"]
    optional: false
    description: "backend.md：领域逻辑、事务、与外部系统协作实现。"
    status: "active"

  - id: "integration"
    name: "集成与异步"
    chapter_no: 5
    chapter_no_cn: "五"
    chapter_label_style: "chinese"
    belongs_to: ["TP", "AP", "AI"]
    optional: true
    description: "integration.md：MQ、外部依赖、通知等。"
    status: "active"

  - id: "config"
    name: "配置与安全"
    chapter_no: 6
    chapter_no_cn: "六"
    chapter_label_style: "chinese"
    belongs_to: ["TP", "AP", "AI"]
    optional: true
    description: "config.md：配置项、字典、权限与安全。"
    status: "active"

  - id: "frontend"
    name: "前端方案"
    chapter_no: 7
    chapter_no_cn: "七"
    chapter_label_style: "chinese"
    belongs_to: ["TP", "AP", "AI"]
    optional: true
    description: "frontend.md：页面/组件/路由/交互（当 CHANGE_SCOPE 含 frontend 时纳入）。"
    status: "active"
```

### registry/change-element-mapping.yaml

```yaml
# change-element-mapping.yaml
# 原子变化点 → 设计要素的聚合影响映射
# element_id 必须为 element-type-registry.yaml 中已有的 id
#
# impact_level：
#   certain     - 一定影响，必须执行
#   likely      - 通常影响，默认执行（用户可跳过）
#   conditional - 条件影响，根据 condition 判断或交由用户决定
#
# 映射来源：TDD 高阶 §6 映射表聚合到设计要素粒度

change_element_mappings:

  # ─── IA 类 ────────────────────────────────────
  - change_id: "IA-01"
    affects:
      - element_id: "data-model"
        impact_level: "certain"
        reason: "新实体 → 新物理表/缓存/状态机"
      - element_id: "api-contract"
        impact_level: "certain"
        reason: "新实体通常需 CRUD 接口"
      - element_id: "backend-impl"
        impact_level: "certain"
        reason: "新 Entity/DTO/VO 类 + 业务逻辑"
      - element_id: "config"
        impact_level: "conditional"
        condition: "若实体含枚举属性需数据字典"
      - element_id: "frontend"
        impact_level: "conditional"
        condition: "若新实体有对应管理页面"

  - change_id: "IA-02"
    affects:
      - element_id: "data-model"
        impact_level: "certain"
        reason: "字段增减直接影响表结构/缓存"
      - element_id: "backend-impl"
        impact_level: "likely"
        reason: "Entity 类字段同步"
      - element_id: "api-contract"
        impact_level: "likely"
        reason: "接口入参出参可能变"
      - element_id: "config"
        impact_level: "conditional"
        condition: "若属性含枚举约束或缓存键变化"

  - change_id: "IA-03"
    affects:
      - element_id: "data-model"
        impact_level: "certain"
        reason: "外键/关联表/索引变更"
      - element_id: "backend-impl"
        impact_level: "certain"
        reason: "关联映射逻辑"
      - element_id: "api-contract"
        impact_level: "likely"
        reason: "关联查询接口"

  - change_id: "IA-04"
    affects:
      - element_id: "data-model"
        impact_level: "certain"
        reason: "状态机定义直接变更"
      - element_id: "backend-impl"
        impact_level: "certain"
        reason: "状态流转逻辑 + 时序变化"

  - change_id: "IA-05"
    affects:
      - element_id: "config"
        impact_level: "certain"
        reason: "字典键值映射直接变更"
      - element_id: "data-model"
        impact_level: "likely"
        reason: "字段约束调整"
      - element_id: "backend-impl"
        impact_level: "likely"
        reason: "枚举类定义"

  # ─── FS 类 ────────────────────────────────────
  - change_id: "FS-01"
    affects:
      - element_id: "api-contract"
        impact_level: "certain"
        reason: "新特性需新接口"
      - element_id: "backend-impl"
        impact_level: "certain"
        reason: "新业务逻辑类"
      - element_id: "frontend"
        impact_level: "likely"
        reason: "新特性通常对应新页面"
      - element_id: "config"
        impact_level: "likely"
        reason: "新特性需权限配置"

  - change_id: "FS-02"
    affects:
      - element_id: "backend-impl"
        impact_level: "certain"
        reason: "业务规则逻辑实现"
      - element_id: "api-contract"
        impact_level: "likely"
        reason: "规则变化可能影响接口校验"
      - element_id: "config"
        impact_level: "conditional"
        condition: "若规则阈值可配置化"

  - change_id: "FS-03"
    affects:
      - element_id: "frontend"
        impact_level: "certain"
        reason: "交互流程直接变更"
      - element_id: "api-contract"
        impact_level: "likely"
        reason: "操作触发的后端接口"
      - element_id: "backend-impl"
        impact_level: "likely"
        reason: "操作逻辑实现"

  - change_id: "FS-04"
    affects:
      - element_id: "backend-impl"
        impact_level: "certain"
        reason: "导出方案直接变更"
      - element_id: "api-contract"
        impact_level: "certain"
        reason: "导出接口定义"
      - element_id: "integration"
        impact_level: "conditional"
        condition: "若异步导出需通知下发"

  - change_id: "FS-05"
    affects:
      - element_id: "backend-impl"
        impact_level: "certain"
        reason: "定时任务/自动逻辑"
      - element_id: "config"
        impact_level: "likely"
        reason: "任务配置项"
      - element_id: "integration"
        impact_level: "conditional"
        condition: "若任务涉及异步消息"

  - change_id: "FS-06"
    affects:
      - element_id: "integration"
        impact_level: "certain"
        reason: "通知渠道与文案直接变更"
      - element_id: "config"
        impact_level: "conditional"
        condition: "若通知频控可配置"

  # ─── UP 类 ────────────────────────────────────
  - change_id: "UP-01"
    affects:
      - element_id: "frontend"
        impact_level: "certain"
        reason: "页面清单/组件/交互直接变更"
      - element_id: "api-contract"
        impact_level: "likely"
        reason: "页面对应后端接口"
      - element_id: "config"
        impact_level: "likely"
        reason: "页面菜单权限"

  - change_id: "UP-02"
    affects:
      - element_id: "frontend"
        impact_level: "certain"
        reason: "布局结构变更"
      - element_id: "api-contract"
        impact_level: "conditional"
        condition: "若字段增减影响接口参数"

  - change_id: "UP-03"
    affects:
      - element_id: "frontend"
        impact_level: "certain"
        reason: "交互流程直接变更"

  - change_id: "UP-04"
    affects:
      - element_id: "frontend"
        impact_level: "certain"
        reason: "菜单路由配置"
      - element_id: "config"
        impact_level: "certain"
        reason: "菜单可见性权限"

  - change_id: "UP-05"
    affects:
      - element_id: "frontend"
        impact_level: "certain"
        reason: "兼容性设计变更"

  # ─── PD 类 ────────────────────────────────────
  - change_id: "PD-01"
    affects:
      - element_id: "config"
        impact_level: "certain"
        reason: "角色清单/权限矩阵直接变更"
      - element_id: "backend-impl"
        impact_level: "conditional"
        condition: "若涉及数据权限逻辑实现"

  - change_id: "PD-02"
    affects:
      - element_id: "config"
        impact_level: "certain"
        reason: "功能权限矩阵直接变更"
      - element_id: "api-contract"
        impact_level: "likely"
        reason: "接口鉴权注解"
      - element_id: "frontend"
        impact_level: "likely"
        reason: "菜单/按钮可见性"

  - change_id: "PD-03"
    affects:
      - element_id: "config"
        impact_level: "certain"
        reason: "数据权限矩阵直接变更"
      - element_id: "backend-impl"
        impact_level: "likely"
        reason: "数据权限过滤逻辑"

  # ─── ID 类 ────────────────────────────────────
  - change_id: "ID-01"
    affects:
      - element_id: "integration"
        impact_level: "certain"
        reason: "外部服务依赖清单直接变更"
      - element_id: "architecture"
        impact_level: "likely"
        reason: "系统边界调整"
      - element_id: "backend-impl"
        impact_level: "likely"
        reason: "新增外部调用链路时序"

  - change_id: "ID-02"
    affects:
      - element_id: "integration"
        impact_level: "certain"
        reason: "集成方式调整"
      - element_id: "backend-impl"
        impact_level: "conditional"
        condition: "若涉及跨系统一致性"

  - change_id: "ID-03"
    affects:
      - element_id: "integration"
        impact_level: "certain"
        reason: "接口契约变更"
      - element_id: "api-contract"
        impact_level: "conditional"
        condition: "若内部适配接口需同步调整"

  # ─── SS 类 ────────────────────────────────────
  - change_id: "SS-01"
    affects:
      - element_id: "backend-impl"
        impact_level: "certain"
        reason: "时序图/场景逻辑直接变更"
      - element_id: "integration"
        impact_level: "conditional"
        condition: "若场景含异步触发事件"

  - change_id: "SS-02"
    affects:
      - element_id: "api-contract"
        impact_level: "certain"
        reason: "错误码体系变更"
      - element_id: "backend-impl"
        impact_level: "certain"
        reason: "异常分支时序"
      - element_id: "integration"
        impact_level: "conditional"
        condition: "若涉及降级策略"

  - change_id: "SS-03"
    affects:
      - element_id: "backend-impl"
        impact_level: "certain"
        reason: "审批流程定义直接变更"
      - element_id: "integration"
        impact_level: "likely"
        reason: "审批通知"
      - element_id: "config"
        impact_level: "likely"
        reason: "审批角色权限"

  # ─── NF 类 ────────────────────────────────────
  - change_id: "NF-01"
    affects:
      - element_id: "config"
        impact_level: "certain"
        reason: "性能指标直接变更"
      - element_id: "data-model"
        impact_level: "likely"
        reason: "缓存策略调整"
      - element_id: "architecture"
        impact_level: "conditional"
        condition: "若需引入新中间件"

  - change_id: "NF-02"
    affects:
      - element_id: "config"
        impact_level: "certain"
        reason: "安全策略直接变更"
      - element_id: "architecture"
        impact_level: "conditional"
        condition: "若需新增安全组件"

  - change_id: "NF-03"
    affects:
      - element_id: "config"
        impact_level: "certain"
        reason: "可用性指标直接变更"
      - element_id: "architecture"
        impact_level: "conditional"
        condition: "若 SLA 变更导致部署架构调整"

  - change_id: "NF-04"
    affects:
      - element_id: "frontend"
        impact_level: "likely"
        reason: "页面布局/交互流程可能需要优化"

  - change_id: "NF-05"
    affects:
      - element_id: "frontend"
        impact_level: "certain"
        reason: "埋点触发点与交互流程绑定"
      - element_id: "api-contract"
        impact_level: "conditional"
        condition: "若埋点数据需上报后端"

  # ─── AA 类 ────────────────────────────────────
  - change_id: "AA-01"
    affects:
      - element_id: "architecture"
        impact_level: "certain"
        reason: "服务边界划分直接变更"
      - element_id: "integration"
        impact_level: "conditional"
        condition: "若架构变更影响系统依赖"

  - change_id: "AA-02"
    affects:
      - element_id: "architecture"
        impact_level: "likely"
        reason: "特性分类可能影响服务划分"
      - element_id: "api-contract"
        impact_level: "likely"
        reason: "接口路径可能随特性编号调整"
      - element_id: "config"
        impact_level: "likely"
        reason: "权限矩阵按特性清单组织"

  # ─── CF 类 ────────────────────────────────────
  - change_id: "CF-01"
    affects:
      - element_id: "config"
        impact_level: "certain"
        reason: "配置项清单直接变更"
      - element_id: "backend-impl"
        impact_level: "likely"
        reason: "配置读取逻辑"
      - element_id: "api-contract"
        impact_level: "conditional"
        condition: "若配置项需通过接口管理"
      - element_id: "frontend"
        impact_level: "conditional"
        condition: "若需前端配置管理页面"

  - change_id: "CF-02"
    affects:
      - element_id: "config"
        impact_level: "certain"
        reason: "IT 配置项清单直接变更"
      - element_id: "architecture"
        impact_level: "conditional"
        condition: "若涉及部署级配置"

  # ─── PP 类 ────────────────────────────────────
  - change_id: "PP-01"
    affects:
      - element_id: "architecture"
        impact_level: "conditional"
        condition: "若范围扩大导致新增微服务"
      - element_id: "config"
        impact_level: "conditional"
        condition: "若成功标准变化影响性能/安全目标"
```

### registry/atomic-change-registry.yaml

```yaml
# atomic-change-registry.yaml
# 由 orchestration/o-design-incremental-build.md 在变化点识别阶段读取
# 来源：TDD 增量高阶方案 V1.0 第五章
#
# PRD 要素域分类（10 类）：
# IA - 信息架构 (Info Architecture)
# FS - 功能特性 (Feature Spec)
# UP - 界面原型 (UI Prototype)
# PD - 权限设计 (Permission Design)
# ID - 集成设计 (Integration Design)
# SS - 场景方案 (Scenario Solution)
# NF - 非功能需求 (Non-Functional)
# AA - 应用架构 (App Architecture)
# CF - 配置设计 (Config Design)
# PP - 定位与目标 (Product Positioning)
#
# ─── PRD 子要素覆盖说明（来源：TDD 高阶 §5.11）─────────────
# 本清单仅列出能独立触发设计变更的子要素作为原子变化点。
# 以下 PRD 子要素的变更通常是上游变化点的连带结果（cascade），
# 不作为独立变化点，而是在要素循环中作为上下文参考：
#
#   功能特性.实体操作说明       → cascade←IA-01/IA-02 或 FS-01
#   功能特性.验收标准           → cascade←FS-02/FS-03
#   信息架构.数据样例           → cascade←IA-02（Step 6 中作为验证参考）
#   信息架构.历史数据切换       → cascade←IA 类（AP 类型场景专属）
#   场景解决方案.解决方案集成图 → cascade←SS-01（随场景清单连带重绘）
#   Story设计                   → 输入层，通过 PrdChange 登记引用，非独立变化点
#
# 完整的 PRD 子要素 → 原子变化点对照关系见 TDD 高阶方案 §5.11 表格。

atomic_changes:

  # ─── IA 类（信息架构变更，5 个）────────────────
  - id: "IA-01"
    name: "新增/删除实体"
    category: "IA"
    prd_element: "info-architecture"
    description_zh: "PRD 信息架构新增或删除业务对象"
    detection_keywords:
      - "DELTA"
      - "info-architecture"
      - "op=add"
      - "op=delete"
      - "实体清单变化"
      - "新增实体"
      - "删除实体"
    examples:
      - "增量 PRD 新增 Supplier 实体"
    status: "active"

  - id: "IA-02"
    name: "实体属性变更"
    category: "IA"
    prd_element: "info-architecture"
    description_zh: "PRD 信息架构中已有实体的属性增加、修改或删除"
    detection_keywords:
      - "info-architecture"
      - "实体详情表字段"
      - "字段增减"
      - "属性新增"
      - "属性修改"
    examples:
      - "PurchaseOrder 实体新增 supplier_code 字段"
    status: "active"

  - id: "IA-03"
    name: "实体关系变更"
    category: "IA"
    prd_element: "info-architecture"
    description_zh: "PRD 信息架构中实体间关联关系调整"
    detection_keywords:
      - "info-architecture"
      - "ER 图变化"
      - "外键标注变化"
      - "关联关系调整"
    examples:
      - "User 与 Role 从一对多改为多对多"
    status: "active"

  - id: "IA-04"
    name: "实体状态流转变更"
    category: "IA"
    prd_element: "info-architecture"
    description_zh: "PRD 信息架构中实体状态机调整"
    detection_keywords:
      - "info-architecture"
      - "状态流转图变化"
      - "新增状态"
      - "状态机调整"
    examples:
      - "Order 新增'待发货'状态节点"
    status: "active"

  - id: "IA-05"
    name: "属性约束/枚举值变更"
    category: "IA"
    prd_element: "info-architecture"
    description_zh: "PRD 信息架构中实体属性的约束条件或枚举值域调整"
    detection_keywords:
      - "info-architecture"
      - "属性约束"
      - "枚举值"
      - "值域调整"
    examples:
      - "优先级字段从 2 个枚举值扩展为 4 个"
    status: "active"

  # ─── FS 类（功能特性变更，6 个）────────────────
  - id: "FS-01"
    name: "子特性新增/删除"
    category: "FS"
    prd_element: "feature-spec"
    description_zh: "PRD 功能特性新增或删除子特性"
    detection_keywords:
      - "feature-spec"
      - "op=add"
      - "op=delete"
      - "FR 编号变化"
      - "新增子特性"
    examples:
      - "新增 FR-01-03-002 供应商指定子特性"
    status: "active"

  - id: "FS-02"
    name: "业务规则变更"
    category: "FS"
    prd_element: "feature-spec"
    description_zh: "PRD 功能特性中业务规则新增或修改"
    detection_keywords:
      - "feature-spec"
      - "业务规则"
      - "规则变化"
      - "阈值"
    examples:
      - "审批金额阈值从 5 万改为 10 万"
    status: "active"

  - id: "FS-03"
    name: "UIUX 操作说明变更"
    category: "FS"
    prd_element: "feature-spec"
    description_zh: "PRD 功能特性中操作步骤、触发动作调整"
    detection_keywords:
      - "feature-spec"
      - "UIUX 操作说明"
      - "操作步骤"
      - "触发动作"
    examples:
      - "提交操作增加二次确认弹窗"
    status: "active"

  - id: "FS-04"
    name: "导出/报表功能变更"
    category: "FS"
    prd_element: "feature-spec"
    description_zh: "PRD 功能特性中导出类子特性新增或修改"
    detection_keywords:
      - "feature-spec"
      - "导出"
      - "报表"
      - "批量导出"
    examples:
      - "新增采购单批量导出功能"
    status: "active"

  - id: "FS-05"
    name: "系统自动触发功能变更"
    category: "FS"
    prd_element: "feature-spec"
    description_zh: "PRD 功能特性中定时/自动执行的子特性新增或修改"
    detection_keywords:
      - "feature-spec"
      - "自动"
      - "定时"
      - "超时"
      - "触发"
    examples:
      - "审批超时 24 小时自动转交"
    status: "active"

  - id: "FS-06"
    name: "知会/通知功能变更"
    category: "FS"
    prd_element: "feature-spec"
    description_zh: "PRD 功能特性中消息通知类子特性新增或修改"
    detection_keywords:
      - "feature-spec"
      - "通知"
      - "知会"
      - "提醒"
      - "邮件"
    examples:
      - "审批通过后邮件通知申请人"
    status: "active"

  # ─── UP 类（界面原型变更，5 个）────────────────
  - id: "UP-01"
    name: "页面新增/删除"
    category: "UP"
    prd_element: "ui-prototype"
    description_zh: "PRD 界面原型中页面清单增加或删除"
    detection_keywords:
      - "ui-prototype"
      - "页面清单"
      - "PAGE 编号变化"
      - "新增页面"
    examples:
      - "新增供应商指定弹窗页面 PAGE-005"
    status: "active"

  - id: "UP-02"
    name: "页面字段/布局调整"
    category: "UP"
    prd_element: "ui-prototype"
    description_zh: "PRD 界面原型中已有页面的字段、列、布局变更"
    detection_keywords:
      - "ui-prototype"
      - "页面规格"
      - "字段增减"
      - "布局调整"
    examples:
      - "列表页新增'创建人部门'列"
    status: "active"

  - id: "UP-03"
    name: "交互原型/Pageflow 变更"
    category: "UP"
    prd_element: "ui-prototype"
    description_zh: "PRD 界面原型中页面间跳转关系或交互逻辑调整"
    detection_keywords:
      - "ui-prototype"
      - "Pageflow"
      - "页面跳转"
      - "交互原型"
    examples:
      - "提交后跳转路径由列表改为详情页"
    status: "active"

  - id: "UP-04"
    name: "菜单变更"
    category: "UP"
    prd_element: "ui-prototype"
    description_zh: "PRD 界面原型中菜单结构调整"
    detection_keywords:
      - "ui-prototype"
      - "菜单项增减"
      - "菜单变更"
    examples:
      - "二级菜单新增'供应商管理'"
    status: "active"

  - id: "UP-05"
    name: "兼容性设计变更"
    category: "UP"
    prd_element: "ui-prototype"
    description_zh: "PRD 界面原型中浏览器支持、分辨率、响应式设计要求调整"
    detection_keywords:
      - "ui-prototype"
      - "兼容性设计"
      - "响应式"
      - "移动端"
    examples:
      - "新增移动端适配要求"
    status: "active"

  # ─── PD 类（权限设计变更，3 个）────────────────
  - id: "PD-01"
    name: "角色定义变更"
    category: "PD"
    prd_element: "permission-design"
    description_zh: "PRD 权限设计中角色新增、删除或职责调整"
    detection_keywords:
      - "permission-design"
      - "角色清单变化"
      - "新增角色"
    examples:
      - "新增'供应商管理员'角色"
    status: "active"

  - id: "PD-02"
    name: "功能权限变更"
    category: "PD"
    prd_element: "permission-design"
    description_zh: "PRD 权限设计中按钮/菜单权限矩阵调整"
    detection_keywords:
      - "permission-design"
      - "功能权限矩阵"
      - "权限行列变化"
    examples:
      - "'指定供应商'按钮仅采购员可见"
    status: "active"

  - id: "PD-03"
    name: "数据权限/敏感数据变更"
    category: "PD"
    prd_element: "permission-design"
    description_zh: "PRD 权限设计中数据可见范围或敏感字段标注调整"
    detection_keywords:
      - "permission-design"
      - "数据权限"
      - "敏感数据"
      - "数据可见范围"
    examples:
      - "部门主管可查看全部门数据"
    status: "active"

  # ─── ID 类（集成设计变更，3 个）────────────────
  - id: "ID-01"
    name: "外部系统新增/删除"
    category: "ID"
    prd_element: "integration-design"
    description_zh: "PRD 集成设计中外部系统依赖新增或删除"
    detection_keywords:
      - "integration-design"
      - "外部系统清单变化"
      - "新增对接"
    examples:
      - "新增与 SAP 系统的对接"
    status: "active"

  - id: "ID-02"
    name: "集成点新增/修改"
    category: "ID"
    prd_element: "integration-design"
    description_zh: "PRD 集成设计中集成点的同步/异步方式调整"
    detection_keywords:
      - "integration-design"
      - "集成点变化"
      - "同步改异步"
    examples:
      - "订单同步从实时 API 改为 MQ 异步"
    status: "active"

  - id: "ID-03"
    name: "集成接口规范变更"
    category: "ID"
    prd_element: "integration-design"
    description_zh: "PRD 集成设计中接口入参、出参、协议调整"
    detection_keywords:
      - "integration-design"
      - "接口规范变化"
      - "入参出参"
    examples:
      - "订单接口新增'渠道来源'入参"
    status: "active"

  # ─── SS 类（场景方案变更，3 个）────────────────
  - id: "SS-01"
    name: "场景新增/删除/流转变更"
    category: "SS"
    prd_element: "scenario-solution"
    description_zh: "PRD 场景解决方案中场景清单变化或场景串联路径调整"
    detection_keywords:
      - "scenario-solution"
      - "场景清单"
      - "解决方案集成图"
      - "场景串联"
    examples:
      - "新增'供应商指定'场景串联"
    status: "active"

  - id: "SS-02"
    name: "异常场景/处理策略变更"
    category: "SS"
    prd_element: "scenario-solution"
    description_zh: "PRD 场景解决方案中异常分支或异常处理策略调整"
    detection_keywords:
      - "scenario-solution"
      - "异常场景"
      - "异常处理"
      - "降级"
    examples:
      - "外部服务失败从阻断改为降级"
    status: "active"

  - id: "SS-03"
    name: "审批场景变更"
    category: "SS"
    prd_element: "scenario-solution"
    description_zh: "PRD 场景解决方案中审批类场景流程或角色调整"
    detection_keywords:
      - "scenario-solution"
      - "审批场景"
      - "审批流"
    examples:
      - "审批流增加'部门预审'节点"
    status: "active"

  # ─── NF 类（非功能需求变更，5 个）───────────────
  - id: "NF-01"
    name: "性能要求变更"
    category: "NF"
    prd_element: "nfr"
    description_zh: "PRD 非功能需求中响应时间、并发、吞吐等指标调整"
    detection_keywords: ["nfr", "性能", "响应时间", "并发"]
    examples: ["响应时间从 3 秒收紧到 1 秒"]
    status: "active"

  - id: "NF-02"
    name: "安全隐私要求变更"
    category: "NF"
    prd_element: "nfr"
    description_zh: "PRD 非功能需求中加密、脱敏、隐私保护、合规要求调整"
    detection_keywords: ["nfr", "安全隐私", "加密", "脱敏", "GDPR"]
    examples: ["新增 GDPR 合规要求、手机号脱敏"]
    status: "active"

  - id: "NF-03"
    name: "可用性/可维护性变更"
    category: "NF"
    prd_element: "nfr"
    description_zh: "PRD 非功能需求中 SLA / RTO / RPO / 日志规范 / 监控指标调整"
    detection_keywords: ["nfr", "可用性", "SLA", "RTO", "RPO"]
    examples: ["可用性从 99.9% 提升到 99.99%"]
    status: "active"

  - id: "NF-04"
    name: "易用性要求变更"
    category: "NF"
    prd_element: "nfr"
    description_zh: "PRD 非功能需求中操作步骤、错误提示、界面交互易用性指标调整"
    detection_keywords: ["nfr", "易用性", "操作步骤"]
    examples: ["关键操作流程步骤不超过 5 步"]
    status: "active"

  - id: "NF-05"
    name: "埋点要求变更"
    category: "NF"
    prd_element: "nfr"
    description_zh: "PRD 非功能需求中新增或调整页面/操作埋点"
    detection_keywords: ["nfr", "埋点", "埋点设计"]
    examples: ["新增订单提交按钮点击埋点"]
    status: "active"

  # ─── AA 类（应用架构变更，2 个）────────────────
  - id: "AA-01"
    name: "应用架构图/系统边界变更"
    category: "AA"
    prd_element: "app-architecture"
    description_zh: "PRD 应用架构图中模块划分或外部系统依赖关系调整"
    detection_keywords: ["app-architecture", "架构图", "系统边界"]
    examples: ["架构图新增 SAP 系统依赖节点"]
    status: "active"

  - id: "AA-02"
    name: "特性分类/特性层级变更"
    category: "AA"
    prd_element: "app-architecture"
    description_zh: "PRD 应用架构中特性分类、特性、子特性的层级结构或编号体系调整"
    detection_keywords: ["app-architecture", "子特性清单", "特性分类"]
    examples: ["新增'供应商管理'特性分类，下辖 2 个子特性"]
    status: "active"

  # ─── CF 类（配置设计变更，2 个）────────────────
  - id: "CF-01"
    name: "用户配置项变更"
    category: "CF"
    prd_element: "config-design"
    description_zh: "PRD 配置设计中业务可配置项新增或修改"
    detection_keywords: ["config-design", "用户配置项"]
    examples: ["审批金额阈值改为用户可配置"]
    status: "active"

  - id: "CF-02"
    name: "IT 管理配置项变更"
    category: "CF"
    prd_element: "config-design"
    description_zh: "PRD 配置设计中 IT 运维配置项新增或修改"
    detection_keywords: ["config-design", "IT管理配置项"]
    examples: ["新增系统超时时间配置项"]
    status: "active"

  # ─── PP 类（定位与目标变更，1 个）───────────────
  - id: "PP-01"
    name: "产品目标/范围变更"
    category: "PP"
    prd_element: "product-positioning"
    description_zh: "PRD 定位与目标中产品范围边界、成功标准或灰度策略调整"
    detection_keywords: ["product-positioning", "范围和边界", "产品目标"]
    examples: ["产品范围新增'供应商管理'子领域"]
    status: "active"
```

### registry/dependency-graph.yaml

```yaml
impact_edges:
  - source: "architecture"
    targets:
      - element: "data-model"
        impact_type: "direct"
        reason: "逻辑架构直接影响存储与分库分表策略"
      - element: "integration"
        impact_type: "direct"
        reason: "部署与调用链决定集成拓扑"
      - element: "backend-impl"
        impact_type: "indirect"
        reason: "技术栈变更可能影响分层约定"
      - element: "config"
        impact_type: "indirect"
        reason: "中间件选型决定公共组件实现"

  - source: "data-model"
    targets:
      - element: "api-contract"
        impact_type: "direct"
        reason: "资源与实体决定 API 模型"
      - element: "backend-impl"
        impact_type: "direct"
        reason: "持久化与状态机约束业务实现"
      - element: "config"
        impact_type: "indirect"
        reason: "字段约束/枚举影响数据字典"

  - source: "api-contract"
    targets:
      - element: "backend-impl"
        impact_type: "direct"
        reason: "契约是服务实现的约束"
      - element: "frontend"
        impact_type: "direct"
        reason: "前端依赖 API 与错误码约定"
      - element: "config"
        impact_type: "indirect"
        reason: "鉴权/幂等等可能影响配置项"

  - source: "backend-impl"
    targets:
      - element: "integration"
        impact_type: "direct"
        reason: "业务编排驱动异步与外部调用"
      - element: "api-contract"
        impact_type: "indirect"
        reason: "实现细节可能反向推导接口调整"

  - source: "integration"
    targets:
      - element: "backend-impl"
        impact_type: "indirect"
        reason: "MQ/外部服务变化可能影响业务时序"
      - element: "config"
        impact_type: "indirect"
        reason: "集成配置项变化"

  - source: "config"
    targets:
      - element: "frontend"
        impact_type: "indirect"
        reason: "字典、权限与开关影响前端行为"
      - element: "api-contract"
        impact_type: "indirect"
        reason: "权限变更可能需要在 API 上增加鉴权注解"

  - source: "frontend"
    targets:
      - element: "config"
        impact_type: "indirect"
        reason: "页面菜单资源变更需同步权限矩阵"
```

### registry/input-type-registry.yaml

```yaml
# input-type-registry.yaml
# 职责：影响「设计」场景路由的核心输入变量；检测细则由执行侧结合 workspace 实际落地。
# workflow-engine 的 Input Inventory 应遍历本列表中的每一项并输出布尔结果。

input_types:

  - id: "PRD_DOC_COMPLETED"
    name: "可用于设计的已完成 PRD"
    detection: |
      存在 {DESIGN_DIR}/prd.md
      AND（建议）frontmatter.status == "completed" 或内容已冻结可视为设计基线
      DESIGN_DIR 解析规则见本 Skill `SKILL.md` 「工作区与业务变量」表；FEATURE_SUBDIR / legacy 以团队工作区约定为准。
    provision_guide: "请在特性的 design 目录下提供 prd.md，或明确 feature 子目录与版本。"
    description: "新建或增量设计的主输入。"

  - id: "PRD_DOC_ANY"
    name: "PRD 草稿（任意状态）"
    detection: |
      存在 {DESIGN_DIR}/prd.md（不强制 completed）
    provision_guide: "PRD 尚未定稿时仅可作有限上下文，关键结论需用户确认。"
    description: "续作或评审场景的辅助匹配。"

  - id: "DESIGN_DOC_INPROGRESS"
    name: "进行中的设计交付（断点续作）"
    detection: |
      以下任一：
      - {DESIGN_DIR}/design.md 存在且 frontmatter.status == "in_progress"
      - workspace/ongoing.md 中记录 current_design_path 且指向未完成设计主文件
    provision_guide: "可直接选择「继续设计」以续接上次进度。"
    description: "design-resume workflow 的关键判据。"

  - id: "DESIGN_HISTORICAL"
    name: "既有设计基线（已完成）"
    detection: |
      当前项目 project_name 下，存在历史版本或当前版本特性目录中已完成的
      design.md（或团队约定的其它已完成设计主文件）
      AND 可作为增量/对照基线（completed 或由用户声明）
      AND 基线目录可解析出与 config.yaml → design_artifacts 对齐的一套文件
    provision_guide: "说明要对哪一版设计做增量或对比。"
    description: "增量/更新场景的基线设计输入。"

  - id: "INCR_PRD_DOC"
    name: "含 DELTA 标注的增量 PRD"
    detection: |
      存在 {DESIGN_DIR}/prd.md
      AND 以下任一成立：
        - prd.md 正文含 <!-- DELTA: ... --> 锚点注释
        - prd.md frontmatter 含 incremental: true
        - prd.md frontmatter 含 prd_change_register 字段
        - prd.md frontmatter 含 impact_analysis.impact_points
    provision_guide: "请提供含 DELTA 标注或 impact_analysis 的增量 PRD 文件。"
    description: "design-incremental-build 的推荐输入，提供结构化变更信息可加速 ChangeRouter。"

  - id: "REVIEW_COMMENTS"
    name: "评审意见"
    detection: |
      用户输入含章节指向 + 修改语义，或文档含 ==高亮==[^n] 脚注类标注。
    provision_guide: "直接描述修改点或提供带标注的评审文档。"
    description: "design-review-modify 的必要输入。"
```

### registry/spec-template-registry.yaml

```yaml
spec_templates:
  - implements: "architecture"
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-design-architecture.md"
    status: "active"

  - implements: "data-model"
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-design-data.md"
    status: "active"

  - implements: "api-contract"
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-design-api.md"
    status: "active"

  - implements: "backend-impl"
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-design-backend.md"
    status: "active"

  - implements: "integration"
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-design-integration.md"
    status: "active"

  - implements: "config"
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-design-config.md"
    status: "active"

  - implements: "frontend"
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-design-frontend.md"
    status: "active"

  - implements: "design-summary-merge"
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-design-summary-merge.md"
    status: "active"

  - implements: "us-design-linkback"
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["build", "modify", "incremental"]
    spec_file: "spec/m-us-design-linkback.md"
    status: "active"

  - implements: "knowledge-exploration"
    for_type: ["TP", "AP", "AI"]
    execution_mode: ["incremental"]
    spec_file: "spec/m-design-knowledge-exploration.md"
    status: "active"
```

### registry/standards-registry.yaml

```yaml
# standards-registry.yaml
# 职责：登记本 Skill 可用规范；element-runner Phase 3 按 spec 表格中的 standard_id 加载。
# file 路径相对于 ia-prd-to-design-new 根目录。
# 约定：与 spec/m-design-*.md 同粒度合并，避免一个设计域多个并列 standard 文件。

standards:
  - id: "app-arch"
    name: "应用架构图规范"
    type: "builtin"
    file: "../ia-fe-to-prd/standards/app-arch-standard.md"
    description: "Mermaid 架构图与分层节点命名（extend 引用的共享规范文件）。"

  - id: "er-diagram"
    name: "ER 图规范"
    type: "builtin"
    file: "../ia-fe-to-prd/standards/er-diagram-standard.md"
    description: "erDiagram 语法与关联约束（extend 引用的共享规范文件）。"

  - id: "design-architecture"
    name: "顶层架构（合并）"
    type: "builtin"
    file: "standards/design-architecture-standard.md"
    description: "技术栈、分层、部署、微服务、特性开关；与 m-design-architecture 对齐。"

  - id: "design-data"
    name: "数据与存储（合并）"
    type: "builtin"
    file: "standards/design-data-standard.md"
    description: "物理表、缓存、状态机；与 m-design-data 对齐。"

  - id: "design-api-contract"
    name: "后端接口契约（合并）"
    type: "builtin"
    file: "standards/design-api-contract-standard.md"
    description: "REST、错误码、权限（契约侧）；与 m-design-api 对齐。"

  - id: "design-backend"
    name: "后端实现（合并）"
    type: "builtin"
    file: "standards/design-backend-standard.md"
    description: "分层、类设计、时序、横切模式、外部韧性；与 m-design-backend 对齐。"

  - id: "design-integration"
    name: "集成与异步（合并）"
    type: "builtin"
    file: "standards/design-integration-standard.md"
    description: "MQ、外部依赖、通知；与 m-design-integration 对齐。"

  - id: "design-config"
    name: "配置与安全（合并）"
    type: "builtin"
    file: "standards/design-config-standard.md"
    description: "配置分层、Lookup、字典编码、权限矩阵、错误码、DFX；与 m-design-config 对齐。"

  - id: "design-frontend"
    name: "前端方案（合并）"
    type: "builtin"
    file: "standards/design-frontend-standard.md"
    description: "组件拆分、路由与交互；与 m-design-frontend 对齐。"
```

### registry/workflow-registry.yaml

```yaml
workflows:
  - id: "design-resume"
    name: "设计续接恢复"
    priority: 100
    input_signature:
      required:
        - id: "DESIGN_DOC_INPROGRESS"
          reason: "存在未完成的设计主产物（design 域）。"
      excluded: []
      optional:
        - id: "PRD_DOC_ANY"
          reason: "可选：prd.md 仅作需求侧参考，辅助续写设计。"
    trigger_keywords: ["继续设计", "resume", "从上次继续", "接着写设计", "断点续作", "接着做"]
    orchestration_file: "orchestration/o-design-resume.md"
    resume_mode: true
    element_sequence: []
    status: "active"

  - id: "design-review-modify"
    name: "设计评审修改"
    priority: 80
    input_signature:
      required:
        - id: "DESIGN_HISTORICAL"
          reason: "修改对象是已完成态的设计基线（design.md）。"
        - id: "REVIEW_COMMENTS"
          reason: "必须有评审意见（文字描述或带标注文档均可，o-design-review-modify 内部区分）。"
      excluded:
        - id: "DESIGN_DOC_INPROGRESS"
          reason: "存在进行中设计时优先走续接恢复。"
      optional:
        - id: "PRD_DOC_ANY"
          reason: "可选：PRD 仅作需求对照参考。"
    trigger_keywords: ["评审修改设计", "根据评审意见", "按意见改设计", "修改设计文档", "按意见改", "有评审标注", "改 backend-api", "改设计文档"]
    orchestration_file: "orchestration/o-design-review-modify.md"
    element_sequence: []
    status: "active"

  - id: "design-incremental-build"
    name: "设计增量/更新"
    priority: 60
    input_signature:
      required:
        - id: "DESIGN_HISTORICAL"
          reason: "必须有已完成设计基线（design.md 等）；增量更新以设计域历史交付为锚。"
      excluded:
        - id: "DESIGN_DOC_INPROGRESS"
          reason: "进行中则走续接恢复。"
        - id: "REVIEW_COMMENTS"
          reason: "存在评审意见时属于 design-review-modify 场景。"
      optional:
        - id: "PRD_DOC_ANY"
          reason: "推荐：prd.md 承载需求变更事实，供 ChangeRouter 对齐；PRD 为输入参考，非本阶段主交付。"
        - id: "PRD_DOC_COMPLETED"
          reason: "已定稿 PRD 可降低澄清成本。"
        - id: "INCR_PRD_DOC"
          reason: "含 DELTA / impact 元数据的 PRD 可加速变化点识别。"
    trigger_keywords: ["增量设计", "设计增量", "优化设计", "1-n", "在现有设计基础上", "update 设计", "DELTA", "影响域", "ChangeRouter", "PC-", "原子变化点"]
    orchestration_file: "orchestration/o-design-incremental-build.md"
    element_sequence: []
    status: "active"

  - id: "design-new-build"
    name: "从 PRD 新建完整技术设计"
    priority: 40
    input_signature:
      required:
        - id: "PRD_DOC_COMPLETED"
          reason: "首版技术设计需以已定稿 PRD 为输入依据；产出为 design 域文件（design.md 等）。"
      excluded:
        - id: "DESIGN_HISTORICAL"
          reason: "若已有完成态设计基线，优先走设计增量/更新。"
        - id: "DESIGN_DOC_INPROGRESS"
          reason: "存在进行中设计时优先走续接恢复。"
        - id: "REVIEW_COMMENTS"
          reason: "存在评审意见时属于 design-review-modify 场景。"
      optional: []
    trigger_keywords: ["PRD转设计", "生成技术方案", "新建设计", "ia-prd-to-design-new", "产品方案转设计", "需求转设计", "创建设计", "全量设计", "完整设计"]
    orchestration_file: "orchestration/o-design-new-build.md"
    element_sequence: []
    status: "active"
```

---

## 【C】orchestration/

**文件列表：**

- o-design-incremental-build.md
- o-design-new-build.md
- o-design-resume.md
- o-design-review-modify.md

**build 类（仅列名，不贴正文）：**

- o-design-new-build.md
- o-design-resume.md
- o-design-review-modify.md

**含 incremental 的文件全文：**

### orchestration/o-design-incremental-build.md

```markdown
# 设计增量/更新 编排文件
# workflow_id: design-incremental-build
# 对应 workflow-registry 中 id: design-incremental-build
# 嵌入 TDD 高阶方案七步同构逻辑（v2.0.0）

## 前置说明
本编排文件由 workflow-engine 在命中 design-incremental-build 后调用。
在已有设计基线（DESIGN_HISTORICAL）上，通过 PRD 变更结构化路由（ChangeRouter），
基于 34 类原子变化点精确识别受影响设计要素，生成 DIP 影响点与 DELTA 增量标注。
实际要素内容生成完全交由 element-runner 执行，本文件只控制宏观流程。

## ⚠️ 多文件输出约定
本编排执行期间，每个要素对应 config.yaml → design_artifacts 中声明的主交付文件。
所有要素执行结果由 element-runner Phase 6 写入对应的输出文档。

---

## 强制读取

1. 本 Skill 根目录 `config.yaml`（含 `design_artifacts` 文件名映射、`extension_registry` 挂载点）
2. 本 Skill `SKILL.md` 中 **路径约定**（`WORKSPACE_ROOT`、`DESIGN_DIR`、`BASELINE_DESIGN_DIR`、`INCR_PRD_FILE`、`LEGACY_CONTEXT`、`DESIGN_ACCUM_FILE` 等路径变量）
3. `{WORKSPACE_ROOT}/workspace/ongoing.md`
4. `registry/atomic-change-registry.yaml`（34 个原子变化点定义）
5. `registry/change-element-mapping.yaml`（变化点 → 设计要素聚合映射）
6. `registry/dependency-graph.yaml`（`impact_edges` 用于安全网校验）
7. `registry/element-type-registry.yaml`（动态读取 chapter_info）
8. `engine/element-runner.md`（`incremental` 模式与 `context.base_doc_path` 约定）
9. `spec/m-design-knowledge-exploration.md`（现有知识库探索的步骤、产出结构与停止条件）
10. `spec/m-design-summary-merge.md`（全部要素完成后的特性级 `design.md` 汇总）

---

## 业务判定模型

本编排使用以下三维模型确定有效要素序列：

| 维度 | 取值 | 说明 |
|------|------|------|
| `MODE` | `new-incremental` / `update` | 与历史基线的关系 |
| `PROJECT_TYPE` | `TP` / `AP` / `AI` | 系统/能力类型 |
| `CHANGE_SCOPE` | `frontend` / `backend` / `fullstack` | 本次变更覆盖哪些层 |

禁止把 `PROJECT_TYPE` 当作前后端覆盖范围的代理。`CHANGE_SCOPE` 在知识探索收敛前不得假定取值。

**工程结构**：默认兼容单工程与 `backend/` + `frontend/` 双工程目录。`CHANGE_SCOPE` 包含 `backend` 时优先检索后端工程上下文；包含 `frontend` 时优先检索前端工程上下文；`fullstack` 时两侧均须检索。

**执行画像**（知识探索完成后确定）：

```yaml
execution_profile:
  has_frontend: true | false
  has_backend: true | false
  backend_variant: standard | ap
  enable_ai: false
```

---

## Phase 0：解析上下文（TDD 高阶 Step 0 环境准备）

1. 解析路径变量（定义见 SKILL.md 路径约定）：`VERSION`、`FEATURE_SUBDIR`、`DESIGN_DIR`、`PRD_FILE`、`STORY_FILE`、`DESIGN_ACCUM_FILE`。
2. **解析 `DESIGN_HISTORICAL`（即 `BASELINE_DESIGN_DIR`）**：确认基线目录、各要素主交付文件路径（与 `config.yaml` → `design_artifacts` 命名一致）；将基线路径记入编排上下文，供 Phase 3 绑定 `context.base_doc_path`。
3. **解析 `INCR_PRD_FILE`**：默认等同 `PRD_FILE`；若增量 PRD 独立文件，须在 ongoing.md 或用户指定中解析。
4. **解析 `LEGACY_CONTEXT`**：扫描存量系统信息路径列表（DDL / OpenAPI / 代码索引）；缺位时标记降级为对话挖掘。
5. **一致性校验**：确认 `BASELINE_DESIGN_DIR` 可解析出与 `config.yaml` → `design_artifacts` 对齐的一套文件。
6. 读取 `PRD_FILE`（及变更说明，若有）作为对齐输入；将路径记入 `context.input_doc_path`。
7. 若本轮 PRD 相对基线仅有局部变更说明，仍须以完整 `prd.md` 或可追溯的差异入口为准，避免遗漏依赖边。

---

## Phase 1：现有知识库探索（强制先于要素执行）

按 `spec/m-design-knowledge-exploration.md` 执行受限探索：

1. 产出 `{DESIGN_DIR}/shared-context.md`（章节结构与禁码、导航字段见 reference）。
2. **存量系统信息收录**（增量模式必检）：按 reference 中"存量系统信息收录"章节执行，存在则路径记入 shared-context 作为 `evidence_source=legacy_system` 的依据来源，不存在则记录"存量信息缺位"标志。
3. **在探索收敛前不得假定 `CHANGE_SCOPE`**；依据 PRD 明文、`decision_facts` 与双工程检索结论确定 `CHANGE_SCOPE`，并与上述执行画像对齐。
4. 若 reference 规定的状态为需用户澄清（`NEEDS_USER_CLARIFICATION`），先完成澄清与回填，再进入后续 Phase。
5. 将 `shared-context.md` 路径作为下游共有输入保存在编排上下文。

---

## Phase 1.0：PRD 变更识别与原子变化点提取（TDD 高阶 Step 1）

**输入**：增量 PRD 文档（`INCR_PRD_FILE`）或简单需求描述

**输出**：PrdChange 列表 + AtomicChange 列表

> **设计要点**：变更登记与变化点识别合为一步。PRD 含 ImpactPoint 时可直接映射；
> 无 ImpactPoint 时需先拆解需求再主动识别。两条路径产出结构一致，后续 Phase 1.5～3B 无差异。

### 1.0.1 输入分类

| 类型 | 判断标准 | 处理路径 |
|------|---------|---------|
| **type_a** | `INCR_PRD_DOC` 检测为 true（含 DELTA 块 + ImpactPoint 清单） | → 直接提取（1.0.2） |
| **type_b** | 存在 PRD 文档有要素章节但无 ImpactPoint | → 主动识别（1.0.3） |
| **type_c** | 输入为一段话或几条要点，无 PRD 结构 | → 主动识别（1.0.3） |

顺序检测，首次命中即确定。

### 1.0.2 直接提取模式（type_a）

PRD 的 ImpactPoint 已携带"哪个要素变了 + 变了什么"，一步到位产出 PrdChange 和 AtomicChange。

对**每条 ImpactPoint / DELTA 块**：

1. **提取 PrdChange**：从 ImpactPoint 的影响要素声明中提取 prd_element、description、source_story，evidence_source=incr_prd
2. **映射 AtomicChange**：按 prd_element 初筛变化点类别（如 info-architecture → IA 类），用 detection_keywords 在 DELTA 块中匹配，确定具体变化点 ID
3. **证据收集**：引用增量 PRD 原文（ImpactPoint 编号 + DELTA 片段）作为 evidence
4. **置信度**：有 ImpactPoint + DELTA 原文支撑，confidence 默认 `high`
5. **用户确认**：同一 PrdChange 命中多个变化点时列出选项让用户选

**暂停触发**：
- DELTA 块描述模糊，无法确定变更类型
- 同一 PrdChange 命中多个变化点且无法消歧
- 命中置信度为"低"

### 1.0.3 主动识别模式（type_b / type_c）

输入无 ImpactPoint，需主动识别变化点。

**第一步：需求拆解**

将输入拆解为独立的变更意图（Raw Intent, RI），每条 RI 描述一个可辨识的业务变化。
拆解原则：一条 RI 对应一个独立业务变化，粒度对齐"用户可独立验收的最小功能点"。
- type_b：从 PRD 各章节提取变化点
- type_c：从自然语言拆解

**第二步：对每条 RI 识别原子变化点**

1. **关键词初筛**：用 atomic-change-registry 的 detection_keywords 在 RI 描述中做模糊匹配，得到候选集合
2. **语义匹配**：对候选集合按变化点的 description_zh + examples 做语义判断，确认或排除
3. **证据收集**：每个识别出的变化点必须能引用以下之一作为 evidence，并标注 evidence_source：
   - `incr_prd`：增量 PRD 对应章节 + 引用片段（type_b 适用）
   - `baseline_design`：基线设计文件对应章节 + 引用片段
   - `dialog`：用户需求描述原文片段或澄清回答（type_c 适用）
4. **用户确认**：同一 RI 命中多个变化点时列出选项让用户选

**第三步：暂停澄清**

关键词初筛命中"可能涉及"但证据不足的域，汇总为澄清问题，按铁律二统一暂停格式输出。
澄清回答后补充变化点，evidence_source=dialog。

**第四步：构造 PrdChange + AtomicChange**

根据识别结果 + 澄清回答，同时构造两个列表。主动识别模式的约束：
- PrdChange.evidence_source 标记为 `dialog`（type_c）或 `incr_prd`（type_b）
- AtomicChange.confidence 默认上限 `medium`（用户逐条确认后可升 high）
- source_story 通常为空，Phase 3B 遇到时跳过回填或仅输出 DIP 清单

**暂停触发**：
- 同一 RI 命中多个变化点且无法消歧
- 命中置信度为"低"
- RI 描述明显超出 34 个变化点的覆盖范围

### 1.0.4 关键约束（两种模式共用）

| 约束 | 说明 |
|------|------|
| PrdChange 与 AtomicChange 一一对应 | 每条 PC 至少映射一个 AtomicChange；同一 PC 可映射多个 |
| 遵守铁律一 | 推导不出的必须暂停询问；所有结论标注 evidence_source |
| 遵守铁律二 | 置信度"低"或无法消歧时必须暂停澄清 |
| 变化点不得超出 34 个清单 | 超出覆盖范围时暂停说明 |

---

## Phase 1.5：变化点路由四步流程（TDD 高阶 Step 1.1 ~ 4，ChangeRouter）

### Step 1.1：原子变化点识别

1. 读取 `registry/atomic-change-registry.yaml`
2. 对每条 PC，按 `prd_element` 初筛类别，用 `detection_keywords` 精确匹配
3. 每条命中必须引用 evidence（增量 PRD 原文 / 基线设计 / 存量系统 / 用户对话）
4. 构建 AtomicChange 实例：
   - `id`：`{CATEGORY-NN}`（如 IA-01、FS-02）
   - `source_prd_change`：`PC-{xx}`
   - `evidence`：证据原文片段
   - `evidence_source`：`incr_prd` | `baseline_design` | `legacy_system` | `dialog`
   - `confidence`：`high` | `medium` | `low`
   - `open_question`：置信度非 high 时的待确认问题
5. **confidence 为 medium/low 时必须暂停**，向用户展示证据与待确认问题，等待确认后继续
6. 输出 `triggered_changes`（AtomicChange 列表），写入编排上下文

### Step 2：影响汇聚

1. 读取 `registry/change-element-mapping.yaml`
2. 对 `triggered_changes` 中每个变化点 change_id，查找 `affects` 列表
3. 按 impact_level 处理：
   - `certain` → 直接加入候选序列
   - `likely` → 标记为可跳过，默认加入
   - `conditional` → 检查 condition 条件，或交由用户决定
4. 合并去重，输出候选 `effective_sequence`

### Step 3：always_affected 标注

方案 A（外置收口）：增量设计只产出 DIP + 多文件 DELTA；开发 Task 拆分由 `ia-prd-to-tdd` 增量承接。本步跳过。

### Step 4：依赖图安全网校验

1. 遍历 `registry/dependency-graph.yaml` 的 `impact_edges`
2. 对 `effective_sequence` 中每个 source element，取 direct targets
3. 不在序列中的 target 归入安全网候选
4. 若安全网候选非空，输出交互：
   - `[Y]` 全部加入
   - `[S]` 选择性加入
   - `[N]` 跳过
5. 按 `chapter_no` 升序排列最终 `effective_sequence`

**MODE 过滤**（同步执行）：
- `new-incremental` / `update` 从序列移除 `architecture`（除非被 ChangeRouter 以 certain 命中）。

**CHANGE_SCOPE 过滤**（同步执行）：
- 仅 `backend`：移除 `frontend`。
- 仅 `frontend`：是否移除后端链由用户确认（默认保守：不自动剔除后端链）。
- `fullstack`：前后端链路均可进入；`config` / `integration` 仍按需。

---

## Phase 2：执行计划展示与确认（TDD 高阶 Step 5）

输出如下模板，等待用户确认：

```text
✅ 设计增量影响域分析完成

PRD 变更条目：
  PC-01: "{描述}" (← S-FR-xx-xx)
  PC-02: "{描述}" (← S-FR-xx-xx)

触发原子变化点：
  PC-01 → {change_id}({confidence})
  PC-02 → {change_id}({confidence})

受影响设计要素（按章节顺序）：
  {no}. {element_name}（{trigger_type}，触发 {source_changes}）
  ...
不涉及要素：{排除的要素及原因}

[C] 开始执行  [B] 重做 ChangeRouter  [Q] 退出
```

- 用户选 `[C]`：冻结 scope，进入 Phase 3
- 用户选 `[B]`：回到 Phase 1.0 重新执行
- 用户选 `[Q]`：保存当前上下文到 ongoing.md 后退出

---

## Phase 3：要素执行循环（TDD 高阶 Step 6）

对 `effective_sequence` 中每个 `element_id`：

```
FOR EACH element IN effective_sequence:
  1. 从 element-type-registry 动态读取 chapter_info：
     chapter_info = {
       l1_no: element.chapter_no_cn,
       element_name: element.name,
       sub_elements: element.sub_elements,
       backend_only: element.backend_only,
       chapter_label_style: element.chapter_label_style
     }
  2. 过滤本要素相关的变化点列表（element_changes）：
     从 triggered_changes 中筛选与本 element_id 关联的变化点子集
  3. 设置 context.output_doc_path = {DESIGN_DIR}/{config.design_artifacts[element_id]}
  4. 设置 context.base_doc_path = BASELINE_DESIGN_DIR 中该要素已有交付文件路径
     （若基线缺少该文件，须用户确认是否改为 build 或补齐基线，禁止静默空基线）
  5. 调用 element-runner(element_id, execution_mode="incremental", context)
     其中 context.impact_analysis 含：
     - prd_change_register
     - triggered_changes
     - effective_sequence
     - element_changes（本要素子集）
  6. element-runner 输出操作菜单后 FOR 循环挂起，等待用户选择
  7. 该要素会话结束前须按 spec/m-design-summary-merge.md 产出
     `## 汇总输入（供 design.md 合并）` 结构块；编排留存待 Phase 3A 合并
  8. 每个要素执行完毕后累积 DIP 到 context.impact_points
END FOR
```

---

## Phase 3A：汇总生成 `{DESIGN_DIR}/design.md`

在 Phase 3 **全部受影响要素**均已成功结束后：

1. **必须严格按** `spec/m-design-summary-merge.md` 收集本轮各要素会话中的汇总输入，执行门禁自检后写入或刷新 `{DESIGN_DIR}/design.md`。
2. **增量专属章节**（在标准汇总章节前追加）：

```markdown
## 0. 变更说明
- 基线设计目录：{BASELINE_DESIGN_DIR}
- 增量 PRD：{INCR_PRD_FILE}
- 存量系统信息：{LEGACY_CONTEXT 或 "未提供"}
- PRD 变更条目：{PC-01, PC-02, ...}
- 触发变化点：{change_ids}

## A. 影响点索引
| DIP 编号 | 来源 PC | 来源变化点 | 触发类型 | 受影响要素 | action | baseline_ref |
|----------|--------|----------|---------|----------|--------|--------------|
```

3. **DIP 全局重编号**：将各要素内临时编号的 DIP 统一重编为 `DIP-001`、`DIP-002`、... 的全局序号。
4. 将 `prd_change_register`、`triggered_changes`、`impact_points` 等全局寄存字段**仅在此处**写入 design.md。
5. 若门禁失败，按该 reference 暂停策略处理，**不得**进入 Phase 3B。

---

## Phase 3A-1：草案审阅与确认（TDD 高阶 §11.1 同构）

**前置条件**：Phase 3A `design.md` 已成功生成。

**处理**：输出完整草案供用户审阅，格式如下：

---

=== 增量设计影响域分析草案 ===

【一、PRD 变更条目】
PC-01: {描述} / 来源 {source_story} / 状态：已分析
PC-02: {描述} / 来源 {source_story} / 状态：已分析

【二、原子变化点】
PC-01 → {change_id}({confidence}, evidence_source={source})
PC-02 → {change_id}({confidence}, evidence_source={source})

【三、受影响设计要素总表】
| 要素 | 触发类型 | 触发变化点 | 改动摘要 |
|------|---------|----------|---------|

【四、不涉及要素说明】
| 要素 | 不涉及原因 | 验证依据 |
|------|-----------|---------|

【五、影响点清单（DIP）】
DIP-001 [primary, source_change={id}, source_prd_change={pc}]
  element: {element_id}
  baseline_ref: {基线章节}
  baseline_state: {基线现状}
  action: 新增|修改|删除
  target_state: {目标状态}
  target_state_evidence: {四档之一}
  compatibility_note: {兼容说明}
  boundary_constraints:
    - target: {禁止改动对象}
      reason: {原因}
      consequence: {后果}
      evidence: {依据}

DIP-002 [...]

【六、US 设计引用预览】
（Phase 3B 待执行，此处列出 DIP.source_prd_change → PrdChange.source_story 的预估关联）

=== 待确认问题汇总 ===

请确认：
1. 分析结论是否准确？有无遗漏或错误？
2. 影响点的边界约束是否完整？
3. 兼容性说明是否充分？
4. US 设计引用预览是否覆盖全部关联设计章节？

[Y] 确认，继续 Phase 3B  [B] 修正后重新汇总  [Q] 退出

---

- 用户选 `[Y]`：进入 Phase 3B
- 用户选 `[B]`：回到 Phase 3 对指定要素重新执行 element-runner
- 用户选 `[Q]`：保存当前上下文到 ongoing.md 后退出

---

## Phase 3B：US 与设计交付物索引关联（条件执行）

在 Phase 3A `design.md` 已成功生成或用户确认跳过后：

1. 若 `{DESIGN_DIR}/story.md` **不存在**，跳过本 Phase。
2. 若存在，**必须严格按** `spec/m-us-design-linkback.md` 执行：将本轮已更新/产出的多文件设计交付物（以 `config.yaml` → `design_artifacts` 为准，含 `shared-context.md` 及 `design.md`）的可定位索引写回各 US。
3. 执行完成后以该 reference 的完成消息为准（`DONE: story.md design linkback`）。

---

## Phase 4：完成收尾（TDD 高阶 Step 7 可选收口）

1. 更新 `{WORKSPACE_ROOT}/workspace/ongoing.md` 与 `DESIGN_ACCUM_FILE`（跨版本累积视图）。
2. 输出 SKILL.md 中定义的增量模式完成提示模板。
3. 增量设计产物已齐备，建议下游接续 `ia-prd-to-tdd` 增量工作流。
```

---

## 【D】spec/

**m-*.md 文件名列表：**

- _template.md
- m-design-api.md
- m-design-architecture.md
- m-design-backend.md
- m-design-config.md
- m-design-data.md
- m-design-frontend.md
- m-design-integration.md
- m-design-knowledge-exploration.md
- m-design-summary-merge.md
- m-us-design-linkback.md

**容器型要素（architecture）的"前置条件"与"输出骨架"：**

### m-design-architecture.md — 前置条件

```markdown
## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|----------------------|------|
| — | 以 PRD/Story 中系统形态与约束为基线；避免无上下文的孤立架构条目。 |
| （可选）`data-model` | 若先于架构写库表，仅以引用关系出现在微服务边界，不互为阻塞 |

**必要输入**

- 生效的 `{DESIGN_DIR}/prd.md`（及按需 `story.md`）含系统类型、部署要求、合规或技术基线陈述。
- 工作流确认 `MODE`、`PROJECT_TYPE`、`CHANGE_SCOPE`；本要素条文与 **`MODE`** 关系见「跳过条件」。

**跳过条件**

- `MODE ∈ {new-incremental, update}`：**不产出**顶层 `architecture.md`（与 SKILL 对齐）；若在修改类工作流仍需引用历史架构条文，仅从 `DESIGN_ACCUM_FILE`/`architecture.md` 存量读取。
- Story 明确要求「不涉及架构变更」且无 greenfield：**可经 orchestration 将本要素移出序列**。
```

### m-design-architecture.md — 输出骨架

```markdown
## 输出骨架

（章节编号示例，以 orchestration 传入 `chapter_info` 为准）

```markdown
## {L1_no} {element_name}

### {L2_no} 技术选型与代码架构综述
...

### {L2_no} 部署架构
...

### {L2_no} 微服务架构
...

### {L2_no} 灰度与特性开关
...

### {L2_no} 代码架构（四层与包命名）
...

### {L2_no} 公共基础库
...

### {L2_no} 公共组件（AOP 切面）
...
```
```

**叶子型要素（api-contract）的"前置条件"与"输出骨架"：**

### m-design-api.md — 前置条件

```markdown
## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|---------------------|------|
| `data-model` | 分页/枚举字段语义一致 |

**必要输入**

- PRD 「功能规格」与 Story 条目；如涉及存量改动，须提供影响面说明位。
```

### m-design-api.md — 输出骨架

```markdown
## 输出骨架

```markdown
## {章节} 后端接口契约

### 变更概要
### 接口清单
### 通用约定
### 接口详细设计
```
```

---

## 【E】样例输出文档

**选取：`workspace/design/I20260418/design.md`**

**(1) Frontmatter（YAML 块）：**

```yaml
---
name: I20260418 技术设计方案
version: I20260418
created_by: ia-prd-to-design skill
created_at: 2026-04-17
mode: 前后端联合
status: draft
---
```

**(2) 完整标题行列表：**

```
# I20260418 技术设计方案
## 架构决策记录
## 一、设计概述
### 1.1 功能背景
### 1.2 核心业务目标
### 1.3 技术范围界定
## 二、架构变化(摘要)
### 2.1 新增组件/模块
### 2.2 变更组件/模块
### 2.3 架构影响分析
## 三、数据库设计(摘要)
### 3.1 数据库表清单(概览)
### 3.2 数据模型变化(摘要)
## 四、API 设计(摘要)
### 4.1 API接口清单(概览)
### 4.2 API变化分析
## 五、前端设计(摘要)
### 5.1 页面/组件清单(概览)
### 5.2 前端技术方案(摘要)
## 六、后端服务设计(摘要)
### 6.1 业务逻辑设计(摘要)
#### 6.1.1 业务流程设计
#### 6.1.2 状态机设计
### 6.2 权限设计(摘要)
#### 6.2.1 功能权限矩阵
#### 6.2.2 数据权限规则
### 6.3 配置设计(摘要)
#### 6.3.1 Lookup 配置清单
#### 6.3.2 数据字典配置
#### 6.3.3 配置项平台(无)
### 6.4 DFX设计(摘要)
#### 6.4.1 性能设计
#### 6.4.2 可靠性设计
#### 6.4.3 可维护性设计
## 七、技术决策记录
## 八、待澄清事项
## 九、附录
### 9.1 参考文档
### 9.2 设计规范来源
### 9.3 Subagent 执行记录
#### 数据库设计 Subagent
#### API设计 Subagent
#### 前端设计 Subagent
#### 后端设计 Subagent
```

---

## 【F】

**(1) output-contract.yaml**

(不存在)

**(2) config / orchestration / spec / registry 中 grep manifest 命中行**

未发现 manifest 产出
