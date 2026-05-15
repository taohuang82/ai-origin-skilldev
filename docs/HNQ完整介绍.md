# HNQ 完整介绍

## 一、概述

### 1.1 什么是 HNQ

HNQ是数字化产品的 AI 研发平台。它覆盖研发全生命周期：需求分析、设计、实现、测试、部署，基于 **ICOV 框架**（输入 → 能力 → 输出 → 验证）。

### 1.2 核心架构

HNQ 采用三层架构：

```
┌─────────────────────────────────────────────────────────┐
│                    Commands Layer                        │
│  (用户入口：iscit-pilot, iscit-dev-new, iscit-kl-build...) │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                   Orchestrator Layer                     │
│  (编排器：Pilot内核、dev、kl-build、req-analy、ps...)      │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                    Skills Layer                          │
│  (原子能力：babelfish、biz-kl-builder、TDD、brainstorm...) │
└─────────────────────────────────────────────────────────┘
```

### 1.3 ICOV 框架

每个 HNQ 能力都遵循 ICOV 框架：

- **I（Input）**：定义边界和需求
- **C（Capability）**：编排 skills 和子代理
- **O（Output）**：产出可验证交付物
- **V（Validation）**：闭环反馈

---

## 二、核心组件：Pilot 执行内核

### 2.1 Pilot 内核概述

Pilot 内核是 HNQ 的核心执行管理框架，为所有 `iscit-*` 命令提供统一的会话管理与状态机路由。

**核心能力**：
- 两层状态机：旅程级（自动推荐下一个 command）+ 命令级（command 内路由 sub-skill）
- 会话持久化：`workspace/.session/session.yaml`（机器状态）+ `SESSION.md`（人类仪表盘）
- Checkpoint / 恢复：跨 agent 会话可续接
- 多 agent 适配：支持 OpenCode、Cursor、Claude Code 等多种运行环境

### 2.2 Pilot 协议体系

Pilot 内核定义了 6 个核心协议：

| 协议 | 名称 | 触发时机 | 核心职责 |
|------|------|---------|---------|
| 协议 0 | 检测状态 | 每次交互第一步 | 扫描项目文件，确定两层状态机位置 |
| 协议 1 | 路由 | 协议 0 之后 | 根据状态决定下一步动作 |
| 协议 2 | 初始化会话 | 命令选定后 | 创建新会话目录和 session.yaml |
| 协议 3 | 分解 | 协议 2 之后 | 从编排器 SKILL.md 提取 L1/L2 结构 |
| 协议 4 | 执行 | 协议 3 之后 | 运行当前步骤，更新状态 |
| 协议 5 | 检查点 | L1 阶段完成 | 持久化阶段完成状态 |
| 协议 6 | 恢复 | 发现活跃会话 | 从已有 session 恢复执行 |

### 2.3 会话文件结构

```
workspace/.session/
├── 20260413-001/              ← 当前会话目录
│   ├── session.yaml           ← 机器可读状态
│   └── SESSION.md             ← 人类可读仪表盘
├── current -> 20260413-001    ← 当前活跃会话指针
└── archive/                   ← 已完成会话归档
    └── 20260410-001/
```

### 2.4 多 Agent 适配

| 运行环境 | 适配方式 | 体验 |
|---------|---------|------|
| OpenCode + plugin | `pilot-kernel-plugin.js` 提供自动化 tools | 最佳：状态自动检测、产物自动追踪 |
| Cursor + rule | `cursor-rule.md` 作为 always-on rule | 良好：LLM 知道内核存在，手动读写 |
| Claude Code + hooks | `pilot-cli.js` + hooks.json | 良好：SessionStart 自动注入状态 |
| 其他 agent | 纯通用层：LLM 读 SKILL.md 执行协议 | 基本可用 |

---

## 三、Commands（命令层）

HNQ 提供完整的命令体系，覆盖研发全流程。

### 3.1 核心命令

