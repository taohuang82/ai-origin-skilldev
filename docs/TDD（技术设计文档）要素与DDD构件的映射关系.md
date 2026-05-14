# TDD（技术设计文档）要素与DDD构件的映射关系

> **术语说明**：本文中「TDD」特指「技术设计文档（Technical Design Document）」，而非「测试驱动开发（Test-Driven Development）」。

------

## 一、TDD要素与DDD构件的依赖关系总览

在DDD实践中，**TDD要素主要作为「设计输入」和「实现约束」**，驱动DDD各构件的产出。依赖关系可归纳为：

| DDD构件                      | 核心职责                                                     | 依赖的主要TDD要素（输入来源）                                | 依赖说明                                                     |
| ---------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **Entity**                   | 具有唯一标识的业务对象，封装业务规则与状态变更               | • 2.1 物理表设计<br>• 2.3 实体流转关系<br>• 3.1 API清单（请求/响应参数）<br>• 6.1 数据字典 | 表的字段、唯一标识、状态枚举、字典值直接映射为Entity的属性；状态机定义其生命周期行为 |
| **Value Object**             | 无唯一标识的不可变值对象，描述业务特征                       | • 2.1 物理表设计（嵌入式字段或独立表）<br>• 3.1 API清单（复合类型参数）<br>• 6.1 数据字典 | 值对象的属性集合来源于表结构中的嵌入式字段（如地址、金额范围）；字典项可封装为值对象 |
| **Domain Event**             | 描述领域内已发生的业务事实，携带事件ID与时间戳               | • 5.1 MQ清单<br>• 2.3 实体流转关系                           | 消息Topic/Tag对应领域事件类型；状态流转的后置动作触发领域事件发布 |
| **Domain Service**           | 处理跨实体的业务逻辑、无状态的计算或协调                     | • 3.3 处理逻辑时序<br>• 3.4 分布式事务<br>• 5.1 MQ清单<br>• 5.2 外部服务依赖 | 时序图中的复杂业务流、分布式事务协调、外部服务调用、消息发送等由Domain Service实现 |
| **Repository**               | 负责聚合根的持久化存取，接口定义在领域层，实现在基础设施层   | • 2.1 物理表设计（表结构、索引）<br>• 3.6 定时任务（查询逻辑）<br>• 5.1 MQ清单（存储到DB）<br>• 6.4 配置项清单（数据源配置） | 表结构决定Repository的查询条件、索引设计影响查询方法；定时任务的扫描逻辑依赖Repository |
| **聚合根（Aggregate Root）** | 作为业务一致性边界，是聚合的唯一入口，协调内部Entity与Value Object | • 2.3 实体流转关系<br>• 3.2 核心代码类（UML类图）<br>• 3.3 处理逻辑时序 | 状态流转定义聚合根状态机；类图和时序图明确聚合内的对象组合关系 |

> **关键结论**：
>
> - **Entity、Value Object、Domain Event、Domain Service** 直接由业务需求（PRD）经由TDD要素中的**数据模型、API、时序、状态机、消息**驱动产出。
> - **Repository** 由**物理表设计、查询逻辑**驱动，接口定义属于领域层，具体实现属于基础设施层，遵循依赖倒置原则。
> - **聚合根** 是特殊的Entity，承担一致性边界职责，不应与普通Entity混用表述。
> - 整个TDD过程遵循「**用例驱动 → 领域模型 → 持久化设计**」的顺序，符合DDD的战略设计思想。

------

## 二、TDD要素对DDD构件输出形式的影响（按TDD要素分类表格）

以下表格针对每个TDD子要素，说明其**会影响哪些DDD构件的「输出形态」**，即在DDD实现中，该要素将具体约束或改变各构件的设计内容。

### 第一章：顶层架构与全局规范

