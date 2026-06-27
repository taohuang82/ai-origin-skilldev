---
name: ia-prd-to-design
description: >
  将版本化 PRD（及 Story）转化为多文件技术方案设计；支持新建设计、增量/更新、
  评审修改与断点续作。内置 engine + registry/spec 驱动各设计域产出。
  触发词：PRD转设计、生成技术方案、ia-prd-to-design、设计增量、
  修改设计文档、继续设计
disable-model-invocation: false
version: 2.3.0
spec_compliance: "v1.6.0"
---

# ia-prd-to-design

启动声明：
`我正在使用 ia-prd-to-design，在已确认的版本化 PRD 基础上生成或修订多文件技术设计，并按 registry/spec 逐要素执行。`


## 全局执行约束

- **先路由、后执行**：先完整读取 `config.yaml` 中挂载的 `engine/workflow-engine.md`，确认 workflow 后再进入对应 orchestration。
- **路径解析（两套根目录）**：
  - **Skill 根目录**（本包 `ia-prd-to-design/`）：`registry/`、`engine/`、`config.yaml` 的相对路径基准。
  - **工作仓库根目录**（用户当前打开的工程/仓库根）：`config.yaml` 中 `context.ongoing_file`、`output_folder_base` / `input_folder_base`、`standards.extend_index` 等路径基准。
- **Subagent 直派**：orchestration 直接通过 Task 工具派发 Subagent 写设计正文；禁止绕过 Subagent 在主会话写正文
- **前置门禁在 orchestration**：派发前检查 depends_on 对应 artifact 存在、force_read[] 文件存在
- **spec/standards 仅 Subagent 加载**：Subagent Step 0 按 element_ids[] 逐子要素 Read spec/{domain}/{id}.md + standards/{domain}/{id}.md；orchestration 禁止加载 spec/standards 全文
- **frontmatter 由 orchestration 写入**：Subagent 落盘后，orchestration 负责更新 artifact 的 YAML frontmatter（stepsCompleted / last_element / last_updated / status）；Subagent 禁止读写 frontmatter
- **轻量后置校验**：orchestration 对 Subagent 返回做汇总块完整性 + 空内容/占位符正则扫描 + DELTA 块存在性检查（不重读 spec/standards）；不通过则 [B] 重派 Task
- **Subagent 自检报告约束**：Subagent 返回载荷必须包含 `## 质量自检报告`；自检报告不得写入各设计 artifact（`architecture.md`、`data.md`、`backend-api.md`、`backend.md`、`frontend.md`、`integration.md`、`config.md`、`design.md`）；禁止命名为「Spec 覆盖检查」或「Spec 覆盖报告」；orchestration 只校验返回载荷，不合并到 `{DESIGN_DIR}/design.md`
- **Subagent 前台执行约束**：所有设计类 Subagent 和 Story-Enricher 默认前台执行（`run_in_background: false`）；禁止后台静默队列；若环境不支持前台并行，改为串行执行
- **规范加载优先级**：项目级 extend-rule > 内置 standards > 内置 spec；extend-rule 缺失不阻断内置规范加载
- **一次汇总 C/B/S/Q**：全部要素完成后输出一次操作菜单；不在每域中间卡点
- **spec 内 [交互] 在 Subagent 会话完成**；orchestration 会话不做域内交互
- **汇总块透传链**：Subagent 返回 → orchestration 轻量校验 → append collected_summaries[] → Phase 2A merge
- **子要素路径 SSOT**：registry/element-registry.yaml；逻辑 ID 经 RESOLVE_ELEMENT() 与 aliases 解析
- **增量 DELTA/DIP**：Subagent 输出须含 DELTA + 关联 DIP；全局 DIP 寄存仅在 Phase 3A 写入 design.md
- **Subagent 结构**：所有 ia-*-designer 须对齐 subagents/_template.md Step 0–5
- **语言与事实约束**：始终使用中文；优先基于 PRD / Story / 已有设计事实
- **增量模式外置收口**：增量设计只产出 DIP + 多文件 DELTA；开发 Task 拆分由 `ia-prd-to-tdd` 增量工作流承接。
- **PRD 章节来源 SSOT**：子要素读取 PRD 的章节/信号以 `registry/element-registry.yaml` 中 `prd_sources` 为准；orchestration 可在 Prompt 中透传该元数据，但禁止解释、改写或替代 Subagent 的 PRD 抽取判断；Subagent 在 Step 0/1 消费 `prd_sources`，并结合子要素 spec 执行抽取与适用性判断。
- **代码信号优先**：当 workflow 依赖 `code-signal-registry.yaml` 时，orchestration 仅对受影响要素执行代码信号扫描，按匹配程度决定设计执行档位；禁止在识别前完整预加载 spec/standards
- **主会话直接写入**：不使用 Subagent 返回载荷中转机制时，设计正文由主会话直接写入 artifact 文件，取消汇总块透传链
- **按需加载规范**：spec/standards 根据代码信号匹配结果动态加载，pattern_match 优先从代码推断，partial_match 可加载关键约束，no_match 才完整加载规范
- **自检分级**：轻匹配要素做空内容 + 占位符扫描；完整规范驱动要素额外执行 spec 质量检查点对照
- **模式降级**：从代码推断存在语义遗漏风险，PRD 出现明显新模式或代码信号与需求不一致时，应主动提升为更高规范依赖档位
- **设计-代码一致性校验**（轻量模式 Phase 3.5）：设计完成后，对 pattern_match / partial_match 要素逐项比对设计产出与代码实际，确保表名、API 路径、类名、配置项等关键标识与代码仓库一致
  - 校验规范 SSOT：`spec/m-design-code-consistency-check.md`；编排仅引用该 spec，不重复声明校验协议和维度表
  - 校验范围：仅 pattern_match 和 partial_match 要素；no_match 全新要素跳过
  - 代码优先修正：存量信息以代码为准修正设计文档（代码是存量事实的 SSOT）；PRD 新增的增量内容保留不覆盖
  - 代码补充：代码中存在但设计文档未提及的存量信息，补充到设计文档并标记 `<!-- STOCK: 存量信息，来自代码 -->`
  - 修正标记：被修正段落追加 `<!-- FIXED: 校验修正，以代码为准，原值: {original_value} -->`
  - 未识别到物理事实：代码中完全找不到真实表名/API 路径等关键物理标识时，追加 `<!-- MISSING_PHYSICAL_FACT: ... -->`，不自动修正
  - 不修改 DELTA 块：`<!-- DELTA: ... -->` 记录的是本次增量变更，不受校验影响
  - 校验报告：输出一致/已修正/无存量代码对照/未识别到存量物理事实 四类统计，支持 [C] 继续 / [R] 重新校验 / [M] 手动修正 / [P] 提供缺失的物理事实