| 命令 | 说明 | 路由目标 |
|------|------|---------|
| `iscit-pilot` | Pilot 内核入口（旅程导航 / auto / status / history） | skills/iscit-pilot-skills |
| `iscit-ps` | Project Space 管理（create / track / use / checkout / sync） | skills/iscit-ps-skills |
| `iscit-dev-env-init` | 开发环境初始化（jdtls Java LSP） | skills/dev-env |
| `iscit-kl-build-init` | 知识库全量构建（4阶段流水线） | skills/iscit-kl-build-skills |
| `iscit-kl-build-refine` | 知识库迭代精炼 | skills/iscit-kl-build-skills |
| `iscit-req-analy` | 需求分析 | skills/iscit-req-analy-skills |
| `iscit-rr-to-design` | 需求到设计全链路 ⟨Beta⟩ | skills/rr-to-design |
| `iscit-dev-new` | 新功能开发（设计 → TDD → 评审） | skills/dev |
| `iscit-dev-fix` | Bug 修复（调试 → TDD 修复 → 验证） | skills/dev |

### 3.2 命令详细说明

#### iscit-pilot

**触发词**：pilot、下一步、继续、what's next、全链路、自动执行、会话状态、旅程

**行为模式**：

1. **不带子命令**：自动检测状态并行动
   - 有活跃会话 → 直接恢复
   - 无活跃会话，有下一步 → 自动启动默认命令
   - bare（什么都没有） → 自动初始化

2. **子命令 `auto`**：启动全链路自动执行模式
   - 询问用户目标状态
   - 按转移表链式执行
   - 到达目标状态或失败时停下

3. **子命令 `status`**：输出当前会话摘要

4. **子命令 `history`**：列出所有会话历史

#### iscit-ps

**Project Space 管理命令**，用于管理多代码仓 + 知识仓的项目空间。

**核心操作**：
- `create`：创建新的 Project Space
- `track`：关联/切换知识库 Git
- `use`：注册新的代码仓
- `checkout`：拉取已注册的代码仓
- `sync`：同步代码仓系统语义到知识库
- `remove`：移除已注册的代码仓

**状态检测**：
- 自动检测 `docs/ps.yaml` 判断是否已有 Project Space
- 交叉校验识别中断导致的不一致状态
- 扫描未注册的代码仓

#### iscit-kl-build-init

**知识库全量初建命令**，从零开始执行完整的四阶段流水线。

**四阶段流程**：

1. **L1-0 it-project-initializer** — 项目初始化（按需执行）
   - 产出：AGENTS.md、docs/init/ARCHITECTURE.md、MODULE_INDEX.md 等

2. **L1-1 Babelfish** — 代码领域建模
   - 流程：init → scan → discover → model
   - 产出：docs/sys_kl/<项目名>/（限界上下文、领域模型、业务规则）

3. **L1-2 ArcherFish** — 业务知识库构建
   - 流程：init → build → evaluate
   - 产出：docs/biz_kl/（实体、规则、流程、配置、术语）

4. **L1-3 分析与打包** — 双侧质量分析 + 打包
   - 产出：quality_report.md、semantic_core_package.md

**断点恢复**：启动时自动检测已有进度，询问用户从哪一步继续。

#### iscit-kl-build-refine

**知识库迭代精炼命令**，对已有知识库进行增量更新和优化。

**精炼方向**：

**sys_kl 精炼**：
- `insight`：专家洞察注入
- `context`：上下文边界调整
- `model`：上下文模型精化
- `clarify`：歧义澄清
- `terminology`：术语编辑
- `rules`：规则编辑
- `quality`：全面质量诊断

**biz_kl 精炼**：
- `evaluate`：质量评测
- `build`：增量知识构建
- `docs`：补充文档知识源
- `archive`：知识废弃/归档
- `structure`：领域结构调整
- `relations`：知识关联补充
- `cross-validate`：双库交叉验证

#### iscit-req-analy

