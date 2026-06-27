---
standard_id: "arch-tech-stack"
domain: "architecture"
---

# arch-tech-stack

**规范分段**：`arch-tech-stack`

### 规范条文

# 技术选型与代码架构规范（TDD 第1章 §1.1 / §1.5 / §1.6 / §1.7）

> **仅在 build 模式下输出。**

## 1.1 技术选型规范

### 版本锁定原则

- 所有依赖必须锁定到具体版本号（major.minor.patch），禁止使用 LATEST 或范围版本
- 优先使用公司内部经过安全审计的版本基线
- Spring Boot、Vue 等主框架使用当前 LTS（Long-Term Support）版本

### 技术栈分层

| 层次 | 选型范围 |
|------|---------|
| 后端框架 | Spring Boot（推荐 3.x）|
| 服务治理 | Spring Cloud Alibaba（Nacos + Sentinel + Seata）|
| 数据层 | MySQL 8.0 + MyBatis-Plus / JPA |
| 缓存 | Redis 7.x（Redisson 客户端）|
| 消息队列 | RocketMQ 5.x |
| 前端框架 | Vue 3 + Vite 5 + TypeScript |
| 前端状态 | Pinia |
| 前端 UI 组件库 | Element Plus / 内部组件库 |
| 构建工具 | Maven 3.9（后端）/ Vite 5（前端）|

## 1.5 代码架构规范

### 分层结构（DDD 四层）

```
src/
├── interfaces/        # 接口层：API / DTO / Converter / 参数校验 / MQ Consumer
├── application/       # 应用层：APPService
├── domain/            # 领域层：Service/ Entity/VO/Command / Repository 接口 / DomainEvent / 枚举 / 常量
└── infrastructure/    # 基础设施层：RepositoryImpl / MQ Producer / DAO / PO / DTO / Converter
```

### 依赖方向约束

- Domain 层禁止依赖 Infrastructure
- Application 层禁止直接操作数据库（通过 Repository 接口）
- Interface 层禁止包含业务逻辑
- 使用防腐层（ACL）隔离外部模型，禁止将外部 DTO 直接渗透到内部领域层

### 包命名规范

- 根包：`com.{company}.{product}.{service}`
- 模块包：`com.{company}.{product}.{service}.{module}`（如 `order`、`user`）

## 1.6 公共基础库规范

### 必须封装的公共能力

| 能力 | 封装形式 | 模块 |
|------|---------|------|
| 统一响应封装 | `ApiResponse<T>` 泛型响应体  | `common-core` |
| 全局异常处理 | `@ControllerAdvice` + `GlobalExceptionHandler` | `common-core` |
| 工具类 | `DateUtils`, `JsonUtils`, `StringUtils` | `common-util` |
| 请求封装（前端） | Axios 封装 + Token 注入 + 错误拦截 | `request.ts` |

## 1.7 公共组件规范

### 切面组件

| 注解 | 功能 | 切面织入时机 |
|------|------|------------|
| `@Idempotent` | 幂等控制 | 方法执行前（Redis SETNX 去重）|
| `@DistributedLock` | 分布式锁 | 方法执行前后（Redisson，自动释放）|
| `@AuditLog` | 操作审计日志 | 方法执行后（记录操作人、入参摘要、结果）|
| `@Desensitize` | 响应字段脱敏 | Jackson 序列化时（手机号/身份证等）|

### 切面设计约定

- 切面逻辑不包含业务判断，只做横切关注点处理
- 切面异常不影响主业务流程（最多记录日志）
- 幂等键的有效期与业务 TTL 对齐

### 公共二方件
| 编号 | 模块名称            | 功能描述 | 适用场景                                |
|:----:|:----------------|:---------|:------------------------------------|
| **01** | **异步任务实现**      | Jalor框架异步消息系统完整实现流程 | 需要后台异步处理的长耗时任务、批量操作、线程池管理           |
| **02** | **Excel导入实现**   | 支持CXF和DDD架构的Excel导入完整实现 | 批量导入数据、Excel文件解析、多Sheet处理、分页处理、错误收集 |
| **03** | **Excel导出实现**   | Jalor框架Excel导出功能实现 | 数据导出为Excel文件、同步/异步导出、字段转换           |
| **04** | **审批流集成**       | IAOne审批流完整功能实现指南 | 创建审批流程、审批操作、流程查询、流程管理               |
| **05** | **RPC接口实现**     | IAOne RPC标准化接口配置和实现 | 跨服务调用、标准化RPC接口配置、服务间通信              |
| **06** | **AE数据查询**      | 审计单元数据、组织信息、业务场景查询 | 查询AE数据、组织层级、责任田数据、产业信息              |
| **07** | **RU数据查询**      | 审计资源数据查询完整指南 | 查询审计资源、审计单元关联数据                     |
| **08** | **数据字典配置查询**    | jalor数据字典查询实现 | 查询数据字典配置数据                          |
| **09** | **Lookup查询工具**  | Lookup数据快速查询工具实现 | 快速查询Lookup配置数据、下拉选项数据               |
| **10** | **Todos SDK集成** | IAOne待办任务SDK完整集成指南 | 待办任务管理、任务状态查询、任务通知                  |
| **11** | **Espace消息集成**  | IAOne Espace消息通知SDK集成 | 企业空间消息推送、提醒通知                       |
| **12** | **权限注解生成**      | 权限控制注解自动生成工具 | 生成权限控制注解、配置权限点                      |
| **13** | **异常处理规范**      | Jalor框架业务异常定义和使用规范 | 业务异常定义、异常抛出、异常码规范、国际化消息             |
| **14** | **编号生成器**       | 统一的编号生成、占用、释放和查询功能 | 业务编号生成、编号生命周期管理、编号预览、批量生成           |
| **15** | **DDD代码生成**     | DDD架构四层代码框架生成规范 | 领域对象代码生成、四层架构规范、命名约定                |
| **16** | **EDM SDK集成**   | EDM文档管理SDK完整集成指南 | 文档上传下载、PDF转换、水印加密、批量文档操作             |


