# FE 新建编排（调度器）
# workflow_id: fe-new-build
# 对应 workflow-registry 中 id: fe-new-build

## 前置说明

本编排由 workflow-engine 命中 `fe-new-build` 后调用。**要素正文全部由 element-runner（subAgent）写入**，本文件只做宏观调度：选要素、建 DAG、派发、ASK/RESUME、写 frontmatter、汇总。

## 产出形态约束

本 Skill 全程只有**一个** FE 输出文档（路径 = `{output_folder_base}/{version}/{default_filename}`，即 `workspace/requirements/{ongoing.current_version}/fe.md`）。所有要素 artifact.scope=shared，正文由各 subAgent 追加写入同一文档对应节。写同一文档 → 要素**串行**执行。主 agent 是 frontmatter 的唯一写者。

## 禁止

- 直接生成/写入要素正文（必须派发 element-runner）。
- 读取 spec/*.md（只有 element-runner 读 spec）。
- 硬编码章节映射（从 element-type-registry 动态读 name_cn）。
- 在某要素返回 ##ASK 后、用户确认前，派发其下游要素。

---

## Phase 0：初始化 + requirement_type 判定

1. **确定输出路径**：读取 `ongoing.md.current_version`（如 `l20260701`），组装 FE 文档路径 = `{config.output_folder_base}/{version}/{config.default_filename}`（即 `workspace/requirements/l20260701/fe.md`）。若 ongoing.md 无 current_version → 向用户确认版本目录名。
2. 创建/定位 FE 输出文档（上述路径），写入初始 frontmatter（frontmatter_seed）。
3. **判定 requirement_type**：按需求的**业务性质**分类：
   - **TP 作业类**：OLTP 事务处理型（日常作业：增删改查、审批、调度、上架等）
   - **AP 分析类**：OLAP 数据分析 / 报表 / BI / 看板型需求
   - **AI 类**：AI 能力相关需求（模型算法、AI工具等）
   - **IT 类**：纯IT视角需求，基本不涉及业务（刷数 / 技术改造 / 性能 / 架构等）
   判定后写入 frontmatter.requirement_type；无法判定则向用户澄清（确认对话选项描述必须用上述正确含义，禁止用"专题/优化/界面/技术"等错误释义）。
4. （dual_input）若存在原始需求文档（REQUIREMENT_DOC）→ 先抽取要点作为 extracted_info；否则走对话澄清。

## Phase 1：选要素 + 建 DAG（全动态，禁硬编码要素名）

1. **动态选要素**：遍历 element-type-registry（shared）**所有** element_type，选出满足 `emerge_stage == FE` **或** `emerge_stage == any` 者，得到本次要素集合 `E`。
   - **禁止**在本编排中写死任何要素名单或数量；要素集合完全由 registry 数据决定。
   - 新增/删除一个 FE 要素时，只需改 shared element-type-registry（emerge_stage）+ spec-template-registry（配置）+ 建对应 spec，本编排**零改动**。
2. **过滤可执行**：对 `E` 中每个要素，在 spec-template-registry 查其配置；若某要素在 spec-template-registry 无 active 记录 → 记录告警并跳过（不阻断其余要素）。
3. **读配置**：取每要素的 spec_file / standards_refs / artifact / execution / depends_on / upstream。
4. **建 DAG（Kahn 拓扑排序）**：
   - 以 `E` 为节点集，以各要素 `depends_on` 为有向边（被依赖者 → 依赖者），构建有向无环图。
   - **Kahn 算法**：
     1. 计算每个节点的入度（= `depends_on` 中属于 `E` 的要素数量）。
     2. 入度为 0 的节点入队（无依赖的起始要素）。
     3. 循环：出队一个节点，加入执行序列；将其所有下游节点的入度减 1，若入度降为 0 则入队。
     4. 队列空时结束。若执行序列长度 < `E` 长度 → 存在环，报错中断。
   - **波次标注**：同一轮入队的节点属于同一波次（可并行，但单文档约束下串行执行同波次内按 element_id 字母序）。
   - **禁止**：不得忽略、覆盖或自行编造 `depends_on` 关系；不得用要素名字面顺序替代拓扑排序结果。顺序由数据推导，非预写。
   - **输出**：打印实际推导出的执行序列（含波次），例如：
     ```
     波0：OriginalRequirement
     波1：ProductOverview
     波2：BusinessProcess
     波3：Role, BusinessRule
     波4：SubFeature
     波5：Page
     波6：NonFunctional
     波7：Glossary
     ```
     > 此示例基于当前 spec-template-registry 的 depends_on 定义；若 depends_on 变更，输出自动跟随。

## Phase 2：波次调度循环（单文档串行）

FOR EACH element IN 有效执行序列：
  1. **依赖门**：确认 element.depends_on 中每个要素已在 frontmatter.stepsCompleted 且已被用户确认；未满足 → 暂停等待。
  2. **解析 upstream**：对 element.upstream 每条，沿 via_relation(seq) + direction 从已产要素读取上游内容 → 组装 `upstream_payload`。
  3. **组装派发参数**：
     ```
     { element_id, spec_path, standards_refs, execution_mode: "build",
       artifact_target: { scope: "shared", file: fe_output_path, heading: element.name_cn },
       upstream_payload, interaction: { allowed: element.execution.interactive },
       chapter_info: { name_cn: element.name_cn, fields_order: <schema.fields>, backend_only: false } }
     ```
  4. **按 dispatch 模式执行要素**：

     **判定 dispatch 值**：若要素在 spec-template-registry 中 `execution.dispatch` 有值 → 用它；否则继承 `config.yaml.execution_dispatch` 全局值。得到 `dispatch` = `subagent` 或 `inline`。

     ### 分支 A：dispatch = "subagent"

     使用 Agent 工具调用 subAgent，参数如下：
     - `subagent_type`: 不填（默认通用类型）
     - `description`: "FE-{element_id} 要素执行"
     - `prompt`: 包含以下内容（按 element-runner.md Step 0 的参数结构组织）：
       ```
       你是 element-runner subAgent。请严格按照 engine/element-runner.md 的 Step 0~5 执行。

       ## 派发参数
       element_id        : "{element_id}"
       spec_path         : "{spec_path}"
       standards_refs    : {standards_refs}
       execution_mode    : "build"
       artifact_target   :
         scope           : "shared"
         file            : "{fe_output_path}"
         heading         : "{element.name_cn}"
       upstream_payload  : {upstream_payload JSON}
       interaction       :
         allowed         : {element.execution.interactive}
         resume_token    : ""
         answer          : ""
       chapter_info      :
         name_cn         : "{element.name_cn}"
         fields_order    : {schema.fields}
         backend_only    : false

       ## 关键约束
       - 先 Read engine/element-runner.md 获取完整执行流程
       - 按 Step 1→2→3→4→5 顺序执行，不可跳步
       - [交互] 步必须返回 ## 待确认，禁止自行补全
       - 写入前必须先 Read artifact_target.file 取最新内容
       - 返回 DONE + 质量自检报告 + 汇总输入
       ```

     ### 分支 B：dispatch = "inline"

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

  5. **接收返回 + 逐要素确认（硬规则）**：
     - 若返回 `## 待确认`（该要素含 [交互] 步）→ **主 agent 必须停止推进、把问题呈现给用户、结束本次回复、等待用户回复**；收到答复后 RESUME 该要素直至 DONE。**严禁在用户确认前继续派发任何后续要素。**
     - 若返回 `DONE`（execution.interactive=true 的要素）→ 仍需向用户展示该要素结果并取得"继续"确认，才推进下一个（可批量确认 execution.interactive=false 的要素）。
     - 若返回 `DONE`（execution.interactive=false，如 Glossary）→ 可直接继续。
  6. **轻量后置校验**：无占位符 / 无空内容 / `## 汇总输入` 块存在；不通过 → 暂停报告。
  7. **写 frontmatter**（主 agent）：stepsCompleted += element_id；last_element = element_id；last_updated = 今日；收集 `## 汇总输入`。
  8. **处理回填**：若 `## 汇总输入.backfilled` 非空（本阶段 FE 一般为空，回填在 PRD），记录。

## Phase 3：汇总 + 统一编号

1. **统一编号**：全部要素生成后，按要素类型给实例分配稳定连续编号，并回写文档与其 id：
   - 角色 `ROLE-01…`、业务规则 `RULE-01…`、业务流程 `PROC-01…`、子特性沿用 `FR-001…`（fr_code）、页面 `PAGE-01…`、非功能 `NFR-01…`、术语 `GL-01…`。
   - 编号写入各要素实例 common_fields.id，并在文档节的表格首列体现，供跨要素引用（如子特性引用角色编号）。
2. **汇总**：合并各要素 `## 汇总输入` → FE 文档收尾（目录/索引，如需）。

## Phase 4：末尾一次汇总确认（始终有）

输出整体确认（变更总览 + 9 要素摘要）：
```
── FE 生成完成，请整体确认 ──
  已生成：{9 要素摘要}
  [C] 确认并结束   [B] 返修某要素   [S] 查看全文   [Q] 保存并退出
```
等待用户整体确认（即便过程中已逐个确认，此步必有）。

## Phase 5：完成收尾

1. 跨要素一致性检查（关系字段引用的上游要素均已存在于本文档）。
2. 写输出文档 frontmatter.status = "completed"。
3. **更新 ongoing.md**（运行时全局锚点，主 agent 写）：
   ```yaml
   current_version: "{version}"          # 当前项目版本目录（用户/系统给定）
   project_name: "{project}"
   workflow_hint: "fe-new-build"          # 供 workflow-engine 断点/续接
   fe:                                    # 本 Skill 命名空间（禁跨命名空间互写）
     current_path: "{output 路径}"
     status: "completed"
     stepsCompleted: [ ...要素... ]
     last_updated: "{今日}"
   ```
   > ongoing.md 记录"跨 Skill 全局锚点 + 各 Skill 进度"，是断点恢复与 FE→PRD→TDD 协同的基础，每个 Skill 结束都要更新自己的命名空间。要素级细状态存在输出文档 frontmatter，二者分工。
4. 输出 SKILL.md 的完成提示模板。