**需求分析命令**，将原始需求转化为结构化的 User Story。

**核心能力**：
- 解析原始需求
- 拆解为 User Stories
- 生成验收标准
- 需求质量评估

**路由**：直接按 `requirement-designer` skill 执行。

#### iscit-rr-to-design

**需求到设计全链路命令 ⟨Beta⟩**，从需求文档到技术设计方案的完整流程。

**流程**：
```
ia-new-version → ia-fe-generator → ia-fe-to-prd → ia-prd-to-design
```

**核心步骤**：
- Step 0：项目健康检查
- Step 1：检测意图（新版本/继续版本/Bug修复）
- Channel A：新版本开发流程
- Channel B：继续上次版本

#### iscit-dev-new

**新功能开发命令**，从 User Story 开始执行完整的开发流程。

**五阶段流程**：

1. **L1-1 技术设计探索**：加载规范、brainstorming、产出 ADR
   - Checkpoint：委派 verification 代理核对 PRD/需求 ↔ design.md

2. **L1-2 实施规划**：编写行动计划、可选 worktree
   - Checkpoint：核对 PRD/需求 ↔ design ↔ tasks/PLAN.md
   - Worktree 基线：默认从当前 HEAD 创建

3. **L1-3 TDD 实施**：TDD + 子代理执行（带约束）
   - RED-GREEN-REFACTOR 循环
   - 独立任务可并行执行
   - HTTP/持久化需集成级验证

4. **L1-4 协作与评审**：AI自检、PR 评审
   - requesting-code-review
   - WeQ/eDevOps 提交

5. **L1-5 分支完结**：合并、清理、报告

**约束笔记机制**：AI 反复跑偏时，写入 `constraints/*.md` 持久化纠正。

#### iscit-dev-fix

**Bug 修复命令**，系统化定位根因并验证修复。

**五阶段流程**：

1. **L1-F1 问题定位**：调试（带约束）
2. **L1-F2 修复实施**：TDD 修复（遵守约束）
3. **L1-F3 完成验证**：质量检查
4. **L1-F4 评审提交**：AI自检 + PR 评审
5. **L1-F5 分支完结**：合并和清理

### 3.3 其他命令

| 命令 | 说明 |
|------|------|
| `iscit-test-design-new` | 测试用例设计 |
| `iscit-test-dev` | 测试代码开发 |
| `iscit-test-ex` | 测试执行 |
| `iscit-ap-design` | AP大数据设计 |
| `iscit-ap-data-init` | AP数据初始化 |
| `it-project-init` | 项目初始化 |
| `it-idea` | 创意探索 |
| `it-dev` | IT开发 |
| `it-code-review` | 代码评审 |
| `it-build-fix` | 构建修复 |
| `it-java-ut` | Java单元测试 |
| `it-design` | IT设计 |
| `it-compound` | 知识积累 |
| `it-code-commit` | 代码提交 |
| `it-cicd` | CI/CD流水线 |
| `it-bug-fix` | Bug修复 |
| `test-ex` | 测试执行 |
| `test-ex-ui` | UI测试执行 |
| `test-dev` | 测试开发 |
| `test-design` | 测试设计 |
| `build-fix` | 构建修复 |

---

## 四、Skills（技能层）

HNQ 提供丰富的原子能力技能，按功能域分类。

### 4.1 核心编排技能

#### dev（开发编排器）

**职责**：新功能开发与 Bug 修复的全流程编排

**核心特性**：
- 集成 superpowers 工作流
- 支持 checkpoint 交互
- 约束笔记机制（AI 跑偏时的持久化纠正）
- 自动桥接 req-analy

**路径约定**：
- 工作层：`workspace/`（研发过程产物）
- 知识层：`docs/`（系统知识、业务知识）
- 约束笔记：`workspace/design/{周期}/constraints/*.md`

#### kl-build（知识库构建编排器）

**职责**：知识库全量初建和迭代精炼的 subagent 编排

