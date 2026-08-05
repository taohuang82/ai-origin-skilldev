# 把 Coding Agent 代码接纳率从 50% 提上去:存量 Java 代码的逆向文档 + Harness 方案

> 适用对象:开发负责人、Coding Agent 工程化负责人
> 存量代码特征:Java/Spring、JDK 1.8、MySQL + 高斯DB、前端 Vue、前后端分离、3 年以上、文档缺失、存在 A→B→A 残留死代码
> 现有内网管线:sys_kl(逆向代码的系统知识库)→ biz_kl(面向人的业务知识库)→ 历史方案文档补充
> 现状痛点:20 人天以下零星需求可用;稍大或代码不规范时,专业开发只能接纳 Coding Agent 产出代码的约 50%
> 研究性质说明:代码在公司内网,本研究无法实测,所有涉及 sys_kl 的判断均标注「基于领导描述,未实测」;选型与路线图基于公开论文/开源项目/案例数字论证。

---

## 一、一页纸执行摘要

**问题**:50% 接纳率的根因不是「Agent 不够聪明」,而是「Agent 拿到的上下文是错的或残缺的」——sys_kl 在不规范代码上失真,biz_kl 把脆弱推断当事实喂给 Agent,且没有自动验收闸门把人工才能发现的问题前置成自动失败。

**核心结论**:五支独立团队(OpenAI、Anthropic、Carlini、Horthy、Vasilopoulos)收敛出同一论断——「瓶颈是基础设施,不是智力」[1]。把接纳率提上去靠三件事:(1)让逆向文档「诚实」(猜的标出来、缺口留给人);(2)用 characterization test 锁死当前行为,治 A→B→A 残留;(3)建 Claude Code Harness,把人工验收拆成自动闸门 + 关键点人审。

