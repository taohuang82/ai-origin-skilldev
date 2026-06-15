# 增量设计：现有知识库探索（编排引用）

本文件供 **`orchestration/o-design-incremental.md`** 在要素执行前驱动「受限知识探索」。

**核心目的**：通过对知识库与代码的分层检索，**定位与本次变更相关的 API、核心实体及核心 Domain 类**，为下游要素设计（`data.md`、`backend-api.md`、`backend.md` 等）提供准确的复用基线与变更起点。

**编排职责**：按本节步骤产出 `{DESIGN_DIR}/shared-context.md`，并在探索收敛后确定 **`CHANGE_SCOPE`**（见本 Skill `SKILL.md`：**探索结束前不得以默认值代替事实检索**）。

---

## 产出禁码（强制）

在 `shared-context.md`、执行摘要及向主 Agent 可见的探索输出中，**禁止**书写具体可执行代码（含完整类/方法体、可运行脚本等）及 **SQL**（含 DDL/DML）；以结构化说明、清单与文字描述代替。

## 设计原则（强制）

- 本阶段仅沉淀检索事实、导航索引与决策澄清，禁止直接输出可执行具体代码（含完整类/方法体、脚本、SQL）。

## 增量从简（强制）

以导航索引、决策事实与澄清增量为主；避免大段摘录已有文档正文；单条事实最短表述。

## 探索不替代下游设计

- 本阶段 **不直接产出** 各要素设计文件（`data.md`、`backend-api.md` 等）。
- **不输出** 条目级「新增 / 修改 / 复用」最终结论，不负责输出 `dispatch` / `depends_on` / `outputs` 等执行编排字段。
- 所有设计结论以下游读取 **原始文件** 为准；此处只沉淀共享检索索引与决策事实卡片。

## 输入（编排侧须就绪）

| 项 | 说明 |
|----|------|
| PRD | `{DESIGN_DIR}/prd.md`（或本轮对齐的新版 PRD 路径） |
| MODE | `new-incremental` 或 `update`（与本 Skill 一致） |
| 历史设计基线 | `DESIGN_HISTORICAL` 解析结果：既有设计文件目录与主文件（编排指定） |
| 跨版本累积视图 | `DESIGN_ACCUM_FILE`：`{DESIGN_ROOT}/design.md`（变量定义见 `SKILL.md`） |
| 输出 | `{DESIGN_DIR}/shared-context.md` |

**现有设计目录（检索时用）**：

- `new-incremental`：优先 `{WORKSPACE_ROOT}/workspace/design/` 及本轮 `DESIGN_HISTORICAL` 指向目录中与变更相关的存量文件。
- `update`：以 `{DESIGN_DIR}/` 下已有设计文件为主，并与 `DESIGN_ACCUM_FILE` 对照。

---

## 输出目标：`shared-context.md` 结构

采用 **导航优先、事实最小化、原文为准**：

```markdown
## 决策事实卡片（decision_facts）
## 原始来源导航（source_navigation）
## 要素影响与复用摘要（供编排映射 effective_sequence 与 downstream 使用）
## 跨版本依赖（new-incremental 模式侧重）
## 技术方案澄清与已确认决策
## existing_knowledge 回填建议
## 相关 API 清单（related_apis）
## 核心实体清单（core_entities）
## 核心 Domain 类清单（core_domain_classes）
```

说明：

- `decision_facts`：少量已被原文确认、会影响方案决策的事实 / 约束 / 冲突 / 待确认项。
- `source_navigation`：后续必须读取的原始文件 **元数据**，**不**输出正文摘要，不替代原文深读。
- `要素影响与复用摘要`：可与 `registry/dependency-graph.yaml` 的 `incremental_impact_rules` 对照，仅表达事实摘要与复用边界 / 风险，不写最终变更裁决。
- `related_apis`：与本次变更直接关联的已有 API 接口清单（路径、方法、所属 UIAPI/Service 类、关联 Domain）。
- `core_entities`：受影响的核心实体清单（实体名、PO 类路径、对应表名、关键字段概要）。
- `core_domain_classes`：受影响的核心 Domain 层类清单（按 DDD 四层分类，含类名、职责、依赖关系）。