**模式**：
- `init`：全量初建（4阶段流水线）
- `refine`：迭代精炼（交互式调整）

**Project Space 感知**：
- 自动检测 `docs/ps.yaml`
- 支持跨代码仓和单代码仓两种构建模式

#### ps（Project Space 编排器）

**职责**：管理多代码仓 + 知识仓的项目空间

**核心操作**：
- 状态检测与诊断
- 创建 Project Space
- 关联知识库 Git
- 注册/拉取/同步代码仓

#### req-analy（需求分析编排器）

**职责**：需求分析入口，路由到 requirement-designer

#### rr-to-design（需求到设计编排器）

**职责**：从需求文档到技术设计方案的完整流程

### 4.2 知识库构建技能

#### babelfish（代码领域建模）

**职责**：从代码中逆向抽出限界上下文、领域模型与业务规则

**核心流程**：
- `init`：初始化项目
- `scan`：扫描代码结构
- `discover`：发现限界上下文
- `model`：建模上下文
- `analyze`：质量分析
- `package`：打包语义核心

**产出**：
- docs/sys_kl/<项目名>/（系统知识库）
- semantic_core_package.md（语义核心包）

#### biz-kl-builder（业务知识库构建）

**职责**：业务知识库生命周期管理

**知识单元类型**：
- 实体（Entity）
- 规则（Rule）
- 流程（Process）
- 配置（Configuration）
- 术语（Terminology）

**运行模式**：
- Init：全量构建
- Build：增量更新
- Evaluate：质量评测
- Archive：知识废弃
- Health Check：健康巡检
- Migration：结构迁移

#### iscit-prebuild-biz-kl（业务知识库预构建）

**职责**：文档格式转换 + 知识地图构建

**两阶段**：
1. 文档格式转换：Office/PDF → Markdown
2. 知识地图构建：生成 KNOWLEDGE_MAP.md

#### cross-validate（交叉验证）

**职责**：biz_kl 与 sys_kl 要素级交叉验证

**双维度结算**：
- verdict（语义对齐）
- anchor_status（代码锚点）

#### biz-kl-query（业务知识检索）

**职责**：接受自然语言业务问题，在 biz_kl 中精准检索

### 4.3 开发技能

#### brainstorming

**职责**：创意探索，在实现前探索用户意图、需求和设计

**强制规则**：任何创意工作前必须使用

#### test-driven-development

**职责**：测试驱动开发，强制执行 RED-GREEN-REFACTOR 循环

#### writing-plans

**职责**：编写实施计划，在编码前规划多步骤任务

#### executing-plans

**职责**：执行实施计划，在独立会话中执行

#### subagent-driven-development

**职责**：子代理驱动开发，并行执行独立任务

#### using-git-worktrees

**职责**：使用 git worktree，为功能工作创建隔离环境

#### systematic-debugging

**职责**：系统化调试，在提出修复前诊断问题

#### verification-before-completion

**职责**：完成前验证，在声称完成前运行验证命令

#### requesting-code-review

**职责**：请求代码评审，在合并前验证工作

#### receiving-code-review

**职责**：接收代码评审反馈，在实现建议前验证

#### finishing-a-development-branch

**职责**：完结开发分支，决定如何集成工作

### 4.4 测试技能

#### api-test-design

**职责**：API接口测试设计文档生成

**输入**：YAML格式的接口定义
**输出**：Markdown格式的测试设计文档

#### api-test-design-biz

**职责**：基于业务场景的API测试设计

**特性**：
- 优先使用业务场景知识库预置步骤
- 应用测试设计方法论（Pairwise、等价类、边界值）

#### api-test-dev-python

**职责**：根据测试设计文档生成Python自动化测试脚本

**核心规则**：每个步骤和断言必须在知识库中查找模板

#### api-test-executor

**职责**：执行Python测试脚本并生成测试报告

#### ui-test-design-skill

**职责**：基于产品设计文档生成UI功能测试用例

