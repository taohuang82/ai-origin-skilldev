---
standard_id: "config-app-config"
domain: "config"
---

# config-app-config

**规范分段**：`config-app-config`

### 规范条文

# 配置项与非功能安全规范（TDD 第6章 §6.4 / §6.5）

> 本要素整合原 `be-config`（后端配置）、`be-dfx`（可观测性）与 `fe-nfr`（前端非功能规范）。

## 6.4 配置项清单规范

### 配置分层原则

| 层级 | 存储位置 | 变更方式 | 适用场景 |
|------|---------|---------|---------|
| 基础设施配置 | 环境变量 / K8s ConfigMap / Secret | 重启 Pod | DB 地址、密钥（敏感，不进代码仓库） |
| 应用行为配置 | `application.yml` | 重新部署 | 线程池大小、超时时间 |
| 运行时业务参数 | 配置中心（Nacos/Apollo） | 实时推送（热更新） | 功能开关、限流阈值、白名单 |

### 配置类型分类

根据配置项特性选择合适的配置类型：

#### 类型1：lookup（枚举值配置）

**适用场景**：
- 固定枚举值，数值相对固定
- 示例：
  - 状态（草稿/生效/失效）
  - 优先级（高/中/低）
  - 类型（类型A/类型B）
  - 级别（一级/二级/三级）

**配置方式**：
- 使用Jalor框架的lookup机制
- 手工或通过Excel导入配置

**维护方式**：
- 研发侧维护（需要研发团队配置）

**编码格式**：
- Classify Code使用uppercase格式（如 `ORDER_STATUS`）
- Item Code使用uppercase格式（如 `DRAFT`、`ACTIVE`）

**编码规范**：
- Classify Code: 使用uppercase格式（全大写），下划线分隔单词
- Item Code: 使用uppercase格式（全大写），与Classify Code对应

**Excel导入模板格式**：

**Sheet1: Lookup Classify（Lookup分类）**
| Code | Parent Classify | Name | Status | Lookup Type | Desc |
|------|-----------------|------|--------|-------------|------|
| ORDER_STATUS | null | 订单状态 | ACTIVE | STANDARD | 订单状态枚举 |

**Sheet2: Lookup Item（Lookup项）**
| Classify Code | Item Code | Item Name | Desc | Parent Item | Status | Lookup Type | Language | Sort |
|---------------|-----------|-----------|------|-------------|--------|-------------|----------|------|
| ORDER_STATUS | DRAFT | 草稿 | 草稿状态 | null | ACTIVE | STANDARD | zh_CN | 1 |

#### 类型2：配置项平台（业务侧维护的大数据量配置）

**适用场景**：
- 业务侧自行维护的数据量大、变化频繁的配置
- 示例：
  - 业务规则配置表（规则参数、计算系数）
  - 映射关系配置（编码映射、类型映射）

**配置方式**：
- IT建表存储，提供配置管理界面

**维护方式**：
- 业务侧自行维护（无需研发团队介入）

**技术实现**：
- 配置表 + 配置管理界面

**⚠️ 建表强制规范**：

必须遵循以下建表规范，否则配置项新增业务数据时会报错！

1. **表名必须以 `config_` 开头**
   - 选择配置表时仅展示授权了的以 `config_` 开头的表
   - 示例：`config_business_rule_t`、`config_threshold_t`

2. **配置表必须以 `ID` 为主键**
   ```sql
   id VARCHAR(64) NOT NULL,
   CONSTRAINT pk_config_xxx_t_id PRIMARY KEY (id)
   ```

3. **配置表必须包含 `_temp` 字段**
   - **字段类型**：`VARCHAR`
   - **字段长度**：大于除审计字段外其他字段总和
   - **用途**：用于展示新增业务配置数据时前端标识数据状态
   - **字段格式**：
     ```json
     {"dataMap":{业务数据},"type":"-1 or 1 or 0"}
     ```
     - 数字表示状态：
       - `1`：新增
       - `0`：编辑
       - `-1`：删除

4. **配置表必须存在 `published_flag` 字段**
   - **字段类型**：`CHAR(1)`
   - **用途**：标识配置值是否已发布
   - **枚举值**：
     - `Y`：已发布
     - `N`：未发布

5. **配置表必须给 `iaudit_common` 授权**
   ```sql
   GRANT USAGE ON SCHEMA iaudit_apr TO iaudit_common;
   GRANT SELECT,UPDATE,INSERT,DELETE,TRUNCATE ON config_xxx_t TO iaudit_common;
   ```

**完整建表示例**：