- **物理事实驱动档位判定**（轻量模式 Phase 2）：code-signal-registry.yaml 中声明 `physical_facts` 的要素，必须成功提取 `required_for_pattern_match` 的物理事实才能进入 pattern_match；否则降级为 partial_match
  - 当前声明 required_for_pattern_match 的要素：`data-table`（真实物理表名）、`be-api`（真实 API 路径）

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
| `DESIGN_ACCUM_FILE` | `{WORKSPACE_ROOT}/workspace/design/DESIGN.md`（跨版本技术设计累积视图） |
| `SKILL_ROOT` | 本包 `ia-prd-to-design` 根目录 |
| `BASELINE_DESIGN_DIR` | 基线特性设计目录（`DESIGN_HISTORICAL` 解析结果），含 `design_artifacts` 各文件 |
| `INCR_PRD_FILE` | 增量 PRD 文件路径，默认等同 `PRD_FILE`；若增量 PRD 独立文件，须在 ongoing.md 或用户指定中解析 |
| `LEGACY_CONTEXT` | 可选：存量系统信息路径列表（DDL / OpenAPI / 代码索引），缺位时降级为对话挖掘 |

详细的业务判定模型（`MODE`、`PROJECT_TYPE`、`CHANGE_SCOPE`、`EXECUTION_PROFILE`）由各 orchestration 在初始化阶段确定和消费。

## 启动序列

1. 读取本目录 `config.yaml`，建立 engine、registry、standards 挂载点。
2. **引擎版本自检**（容错执行）：校验 `config.yaml` → `spec_compliance` 与 `engine/workflow-engine.md` → `spec_compliance` 一致；不一致则输出警告但不阻断。
3. 读取 `workspace/ongoing.md`，检测当前项目状态与输入源。
4. 读取 `engine/workflow-engine.md`，将用户原始输入与输入检测结果传入。
5. workflow 确认后加载对应 orchestration_file；orchestration 负责 Subagent 派发与门禁，Subagent 负责 spec/standards 加载与正文写作。