**特性**：
- 包含可执行的点击步骤
- 页面元素定位信息
- 配置文件驱动机制
- 支持Playwright自动化测试

#### uitest-runner

**职责**：解析测试用例并执行UI自动化测试

**核心特性**：
- 默认Playwright MCP执行
- HTTPS证书信任处理
- 登录等待机制
- 智能元素匹配
- 失败重试机制
- 状态持久化（断点续传）

#### dfx-test-design

**职责**：DFX测试设计文档生成

**支持类型**：
- 性能测试
- 安全测试
- 可靠性测试
- 兼容性测试
- 可维护性测试
- 韧性测试

#### iscit-ap-test-design

**职责**：根据AP类需求设计数据库测试用例

#### iscit-ap-test-ex

**职责**：根据用例生成SQL验证脚本，执行测试并输出报告

#### python-testing

**职责**：Python测试策略，使用pytest和TDD方法

#### tdd-workflow

**职责**：测试驱动开发工作流，覆盖率超过80%

### 4.5 前端开发技能

#### iscit-js-dev

**职责**：ISC IT JavaScript前端开发

**默认配置**：Vue2 + Options API + JavaScript + AUI 5

**触发词**：新建工程、搭建AUI工程、按US开发、Vue2 AUI

#### iscit-dev-dxp

**职责**：DXP开发，Vue3 + TypeScript + AUI代码生成

**特性**：
- 支持US单号自动读取设计文档
- 提供DXP规范和二次封装组件
- DXP卡片Demo工程快速搭建

#### iscit-frontend-design-skill

**职责**：ISC IT前端详细设计

**流程**：
- 读取设计文档
- 查阅前端知识库
- 调用 it-idea-explorer 进行详细设计探索
- 输出可执行的前端详细设计方案

#### it-get-aui-component

**职责**：获取AUI组件库知识

**用途**：生成代码或修复组件问题时获取正确的组件用法

#### it-frontend-specifications-skill

**职责**：IT前端开发规范指引

**覆盖**：Vue2/Vue3项目开发规范和最佳实践

#### it-aui-project-creator

**职责**：创建AUI前端工程

**支持**：站点/npm包/monorepo

#### iscit-req2proto

**职责**：将业务需求转换为可交互的HTML原型页面

**特性**：
- 内置ISC IT/DXP UX规范
- 支持语言描述或草图识别
- 数据存储于localStorage提供逼真体验

### 4.6 后端开发技能

#### it-jalor

**职责**：Jalor框架开发工作

**触发词**：Jalor框架、Jalor开发、Jalor公服

#### it-jalor-init

**职责**：初始化Jalor项目

**支持**：
- Biz微服务
- CS公服
- Gateway网关
- 公服数据库初始化

#### springboot-patterns

**职责**：Spring Boot架构模式

**覆盖**：REST API设计、分层服务、数据访问、缓存、异步处理、日志记录

#### springboot-security

**职责**：Spring Security最佳实践

**覆盖**：身份验证/授权、CSRF、密钥、速率限制、依赖安全

#### springboot-tdd

**职责**：Spring Boot测试驱动开发

**工具**：JUnit 5、Mockito、MockMvc、Testcontainers、JaCoCo

#### springboot-verification

**职责**：Spring Boot验证循环

**流程**：构建、静态分析、测试覆盖率、安全扫描、差异审查

#### jpa-patterns

**职责**：JPA/Hibernate模式

**覆盖**：实体设计、关系、查询优化、事务、审计、索引、分页

#### backend-patterns

**职责**：后端架构模式

**覆盖**：Node.js、Express、Next.js API路由

### 4.7 Java单元测试技能

#### it-java-ut-code-generator

**职责**：Java单元测试代码生成

#### it-java-ut-test-planner

**职责**：Java单元测试规划，分析被测类并规划高覆盖率用例

#### it-java-ut-test-error-fixer

**职责**：Java单元测试错误修复

#### it-java-ut-coverage-analyzer