---

## Phase A：知识库文档探索

### Layer 1：业务知识探索（按需精读）

知识源：`docs/biz_kl/`

建议顺序：

1. `docs/biz_kl/01_index.md`
2. `docs/biz_kl/10_business_domains/*.md`（按关键词挑选）
3. `docs/biz_kl/20_business_processes/*.md`（按流程相关性）
4. `docs/biz_kl/40_glossary/*.md`（术语补充）

---

### Layer 2：系统架构探索（分层读取）

知识源：工程级 `docs/init/` + 根级 `docs/init/`（回退）+ `docs/sys_kl/*/`

1. **识别工程结构**：若存在 `{WORKSPACE_ROOT}/backend/` 与 `{WORKSPACE_ROOT}/frontend/`，按 **双工程** 处理；否则按单工程，继续使用根级 `docs/init/`。
2. **双工程检索约束（探索期）**：
   - **默认**：同时检索 `{WORKSPACE_ROOT}/backend/docs/init/` 与 `{WORKSPACE_ROOT}/frontend/docs/init/`，并分别写入 `source_navigation`。
   - **例外收窄**：仅当 PRD **明文**写明本次不涉及前端或不涉及后端时，可跳过对应侧 `docs/init/`，并在 `decision_facts` 记录收窄依据。
   - 根级 `docs/init/` 仅作工程级缺失时的回退，不得用根级替代本应检索的工程级知识源。

**全局必读（路由与边界）**：

- `docs/init/ARCHITECTURE.md`
- `docs/init/MODULE_INDEX.md`
- `docs/sys_kl/*/01_system_overview.md`
- `docs/sys_kl/*/02_strategic_map.md`

**专题按需**：

- `docs/init/domains/INDEX.md`：按业务域组织的 API/表/类索引（**分域明细主源**）
- `docs/init/domains/{domain_id}/interfaces.md`：该域 API 接口明细
- `docs/init/domains/{domain_id}/tables.md`：该域数据库表结构明细
- `docs/init/domains/{domain_id}/classes.md`：该域类清单明细
- `docs/init/DB_SCHEMA.md`：表结构汇总索引（链接至各域 `tables.md`）
- `docs/init/API_REFERENCE.md`：接口契约汇总索引（链接至各域 `interfaces.md`）
- `docs/init/CLASSES.md`：类清单汇总索引（链接至各域 `classes.md`）
- `docs/init/EXTERNAL_SERVICES.md`：外部系统与集成边界
- `docs/init/DEPLOYMENT.md`：部署、环境、容量与非功能

#### Layer 2a：前端专项（探索期默认执行；PRD 明文无前端可跳过）

根目录：优先 `{WORKSPACE_ROOT}/frontend/docs/init/`；单工程或不存在则 `{WORKSPACE_ROOT}/docs/init/`。

- 必读导航：`FRONTEND_PAGE_DESIGN.md`、`MODULE_INDEX.md`、`FRONTEND_API.md`、`ARCHITECTURE.md`、`PROJECT_INDEX.md`（路径均在对应 `docs/init/` 下）。
- 按需：`AUI_SERVICES.md`、`AUI_COMPONENTS.md`、`FRONTEND_SERVICES.md`。
- 若 PRD 已落到具体 US 且存在 UI 改进文档：`docs/[US-id]/design/ui/*_improvement.md`。

#### Layer 2b：历史技术设计累积视图（依赖检索必做）

知识源：**`DESIGN_ACCUM_FILE`**（`{DESIGN_ROOT}/design.md`）。

- 区分：累积视图 vs `{DESIGN_DIR}` 内**本批次**交付文件。
- 必须检索（全文或按 PRD 关键词定位章节），将可复用事实、命名与契约口径写入「要素影响与复用摘要」与「跨版本依赖」。
- 若文件不存在或为空：在 `shared-context.md` 写明「无累积设计底稿」，并依赖 `docs/init/` 与后续导航结论。

---