| TDD子要素          | 影响的DDD构件                                    | 具体影响说明（输出形态变化）                                 |
| ------------------ | ------------------------------------------------ | ------------------------------------------------------------ |
| 1.1 技术选型       | Repository、Domain Service                       | 选择JPA/MyBatis影响Repository实现样式（面向对象映射 vs 手写SQL）；RPC框架影响Domain Service的调用方式等 |
| 1.2 部署架构       | 聚合根、Repository                               | 跨地域或单元化部署架构会影响聚合一致性边界的粒度设计；分布式场景下Repository可能需要支持分库分表路由策略 |
| 1.3 微服务架构     | 聚合根、Repository                               | 限界上下文（Bounded Context）定义微服务的划分边界，聚合根设计应首先遵从限界上下文；跨服务场景下Repository可能面临分库分表 |
| 1.4 灰度与特性开关 | Domain Service                                   | 特性开关可注入Domain Service，实现业务逻辑的动态分支         |
| 1.5 代码架构       | Entity、Value Object、Domain Service、Repository | 强制分层（如`domain`包、`infrastructure`包）直接定义各构件存放位置；依赖倒置原则明确Repository接口在domain层，实现在infra层 |
| 1.6 公共基础库     | Entity、Value Object                             | 基础抽象类（如BaseEntity）影响Entity的通用属性（id、version）；工具类可用于值对象转换 |
| 1.7 公共组件       | Repository、Domain Service                       | 分布式锁组件影响Repository并发更新逻辑；幂等组件影响Domain Service的重复请求处理；日志切面记录领域事件 |

### 第二章：数据存储与模型设计

| TDD子要素        | 影响的DDD构件                                | 具体影响说明（输出形态变化）                                 |
| ---------------- | -------------------------------------------- | ------------------------------------------------------------ |
| 2.1 物理表设计   | **Entity**、**Value Object**、**Repository** | • 表名→聚合根类名，字段→Entity属性（类型、约束）<br>• 嵌入式字段（如address_province、address_city）→Value Object `Address`<br>• 索引定义→Repository方法命名（如`findByOrderNo`）<br>• 分库分表键→Repository路由策略 |
| 2.2 缓存设计     | Repository、Domain Service                   | • 缓存Key与TTL约束Repository的缓存注解或手动缓存逻辑<br>• 双写一致性影响Repository的更新后清缓存操作<br>• 缓存穿透/雪崩策略影响Domain Service的降级处理 |
| 2.3 实体流转关系 | **聚合根**、Domain Service、**Domain Event** | • 状态图→聚合根内部状态机方法（如`submit()`、`approve()`）<br>• 前置/后置条件→Domain Service中的流转校验逻辑<br>• 枚举值→Entity状态属性类型（Enum）<br>• 状态变更后置动作→触发Domain Event发布 |

### 第三章：后端接口与业务逻辑

| TDD子要素         | 影响的DDD构件                                                | 具体影响说明（输出形态变化）                                 |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 3.1 API清单       | Entity、Value Object、Domain Service                         | • 请求/响应参数中的字段→Entity属性或Value Object定义（注意：面向接口的DTO属于应用层，不等于领域对象本身）<br>• 接口路径/方法→Domain Service的入口方法（如`OrderService.placeOrder()`）<br>• 字段来源引用PRD实体详情→确保领域模型与业务需求一致 |
| 3.2 核心代码类    | **Entity**、**Value Object**、**Domain Service**、**Repository**、**聚合根** | • UML类图→定义聚合根、实体、值对象的类结构及关联关系<br>• 接口/实现类表格→明确Domain Service接口与实现<br>• 设计模式（工厂、策略）→影响Domain Service的构造方式 |
| 3.3 处理逻辑时序  | **Domain Service**、Entity                                   | • 时序图中的交互→映射为Domain Service中方法调用链<br>• 分支与异常路径→Domain Service中的if/else和异常抛出<br>• 涉及组件（如外部服务）→Domain Service依赖Repository或其他Domain Service |
| 3.4 分布式事务    | **Domain Service**                                           | • 事务模式（TCC/Saga）→Domain Service中实现正向方法、补偿方法<br>• 事务边界定义→确定哪些领域操作需要标记`@Transactional`或发起Saga |
| 3.5 数据导出/报表 | Repository、Domain Service                                   | • 导出查询条件→Repository的查询方法（如分页、游标）<br>• 异步导出→Domain Service中触发导出任务、回调通知 |
| 3.6 定时任务      | **Repository**、Domain Service                               | • 查询SQL逻辑→Repository的批量查询方法<br>• 批处理逻辑→Domain Service的批量处理入口<br>• 分片策略→Repository的分片查询实现 |
| 3.7 审批流配置    | **聚合根**、Domain Service                                   | • BPMN节点→聚合根状态流转的步骤<br>• 审批人策略→Domain Service中获取审批人逻辑<br>• 会签/或签→聚合根内部记录审批结果集合 |

### 第四章：前端展现与交互设计