**职责**：Java测试覆盖率分析优化

#### it-java-ut-dependency-analyzer

**职责**：Java单元测试依赖分析

#### it-java-ut-test-reporter

**职责**：单元测试报告生成

### 4.8 AP大数据技能

#### iscit-ap

**职责**：AP侧数据库开发

**覆盖**：表设计、函数开发、ETL任务、BIDS服务

#### iscit-ap-data-init

**职责**：大数据知识库构建编排器

**流程**：逐层拉取数据库资产、BIDS服务、DWR/ETL/ODS血缘

#### iscit-ap-design-document

**职责**：AP复杂功能和重构的软件工程设计

#### iscit-ap-requirement-analysis

**职责**：AP大数据需求分析

#### it-ap

**职责**：AP侧开发专用技能

#### iscit-search-table

**职责**：数据库表语义化文档生成

#### it-sql-execute

**职责**：对数据库进行查询等操作

### 4.9 知识积累技能

#### it-compound

**职责**：记录已解决的问题以积累团队知识

#### it-compound-docs

**职责**：将已解决的问题文档化为YAML frontmatter分类文档

#### it-compound-refresh

**职责**：刷新 docs/solutions/ 中过时或跑偏的学习和模式文档

#### dream

**职责**：Memory consolidation，分析会话导出，提炼可执行规则到AGENTS.md

### 4.10 规范检查技能

#### bet-it-military

**职责**：军规规范定义

**三层体系**：
- 全局基础
- HNQ仓库
- 业务仓库可选的项目自定义（.project-context/extend-rule/）

#### huawei-java-standards

**职责**：Java语言编程规范V5.4

**覆盖**：168条规范检查清单

#### huawei-python-standards

**职责**：Python语言编程规范V3.4

**覆盖**：100+条规范检查清单

#### huawei-js-ts-standards

**职责**：JavaScript&TypeScript语言编程规范V3.2

**覆盖**：100+条规范检查清单

#### huawei-mysql-standards

**职责**：SQL语言编程规范V1.1

**覆盖**：100+条规范检查清单

#### huawei-web-security-standards

**职责**：Web应用安全开发规范V3.3-beta

**覆盖**：170+条安全规范检查清单

### 4.11 其他技能

#### xlsx

**职责**：电子表格处理

**场景**：打开、读取、编辑、创建 .xlsx/.xlsm/.csv/.tsv 文件

#### workflow

**职责**：自动化执行从需求设计到系统测试的完整开发流程

#### skill-create-helper

**职责**：辅助开发者创建符合规范的Skill

#### it-design-document

**职责**：复杂功能和重构的软件工程设计

#### it-design-draft-to-text

**职责**：将设计稿自动转换为结构化布局分析文档

#### it-project-initializer

**职责**：为代码仓库初始化AGENTS.md和渐进式文档系统

#### it-idea-explorer

**职责**：智能化创意设计与问题解决助手

#### it-requirement-analysis

**职责**：获取需求详情并完成需求澄清

#### it-requirement-quality-evaluation

**职责**：需求质量评估

#### loop-worker-init

**职责**：在需求设计完成后生成开发任务列表

#### it-session-summary

**职责**：分析并总结当前会话的开发指标

#### it-dev-env-initializer

**职责**：为Windows系统一键初始化开发环境

#### it-ci-cd-pipeline

**职责**：自动化执行微服务的CI/CD流水线

#### code-commit

**职责**：将代码提交到codehub仓

#### dts-fix

**职责**：DTS问题单修复

#### security-scan

**职责**：使用AgentShield扫描Claude Code配置

#### dataops-swagger-generator

**职责**：Swagger API文档生成器

#### python-script-generator

**职责**：根据测试设计文档生成Python测试脚本

#### test-case-us-associate

**职责**：在测试管理平台创建测试用例并关联到US需求

#### strategic-compact

**职责**：建议在逻辑间隔处进行手动上下文压缩