### Layer 3：上下文导航与命中 context 最小深读

知识源：`docs/sys_kl/`

1. 发现服务目录。
2. 优先读导航层：`02_strategic_map.md`、`semantic_core_package.md`、`knowledge_graph.yaml`。
3. 若无结构化产物，退化为索引 / 目录 / 标题层导航，**不得假装**已完成结构化检索。
4. 对 PRD 命中的候选 context **最小深读**：
   - 每个候选至少 `contexts/<Context>/01_developer-guide.md`
   - 涉及实体关系、状态机、聚合、数据/API 口径 → 再读 `02_domain_model.md`
   - 术语歧义 → 再读 `04_ubiquitous_language.md`
5. `source_navigation` 只列下游需要的元数据，不大段摘抄正文。

`source_navigation` 每项至少：`source_id`、`path`、`kind`、`reason`、`for_agents`、`read_depth`。

`read_depth`：`must-read` | `recommended` | `optional`。  
`for_agents`：`overall` | `data` | `api` | `backend` | `frontend` | `integration` | `config` | `all`。

---

## Phase B：代码探索——定位 API、核心实体与 Domain 类

> **前置**：Phase A（Layer 1–3）已完成，此时应已掌握：受影响的业务域/模块名、关键实体术语、现有 API 路由前缀与模块划分。Phase B 以这些信息为检索线索进入代码层。

### DDD 四层架构参考模型

代码探索需按 DDD 四层定位类文件，各层职责与典型类：

| 层 | 职责 | 典型类 / 命名模式 |
|----|------|-------------------|
| **Interface（接口层）** | HTTP 请求接收、参数校验、VO/DTO 转换、调用应用服务 | `{Domain}UIAPI`（接口）、`{Domain}UIAPIImpl`（实现）、`{Domain}DTO`、`{Source}To{Target}Converter` |
| **Application（应用层）** | 编排 Domain 服务、事务边界、跨领域协调 | `{Domain}APPService` |
| **Domain（领域层）** | 核心业务逻辑、领域模型、业务规则 | `{Domain}Service`、`{Domain}VO`、`{Domain}Query`、`{Domain}Command`、`{Domain}Repository`（接口）、`{Domain}Delegate`（接口） |
| **Infrastructure（基础设施层）** | 实现 Domain 层接口、数据库访问、外部系统集成 | `{Domain}PO`、`{Domain}RDBRepository`、`{Domain}DAO`、`{Domain}DelegateImpl`、`{Domain}RPC`、`{Source}To{Target}Converter` |

**依赖方向（严格分层）**：
```
Interface → Application → Domain ← Infrastructure
```

- Infrastructure 层**实现** Domain 层接口（Repository / Delegate），不是反向依赖。
- Domain 层完全不依赖 Infrastructure 层技术实现。

### Step 1：定位相关 API

1. **从 `docs/init/domains/INDEX.md`、`docs/init/API_REFERENCE.md` 或 `docs/init/MODULE_INDEX.md` 提取候选路由前缀**：将 PRD 涉及的业务动作映射到 `/uiapi`、`/services`、`/publicservices` 路由；优先按域目录 `{domain_id}/interfaces.md` 定位相关接口。
2. **在代码中搜索 UIAPI 接口与实现类**：
   - 搜索 Interface 层：以 `{Domain}UIAPI` / `{Domain}UIAPIImpl` 命名模式，或 `@RequestMapping` / `@PostMapping` / `@GetMapping` 等注解定位。
   - 搜索路径优先级：`src/main/java/**/facade/`、`src/main/java/**/controller/`、`src/main/java/**/uiapi/`（以实际工程包结构为准）。
3. **记录每个命中 API 的**：接口类全路径、方法签名、HTTP Method + URL、关联的 DTO 类名。
4. 将结果写入 `shared-context.md` → `related_apis`。

### Step 2：定位核心实体

