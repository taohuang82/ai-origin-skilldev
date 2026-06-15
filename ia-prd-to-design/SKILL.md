---
name: ia-prd-to-design-new
description: >
  将版本化 PRD（及 Story）转化为多文件技术方案设计；支持新建设计、增量/更新、
  评审修改与断点续作。内置 engine + registry/spec 驱动各设计域产出。
  增量模式下执行 PRD 变更结构化路由（ChangeRouter），基于 34 类原子变化点
  精确识别受影响设计要素，生成 ImpactPoint 影响点与 DELTA 增量标注。
  触发词：PRD转设计、生成技术方案、ia-prd-to-design-new、设计增量、
  修改设计文档、继续设计、DELTA、影响域、ChangeRouter、PC-、原子变化点、
  增量设计影响分析
disable-model-invocation: false
version: 2.0.0
spec_compliance: "v1.3.0"
---

# ia-prd-to-design-new

启动声明：
`我正在使用 ia-prd-to-design-new，在已确认的版本化 PRD 基础上生成或修订多文件技术设计，并按 registry/spec 逐要素执行。`

模式细分：
- 新建完整设计：`design-new-build`
- 增量/更新：`design-incremental-build`（将执行 PRD 变更结构化路由 ChangeRouter，识别原子变化点 → 设计要素映射 → 影响点分析 → DELTA 增量标注）
- 评审修改：`design-review-modify`
- 断点续作：`design-resume`

## 全局执行约束

- **先路由、后执行**：先完整读取 `config.yaml` 中挂载的 `engine/workflow-engine.md`，确认 workflow 后再进入对应 orchestration。
- **路径解析（两套根目录）**：
  - **Skill 根目录**（本包 `ia-prd-to-design-new/`）：`registry/`、`engine/`、`config.yaml` 的相对路径基准。
  - **工作仓库根目录**（用户当前打开的工程/仓库根）：`config.yaml` 中 `context.ongoing_file`、`output_folder_base` / `input_folder_base`、`standards.extend_index` 等路径基准。
- **要素必须经过 element-runner**：所有要素必须经由 `engine/element-runner.md` 的六阶段流程执行；禁止 orchestration 绕过 element-runner 直接生成设计内容。
- **Phase 6 唯一状态写入点**：仅在 element-runner Phase 6 更新输出文档 frontmatter（`stepsCompleted`、`last_element`、`status` 等）；禁止在其余阶段写入这些字段。
- **多文件输出约定**：每个要素对应 `config.yaml` → `design_artifacts` 中声明的主交付文件；orchestration 在调用 element-runner 前必须将 `context.output_doc_path` 设为该要素的主输出文件路径。
- **语言与事实约束**：始终使用中文；优先基于 PRD / Story / 已有设计事实，不凭空发明业务需求。
- **增量模式外置收口**：增量设计只产出 DIP + 多文件 DELTA；开发 Task 拆分由 `ia-prd-to-tdd` 增量工作流承接。

## 路径约定

orchestration 执行前读取 `workspace/ongoing.md` 与当前版本目录，建立以下核心路径变量（特性设计子目录与 legacy 回退以团队工作区约定和实际布局为准）：

| 变量 | 说明 |
|------|------|
| `WORKSPACE_ROOT` | 用户工作区绝对路径；禁止使用 Skill 目录作为业务文件根路径 |
| `VERSION` | 用户指定版本；未指定时解析 `workspace/ongoing.md` 的 `current_version` |
| `FEATURE_SUBDIR` | 特性设计子目录名（`YYYYMMDD-特性名称`，位于 `design/{VERSION}/` 下） |
| `DESIGN_DIR` | 特性目录，默认 `{WORKSPACE_ROOT}/workspace/design/{VERSION}/{FEATURE_SUBDIR}` |
| `PRD_FILE` | `{DESIGN_DIR}/prd.md` |
| `STORY_FILE` | `{DESIGN_DIR}/story.md` |
| `DESIGN_FILE` | `{DESIGN_DIR}/design.md` |
| `DESIGN_ACCUM_FILE` | `{WORKSPACE_ROOT}/workspace/design/design.md`（跨版本技术设计累积视图） |
| `SKILL_ROOT` | 本包 `ia-prd-to-design-new` 根目录 |
| `BASELINE_DESIGN_DIR` | 基线特性设计目录（`DESIGN_HISTORICAL` 解析结果），含 `design_artifacts` 各文件 |
| `INCR_PRD_FILE` | 增量 PRD 文件路径，默认等同 `PRD_FILE`；若增量 PRD 独立文件，须在 ongoing.md 或用户指定中解析 |
| `LEGACY_CONTEXT` | 可选：存量系统信息路径列表（DDL / OpenAPI / 代码索引），缺位时降级为对话挖掘 |