---

## 五、Agents（代理层）

HNQ 通过 Task 工具调用各类专用代理。

### 5.1 开发类代理

| 代理 | 职责 |
|------|------|
| developer | 根据设计文档实现代码并编写测试 |
| sub-developer | 根据设计文档、测试报告进行代码开发 |
| it-developer | 根据设计文档实现代码 |
| it-sub-developer | 根据设计文档进行代码开发 |
| it-frontend-aui-developer | 分析页面布局需求，生成AUI页面代码 |

### 5.2 设计类代理

| 代理 | 职责 |
|------|------|
| it-designer | 根据需求内容生成软件设计文档 |
| ia-context-resolver | 从PRD中提取关键业务概念，定位受影响业务域 |
| agent-element-designer | 完成要素的增量技术设计 |

### 5.3 测试类代理

| 代理 | 职责 |
|------|------|
| test-developer | TestNG自动化测试代码生成 |
| test-ex-agent | TestNG测试执行 |
| test-ex-router-agent | 测试执行路由（自动检测项目类型） |
| ui-test-ex-agent | UI测试执行 |
| ui-test-designer | UI功能测试设计 |
| dfx-test-designer | DFX测试设计文档生成 |
| dfx-feature-designer | DFX测试设计文档生成 |
| api-test-designer | API功能测试设计 |
| api-batch-designer | API接口批次测试设计 |
| test-suggestion-generator | 根据代码生成测试建议 |
| it-java-ut-guide | Java单元测试专家 |

### 5.4 任务管理类代理

| 代理 | 职责 |
|------|------|
| task-initializer | 将设计文档拆分为可执行的开发任务列表 |
| it-task-initializer | 将实施计划拆分为开发任务列表 |
| loop-worker-init | 读取设计文档并拆分为开发任务列表 |

### 5.5 代码审查类代理

| 代理 | 职责 |
|------|------|
| it-code-reviewer | 代码审查专家 |
| it-committer | Committer角色，审核MR |

### 5.6 知识库类代理

| 代理 | 职责 |
|------|------|
| learnings-researcher | 搜索过往解决方案 |
| iscit-search-table-agent | 数据库表语义化文档生成 |
| iscit-bigdata-init-agent | 数仓逆向，从Java代码追溯数据血缘 |

### 5.7 其他代理

| 代理 | 职责 |
|------|------|
| explore | 快速探索代码库 |
| general | 通用多步骤任务执行 |
| skill-executor | 执行特定技能 |
| verification | 只读验证代理 |
| build-resolver-guide | 通用构建解析器 |
| bug-fix-guide | DTS问题单修复流程引导 |

---

## 六、开发流程详解

### 6.1 新功能开发流程（iscit-dev-new）