1. **从 API 入参/出参的 DTO 反向推导 Domain 实体名**：DTO 命名通常为 `{Entity}DTO`，对应 Domain 层 `{Entity}VO` 与 Infrastructure 层 `{Entity}PO`。
2. **从 `docs/init/DB_SCHEMA.md` 交叉验证表名与 PO 映射**：确认实体对应的数据库表。
3. **在代码中搜索 PO 类**：搜索 `{Entity}PO` 或位于 `**/po/`、`**/entity/`、`**/dataobject/` 包下的类，确认字段、表注解（`@Table` / `@Entity`）。
4. **记录每个核心实体的**：实体名、PO 类全路径、对应表名、关键业务字段（尤其是状态字段、外键关联）。
5. 将结果写入 `shared-context.md` → `core_entities`。

### Step 3：定位核心 Domain 类

以 Step 1–2 命中的 Domain 名为线索，按四层逐层定位：

1. **Domain 层（必查）**：
   - `{Domain}Service`：核心业务逻辑入口
   - `{Domain}Repository`（接口）：持久化契约
   - `{Domain}VO`：值对象 / 领域模型
   - `{Domain}Query` / `{Domain}Command`：查询与命令对象
   - `{Domain}Delegate`（接口）：外部系统调用契约
2. **Application 层（必查）**：
   - `{Domain}APPService`：编排入口，确认当前业务流编排方式
3. **Infrastructure 层（按需）**：
   - `{Domain}RDBRepository`：仓储实现（确认查询口径）
   - `{Domain}DAO`：MyBatis 映射（确认 SQL 模式）
   - `{Domain}DelegateImpl` / `{Domain}RPC`：外部系统集成实现
4. **Interface 层（Step 1 已覆盖，此处补充）**：
   - VO ↔ DTO 转换器：确认转换规则与字段映射

**对每个命中类记录**：类全路径、所属 DDD 层、职责概要（一句话）、关键依赖（注入了哪些 Service / Repository / Delegate）。

将结果写入 `shared-context.md` → `core_domain_classes`，按 DDD 层分组。

### Step 4：依赖链校验与补全

1. 从 Step 1–3 的结果中构建 **调用链图**：`UIAPI → APPService → Service → Repository / Delegate`，检查是否有断链或遗漏的中间层类。
2. 若发现 Service 注入了其他 Domain 的 Repository / Delegate，标记为 **跨域依赖**，记入 `decision_facts`。
3. 若代码中存在但知识库文档未覆盖的实体或 API，标记为 **文档缺口**。

---

## 检索策略（准确定位优先）

1. 将 PRD 转为检索意图：业务对象、动作、角色、页面/接口、外部系统、数据对象、权限词、非功能词、**变更动词**；术语归一与 alias。
2. **Phase A 路由层（先读全局路由层，不深读正文）**：
   - `docs/biz_kl/01_index.md`、`02_product_overview.md`（若存在）
   - `docs/init/ARCHITECTURE.md`、`MODULE_INDEX.md`
   - `docs/sys_kl/*/01_system_overview.md`、`02_strategic_map.md`
   - **`DESIGN_ACCUM_FILE`**
   - `docs/extend-rule/INDEX.md`（与本仓库 extend-rule 约定一致时）
   - 双工程且 PRD 命中 UI/页面/路由：补充 `frontend/docs/init/` 下 `FRONTEND_PAGE_DESIGN.md`、`MODULE_INDEX.md`、`FRONTEND_API.md`、`PROJECT_INDEX.md`
3. **受限一跳 BFS**：业务域 → 流程/规则/术语；context → 最小深读文件 → 必要时上下游 context；历史设计条目 → 相关模块/接口/集成。**一次只允许一跳扩展**。
4. **仅在**结构化知识冲突、缺口或需回溯原始措辞时回到 `llm_knowledge/`。
5. **Phase B 代码侧**：在 Phase A 收敛后进入代码探索（Step 1–4），以文档探索沉淀的模块名、实体名、API 路由为线索搜索代码。双工程时后端代码根目录为 `{WORKSPACE_ROOT}/backend/`，单工程时为 `{WORKSPACE_ROOT}/`。前端代码入口（如 `src/pages/{模块}/`、`src/router/routerData.js` 等）以实际仓库为准，记入 `source_navigation`。
6. **停止条件**：能回答以下全部问题即停止扩展——
   - 哪些 context/模块受影响、边界契约与主流程是什么
   - 哪些文件 must-read、哪些事实已确认、哪些仍不确定
   - **本次变更关联哪些已有 API（路径 + 方法）**
   - **核心实体有哪些（名称 + 表 + 关键字段）**
   - **核心 Domain 类有哪些（按 DDD 四层列出、含依赖关系）**

