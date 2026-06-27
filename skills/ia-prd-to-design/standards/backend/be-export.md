---
standard_id: "be-export"
domain: "backend"
---

# be-export

**规范分段**：`be-export`

### 规范条文

# 数据导出/报表规范（TDD 第3章 §3.5）

## 3.5 数据导出/报表规范

仅当 PRD 包含导出或报表功能时输出。

### 导出模式选型

| 场景 | 模式 | Jalor 实现方式 | 说明 |
|------|------|---------------|------|
| 数据量 < 5000 条 | 同步导出 | `IDownloadSupport` + `LocalExcelExportAssistant.exportExcel()` | 接口直接返回文件流，可后处理上传 EDM |
| 数据量 ≥ 5000 条 | 异步导出 | `LocalExcelExportAssistant.submitExportTask()` | 提交任务 → 框架异步处理 → 下载链接 |

### 架构模式

根据项目已有框架自动识别，无需询问用户：

| 架构 | 适用场景 | 说明 |
|------|---------|------|
| CXF 架构 | MVC 开发范式 | Service 通过 `jaxrs:server` 暴露 REST 接口 |
| DDD 架构 | DDD 开发范式 | ExportConsumer 归属 Domain 层，Repository 查询数据 |

### 导出 VO 类规范

- 使用 Lombok `@Data`（或 `@Setter @Getter`），不手写 getter/setter
- 不强制继承 `BaseResourceVO`，根据项目现有规范决定
- 字段类型规范：数字/金额/单价 → `BigDecimal`；日期/时间 → `Date`（需加序列化器）；整数计数 → `Integer`；其他 → `String`
- 枚举字段需建立三个属性：原值属性（小驼峰）、code 属性（原属性名 + Code）、name 属性（原属性名 + Name）
- VO 类名以 `VO` 结尾，贴合业务含义
- VO 可包含非导出辅助字段（如 userId 用于关联查询），这些字段不出现在 XML 映射中
- 如果项目已存在对应业务 VO 类，直接复用，不重新定义

### 查询对象（Query）规范

- 导出查询条件封装为独立的 Query 类（实现 `Serializable`），而非直接复用 VO
- Query 类使用 Lombok `@Data`，字段仅包含导出所需的查询条件
- 示例：`MatchResultExportQuery`（含 batchId）、`TagSchemeExportQuery`（含 version、versionLabel）

### Excel 映射 XML 规范

- 文件名固定以 `.excelExport.xml` 结尾
- `<excel>` 节点 id 属性以 `.excelExport` 结尾，贴合业务含义
- `<excel>` 节点可配置 `fileName` 属性，指定导出文件的基础名称
- `<excel>` 节点 privilege 属性格式：`Service${@JalorResource 的 code 值}$export`（同步导出需配置，异步导出不配置）
- `<sheet>` 节点 consumerBean 属性格式：`IExcelDataProvider.{ConsumerClassName}`
- `<sheet>` 节点可配置 `batchSize` 属性指定每批处理量（默认 1000）
- `<column>` 节点 name 属性须与 Excel 表头完全一致（保留特殊字符和大小写）
- `<column>` 节点仅映射 VO 中存储原值的属性（枚举字段不映射 code/name 子属性）
- `<column>` 节点可配置 `extentionBean` 属性指定单元格扩展处理器（如合并单元格），格式：`IFieldProcessor.{processorName}`

### 数据生产者（ExportConsumer）规范

**两种实现方式**：

| 方式 | 适用场景 | 基类/接口 | 生命周期回调 |
|------|---------|----------|------------|
| 继承 `BaseExportExcelProvider` | 异步导出，需一站式推送/生命周期回调 | `extends BaseExportExcelProvider`（间接实现 `IExcelDataProvider + IExcelExtentionDataProvider`） | 有 `begin()` / `end()` / `fail()` |
| 直接实现 `IExcelDataProvider` | 同步导出，逻辑极简 | `implements IExcelDataProvider` | 无 |

