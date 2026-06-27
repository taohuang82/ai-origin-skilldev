---
module_id: "m-design-code-consistency-check"
implements: "design-lightweight-incremental"
for_type: ["INCR_PRD_DOC"]
execution_mode: ["incremental"]
status: "active"
for_scenario: ["存量系统增量设计"]
---

# m-design-code-consistency-check — 设计-代码一致性校验

> **适用 workflow**：`design-lightweight-incremental`
> **执行时机**：Phase 3（串行逐域设计）完成后，Phase 4（汇总与索引）之前
> **核心原则**：代码是存量事实的 SSOT（Single Source of Truth），设计文档中的存量信息必须与代码仓库一致

---

## 目标

确保轻量模式产出的设计文档中，从代码推断的存量信息（表名、API 路径、类名、配置项等）与代码仓库中的实际定义一致。不一致时以代码为准自动修正设计文档，避免设计文档与代码事实脱节。

**输出物**：校验报告（一致/已修正/无存量代码对照三类统计）+ 修正后的 `design.md`

**成功标准**：
- 所有 pattern_match / partial_match 要素均完成校验
- 不一致项已自动修正并标记 `<!-- FIXED: ... -->`
- 代码中存在的存量信息已补充并标记 `<!-- STOCK: ... -->`
- `<!-- DELTA: ... -->` 块未被修改

---

## 前置条件

**依赖要素**：无（本 spec 不依赖其他要素的设计产出）

**必要输入**：

| 输入 | 来源 | 说明 |
|------|------|------|
| `effective_sequence[]` | Phase 1 产出 | 受影响要素集合，含各要素的档位（tier） |
| `design.md` | Phase 3 产出 | 已完成的设计文档，含各要素的设计章节 |
| `code-signal-registry.yaml` | `config.yaml` → `extension_registry.code_signals` | 各要素的代码信号扫描指令 |
| 代码仓库文件 | 工作区根目录 | 各要素对应的实际代码文件 |

**跳过条件**：
- `effective_sequence` 中无 pattern_match 或 partial_match 要素（全部为 no_match 全新要素）
- `design.md` 不存在或为空

---

## 约束

### 格式规范

> 运行时 SSOT：`registry/code-signal-registry.yaml`（代码信号扫描指令）

### 设计约束

| 约束编号 | 级别 | 规则 | 验证方法 |
|----------|------|------|---------|
| CC-01 | MUST | 仅对 tier 为 pattern_match 或 partial_match 的要素执行校验；no_match 要素跳过 | 遍历 effective_sequence 时检查 tier 字段 |
| CC-02 | MUST | 重新扫描代码文件获取最新状态，不依赖 Phase 2 缓存的扫描结果 | 每个要素独立执行 Glob + Read |
| CC-03 | MUST | 存量信息以代码为准修正设计文档；PRD 新增的增量内容保留不覆盖 | 比对时区分存量字段与增量字段 |
| CC-04 | MUST | 被修正的段落追加 `<!-- FIXED: 校验修正，以代码为准，原值: {original_value} -->` | 正则扫描 design.md 确认标记存在 |
| CC-05 | MUST | 代码中存在但设计文档未提及的存量信息，补充并标记 `<!-- STOCK: 存量信息，来自代码 -->` | 正则扫描 design.md 确认标记存在 |
| CC-06 | MUST | 不修改 `<!-- DELTA: ... -->` 块（DELTA 记录的是本次增量变更） | 比对前后 design.md 中 DELTA 块内容一致 |
| CC-07 | SHOULD | 校验完成后输出校验报告，展示三类统计 | 检查报告是否包含 consistent_count / fixed_count / no_code_count |

---

## 执行步骤

### Step 1：确定校验范围

```
FOR each element_id IN effective_sequence:
  IF tier == "no_match":
    → 标记为 skipped（全新要素，无存量代码对照）
    → 跳过
  ELSE IF tier IN ["pattern_match", "partial_match"]:
    → 纳入校验范围
```

### Step 2：逐要素代码扫描与信号提取

对每个纳入校验范围的要素，按 `code-signal-registry.yaml` 的 scan 指令执行：

```
1. 查 code-signal-registry.yaml → 获取该要素的 scan[] 条目
2. 重新 Glob 扫描目标文件是否存在
3. 对存在的文件，Read 全文提取关键信号
```

各要素的信号提取内容：