```sql
-- =============================================
-- 表名：config_business_rule_t  说明：业务规则配置表
-- 建表规范：符合配置项管理平台建表规范
-- =============================================
CREATE TABLE config_business_rule_t (
    id                VARCHAR(64)   NOT NULL,
    rule_code         VARCHAR(128)  NOT NULL,   -- 规则编码，唯一标识
    rule_name         VARCHAR(255)  NOT NULL,   -- 规则名称
    rule_type         VARCHAR(64)   NOT NULL,   -- 规则类型
    rule_params       TEXT          NULL,       -- 规则参数（JSON格式）
    _temp             VARCHAR(2000) NULL,       -- 配置项管理平台临时字段（必须，长度 > 其他字段总和）
    published_flag    CHAR(1)       NOT NULL DEFAULT 'N', -- 发布标识（必须）：Y-已发布 / N-未发布
    -- 审计字段
    created_by       INT8          NOT NULL,
    creation_date    TIMESTAMP(6)  NOT NULL,
    deleted_flag     CHAR(1)       NOT NULL DEFAULT 'N',
    last_updated_by  INT8          NOT NULL,
    last_update_date TIMESTAMP(6)  NOT NULL,
    renter_id        VARCHAR(64)   NULL DEFAULT NULL,
    CONSTRAINT pk_config_business_rule_t_id PRIMARY KEY (id)
);

CREATE UNIQUE INDEX uk_config_business_rule_t_rule_code ON config_business_rule_t(rule_code);

-- 必须给 iaudit_common 授权
GRANT USAGE ON SCHEMA iaudit_apr TO iaudit_common;
GRANT SELECT,UPDATE,INSERT,DELETE,TRUNCATE ON config_business_rule_t TO iaudit_common;
```

### 动态配置要求

- 每个动态配置必须有默认值（配置中心不可用时系统正常运行）
- 配置 Key 命名：`{模块}.{功能}.{参数}`，如 `order.approve.timeout-days=7`
- 配置变更要有变更记录和回滚机制
- 配置监听器需处理变更异常，不因格式错误导致服务崩溃

### 敏感配置

- 密码、密钥、Token 通过 K8s Secret / Vault 管理
- 禁止提交到代码仓库
- 日志输出时脱敏

---

## 6.5 非功能与安全规范

### 性能指标

- 核心接口响应时间 P99 基线，超出触发告警
- QPS 峰值预估及对应限流配置
- 数据库慢查询阈值（通常 1s）

### 安全规范

**后端**：
- 敏感字段脱敏展示（手机号/身份证/银行卡），`@Desensitize` 注解处理
- 通信加密验签（HTTPS + 请求签名）
- 禁止在响应中暴露 DB 错误或堆栈信息

**前端**：
- Token 存 `sessionStorage` 或 HttpOnly Cookie，禁止 `localStorage`（XSS 可窃取）
- 禁用 `v-html`，必须使用时用 DOMPurify sanitize
- 禁止在前端存储或展示未脱敏的敏感信息

### 可观测性规范

**日志**：
- SLF4J + Logback，格式：`时间 级别 [traceId] [userId] 类名 - 消息`
- MDC 维护 `traceId`、`userId`、`tenantId`，全链路透传
- 关键业务操作记录入参和结果（注意脱敏）

**监控指标**：
- Micrometer + Prometheus，命名：`{应用名}_{模块}_{指标名}_{单位}`
- 每个对外接口记录：请求量、成功率、P50/P95/P99 响应时间

**告警**：
| 级别 | 触发条件 | 通知方式 | 响应时效 |
|------|---------|---------|---------|
| P0 | 服务不可用、错误率 > 5% | 电话 + 即时消息 | 15 分钟 |
| P1 | P99 响应时间 > 2s | 即时消息 | 1 小时 |
| P2 | 队列积压 / 非核心异常 | 邮件 | 24 小时 |

### 前端非功能规范

- 路由级懒加载（禁止所有页面打包进主 bundle）
- 单个 chunk 体积 ≤ 500KB（gzip 后）
- 按需引入 UI 组件库（tree-shaking）
- 关键区域使用 `ErrorBoundary` 组件，子组件异常不影响整页
- 全局 `app.config.errorHandler` 捕获未处理异常并上报监控

---

## 项目规范摘录（`规范/` 目录 · IT 设计文档 §5 DFX）

> 来源：`{WORKSPACE_ROOT}/规范/examples/it_design_doc.md`「DFX 设计」；与上文 §6.5 互补时合并输出，避免重复矛盾。

- **安全（必选）**：结合需求给出可落地方案；日志/调试/错误信息中**禁止明文**打印认证凭据等敏感数据。
- **日志上报（必选）**：审计类日志满足 **4W1H**（Who / When / What / Where / How），并与安全要求一致。
- **性能（必选）**：关注帧率与过度绘制、异步与网络调用、大并发接口、大对象与内存/GC、**爆炸半径与过载控制**。
- **兼容性（必选）**：对外接口/常量/上报 key、内部持久化 key、数据库升级等变更须写清兼容策略。
- **全球化（可选）**：涉及则描述服务地/账号/登录/分级差异、界面文案与翻译要求。