详细的业务判定模型（`MODE`、`PROJECT_TYPE`、`CHANGE_SCOPE`、`EXECUTION_PROFILE`）由各 orchestration 在初始化阶段确定和消费。

## 启动序列

1. 读取本目录 `config.yaml`，建立 engine、registry、standards 挂载点。
2. 校验 `engine/ENGINE-VERSION` 与 `docs/engine-canonical/ENGINE-VERSION` 一致；不一致则输出警告，建议同步。
3. **引擎版本自检**（容错执行）：校验 `config.yaml` → `spec_compliance` 与 `engine/workflow-engine.md` → `spec_compliance` 一致；不一致则输出警告但不阻断。
4. 读取 `workspace/ongoing.md`，检测当前项目状态与输入源。
5. 读取 `engine/workflow-engine.md`，将用户原始输入与输入检测结果传入。
6. workflow 确认后加载 workflow-registry 中对应的 orchestration_file。
7. **增量专属**（仅 `design-incremental-build`）：ChangeRouter 完成后展示 `effective_sequence` 执行计划供用户确认，用户选 `[C]` 后冻结 scope，orchestration 负责编排，element-runner 负责要素执行。

## 完成提示模板

### 新建模式

```text
✅ ia-prd-to-design-new 已完成
特性目录：{DESIGN_DIR}
当前模式：{workflow_id} / {execution_mode}
已按要素生成或更新设计文件：
  architecture.md / data.md / backend-api.md / backend.md
  integration.md / config.md / frontend.md
  design.md（特性级摘要与引用）
若存在 story.md：已将设计索引关联至各 US。
建议下一步：测试用例与编码计划等工作流
```

### 增量模式

```text
✅ ia-prd-to-design-new (incremental) 已完成
特性目录：{DESIGN_DIR}
当前模式：design-incremental-build / incremental

PRD 变更条目（PC）：{pc_count} 条
触发原子变化点：{change_ids}
受影响设计要素：{effective_sequence_count} 个
影响点（DIP）：{dip_count} 条

已更新设计文件（含 DELTA 标注）：
  {更新的 artifact 列表}
全局分析寄存：design.md

建议下一步：
  - 评审增量设计产物
  - 执行 ia-prd-to-tdd 增量工作流（输入已齐备）
```

---

## 增量分析数据结构定义

### PrdChange（PRD 变更条目）

```yaml
PrdChange:
  id:           "PC-{序号}"
  prd_ref:      "增量 PRD 章节/IP 引用"
  prd_element:  "PRD 要素 ID"
  description:  "变更描述（一句话概括）"
  source_story: "S-FR-xx-xx-xxx-xx"
```

### AtomicChange（原子变化点运行时实例）

```yaml
AtomicChange:
  id:               "{CATEGORY-NN}"       # 如 IA-01、FS-02
  source_prd_change: "PC-{xx}"
  evidence:         "证据原文片段"
  evidence_source:  "incr_prd | baseline_design | legacy_system | dialog"
  confidence:       "high | medium | low"
  open_question:    "置信度非 high 时的待确认问题"
```

### DesignImpactPoint（设计影响点，DIP）

> 与 TDD 高阶 ImpactPoint / PRD 增量 ImpactPoint 同构

```yaml
DesignImpactPoint:
  id:                  "DIP-{全局序号}"
  source_prd_change:   "PC-{xx}"
  source_change:       "{change_id}"
  trigger_type:        "primary | cascade"
  cascade_rule:        ""
  element:             "{design_element_id}"    # element-type-registry 中的 id

  # 变更落点
  baseline_ref:        "基线设计文件 §X.Y 章节引用"
  baseline_state:      "基线现状"
  action:              "新增 | 修改 | 删除 | 复用 | 不涉及"
  target_state:        "变更后目标状态"
  target_state_evidence: "incr_prd | baseline_design | legacy_system | dialog"
  compatibility_note:  "存量兼容说明"
  in_scope:            ["明确包含的对象列表"]
  out_of_scope:        ["明确排除的对象列表"]

  # 边界约束（可选子字段）
  boundary_constraints:
    - target:       "禁止改动的对象"
      reason:       "禁止原因"
      consequence:  "若违反会发生什么"
      evidence:     "依据来源"
```