| TDD子要素              | 影响的DDD构件          | 具体影响说明（输出形态变化）                                 |
| ---------------------- | ---------------------- | ------------------------------------------------------------ |
| 4.1 页面清单与布局     | -（无直接影响）        | 前端页面布局不直接影响DDD构件；页面所需数据通过应用层（Application Service）编排后以DTO形式返回，领域模型本身不应随前端布局变动 |
| 4.2 前端已有公共组件   | -（无直接影响）        | 不直接影响DDD构件                                            |
| 4.3 新增组件设计       | -（间接影响应用层DTO） | 组件Props/Emits所需的数据结构应映射为应用层DTO（数据传输对象），由应用层从Entity/Value Object组装后返回；前端数据结构不应直接驱动领域模型设计，以保持DDD的层次隔离 |
| 4.4 页面交互与接口依赖 | Domain Service         | 接口依赖清单中的API→Domain Service的入口；复杂页面交互逻辑通过应用层编排多个Domain Service完成 |

### 第五章：异步处理与系统集成

| TDD子要素        | 影响的DDD构件                                | 具体影响说明（输出形态变化）                                 |
| ---------------- | -------------------------------------------- | ------------------------------------------------------------ |
| 5.1 MQ清单       | **Domain Event**、Domain Service、Repository | • 消息Topic/Tag→对应领域事件类型（如`OrderPaidEvent`），领域事件是独立的DDD构件，携带事件ID与时间戳，不等于值对象<br>• 消息体Schema→领域事件内部的数据字段，部分字段可建模为Value Object<br>• 幂等策略→Repository通过消息ID去重 |
| 5.2 外部服务依赖 | Domain Service                               | • 外部接口定义→Domain Service中调用防腐层（Anticorruption Layer）<br>• 容错降级→Domain Service实现Fallback逻辑 |
| 5.3 消息通知     | Domain Service                               | 通知触发场景→Domain Service中调用通知服务；频控策略可在Application Service实现 |

### 第六章：配置、字典、安全与权限

| TDD子要素        | 影响的DDD构件              | 具体影响说明（输出形态变化）                                 |
| ---------------- | -------------------------- | ------------------------------------------------------------ |
| 6.1 数据字典     | **Value Object**、Entity   | • 字典键值映射→可封装为值对象（如`Status.fromCode()`）<br>• 级联联动→Entity的校验逻辑中引用字典值对象 |
| 6.2 错误码体系   | Domain Service             | 业务异常→Domain Service抛出自定义异常并关联错误码；文案用于前/后置消息 |
| 6.3 权限矩阵     | -（无直接影响）            | 权限通常在应用层或基础设施层校验，不应渗透影响领域模型设计   |
| 6.4 配置项清单   | Repository、Domain Service | 动态刷新配置→领域逻辑中使用配置对象（如折扣阈值）            |
| 6.5 非功能与安全 | Repository、Entity         | 脱敏规则→Entity的toString()或序列化时脱敏；加密逻辑→Repository存入DB前加密 |

------

## 三、总结实践建议

1. **以聚合根为核心**：物理表设计（2.1）和实体流转关系（2.3）是聚合根与Entity的直接输入，需确保表字段与实体属性双向可追溯。聚合根是特殊的Entity，承担一致性边界职责，应在设计中明确区分。
2. **Value Object的识别**：来自嵌入式字段（2.1）、API复合参数（3.1）、字典项（6.1）的数据应显式建模为值对象，避免基本类型偏执（Primitive Obsession）。
3. **Domain Event的独立建模**：MQ消息体（5.1）应建模为领域事件（Domain Event），而非Value Object。领域事件描述「已发生的业务事实」，具有事件ID和时间戳等标识属性，是DDD的一等构件。
4. **Domain Service的职责**：时序图（3.3）、分布式事务（3.4）、MQ（5.1）中的跨实体或跨系统逻辑都应放在Domain Service中，保持聚合根与Entity的内聚性。
5. **Repository的层次隔离**：Repository**接口定义在领域层**，**实现在基础设施层**，遵循依赖倒置原则。所有持久化细节（2.1的索引、分库分表；3.6的查询SQL）均封装在Repository实现中，领域层仅依赖接口。
6. **保持领域模型与应用层的边界**：前端组件数据结构（4.3）、页面展示需求应通过应用层DTO转换，不得直接影响领域模型设计；权限校验（6.3）属于应用层或基础设施层职责，不应污染领域层。
7. **限界上下文优先于服务边界**：微服务的划分边界应由限界上下文（Bounded Context）驱动确定，而非反向由已有服务边界来定义限界上下文。