## 输出骨架
# 配置项与非功能安全设计（TDD 第6章 §6.4 / §6.5）

<!--
变更标注约定：
- ✨ 新增：本次新增的配置项或规范条目
- 🔧 修改：在现有基础上变更默认值、刷新策略等
-->

## 变更概要

| 要素 | 动作 | 对象 | 说明 |
|------|------|------|------|
| 6.4 配置项 | ✨/🔧 | | |
| 6.5 非功能/安全 | ✨/🔧 | | |

---

## 6.4 配置项清单

### 动态配置项（Nacos/Apollo，支持热更新）

| 配置 Key | 默认值 | 取值范围 | 动态刷新 | 影响面 | 动作 |
|---------|--------|---------|---------|--------|------|
| `order.approve.timeout-days` | `7` | `1~30` | ✅ 实时生效 | 超时自动驳回任务 | ✨ |

---

### ✨/🔧 {配置 Key}

> 🔧 **变更说明**：{仅修改时填写}

| 属性 | 值 |
|------|---|
| 配置层级 | 应用配置 / 动态配置 / 环境变量 |
| 默认值 | |
| 类型 | String / Integer / Boolean |
| 动态刷新 | ✅ 实时生效 / ❌ 需重启 |
| 变更影响面 | {影响的功能或模块} |
| 监听类 | `{XxxConfigListener}` |

---

### 应用配置项（application.yml，随部署生效）

| 配置键 | 默认值 | 说明 |
|--------|--------|------|
| `spring.datasource.hikari.maximum-pool-size` | `20` | 数据库连接池最大数 |

---

### 环境变量清单（K8s ConfigMap/Secret）

| 变量名 | 是否敏感 | 示例值 | 说明 |
|--------|---------|--------|------|
| `DB_URL` | N | `jdbc:mysql://host:3306/db` | 数据库连接串 |
| `DB_PASSWORD` | ✅ Secret | — | 数据库密码 |

---

## 6.5 非功能与安全规范

### 性能指标

| 接口/场景 | QPS 基线 | P99 目标 | 超限告警阈值 | 动作 |
|---------|---------|---------|------------|------|
| 订单查询接口 | 500 QPS | < 500ms | > 2s | ✨ |
| 审批提交接口 | 50 QPS | < 1s | > 3s | ✨ |

---

### 数据脱敏规则

| 字段 | 脱敏规则 | 展示样例 | 实现方式 | 动作 |
|------|---------|---------|---------|------|
| 手机号 | 中间四位替换为 `****` | `138****8888` | `@Desensitize(type=PHONE)` | ✨/🔧 |
| 身份证 | 保留前6后4 | `110101****1234` | `@Desensitize(type=ID_CARD)` | ✨/🔧 |

---

### 可观测性设计

#### 日志设计

| 日志类型 | 触发场景 | 级别 | 关键字段 |
|---------|---------|------|---------|
| 操作日志 | 用户关键操作（审批/创建等） | INFO | userId, action, resourceId, traceId |
| 异常日志 | 业务/系统异常 | ERROR | traceId, errorCode, message, stackTrace |
| 外部调用日志 | 调用三方服务 | INFO | serviceName, method, costMs, success |

#### 监控指标

| 指标名 | 类型 | 说明 | 告警阈值 |
|--------|------|------|---------|
| `{app}_{module}_request_total` | Counter | 接口请求总量 | — |
| `{app}_{module}_request_duration_seconds` | Histogram | 响应时间 | P99 > 见性能指标 |
| `{app}_{module}_error_total` | Counter | 错误请求数 | > 10/min |

#### 链路追踪

- TraceId：网关注入，通过 MDC 全链路透传
- 跨服务：HTTP Header `X-Trace-Id`
- 关键操作打 Span：{列举需追踪的关键方法}

---

### 前端非功能规范

| 规范项 | 要求 | 动作 |
|--------|------|------|
| 路由懒加载 | 所有页面路由使用 `() => import(...)` | 🔧 |
| Chunk 体积 | 单个 chunk ≤ 500KB（gzip 后） | 🔧 |
| Token 存储 | `sessionStorage` 或 HttpOnly Cookie，禁止 `localStorage` | 🔧 |
| 错误边界 | 关键模块用 `ErrorBoundary` 包裹 | ✨/🔧 |
| v-html 使用 | 禁用，例外时使用 DOMPurify sanitize | 🔧 |

---

## IT 设计文档 DFX 自检（模板 · `规范/examples/it_design_doc.md` §5）

| 类别 | 本需求落地说明（要点） |
|------|------------------------|
| 安全 | |
| 日志（4W1H） | |
| 性能 | |
| 兼容性 | |
| 全球化（可选） | |