---

## 物化降级规则

若工作区无物化 `docs/` 知识库或关键导航层缺失：

- 标注 `resolution_confidence = low`
- 仅输出：已确认的少量事实、无法结构化检索的原因、低置信导航
- **禁止**把仅有 `docs.md` / 目录结构说明当成已成功检索的知识库正文

若代码仓库无法按上述命名模式命中类文件：

- 在 `decision_facts` 记录实际包结构与命名规范偏差
- 退化为目录结构扫描 + 类名关键词搜索，仍须按层分类记录

---

## Layer 4：技术方案澄清（与编排衔接）——强制执行

> **本层不可跳过**。无论探索结果的置信度高低，都必须执行本层；区别仅在于产出内容（有疑问时提问，无疑问时显式声明）。

1. 从探索结果抽取不确定项（边界冲突、新增/修改/复用分歧、外部依赖与口径、非功能缺口、API 复用 vs 新建判定、实体字段扩展 vs 新增表、跨域调用方式等）。
2. **存在疑问（常规路径）**：形成 **3～7** 个澄清问题，每项含：描述、影响要素范围、建议选项（可选）、默认假设、问题 ID。输出状态 **`NEEDS_USER_CLARIFICATION`**，并给出主 Agent 可转述的「用户澄清包」。**必须等待用户确认后才能进入下游要素执行**，禁止以默认假设静默跳过。
3. **确实无疑问（例外路径）**：须在 `shared-context.md` 的「技术方案澄清与已确认决策」章节**显式写明**：「经 Phase A + Phase B 探索，以下关键决策点均已从文档/代码中获得确定性结论，无需用户澄清」，并逐条列出已确认的决策点及其依据来源（文件路径或代码位置）。仅当所有决策点都有**原文可溯源的确定性结论**时，才可走此路径。
4. 收到用户答复后回填「技术方案澄清与已确认决策」，并评估 `resolution_confidence`：`high` | `medium` | `low`。
5. `resolution_confidence` 为 `low` 时，**禁止**进入下游要素执行，须补充探索或再次向用户澄清。
6. 澄清完成且 `resolution_confidence ≥ medium`：写明可进入后续编排；状态 **`READY_FOR_OVERALL_DESIGN`**（在本 Skill 增量编排中等价于进入 **`o-design-incremental` Action 2**）。

---

## 存量系统信息收录（增量模式必检）

- 扫描当前版本目录下的 DDL、Swagger/OpenAPI、代码仓库信息
- 存在 → 路径记入 shared-context；作为 evidence_source=legacy_system 的依据来源
- 不存在 → 记录 "存量信息缺位" 标志；后续 ChangeRouter 中降级为对话挖掘

---

## 探索完成后编排必须落地的事项

1. **`CHANGE_SCOPE`**：`frontend` / `backend` / `fullstack`，须与 `decision_facts` 及 PRD 明文一致；写入后续 `context` 或 `execution_profile`（见 `SKILL.md`）。
2. **`incremental_impact_rules`**：结合 `shared-context`「要素影响与复用摘要」与 `registry/dependency-graph.yaml`，裁剪受影响 `element_id`。
3. 下游 `element-runner` 执行 incremental 前，应能保证读取：`PRD_FILE`、`shared-context.md`、`DESIGN_ACCUM_FILE`（按需）及 `source_navigation` 中标记为 `must-read` 的原文路径。
4. **`related_apis`、`core_entities`、`core_domain_classes`** 三份清单已写入 `shared-context.md`，供 `api-contract`、`data-model`、`backend-impl` 等要素直接消费，避免下游重复代码检索。