**通用规范**：

- 添加 `@Service("IExcelDataProvider.{ClassName}")` 注解，Bean 名称须与 XML 中 `consumerBean` 属性一致
- `getBatchData(Serializable serializable, PageVO pageVO)` 方法签名固定，入参为 `Serializable`（运行时强转为 Query 对象）
- `getBatchData()` 内部逻辑：Query 反序列化 → 委托 Repository 查询 → 返回 `List<VO>`
- 多 sheet 导出时，所有 provider 的 `getBatchData` 入参均为第一个 sheet 的 Query 对象
- Repository 返回数据类型须与 Consumer 处理的 VO 类型一致
- DDD 架构下 ExportConsumer 归属 Domain 层

**`BaseExportExcelProvider` 子类额外规范**：

- 须实现 `getModule()` 和 `getPageKey()` 抽象方法，用于"我的导出"页面定位
- `begin()` / `end()` / `fail()` 回调由基类统一处理，发送租户 CS 导出信息
- 如需自定义回调逻辑，覆写对应方法

### 同步导出规范

- 实现 `IDownloadSupport` 接口，`@Service("IDownloadSupport.xxxDownloadSupport")` 暕露下载标识
- 类上加 `@JalorResource(code = "xxxDownloadSupport", desc = "导出xxx")` 注解
- `getFileInfo()` 方法上加 `@JalorOperation(code = RequestConstants.EXPORT, desc = RequestConstants.EXPORT_DESC)`
- 实现 `validatePrivilege()` 方法校验用户权限
- `getFileInfo()` 中调用 `localExcelExportAssistant.exportExcel()`，入参为 XML id 截掉 `.excelExport` 后的部分，第二个入参为 `Serializable`（Query 对象）
- 通过 `IExcelExportContext.getRequest()` 获取 `ExportTaskRequest`，从中取 `fileStore` 和 `fileName`
- 文件显示名格式：`{fileName}_{versionLabel}.{suffix}`
- 下载路径：`${endpoint}/servlet/download??dlType=${xxxDownloadSupport}&contentScope=all`

**同步导出后处理（可选）**：

- 若需将文件上传 EDM 并创建"我的导出"记录，可在 `getFileInfo()` 中通过 `IMessageSender` 发送异步消息
- 异步消息处理器实现 `IMessageProcessor`，在 `process()` 中：上传文件到 EDM（`IAttachmentClient.docUploadByFileByte()`）→ 创建导出任务记录（`IMyExportsService.create()`）
- 异步消息配置在 `{module}.async.beans.xml` 中，使用 `<jlrst:conduits>` 和 `<jlrst:processor>` 注册

### 异步导出规范

- 在 Application 层的 APPService 中注入 `LocalExcelExportAssistant`，调用 `submitExportTask()`
- `submitExportTask()` 入参为 XML id 截掉 `.excelExport` 后的部分，第二个入参为 Query 对象
- 返回值为 `int` 类型任务 ID
- 异常须捕获并抛出自定义 `ApplicationException` 子类
- CXF 架构下通过 `jlrst5.xx.services.xml` 注册 `jaxrs:server`，`serviceBeans` 中 bean 名须与 Service 实现类 `@Service` 注解名一致
- 下载路径：`${endpoint}/servlet/download?dlType=Excel&excelId=${taskId}&execFlag=EXP`

### Repository 层规范（DDD 架构）

- Domain 层定义 Repository 接口，方法返回 `List<XxxVO>`（非 PagedResult）
- Infrastructure 层实现 RDBRepository，调用 DAO 查询 PO 列表，通过 Converter 转换为 VO 列表
- 导出查询方法命名：`queryXxxExportData(Query query)`

### DAO 层规范