```
┌─────────────────────────────────────────────────────────┐
│ L1-1: 技术设计探索                                        │
│   - 加载规范（bet-it-military）                           │
│   - brainstorming                                       │
│   - 产出 ADR                                            │
│   - Checkpoint: verification 代理核对                   │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ L1-2: 实施规划                                            │
│   - writing-plans                                       │
│   - using-git-worktrees（可选）                          │
│   - Checkpoint: verification 代理核对                   │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ L1-3: TDD 实施                                            │
│   - test-driven-development（RED-GREEN-REFACTOR）        │
│   - subagent-driven-development（并行）                  │
│   - 集成级验证（HTTP/持久化）                             │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ L1-4: 协作与评审                                          │
│   - requesting-code-review                              │
│   - verification-before-completion                      │
│   - WeQ/eDevOps 提交                                     │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ L1-5: 分支完结                                            │
│   - finishing-a-development-branch                      │
│   - 合并、清理、报告                                      │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Bug 修复流程（iscit-dev-fix）

```
┌─────────────────────────────────────────────────────────┐
│ L1-F1: 问题定位                                           │
│   - systematic-debugging                                │
│   - 带约束调试                                           │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ L1-F2: 修复实施                                           │
│   - test-driven-development                             │
│   - 遵守约束                                             │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ L1-F3: 完成验证                                           │
│   - verification-before-completion                      │
│   - 质量检查                                             │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ L1-F4: 评审提交                                           │
│   - requesting-code-review                              │
│   - WeQ/eDevOps 提交                                     │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ L1-F5: 分支完结                                           │
│   - 合并和清理                                           │
└─────────────────────────────────────────────────────────┘
```

### 6.3 知识库构建流程（iscit-kl-build-init）

```
┌─────────────────────────────────────────────────────────┐
│ L1-0: 项目初始化（按需）                                  │
│   - it-project-initializer                              │
│   - 产出: AGENTS.md, docs/init/                         │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ L1-1: Babelfish（代码领域建模）                           │
│   - init → scan → discover → model                      │
│   - 产出: docs/sys_kl/<项目名>/                         │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ L1-2: ArcherFish（业务知识库构建）                        │
│   - init → build → evaluate                             │
│   - 产出: docs/biz_kl/                                  │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│ L1-3: 分析与打包                                          │
│   - analyze → package                                   │
│   - 产出: quality_report.md, semantic_core_package.md   │
└─────────────────────────────────────────────────────────┘
```

### 6.4 Checkpoint 机制

每个 L1 阶段结束后执行 checkpoint：

```
🛑 Checkpoint — L1-X 完成
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 阶段成果: [成果摘要]
🔍 质量检查: [通过项/总数]
💡 建议: [下一步建议]

请选择:
[1] 继续 → 进入下一阶段
[2] 调整 → 修改本阶段产出
[3] 终止 → 结束流程
[4] 查看详情 → 展示完整产出
```

### 6.5 约束笔记机制

**目的**：持久化纠正，减少 AI 遗忘与胡编

**存放位置**：
- 推荐：`workspace/design/{V/R/I/SP}YYYYMMDD/constraints/`
- 或：`docs/<需求或任务标识>/constraints/`
- 或：工作区根下的 `constraints/`

**建议文件名**：
- `concepts.md`：关键术语含义、组件职责边界
- `boundaries.md`：禁止修改的接口/类/表/配置
- `data.md`：涉及实体与字段、数据关系

---

## 七、项目结构

### 7.1 HNQ SDK 结构

```
iSupplyAI-HNQ/
├── commands/              # CLI 入口点（iscit-*.md）
├── skills/                # Skill 资产
│   ├── iscit-pilot-skills/     # Pilot 执行内核
│   ├── iscit-ps-skills/        # Project Space 管理
│   ├── iscit-kl-build-skills/  # 知识库构建
│   ├── iscit-req-analy-skills/ # 需求分析
│   ├── dev/                    # 开发类 skill
│   ├── dev-env/                # 环境初始化
│   └── ...                     # 其他技能
├── scripts/
│   ├── src/              # TypeScript 源码
│   └ dist/              # 编译后的 JavaScript
├── resource/             # 外部 skill 源仓库
│   ├── manifest.yaml          # 源定义
│   └ manifest-lock.yaml      # 版本追踪
└── docs/                 # 文档
    └── extend-rule/      # 项目自定义规范
```

### 7.2 业务代码仓结构

```
业务代码仓/
├── workspace/            # 工作层（研发过程产物）
│   ├── requirements/     # 需求输入
│   ├── design/           # 设计产物
│   ├── retrospective/    # 回顾
│   ├── .session/         # Pilot 会话文件
│   └── .memory/          # Dream 冷数据
├── docs/                 # 知识层
│   ├── init/             # 架构初始化
│   ├── sys_kl/           # 系统知识库
│   ├── biz_kl/           # 业务知识库
│   └── ps.yaml           # Project Space 配置
├── .project-context/     # 项目上下文
│   └ extend-rule/        # 扩展规范
├── constraints/          # 约束笔记（可选）
└── AGENTS.md             # 项目概览
```

---