## 项目规范摘录（`规范/` 目录 · IT 设计文档 §4.2.2）

> 来源：`{WORKSPACE_ROOT}/规范/examples/it_design_doc.md`「新引入三/二方库声明」。

- 若引入新依赖，须声明：**坐标与版本**、**引入目的**、**替代方案评估**（含为何不采用现有工具/二方库/自研）。
- **技术评估**须包含：许可证、稳定性与成熟度、与当前技术栈兼容性、性能与安全考量。

## 输出骨架
# 技术选型与代码架构设计（TDD 第1章 §1.1 / §1.5 / §1.6 / §1.7）

> **仅 build 模式输出。** 本文件确定后，后续版本迭代不重新生成，变更需走架构评审。

---

## 1.1 技术选型

### 后端技术栈

| 层次 | 技术选型 | 版本 | 说明 / 选型原因 |
|------|---------|------|--------------|
| 主框架 | Spring Boot | {3.2.x} | |
| 服务注册/配置中心 | Nacos | {2.x} | |
| 数据库 | MySQL | {8.0} | |
| ORM | MyBatis-Plus | {3.5.x} | |
| 缓存 | Redis + Redisson | {7.x / 3.x} | |
| 消息队列 | RocketMQ | {5.x} | |
| 分布式事务 | Seata | {2.x} | 若有跨服务事务 |
| 服务熔断/限流 | Resilience4j / Sentinel | | |
| 构建工具 | Maven | {3.9} | |
| 容器化 | Docker + Kubernetes | | |

### 前端技术栈

| 层次 | 技术选型 | 版本 | 说明 / 选型原因 |
|------|---------|------|--------------|
| 框架 | Vue | {3.4.x} | |
| 构建工具 | Vite | {5.x} | |
| 语言 | TypeScript | {5.x} | strict 模式 |
| 状态管理 | Pinia | {2.x} | |
| UI 组件库 | {Element Plus / 内部库} | {版本} | |
| HTTP 客户端 | Axios | {1.x} | |
| 路由 | Vue Router | {4.x} | |

### 待确认项

- [ ] {技术选型中的不确定项，如 DB 类型、消息队列选型等}

---

## 1.5 代码架构

### 分层结构

```
{根包名}/
├── interfaces/        # Controller / DTO / Converter
│   └── {module}/
├── application/       # Service 接口 + ServiceImpl
│   └── {module}/
├── domain/            # Entity / Repository 接口 / DomainEvent / Enum
│   └── {module}/
└── infrastructure/    # RepositoryImpl / MQ / FeignClient / Cache
    └── {module}/
```

### 包命名

- 根包：`com.{company}.{product}.{service}`
- 示例：`com.example.mall.order`

### 依赖方向防腐说明

{描述本项目特殊的防腐层设计，如对外部系统模型的隔离策略}

---

## 1.6 公共基础库

### 后端公共模块

| 模块名 | 提供能力 | 引入方式 |
|--------|---------|---------|
| `common-core` | `Result<T>`响应封装、`GlobalExceptionHandler`、`BusinessException` | Maven 依赖 |
| `common-util` | `DateUtils`、`JsonUtils`、`PageUtils` | Maven 依赖 |
| `common-framework` | AOP 切面（幂等/锁/审计/脱敏）| Maven 依赖 |

### 前端公共模块

| 模块/文件 | 提供能力 |
|---------|---------|
| `src/utils/request.ts` | Axios 封装，统一 Token 注入、错误拦截、Loading 控制 |
| `src/composables/usePermission.ts` | `hasPermission()` 权限判断 Hook |
| `src/composables/useDict.ts` | 字典缓存与翻译 Hook |

---

## 1.7 公共组件（AOP 切面）

| 注解 | 功能 | 参数说明 | 使用示例 |
|------|------|---------|---------|
| `@Idempotent` | 幂等控制 | `key`（SpEL 表达式）, `ttl`（秒） | `@Idempotent(key="#req.orderNo", ttl=300)` |
| `@DistributedLock` | 分布式锁 | `key`, `timeout`（毫秒） | `@DistributedLock(key="#orderId", timeout=3000)` |
| `@AuditLog` | 操作审计 | `action`（操作名） | `@AuditLog(action="审批订单")` |
| `@Desensitize` | 字段脱敏 | `type`（PHONE/ID_CARD 等） | Jackson 序列化时自动触发 |

---

## 新引入三/二方库声明（模板 · `规范/examples/it_design_doc.md` §4.2.2）

> 迭代版本中若新增依赖，按行填写；无则写「无」。

| 库名称与版本 | 引入目的 | 替代方案评估 | 许可证 | 稳定性与成熟度 | 兼容性 | 性能与安全 |
|----------------|----------|--------------|--------|----------------|--------|--------------|
| | | | | | | |