- 需包含导出查询方法（返回 `List<XxxPO>`）
- 方法参数加 `@Param` 注解
- MyBatis XML 中分页查询需配套 Count 方法（方法名 = 查询方法名 + Count）
- 查询条件提取公共 SQL 片段，字符串类型需判 null 和空串

### 导出状态管理

- 导出状态枚举：`PROCESSING`（处理中）、`PROCESSING_COMPLETED`（完成）、`ABORT`（中止）
- 同步导出后处理中，上传成功设为 `PROCESSING_COMPLETED`，上传失败设为 `ABORT`
- "我的导出"记录须包含：taskId、fileName、exportStatus、edmId、module、page、filePath、runStartTime、runEndTime

### 内存与性能约束

- 禁止一次性把全量数据加载进内存
- DataProvider 通过分页查询流式处理（XML 中 `batchSize` 默认 1000）
- 大文件（> 50MB）存 OSS/EDM，生成带时效的下载链接（有效期 24h）

### 文件格式规范

- 使用 Jalor Excel 组件，禁止使用 POI 直接操作
- 文件后缀统一为 `xlsx`
- 文件名格式：`{业务名称}_{版本或时间}.{格式}`，如 `标签方案_v1.0.xlsx`

## 输出骨架

# 数据导出/报表设计（TDD 第3章 §3.5）

> ⏭️ **跳过说明**：{若无导出需求，填写原因，删除以下内容}

---

## 3.5 数据导出设计

### 导出任务清单

| 导出功能 | 数据量预估 | 导出模式 | 文件格式 | PRD 溯源（TC / FR） | 动作 |
|---------|---------|---------|---------|-------------------|------|
| | < 5000 / ≥ 5000 | 同步 / 异步 | Excel | TC-… / FR-… | ✨/🔧 |

### ✨/🔧 {导出功能名称}

| 属性 | 值 |
|------|---|
| 导出模式 | 同步 / 异步 |
| 架构模式 | CXF / DDD |
| 数据量预估 | {N} 条 |
| 文件格式 | Excel |
| 权限标识 | `Service${code}$export`（同步）/ 无（异步） |

#### 查询对象（Query）设计

| 字段名 | 类型 | 说明 |
|--------|------|------|
| | String / Integer | 查询条件 |

#### 导出 VO 设计

| 字段名 | 类型 | Excel 列名 | 导出 | 说明 |
|--------|------|-----------|------|------|
| | String / BigDecimal / Integer / Date | | Y/N | N 为辅助字段（如 userId）不映射到 XML |

> 枚举字段需额外列出 code/name 属性行。

#### Excel 映射 XML 配置

| 属性 | 值 |
|------|---|
| 文件名 | `{id}.excelExport.xml` |
| `<excel>` id | `{id}.excelExport` |
| `<excel>` fileName | `{导出文件基础名}` |
| `<excel>` privilege | `Service${code}$export`（同步）/ 无（异步） |

**Sheet 列表**：

| Sheet | name | voClassName | consumerBean | batchSize | 说明 |
|-------|------|-------------|-------------|-----------|------|
| 1 | `{SheetName}` | `{全限定VO类名}` | `IExcelDataProvider.{ConsumerClassName}` | 1000 | |
| 2 | `{SheetName}` | `{全限定VO类名}` | `IExcelDataProvider.{ConsumerClassName}` | 1000 | 多sheet时 |

**列映射（Sheet {N}）**：

| Excel 列名（name） | fieldName | type | displayName | extentionBean |
|-------------------|-----------|------|-------------|---------------|
| | | String / BigDecimal / Integer / Date | zh_CN=,en_US= | 可选 |

#### ExportConsumer 设计

| 属性 | 值 |
|------|---|
| 类名 | `{ConsumerClassName}` |
| Bean 名称 | `IExcelDataProvider.{ConsumerClassName}` |
| 实现方式 | `extends BaseExportExcelProvider`（异步）/ `implements IExcelDataProvider`（同步） |
| 所属层 | Domain（DDD）/ Service Impl（CXF） |