**三条最高优先级动作**:
1. **给 sys_kl 加三态置信度标注 + 缺口显式保留**(引 Reversa 的 confirmed/inferred/gap 模型 [2]、Macke & Doyle「错误文档比缺失文档更伤 LLM」结论),让 biz_kl 不再把脆弱推断当事实——预估贡献 +10~15 个百分点。
2. **在 A→B→A 重灾区模块补 characterization test + 标 KNOWN DEFECT + git 考古推断当前生效规则**(引 Feathers《修改代码的艺术》[3]、techtrend PR #376 范例 [4])——预估贡献 +5~10 个百分点。
3. **落地 Claude Code Harness**:AGENTS.md 活约束 + 三层上下文 + PIV 循环 + 验收闸门(lint/类型/单测/characterization/依赖分层护栏)(引 autonomous-coding-harness [5]、Atomic 四支柱 [1]、OpenAI harness 工程 [6])——预估贡献 +10~15 个百分点。

**量化路径**:50% → 75%~85%(三项叠加,去重后估算),每条措施标预估贡献。

---

## 二、现状诊断:50% 接纳率根因分解

「50% 接纳率」意味着 Agent 产出的代码里有一半需要人工返工或重写。根因不在 Agent 本身,而在「上下文供给」和「验收机制」两条链路。以下 6 条根因,每条指向一个可定位的失真点:

### 根因 1:sys_kl 在不规范代码上「把脆弱推断当事实」
- **现象**(基于领导描述,未实测):sys_kl 逆向出的系统知识在不规范代码上准确性差。
- **失真点**:传统逆向工具倾向「补全」而非「留白」。当命名混乱、A→B→A 残留、上帝类存在时,工具会基于模式猜测,但把猜测写成确定性陈述。
- **理论依据**:Macke & Doyle(2024)实证结论——「错误文档会损害 LLM 代码理解,而缺失/不完整文档并不一定产生同种危害」[2]。也就是说,sys_kl 把猜的写成事实,比没有 sys_kl 更糟,因为它主动误导 Agent。
- **后果**:biz_kl 继承这些「伪事实」,Agent 据此生成代码,人工一查发现前提就是错的。

### 根因 2:biz_kl 与代码「单向生成、无双向 trace」,文档代码快速漂移
- **现象**:sys_kl → biz_kl 是单向管线,历史方案文档补充也是一次性抽取。
- **失真点**:没有「Agent 改代码时 biz_kl 同步更新」的闭环。代码改了 3 轮,biz_kl 还停在初版。
- **理论依据**:Reversa 强调 traceability(代码↔规格可追溯)是「可维护运营产物」的前提,而非静态文档 [2];OpenAI harness 把 AGENTS.md 当「dynamic feedback loop」(活约束),遇失败即迭代更新 [1]。
- **后果**:Agent 拿到的 biz_kl 与实际代码不一致,按过时文档生成的代码自然不被接纳。

### 根因 3:A→B→A 残留死代码无安全网,Agent 无法判断「当前生效规则」
- **现象**(基于领导描述,未实测):业务规则开始是 A,改成 B,又改回 A,但 B 的代码还在。
- **失真点**:没有任何机制把「当前实际生效的是 A」这个事实钉死。Agent 看到两套逻辑,要么猜错,要么「好心」把 B 也激活。
- **理论依据**:Feathers 重新定义「遗留代码 = 没有测试的代码」,characterization test 的核心是「Test what IS, not what SHOULD BE」(锁住当前实际行为,含 bug)[3];techtrend PR #376 用 73 个 characterization snapshot 锁行为后删除 134 个归档脚本(17,779 LOC)[4]。
- **后果**:Agent 在没有安全网的情况下重构/扩展,触发「brownfield over-refactor」反模式——产出「plausible-looking, syntactically valid, semantically wrong changes」(看起来合理、语法正确、语义错误)[3]。

### 根因 4:上下文「一次性灌满」而非「三层渐进披露」,Agent 在 dumb zone 工作
- **现象**:Agent 拿到的上下文要么太少(缺关键约束)要么太多(灌满整个仓库)。
- **失真点**:没有分层上下文管理。
- **理论依据**:Horthy 的经验观察——对 ~168K token 上下文窗口,性能在约 40% 利用率处开始下降,超过即进入「Dumb Zone」(幻觉、循环、畸形工具调用)[1];Vasilopoulos(2026)对 108,000 行 C# 系统的学术验证——单文件 AGENTS.md 在规模上失效,需三层架构(Hot-Memory Constitution / 19 个专门 domain agent / 34 个冷记忆规范文档)[1]。
- **后果**:Agent 要么因缺关键约束而猜错,要么因上下文过载而信号密度下降,两者都拉低接纳率。

### 根因 5:验收全靠人工,没有自动闸门把「人工才能发现的问题」前置
- **现象**:50% 里被拒的代码,很多是人工 review 才发现的问题(违反依赖分层、破坏既有行为、风格不一致)。
- **失真点**:验收闸门缺失或形同虚设。
- **理论依据**:autonomous-coding-harness 的「复利误差」论断——「95% 单步可靠性,20 步 = 36% 系统可靠性」,故设四阶段质量保障 + 硬停止护栏(测试因 agent 改动失败时不得实现新特性)[5];OpenAI 案例用「自定义 linter + 结构测试」强制依赖层 `Types → Config → Repo → Service → Runtime → UI`,agent 无法违反模块边界 [1]。
- **后果**:本可在提交前自动拦截的问题流到人工 review,既拖慢接纳,又让 50% 里相当一部分返工是「低级问题」而非「业务判断问题」。

### 根因 6:状态靠对话历史,Agent 跨 session 失忆重做
- **现象**:稍大需求跨多个 session,Agent 上下文遗忘、错误累积、过早宣告完成。
- **失真点**:状态存在对话窗口而非文件系统。
- **理论依据**:Mastra 指出两大失败模式——「context rot」(上下文腐烂,信号密度下降但永不报错)和「lossy compaction」(有损压缩丢掉需求精确措辞和 edge case)[7];autonomous-coding-harness 用 Git 历史 + JSON 进度文件 + 工单 comment 做状态外部化 [5];Atomic 用文件系统研究文档 + 进度文件 [1]。
- **后果**:每个新 session 重新理解项目,重复犯错,人工反复纠正同一类问题。

---

## 三、方向一:逆向文档——为什么 sys_kl/biz_kl 在不规范代码上失真,怎么补

### 3.1 sys_kl 这类「代码→系统知识库」管线在不规范代码上的典型失真点

基于 Reversa [2]、cc-rsg [8]、KDM/ADM [9][10]、Siala & Lano(2025)[11] 的论述,失真点有五类:

1. **隐式规则无法显式化**:遗留知识一部分显式(函数名、SQL、校验、配置),另一部分隐式于实现模式、变更历史、tacit knowledge 中 [2]。sys_kl 若只做静态解析,会漏掉隐式规则(权限、状态、异常分支)。
2. **脆弱推断被写成事实**:基于命名/模式的猜测被包装成确定性陈述,违背 Macke & Doyle「错误文档比缺失文档更伤 LLM」结论 [2]。
3. **死代码与活代码混为一谈**:A→B→A 残留中,B 路径仍被解析为「有效逻辑」,无法区分当前生效规则。CAST 结构分析显示大型 COBOL 资产中死代码可占总量高达 25% [12]。
4. **覆盖面靠文本量而非机械校验**:没有「全件枚举 + 机械覆盖校验」,抽取是采样式的,重要模块可能根本没被覆盖。
5. **纯 LLM 主导,无确定性图托底**:Siala & Lano(2025)实证——基线 LLM 在抽象形式化规约时「prone to errors」(易错);微调后可比规则方法,但「确定性 MDRE + LLM」组合方法取得最佳结果 [11]。

### 3.2 开源项目对比表(行为级文档 vs codewiki)

| 维度 | Reversa [2] | cc-rsg [8] | DeepWiki-Open [13] | Kodesage [14] | CodeSee [15] |
|---|---|---|---|---|---|
| **文档层级定位** | 运营级规格(agent 可消费的行为契约) | 规格文档(行号级溯源) | 仓库级架构 Wiki(codewiki) | 函数级行为文档(plain English) | 结构可视化地图 |
| **行号级溯源** | ✅ 每条 claim 可追溯到文件/模块/路由/schema | ✅ 每条陈述带行号级源码引用 | ❌ LLM 主导,无行号溯源 | ✅ AST code map 含调用关系 | ❌ 可视化为主 |
| **置信度标注** | ✅ 三态:confirmed/inferred/gap | ✅ 三标签:🟢VERIFIED/🟡INFERRED/🔴ASSUMED | ❌ 无 | ❌ 无显式标注 | ❌ 无 |
| **缺口显式保留** | ✅ gaps.md/questions.md 独立章节 | ✅ 「未解决事项」独立章节 + Question Bank | ❌ 无 | ❌ 无 | ❌ 无 |
| **Java/JDK1.8 支持** | 引擎无关,Java 经 tree-sitter/解析器 | ✅ 9 语言含 Java,tree-sitter 角色类型化 | 语言无关(LLM 处理,无专用解析) | ✅ 明确支持「遗留 Java」(AST 解析) | Java 在支持列,但扩展已停维 |
| **Claude Code 集成** | ✅ 支持 Claude Code 等 13+ 引擎 | ✅ 原生 Claude Code skill(SKILL.md/subagent) | ❌ 独立 Web 应用 | ❌ 独立平台(本地/气隙) | ❌ VS Code 扩展 |
| **多智能体管线** | ✅ 7 角色(scout/archaeologist/detective/architect/writer/reviewer/orchestrator) | ✅ 按章 subagent 并行调查 | ❌ 单管线 | 部分 | ❌ |
| **机械覆盖校验** | ✅ File/Unit coverage 指标 | ✅ coverage-check.py + granularity 规则 | ❌ | 部分 | ❌ |
| **开源协议** | 论文 + CLI(许可见仓库) | MIT | MIT | 闭源(商业) | 已被 GitKraken 收购 |
| **JDK1.8 精确行为还原** | 强(可追溯 + 置信度) | 强(行号 + 三标签) | 弱(LLM 主导无解析) | 中(AST 但闭源) | 弱(可视化为主) |

**选型建议**:
- **首选 cc-rsg** 作为 Claude Code 生态内的逆向文档主力工具 [8]:原生 SKILL.md/subagent/AskUserQuestion/Task 集成,6+1 阶段状态机,tree-sitter 支持 Java,行号级溯源 + 三态置信度 + 缺口保留 + 机械覆盖校验齐全,且与 cc-sdd(正向 spec→code)形成闭环。MIT 协议,可直接放入 `.claude/skills/`。
- **Reversa** 作为理论参照与评估协议来源 [2]:其 confirmed/inferred/gap 三态模型、traceability 矩阵、confidence-report/gaps.md/questions.md 产物结构,可直接借鉴进 sys_kl 改造;其评估指标(File coverage/Unit coverage/Traceability density/Confidence distribution/Blocking gaps)可作为 sys_kl 质量度量基线。
- **Kodesage** 作为「遗留 Java 行为级文档」的商业备选 [14]:若内网需本地/气隙部署且要函数级行为说明,Kodesage 的 AST 解析 + 遗留 Java 定位最契合;但闭源,需评估采购。
- **DeepWiki-Open** 仅用于快速生成仓库级架构 Wiki(onboarding 用),不用于行为级规格 [13]。
- **CodeSee** 不推荐:结构可视化且主力产品已易主、扩展停维 [15]。

### 3.3 A→B→A 残留死代码的具体处理做法

四步法(引 Feathers《修改代码的艺术》[3]、techtrend PR #376 [4]、OpenAI harness 工程 [6]):

1. **对每段疑似死代码写 characterization test**:锁住「当前实际行为」(不是应有行为)。Feathers 原则——「The code is the specification — existing behavior IS the requirement until proven otherwise」[3]。配合 Approval Testing / Golden Master:运行代码→序列化输出→作为黄金文件→后续每次运行比对。
2. **标 KNOWN DEFECT**:若捕获到的行为本身是 bug(B 路径仍在被错误触发),测试显式保留这个 bug 并打 `@known_defect` 标记,使其可见可决策,而非偷偷修正 [3]。
3. **git 历史考古推断当前生效规则**:用 `git log -p` / `git blame` 追溯 A→B→A 轨迹,判断 B 路径是否仍被任何入口可达。这一步业界称「code archaeology」[4]。
4. **可达性验证 + 删除 + 可回滚**:用 ripgrep/CI 引用审查确认无生产引用后删除,git 历史作为回滚兜底。techtrend PR #376 范例:73 个 characterization snapshot 锁行为后删 134 个归档脚本(17,779 LOC),回滚策略明确写「Git history preserves all deleted content」[4]。

**配合 OpenAI harness 的「结构化测试 + 可观测驱动」** [6]:characterization test 提供离线/构建期安全网(锁当前行为),Shadow Testing(线上老系统实际输出作 golden ground truth,持续比对新系统输出)提供运行期安全网;两者共同把 Agent 限制在安全轨道。OpenAI Evals 框架建议「Capture JSONL with `codex exec --json` and write deterministic checks」+「Let real failures drive coverage」[6]。

### 3.4 现有 sys_kl 管线最少补强的 5 块

每块说清解决哪个失真、引哪个开源做法、工作量量级(估算):

| # | 补强项 | 解决的失真 | 借鉴的开源做法 | 工作量量级(估算) |
|---|---|---|---|---|
| 1 | **三态置信度标注** | 根因 1(脆弱推断当事实) | Reversa confirmed/inferred/gap [2];cc-rsg 🟢/🟡/🔴 标签 [8] | 中:改 sys_kl 输出 schema + 抽取规则加置信判定 |
| 2 | **缺口显式保留** | 根因 1(补全 vs 留白) | Reversa gaps.md/questions.md [2];cc-rsg Question Bank 7 分类 [8] | 中:新增缺口产物 + biz_kl 渲染缺口章节 |
| 3 | **行号级溯源** | 根因 2(无 trace) | cc-rsg build-trace.py + traceability.md [8];Reversa code-spec-matrix [2] | 中:sys_kl 每条断言附 file:line + 生成 trace 矩阵 |
| 4 | **机械覆盖校验** | 根因 1(采样式抽取) | cc-rsg coverage-check.py + granularity 规则(最低件数 max(50, file_count//20))[8];Reversa File/Unit coverage [2] | 小:加覆盖校验脚本 + 不达标报警 |
| 5 | **确定性图 + LLM 混合** | 根因 1(纯 LLM 主导) | KDM/ADM 确定性 parser 产出图,LLM 只翻译图节点 [9][10];Siala & Lano combined approach [11];HCLTech iLIT-AI 用 CAST 知识图注入 LLM 提升准确率 [12] | 大:引入 tree-sitter/AST 解析层(可借 cc-rsg source-map v2),改造 sys_kl 为「图 + LLM」混合 |

> 注:第 5 块工作量大,但收益最高——Siala & Lano(2025)实证 combined approach 优于单独 LLM 或单独 MDRE [11];HCLTech 在 900 万行 COBOL→Java 试点中观察到「注入确定性上下文后准确率有额外提升」[12]。

---

## 四、方向二:Claude Code 生态下的 Harness——怎么协作到 75%+ 接纳率

### 4.1 HITL 检查点设在哪

综合 autonomous-coding-harness 的 8 检查点 [5]、Atomic 四阶段门控 [1]、Mastra plan→build handoff [7]、cc-sdd 的门控哲学 [16],建议在 Claude Code Harness 设 6 个检查点(对应存量项目特点):

| 检查点 | 阶段 | 作用 | 谁审 |
|---|---|---|---|
| **CP1 需求澄清** | 需求提出后 | 人提需求,Agent 用 AskUserQuestion 反问边界(输入/输出/异常/权限),产出 EARS 格式 requirements.md | 提需求的人 |
| **CP2 方案审视** | 设计后 | Agent 产出 design.md(Mermaid + 文件结构 + 影响面),人审「方案对不对」 | 开发负责人 |
| **CP3 characterization 锁定** | 改代码前 | 对涉及模块补 characterization test 锁当前行为,标 KNOWN DEFECT,人确认「锁的行为对不对」 | 专业开发 |
| **CP4 任务拆解** | 实现前 | Agent 产 tasks.md(P0/P1 标并行 wave),人确认拆解合理 | 开发负责人 |
| **CP5 验收闸门** | 实现后 | 自动跑 lint/类型/单测/characterization/依赖分层护栏,全绿才进人审 | 自动 + 专业开发 |
| **CP6 biz_kl 同步** | 合并前 | Agent 改代码时同步更新 biz_kl(双向 trace),人确认文档代码一致 | 专业开发 |

**设计原则**(引 autonomous-coding-harness [5]):「autonomy balance」——Agent 尽可能自主,但在关键决策点留易注入的人类验证点;目标是战略性检查点而非持续打断。每个检查点统一输出格式(WHAT HAPPENED / IF APPROVED / IF REJECTED),支持 Auto-Accept 模式按 agent 独立保存。

**与 cc-sdd 门控哲学一致** [16]:每阶段暂停供人审,除非显式 bypass(`-y`);生产工作保留手动批准,auto-approval 仅用于受控实验。SDD 论文核心洞见——「In spec-driven development, code is the implementation detail of the specification」[16],规范是契约不是主命令。

### 4.2 三层上下文防失忆(JDK1.8 + Vue + 前后端分离)

引 Atomic 三层上下文 [1]、Vasilopoulos 三层架构 [1]、Mastra observational memory [7]、Claude Code 七种指令方法 [17]:

**Tier 1 全局(每 session 自动加载,根目录 AGENTS.md/CLAUDE.md)**:
- 项目结构表(前后端分离:后端 Java/Spring 模块树 + 前端 Vue 页面树)
- 构建/测试/运行命令(JDK1.8 编译命令、Maven/Gradle、前端 npm)
- 编码规范、依赖分层护栏(后端 controller→service→dao→model;前端 view→store→api)
- 禁止事项(触不得的文件、改不得的核心逻辑)
- 实现:用 `ganimjeong/Harness-for-claude` 模板——AGENTS.md 为源,CLAUDE.md 用 symlink 或 `@AGENTS.md` import [18]

**Tier 2 模块级(调用 subagent/skill 时加载)**:
- 每个业务模块的 biz_kl 条目(带行号溯源 + 置信度标签)
- 模块专属约束(如订单模块的状态机、权限矩阵)
- 实现:cc-rsg 的按章 subagent [8];Atomic 的 10 个专门 sub-agent(研究 agent 只读,工作流 agent 限单任务)[1]

**Tier 3 任务级(按需拉取)**:
- 当前任务涉及的 characterization test、git 历史、相关 PR
- 历史 方案文档(从 biz_kl 历史抽取补充)
- 实现:Atomic 的 research/docs/ 持久知识库 [1];Vasilopoulos 的 34 个冷记忆规范文档 [1]

**防失忆的关键机制**(引 Mastra [7]):
- **observational memory**:不靠对话历史,observer model 读对话写结构化观察(决策、事实、状态变化),reflector model 在阈值(默认 40k token)压缩,决策作为决策存活而非埋在摘要转述里 [7]。
- **live task list**:Agent 写/更新/完成前检查的持久 todo,存在 harness display state [7]。
- **状态外部化**:Git 历史(结构化 commit `<type>(#<issue>): <desc>` + 元数据)+ JSON 进度文件(原子写防损坏)+ 工单 comment 做交接 [5]。

**~40% 上下文甜点**(引 Horthy [1]):给 Agent 塞更多 MCP、冗长文档、累积历史不会更聪明而是更糟。三层上下文的目的就是让 Agent 始终工作在 smart zone(前 ~40%),避免 dumb zone(幻觉、循环、畸形工具调用)[1]。

### 4.3 验收闸门设计(把 50% 里「人工才能发现的问题」前置成自动失败)

引 autonomous-coding-harness 四阶段质量保障 + 硬停止护栏 [5]、OpenAI 架构护栏 [1]、Carlini「CI 作为 harness」[1]:

**五道自动闸门(CP5 内)**:

1. **lint + format**:代码风格(引 autonomous-coding-harness「build 与质量门 lint/format/type 必须过」[5])
2. **类型检查**:JDK1.8 编译 + 前端 TypeScript/Vue 类型
3. **单元测试**:强制为新函数/端点/类写单测(每函数 1 happy path + 1 edge case,每端点 1 success + 1 error)[5]
4. **characterization test 回归**:涉及模块的 characterization snapshot 必须不破(Golden Master 比对)[3][4]
5. **依赖分层护栏**:用自定义 linter + 结构测试强制后端 `controller → service → dao → model`、前端 `view → store → api`,Agent 无法违反模块边界(引 OpenAI `Types → Config → Repo → Service → Runtime → UI` 护栏 [1])

**硬停止护栏(circuit breakers,引 autonomous-coding-harness [5])**:
- 测试因 Agent 改动失败时,不得实现新特性
- 所有测试必须过(或显式跳过带原因)才能做新工作
- 质量检查失败不得创建 issue_closure
- 发现任何回归则停止 MR 创建
- biz_kl 未同步更新不得合并

**Claude Code 可落地的 SKILL.md / subagent 分工建议**:
- **planner subagent**:只读,拆 spec 产 tasks.md,无写权限(引 Atomic [1])
- **worker subagent**:限单任务,实现 + 写单测
- **reviewer subagent**:可标记不可修,审计实现是否符合 design.md(引 Atomic「审查计划比审查代码快」[1])
- **debugger subagent**:reviewer 标记问题后路由,定位 + 修复
- **characterization-writer subagent**:专责写 characterization test(引 SQUAD「Phase 1.5: characterization tests written before any code」[3])
- **biz_kl-sync subagent**:代码变更后同步更新 biz_kl 条目(双向 trace)

**Test Repair Loop**(引 autonomous-coding-harness [5]):读测试→诊断(过时测试/实现 bug/flaky)→修复→重跑验证→3 次失败后跳过并建 bug issue。

### 4.4 biz_kl 和 Harness 怎么咬合(双向 trace 防文档代码漂移)

引 Reversa 闭环(Discovery → Migration → Code Forward)[2]、OpenAI AGENTS.md 活约束 [1]:

**双向 trace 机制**:
- **代码 → biz_kl**:Agent 改代码时,biz_kl-sync subagent 自动定位受影响的 biz_kl 条目(通过行号溯源矩阵),更新或标记「需人确认」。
- **biz_kl → 代码**:Agent 接需求时,先读 biz_kl 条目(带置信度标签),🔴ASSUMED 条目必须 CP1 向人确认后才能作为实现依据。
- **闭环**:逆向文档(Discovery,cc-rsg 产 spec)→ 需求实现(Migration,Coding Agent 改代码)→ 演进(Code Forward,biz_kl 同步更新)形成闭环 [2]。逆向文档成为「可维护的运营产物」而非静态文档。

**防漂移的硬约束**:CP6 检查点——biz_kl 未同步更新不得合并;OpenAI 案例的 AGENTS.md 是「遇失败即迭代更新」的活约束 [1],biz_kl 同理,每次代码变更触发 biz_kl 条目置信度重评。

---

## 五、落地路线图(0-30 天 / 31-90 天 / 90 天后)

### 0-30 天:止血 + 建基础(预估 50% → 60~65%)

| 动作 | 详情 | 预估贡献 | 验证方式 |
|---|---|---|---|
| **A1 试点 cc-rsg** | 选 1 个 A→B→A 重灾区模块,用 cc-rsg 跑逆向,产出带行号溯源 + 三态置信度的 spec [8] | 验证工具可用性 | spec 产物存在 + 专业开发确认行号溯源准确 |
| **A2 给 sys_kl 加三态置信度标注** | 改 sys_kl 输出 schema,每条断言标 confirmed/inferred/gap [2] | +5~8 pp | 抽样 100 条断言,inferred/gap 占比 ≥20%(说明不再全当事实) |
| **A3 补 characterization test** | 在试点模块对疑似死代码写 characterization test + 标 KNOWN DEFECT + git 考古 [3][4] | +3~5 pp | characterization test 数量 + Golden Master 比对通过 |
| **A4 落地 AGENTS.md + CLAUDE.md** | 用 Harness-for-claude 模板,写全局 AGENTS.md(项目结构/命令/规范/禁止事项)[18] | 基础设施 | Agent 新 session 自动加载 + 上下文利用率 <40% |

### 31-90 天:扩面 + 建闸门(预估 60~65% → 70~80%)

| 动作 | 详情 | 预估贡献 | 验证方式 |
|---|---|---|---|
| **B1 sys_kl 加缺口保留 + 行号溯源 + 机械覆盖** | 补强 3.4 的第 2/3/4 块 [2][8] | +5~8 pp | 覆盖校验不达标报警 + 缺口章节数量 |
| **B2 落地 6 检查点 Harness** | 基于 autonomous-coding-harness 模式 [5] + cc-sdd 门控 [16],在 Claude Code 实现 CP1-CP6 | +5~8 pp | 6 检查点全部触发 + Auto-Accept 模式可用 |
| **B3 落地五道自动闸门** | lint/类型/单测/characterization/依赖分层护栏 + 硬停止 [5][1] | +5~8 pp | 闸门拦截率(被自动拦的 PR 占比) |
| **B4 biz_kl 双向 trace** | biz_kl-sync subagent + CP6 硬约束 [2][1] | +3~5 pp | 代码变更后 biz_kl 同步率 ≥90% |
| **B5 扩到 3-5 个模块** | 试点模块经验复制 | 规模化验证 | 接纳率抽样统计 |

### 90 天后:确定性图 + LLM 混合 + 规模化(预估 75% → 80~85%)

| 动作 | 详情 | 预估贡献 | 验证方式 |
|---|---|---|---|
| **C1 sys_kl 改造为「确定性图 + LLM」混合** | 引 tree-sitter/AST 解析层(借 cc-rsg source-map v2 [8]),确定性图保证可达性不幻觉,LLM 只翻译图节点 [9][10][11][12] | +5~10 pp | Siala & Lano combined approach 准确率对比 [11] |
| **C2 全量模块覆盖** | sys_kl/biz_kl 全量改造 | 规模化 | 全模块覆盖率 + 接纳率统计 |
| **C3 observational memory + 状态外部化** | 引 Mastra observational memory [7] + autonomous-coding-harness 状态外部化 [5] | +3~5 pp | 跨 session 失忆问题减少 |
| **C4 持续度量** | 用 Reversa 评估指标(File coverage/Unit coverage/Traceability density/Confidence distribution/Blocking gaps/Expert precision/Agent utility)[2] | 持续改进 | 月度接纳率报告 |

**量化路径汇总(估算,去重后)**:
- 0-30 天:50% → 60~65%(三态置信度 + characterization + AGENTS.md)
- 31-90 天:60~65% → 70~80%(缺口保留 + 行号溯源 + 6 检查点 + 五道闸门 + 双向 trace)
- 90 天后:70~80% → 80~85%(确定性图 + LLM 混合 + 全量覆盖)
- 目标:75%+ 达成(31-90 天阶段),80~85% 可期(90 天后)

> 估算依据:每条措施的预估贡献基于公开案例的定性结论(如 Macke & Doyle「错误文档比缺失文档更伤 LLM」[2]、Horthy 40% 甜点 [1]、HCLTech 注入确定性上下文后准确率提升 [12]),非受控实验数字,标「估算」。

---

## 六、风险与缺口(诚实标注)

1. **未验证假设**:50% 接纳率「基于领导描述,未实测」——本研究无法访问内网代码,无法独立核实 50% 这个数字的统计口径(是按 PR 数?按代码行?按模块?),也无法核实 sys_kl 失真的具体形态。**需内网实测确认**:选 3-5 个被拒 PR,做根因归因,验证本报告 6 条根因的占比。
2. **需内网实测确认的点**:
   - sys_kl 当前输出 schema 是否支持加置信度标注(决定 A2 工作量)
   - biz_kl 的存储形式(数据库?文档?)决定双向 trace 实现方式
   - 现有 CI/CD 是否支持加依赖分层护栏(决定 B3)
   - JDK1.8 编译环境与 Claude Code 的集成方式(内网部署/代理)
3. **开源项目对 JDK1.8 兼容性未知**:
   - cc-rsg 的 tree-sitter Java 抽取器在 JDK1.8 代码上的覆盖率未实测(Java 8 语法相对成熟,理论支持,但框架检测 Spring 版本需确认)[8]
   - characterization test 框架(JUnit4/5、Mockito 版本)需与 JDK1.8 兼容
4. **Reversa/cc-rsg 无大规模 Java 工业案例**:Reversa 案例是 COBOL→Go(教育项目)[2],cc-rsg 处于 v0.7.0(Roadmap v1.0 待实项目应用后稳定)[8]。Java/Spring + JDK1.8 + 前后端分离的组合无公开先例,需试点验证。
5. **Kodesage 闭源**:若选 Kodesage 作为商业备选,需评估采购成本与内网气隙部署可行性 [14]。
6. **OpenAI/Anthropic 原文链接待核**:OpenAI 官方《Harness engineering: leveraging Codex in an agent-first world》(2026-02)与 Anthropic Carlini 编译器项目的直达原文,本研究经中文技术博客引述核实核心论断,但未直接抓取到一级域名原文页面 [6]。如需逐字引用建议从官方检索。
7. **估算的不确定性**:量化路径(50%→75%+)的预估贡献是定性估算,非受控实验。实际提升取决于根因占比、团队执行力、Agent 平台成熟度。建议设月度接纳率度量,动态校正。
8. **Martin Fowler bliki 的 CharacterizationTest 专页不存在**(404),Feathers 权威定义改由 Michael Cutler 博客直接引《Working Effectively with Legacy Code》第 13 章 [3]。

---

## 七、参考(每条带可打开链接)

1. [Atomic: How to Harness Coding Agents with the Right Infrastructure(alexlavaee.me)](https://alexlavaee.me/blog/harness-engineering-why-coding-agents-need-infrastructure/) — harness engineering 四支柱、OpenAI 百万行案例、Anthropic 16 并行 Claude 编译器案例、Horthy 40% 甜点、Vasilopoulos 三层上下文 283 会话验证
2. [Reversa: A Reverse Documentation Engineering Framework(arXiv:2605.18684)](https://arxiv.org/html/2605.18684) — 多智能体管线、confirmed/inferred/gap 三态置信度、traceability 矩阵、gaps.md/questions.md、COBOL→Go 案例(517 claims/10 gaps/53 Gherkin)、评估指标、Macke & Doyle「错误文档比缺失文档更伤 LLM」
3. [Michael Cutler — Characterisation Tests Before Agents Touch Brownfield Code(cutler.sg)](https://cutler.sg/blog/2026-05-characterisation-tests-brownfield-agents) — Feathers《修改代码的艺术》第 13 章权威引述、characterization test 定义、KNOWN DEFECT 标记、brownfield over-refactor 反模式
4. [techtrend PR #376 — characterization tests and archive deletion(GitHub)](https://github.com/pawafulu7/techtrend/pull/376) — 73 个 characterization snapshot 锁行为后删 134 个归档脚本(17,779 LOC)的真实工程范例
5. [autonomous-coding-harness(GitHub README)](https://github.com/GantisStorm/autonomous-coding-harness/blob/main/README.md) — 8 个 HITL 检查点、PIV 循环、三代理架构、状态外部化(Git/工单/JSON)、四阶段质量保障 + 硬停止护栏、复利误差论断
6. [CSDN — Harness Engineering 介绍与概述(引 OpenAI 官方文章)](https://blog.csdn.net/qxmlovezn/article/details/160086657) — OpenAI harness 工程定义、机械化约束、Plans as First-class Artifacts、Shadow Testing、可观测驱动;[OpenAI Developers — Working with evals](https://developers.openai.com/api/docs/guides/evals) / [Testing Agent Skills Systematically with Evals](https://developers.openai.com/blog/eval-skills)
7. [Mastra — Anatomy of a harness: building a coding agent that can run for hours](https://mastra.ai/blog/anatomy-of-a-coding-agent) — context rot/lossy compaction 两大失败模式、thread 持久化、live task list、interrupt/queue/steer、askUser/plan approval、plan→build handoff、approval chain、observational memory
8. [cc-rsg — Claude Code Reverse Spec Generator(GitHub)](https://github.com/daishir0/cc-rsg) — code→spec 逆向、五原则(Honesty/Traceability/Completeness/Progressive elaboration/Resumability)、6+1 阶段状态机、source-map v2 tree-sitter 9 语言、三态置信标签、Question Bank 7 分类、coverage-check.py、与 cc-sdd 的反向对关系、Design Heritage(KDM/OMG ADM/Siala & Lano/Reversa/IBM watsonx/AWS Transform/CAST Imaging)
9. [ISO/IEC 19506:2012 — Knowledge Discovery Meta-Model(KDM)官方标准页](https://www.iso.org/cms/live/live/en/sites/isoorg/contents/data/standard/03/26/32625.html) — KDM 元模型定义、语言无关结构化知识表示、2025 年复审确认现行
10. [Nantes 大学 — Model Driven Reverse Engineering(MoDisco)讲义](https://gl.univ-nantes.io/mde/slides/mdre.html) — ADM 流程(parser→ASTM→KDM)、MDRE 定义(Chikofsky & Cross 1990)、Eclipse MoDisco 参考实现、MDRE 综述(64 方法,程序理解/文档化 29/64 最普遍,UML 最常用输出,Java 27 方法主流输入)
11. [Siala & Lano (2025) — A comparison of LLMs and MDRE for reverse engineering(Front. Comput. Sci.)](https://www.frontiersin.org/journals/computer-science/articles/10.3389/fcomp.2025.1516410/full) — LLM 抽象形式化规约易错、微调后可比规则方法、LLM4Models 在 Java 完整性超 AgileUML、combined approach 取得最佳结果
12. [HCLTech — From COBOL to Modern Java: AI-powered two-step code conversion](https://www.hcltech.com/de-de/blogs/cobol-to-java-modernization) — CAST 确定性知识图经 MCP 注入 LLM、900 万行 COBOL→Java 试点、注入确定性上下文后准确率额外提升、CAST 识别死代码(大型 COBOL 资产死代码可占 25%)
13. [DeepWiki-Open(GitHub AsyncFuncAI/deepwiki-open)](https://github.com/AsyncFuncAI/deepwiki-open) — AI 驱动仓库级 Wiki 生成器、LLM 主导语言无关、codewiki 定位
14. [Kodesage — AI Documentation Tools for Legacy Code / COBOL Modernization](https://kodesage.ai/blog/ai-documentation-tools-for-legacy-code) — AST 解析 + LLM 混合、函数级行为文档、遗留 Java/COBOL/PL/SQL 支持、本地/气隙部署、retroactive tests 生成
15. [CodeSee — VS Code Marketplace(已停维)/ TiorAI 词条](https://marketplace.visualstudio.com/items?itemName=codesee.codesee-symbol-maps) — 代码库结构可视化、Java 在支持列但扩展停维、已被 GitKraken 收购
16. [cc-sdd — Spec Driven Development(GitHub takaram/cc-sdd)](https://github.com/takaram/cc-sdd) / [spec-driven 指南](https://github.com/get-seting/cc-sdd/blob/main/docs/guides/spec-driven.md) / [SDD 论文(openreview)](https://openreview.net/attachment?id=bw5mNj75h9&name=pdf) — spec→code 正向流程、AI-DLC 8 步、门控哲学、SDD 三级严谨度(spec-first/spec-anchored/spec-as-source)、「code is the implementation detail of the specification」
17. [Steering Claude Code — Skills, Hooks, Rules, Subagents(官方)](https://claude.com/blog/steering-claude-code-skills-hooks-rules-subagents-and-more) — Claude Code 七种指令方法(CLAUDE.md/rules/skills/subagents/hooks)的加载时机/压缩行为/context cost 对比
18. [Harness-for-claude 模板(GitHub ganimjeong)](https://github.com/ganimjeong/Harness-for-claude) — AGENTS.md 为源、CLAUDE.md 用 symlink 的实践模板
19. [AGENTS.md vs CLAUDE.md(Shawn Mayzes)](https://www.shawnmayzes.com/ai-engineering/agents-md-vs-claude-md/) — AGENTS.md 由来(OpenAI 2025-08)、spec 化结构、AAIF 接受、60,000+ 项目采用、Claude Code 不读 AGENTS.md 的现状与 workaround
20. [Avesta HQ — Characterisation Tests: The Safety Net You Need Before Touching Legacy Code](https://www.avestahq.com/blog/characterisation-tests-safety-net-legacy-code) — characterization test vs TDD 单元测试对比、Approval Testing/Golden Master、Feathers「legacy code = code without tests」