| 要素 | 提取内容 | 代码来源 |
|------|---------|---------|
| `data-table` | 表名、字段名、字段类型、主键、索引 | DDL 文件 / JPA Entity @Table/@Column 注解 |
| `data-cache` | 缓存框架、缓存 Key 模式、过期策略 | 依赖声明 / @Cacheable 注解 |
| `data-state-machine` | 状态枚举值、状态流转规则 | 枚举类 / 状态字段 |
| `be-api` | API 路径、HTTP 方法、请求/响应 DTO 类名 | Controller/Facade @RequestMapping/@GetMapping 等注解 |
| `be-class` | 类名、继承关系、核心方法签名 | Service/Entity/DTO 类定义 |
| `be-sequence` | 调用链、依赖关系 | Service 实现类 / Delegate 类 |
| `be-transaction` | 事务边界、事务管理器 | @Transactional 注解 |
| `arch-tech-stack` | 框架名、版本号 | pom.xml / package.json |
| `arch-code-structure` | 分层结构、包路径 | 目录结构 |
| `arch-microservice` | 模块划分、模块名 | Maven/Gradle 模块结构 |
| `arch-deployment` | 容器编排、端口、服务名 | docker-compose.yml / k8s 配置 |
| `arch-common-lib` | 公共模块名、共享类 | common/core 模块目录 |
| `arch-common-component` | 公共组件目录、组件名 | components/ 目录 |
| `arch-feature-toggle` | 特性开关框架、开关 Key | 配置文件中的 toggle 相关配置 |
| `fe-tech-stack` | 前端框架、UI 库、构建工具 | package.json / 构建配置文件 |
| `fe-page-structure` | 路由路径、页面组件名 | router 配置 / 卡片 manifest |
| `fe-api-binding` | API 封装方式、请求前缀 | api 封装文件 |
| `fe-component` | 组件命名、字段绑定模式 | 组件文件 |
| `fe-interaction-logic` | 状态管理方案、事件通信 | store/composable/EventBus |
| `fe-nfr` | 国际化方案、性能配置 | i18n 配置 / nginx 配置 |
| `config-dict` | 字典编码、字典项 | 枚举类 / 字典表 |
| `config-permission` | 角色标识、权限点 | 权限注解 / 角色表 |
| `config-error-code` | 错误码前缀、错误码值 | 错误码枚举类 |
| `config-app-config` | 配置项 Key、默认值 | application.yml / properties |
| `config-nfr-security` | 安全框架、限流配置 | Security 配置类 |
| `integration-mq` | MQ 类型、Topic/Queue 名 | 依赖声明 / Consumer 类 |
| `integration-external` | 外部服务名、接口契约 | FeignClient / Delegate |
| `integration-notification` | 通知通道、模板变量 | 通知代码 |
| `data-multi-datasource` | 数据源数量、命名规则 | 数据源配置 XML |
| `be-export` | 导出框架、Provider 类名 | Excel Provider / XML 配置 |
| `be-import` | 导入框架、Provider 类名、模板字段、异步导入任务、错误回写表 | Excel Import Provider / XML 配置 / ImportTask / 临时表/结果表 |
| `be-schedule` | 调度框架、任务类名 | @Scheduled / @XxlJob |
| `be-workflow` | 工作流引擎、流程定义 | 工作流代码 |
| `integration-async-message` | 异步消息 Bean 配置 | async.message.beans.xml |

### Step 3：对照 design.md 比对

```
1. 定位 design.md 中该要素对应的章节（按章节标题匹配）
2. 逐项比对：
   a. 表名/字段名/API 路径/类名等关键标识
   b. 识别不一致项：
      - 设计文档写了但代码中没有 → 以代码为准修正
      - 代码中有但设计文档未体现 → 补充到设计文档
      - 设计文档中 PRD 要求的新增内容 → 保留不覆盖
3. 检查是否存在"未识别到存量物理事实"的情况：
   - 若代码中完全找不到 required_for_pattern_match 对应的物理事实
     （如 data-table 找不到任何真实表名、be-api 找不到任何真实 API 路径）
     → 标记为 missing_physical_fact
   - 这比"已修正"更严重：表示设计产出缺乏存量代码对照，可能完全基于推断或 PRD 新建
```

### Step 4：执行修正

```
修正策略：
  - 存量信息与代码不一致 → 以代码为准修正，追加 <!-- FIXED: 校验修正，以代码为准，原值: {original_value} -->
  - 代码中存在但设计文档未提及 → 补充到设计文档，追加 <!-- STOCK: 存量信息，来自代码 -->
  - PRD 新增的增量内容 → 保留，不修改
  - <!-- DELTA: ... --> 块 → 不修改
  - missing_physical_fact：不自动修正设计产出；追加 <!-- MISSING_PHYSICAL_FACT: 未从代码中提取到 {fact_id}，需人工确认 --> 提示

写入方式：
  - Read design.md → StrReplace 更新对应章节
```

### Step 5：输出校验报告

```
🔍 设计-代码一致性校验完成

━━━ 校验统计 ━━━
  校验要素: {validated_count} 个（pattern_match + partial_match）
  跳过要素: {skipped_count} 个（no_match 全新要素，无存量代码对照）

━━━ 校验结果 ━━━
✅ 一致（共 {consistent_count} 个）：
  1. {element_id}  → {一致性说明}
  ...

🔧 已修正（共 {fixed_count} 个）：
  2. {element_id}  → {修正内容说明}
  ...

⚠️ 无存量代码对照（共 {no_code_count} 个）：
  3. {element_id}  → {说明}
  ...

🔍 未识别到存量物理事实（共 {missing_physical_fact_count} 个）：
  4. {element_id}  → 无法从代码中提取 {fact_id}（如 data-table 找不到真实表名 / be-api 找不到真实 API 路径）
     建议：提供 DDL 文件、OpenAPI 契约、API 文档或手工指定物理标识
  ...

[C] 继续汇总  [R] 重新校验  [M] 手动修正某个要素  [P] 提供缺失的物理事实
```

---

## 质量检查点

- [ ] 所有 pattern_match / partial_match 要素均已完成校验
- [ ] 不一致项已修正并标记 `<!-- FIXED: ... -->`
- [ ] 遗漏的存量信息已补充并标记 `<!-- STOCK: ... -->`
- [ ] 未识别到物理事实的要素已标记 `<!-- MISSING_PHYSICAL_FACT: ... -->`
- [ ] `<!-- DELTA: ... -->` 块内容未被修改
- [ ] 校验报告包含 consistent_count / fixed_count / no_code_count / missing_physical_fact_count 四类统计
- [ ] 修正后的 design.md 无空章节、无占位符
- [ ] 代码扫描使用最新文件状态（非 Phase 2 缓存）