**BaseExportExcelProvider 子类额外属性**（仅异步模式）：

| 属性 | 值 |
|------|---|
| `getModule()` 返回值 | `{EXCEL_MODULE常量}` |
| `getPageKey()` 返回值 | `{PAGE_KEY常量}` |

**getBatchData 逻辑**：

| 步骤 | 说明 | 调用方法 |
|------|------|---------|
| 1 | 强转 Serializable 为 Query | `(XxxQuery) serializable` |
| 2 | 委托 Repository 查询 | `{repository.queryXxxExportData(query)}` |
| 3 | 数据后处理（如翻译枚举、关联查询） | {按需} |
| 4 | 返回 VO 列表 | `return exportDataList` |

> 多 sheet 导出时，每个 sheet 单独一个 Consumer，`getBatchData` 入参均为第一个 sheet 的 Query 对象。

#### 同步导出实现（仅同步模式）

| 属性 | 值 |
|------|---|
| 类名 | `{XxxExportProvider}` |
| Bean 名称 | `IDownloadSupport.{xxxDownloadSupport}` |
| `@JalorResource` code | `{xxxDownloadSupport}` |
| `@JalorOperation` | `code = RequestConstants.EXPORT, desc = RequestConstants.EXPORT_DESC` |
| exportExcel 入参 | `"tagScheme"`, `(Serializable) query`, `new PageVO()` |
| 文件名格式 | `{fileName}_{versionLabel}.{suffix}` |
| 下载路径 | `/servlet/download??dlType={xxxDownloadSupport}&contentScope=all` |

**validatePrivilege 逻辑**：{描述权限校验逻辑}

**getFileInfo 逻辑**：

| 步骤 | 说明 |
|------|------|
| 1 | 从 map 中构造 Query 对象 |
| 2 | 调用 `localExcelExportAssistant.exportExcel()` 获取 IExcelExportContext |
| 3 | 从 context.getRequest() 获取 fileStore 和 fileName |
| 4 | 构造 FileInfoVO（displayName + filePath） |
| 5 | （可选）触发异步后处理消息 |

**异步后处理（可选）**：

| 属性 | 值 |
|------|---|
| 消息类型 | `{MESSAGE_TYPE常量}` |
| 消息内容 VO | `{XxxExportMessageVO}`（含 fileName、fileStore、startTime） |
| 处理器 | `{XxxExportProcessor}` implements `IMessageProcessor` |
| 配置文件 | `{module}.async.beans.xml` |

**处理器逻辑**：

| 步骤 | 说明 | 调用方法 |
|------|------|---------|
| 1 | 上传文件到 EDM | `attachmentClient.docUploadByFileByte()` |
| 2 | 创建"我的导出"记录 | `myExportsService.create()` |
| 3 | 失败时创建 ABORT 记录 | `myExportsService.create()` |

#### 异步导出实现（仅异步模式）

| 属性               | 值                                                                    |
|------------------|----------------------------------------------------------------------|
| Service 类        | `{XxxService}`                                                       |
| submitExportTask 入参 | `"{id}"`（XML id 截掉 `.excelExport`）, `{query对象}`                      |
| 返回值              | `int`（任务 ID）                                                         |
| CXF 配置文件         | `jlrst5.{xx}.services.xml`（CXF 架构）/ 无（DDD 架构，通过 IDownloadSupport 注册） |
| 下载路径             | `/servlet/download?dlType=Excel&excelId=${taskId}&execFlag=EXP`      |

#### Repository 层设计（DDD 架构）

| 接口方法 | 入参 | 返回类型 | 说明 |
|---------|------|---------|------|
| `{queryXxxExportData}` | `{XxxQuery} query` | `List<XxxVO>` | 查询导出数据 |

| 实现类 | 依赖 | 转换器 |
|--------|------|--------|
| `{XxxRDBRepository}` | `{XxxDAO}` | `{XxxPOToVOConverter}` |