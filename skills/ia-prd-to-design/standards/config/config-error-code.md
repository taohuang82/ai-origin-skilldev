---
standard_id: "config-error-code"
domain: "config"
---

# config-error-code

**规范分段**：`config-error-code`

### 规范条文

# 错误码体系规范（TDD 第6章 §6.2）

## 6.2 错误码体系规范

### 异常定义架构

**技术栈**：基于Jalor框架的 `BusinessExceptionAssert` 接口和 `ApplicationException` 体系

**定义位置**：`domain` 层的 `share` 包，异常枚举类命名为 `{Project}BusinessException`

**典型路径**：
```
backend/{project}-domain/src/main/java/com/{company}/mbs/{project}/domain/share/{Project}BusinessException.java
```

**枚举结构**：
```java
@Getter
@AllArgsConstructor
public enum ArsBusinessException implements BusinessExceptionAssert {
    // 异常枚举项定义...
    ;

    private Integer httpCode;  // HTTP状态码
    private String code;       // 业务异常码
    private String message;    // 错误消息（支持占位符{0}, {1}等）
}
```

### 错误码格式规范

**格式**：`{Project}.{Feature}.{ErrorType}.{SixDigitNumber}`

**命名规范**：
- 枚举项命名：使用大写字母和下划线，格式为 `{FEATURE}_{ACTION}_{ERROR}`
- 错误码格式：项目简称 + 功能模块 + 错误类型 + 6位序号
- 错误类型分组：CreateError、QueryError、UpdateError、DeleteError、OperationError

**分组原则**：
- 同一功能模块的异常使用统一前缀
- 数字编码采用6位数字
- 按操作类型分组管理

**示例**：
```java
// 标签创建错误码
LABEL_CREATE_PARAM_ERROR(400, "Ars.Label.CreateError.000001", "创建参数错误:{0}")
LABEL_CREATE_DUPLICATE_ERROR(400, "Ars.Label.CreateError.000002", "标签名称已存在")

// 标签查询错误码
LABEL_QUERY_PARAM_ERROR(400, "Ars.Label.Query.000001", "查询参数错误:{0}")
LABEL_QUERY_NOT_EXIST_ERROR(400, "Ars.Label.Query.000002", "查询的标签不存在")

// 标签更新错误码
LABEL_UPDATE_PARAM_ERROR(400, "Ars.Label.UpdateError.000001", "更新参数错误:{0}")
LABEL_UPDATE_STATUS_ERROR(400, "Ars.Label.UpdateError.000002", "标签状态不允许更新")

// 系统错误码
SYSTEM_CONFIG_ERROR(500, "Ars.System.Config.000001", "系统配置缺失:{0}")
SYSTEM_USER_UNKNOWN(500, "Ars.System.User.000001", "系统用户未配置")
```

### HTTP状态码选择规范

| 状态码 | 适用场景 | 示例 |
|:-------|:---------|:-----|
| **400 Bad Request** | 参数校验失败、业务规则校验、权限检查失败 | 参数缺失、数据格式错误、状态不允许操作、权限不足 |
| **500 Internal Server Error** | 系统配置错误、依赖服务异常、内部逻辑错误 | 配置缺失、系统用户未配置、同步异常 |

**选择原则**：
- 业务层面可预见的错误使用 400
- 系统层面不可预见的错误使用 500
- 权限类错误使用 400（框架约定，不使用 403）

### 断言方法使用规范

**BusinessExceptionAssert 接口提供的断言方法**：

1. **assertIsTrue** - 条件为真时抛出异常
   ```java
   ArsBusinessException.LABEL_CREATE_DUPLICATE_ERROR.assertIsTrue(existingLabel != null);
   ArsBusinessException.LABEL_CREATE_PARAM_ERROR.assertIsTrue(paramInvalid, "标签名称不能为空");
   ```

2. **assertIsFalse** - 条件为假时抛出异常
   ```java
   ArsBusinessException.LABEL_QUERY_NOT_EXIST_ERROR.assertIsFalse(label == null);
   ```

3. **assertNotNull** - 对象为 null 时抛出异常
   ```java
   ArsBusinessException.LABEL_QUERY_NOT_EXIST_ERROR.assertNotNull(label);
   ArsBusinessException.SYSTEM_CONFIG_ERROR.assertNotNull(config, "标签配置未找到");
   ```

4. **直接抛出异常**
   ```java
   throw ArsBusinessException.LABEL_DELETE_USED_ERROR.createException();
   ```

### 异常分层处理原则

| 层次 | 异常处理职责 | 示例 |
|:-----|:-------------|:-----|
| **Interface层** | 参数基础校验（非空、格式） | @Valid注解、手动校验 |
| **Application层** | 业务流程校验、权限检查 | 业务流程前置条件、权限验证 |
| **Domain层** | 业务规则校验、领域逻辑校验 | 业务规则验证、领域约束检查 |
| **Infrastructure层** | 技术异常处理、数据访问异常 | SQLException转换、RPC调用异常 |

**原则**：
- 在合适的层次尽早发现和抛出异常
- 避免异常在深层传播
- 减少异常处理的嵌套层级

### 错误消息设计规范

**清晰性原则**：
- 错误消息应清晰描述问题所在
- 提示用户如何修正错误
- 支持占位符参数传递具体信息

**良好示例**：
```java
"创建参数错误:标签名称不能为空"
"标签名称已存在,请使用不同的名称"
"标签已被使用,无法删除,请先解除关联"
```

**避免示例**：
```java
// 避免模糊描述
"创建失败"
"操作错误"
"系统异常"
```

### 错误码分配原则

- 同一系统内错误码唯一，禁止复用
- 序号从 `000001` 开始，按功能模块分组递增
- 新增错误码追加，禁止修改已存在错误码含义（向后兼容）

### 国际化配置规范

**配置路径**：`resources/i18n/messages_{language}.properties`

**配置示例**：
```properties
# messages_zh_CN.properties
Ars.Label.CreateError.000001=创建参数错误:{0}
Ars.Label.CreateError.000002=标签名称已存在

# messages_en_US.properties
Ars.Label.CreateError.000001=Create parameter error: {0}
Ars.Label.CreateError.000002=Label name already exists
```

**框架处理**：
- Jalor框架自动根据请求头语言选择对应的消息
- 未配置时使用枚举中的默认 message
- 占位符自动替换为传入的参数

### 前端文案规范

- 业务错误：给用户友好提示（中文），引导用户操作
- 系统错误：通用提示（如"系统繁忙，请稍后重试"），不暴露内部细节
- 多语言：`i18n/zh-CN.json` 中 key = 错误码，value = 文案

### API 响应中的错误码使用

**错误码响应示例**：
```json
{
    "code": "Ars.Label.Query.000002",      // 业务异常码
    "httpCode": 400,                       // HTTP状态码
    "entity": null,
    "message": "查询的标签不存在",          // 错误信息
    "faultUid": null,
    "stackTrace": "",
    "friendly": true
}
```

**禁止事项**：
- 禁止在 API 响应中直接返回数据库错误或堆栈信息
- 禁止在异常消息中暴露敏感信息（密码、token等）
- 禁止直接抛出 RuntimeException 或 Exception
- 禁止使用过于笼统的异常消息

## 输出骨架

# 错误码体系设计（TDD 第6章 §6.2）

<!--
变更标注约定：
- ✨ 新增：本次新增的错误码
- 🔧 修改：修改了已有错误码文案（不修改错误码本身）
-->

## 变更概要

| 动作 | 对象 | 说明 |
|------|------|------|
| ✨/🔧 | | |

---

## 6.2 错误码体系

### 异常定义位置

**定义文件**：`backend/{project}-domain/src/main/java/com/{company}/mbs/{project}/domain/share/{Project}BusinessException.java`

**枚举类名**：`{Project}BusinessException`（实现 `BusinessExceptionAssert` 接口）

### 错误码清单

| 错误码 | 错误类型 | HTTP 状态 | 前端用户文案 | 开发者说明 | 动作 |
|--------|---------|----------|-----------|---------|------|
| `{Project}.{Feature}.{ErrorType}.000001` | {错误类型分组} | {HTTP码} | | | ✨ |

---

### ✨/🔧 {模块名} 模块错误码

> 🔧 **变更说明**：{仅修改时填写}

**错误码分组区段**：

| 错误类型 | 错误码区段 | 说明 |
|---------|-----------|------|
| CreateError | `{Project}.{Feature}.CreateError.000001~000099` | 创建操作相关错误 |
| QueryError | `{Project}.{Feature}.Query.000001~000099` | 查询操作相关错误 |
| UpdateError | `{Project}.{Feature}.UpdateError.000001~000099` | 更新操作相关错误 |
| DeleteError | `{Project}.{Feature}.DeleteError.000001~000099` | 删除操作相关错误 |
| OperationError | `{Project}.{Feature}.OperationError.000001~000099` | 其他操作相关错误 |

**枚举定义示例**：

```java
@Getter
@AllArgsConstructor
public enum ArsBusinessException implements BusinessExceptionAssert {

    // ========== {模块名}模块错误码 ==========

    // {模块名} - 创建错误码
    {MODULE}_CREATE_PARAM_ERROR(Response.Status.BAD_REQUEST.getStatusCode(),
        "{Project}.{Module}.CreateError.000001", "创建参数错误:{0}"),
    {MODULE}_CREATE_DUPLICATE_ERROR(Response.Status.BAD_REQUEST.getStatusCode(),
        "{Project}.{Module}.CreateError.000002", "名称已存在"),

    // {模块名} - 查询错误码
    {MODULE}_QUERY_PARAM_ERROR(Response.Status.BAD_REQUEST.getStatusCode(),
        "{Project}.{Module}.Query.000001", "查询参数错误:{0}"),
    {MODULE}_QUERY_NOT_EXIST_ERROR(Response.Status.BAD_REQUEST.getStatusCode(),
        "{Project}.{Module}.Query.000002", "查询的对象不存在"),

    // {模块名} - 更新错误码
    {MODULE}_UPDATE_PARAM_ERROR(Response.Status.BAD_REQUEST.getStatusCode(),
        "{Project}.{Module}.UpdateError.000001", "更新参数错误:{0}"),
    {MODULE}_UPDATE_STATUS_ERROR(Response.Status.BAD_REQUEST.getStatusCode(),
        "{Project}.{Module}.UpdateError.000002", "状态不允许更新"),

    // {模块名} - 删除错误码
    {MODULE}_DELETE_STATUS_ERROR(Response.Status.BAD_REQUEST.getStatusCode(),
        "{Project}.{Module}.DeleteError.000001", "状态不允许删除"),
    {MODULE}_DELETE_USED_ERROR(Response.Status.BAD_REQUEST.getStatusCode(),
        "{Project}.{Module}.DeleteError.000002", "已被使用,无法删除"),

    // 系统错误码（如需要）
    SYSTEM_{MODULE}_ERROR(Response.Status.INTERNAL_SERVER_ERROR.getStatusCode(),
        "{Project}.System.{Module}.000001", "系统异常:{0}"),

    ;

    private Integer httpCode;
    private String code;
    private String message;
}
```

**完整错误码清单**：

| 错误码 | 错误类型 | HTTP 状态 | 前端用户文案 | 开发者说明 | 触发场景 |
|--------|---------|----------|-----------|---------|---------|
| `Ars.Label.CreateError.000001` | CreateError | 400 | 创建参数错误:{0} | Create parameter error | 参数校验失败 |
| `Ars.Label.CreateError.000002` | CreateError | 400 | 标签名称已存在 | Label name duplicate | 名称唯一性校验失败 |
| `Ars.Label.Query.000001` | QueryError | 400 | 查询参数错误:{0} | Query parameter error | 查询参数校验失败 |
| `Ars.Label.Query.000002` | QueryError | 400 | 查询的标签不存在 | Label not found | 数据存在性校验 |
| `Ars.Label.UpdateError.000001` | UpdateError | 400 | 更新参数错误:{0} | Update parameter error | 更新参数校验失败 |
| `Ars.Label.UpdateError.000002` | UpdateError | 400 | 标签状态不允许更新 | Status invalid for update | 状态机校验失败 |
| `Ars.Label.DeleteError.000001` | DeleteError | 400 | 标签状态不允许删除 | Status invalid for delete | 状态机校验失败 |
| `Ars.Label.DeleteError.000002` | DeleteError | 400 | 标签已被使用,无法删除 | Label is in use | 关联数据校验失败 |
| `Ars.System.Label.000001` | SystemError | 500 | 系统繁忙,请稍后重试 | System error | 系统异常 |

**断言方法使用示例**：

```java
// 参数校验 - assertIsTrue
ArsBusinessException.LABEL_CREATE_PARAM_ERROR
    .assertIsTrue(StringUtils.isBlank(request.getName()), "标签名称不能为空");

// 存在性校验 - assertNotNull
Label label = labelRepository.findById(labelId);
ArsBusinessException.LABEL_QUERY_NOT_EXIST_ERROR.assertNotNull(label);

// 业务规则校验 - assertIsTrue
ArsBusinessException.LABEL_DELETE_STATUS_ERROR
    .assertIsTrue(label.getStatus() == LabelStatus.ACTIVE, "只有启用状态的标签可以删除");

// 权限校验 - assertIsTrue
ArsBusinessException.FEATURE_ACCESS_DENIED
    .assertIsTrue(!permissionService.hasAccess(userId, labelId));
```

**错误码分配原则**：
- 同一系统内错误码唯一，禁止复用
- 序号从 `000001` 开始，按错误类型分组递增
- 新增错误码追加，禁止修改已存在错误码含义（向后兼容）

**国际化文件路径**：`resources/i18n/messages_{language}.properties`

```properties
# messages_zh_CN.properties
Ars.Label.CreateError.000001=创建参数错误:{0}
Ars.Label.CreateError.000002=标签名称已存在
Ars.Label.Query.000002=查询的标签不存在

# messages_en_US.properties
Ars.Label.CreateError.000001=Create parameter error: {0}
Ars.Label.CreateError.000002=Label name already exists
Ars.Label.Query.000002=Label not found
```

**异常分层处理建议**：

| 校验类型 | 建议处理层 | 示例 |
|---------|-----------|------|
| 参数基础校验（非空、格式） | Interface层 | @Valid注解、手动校验 |
| 业务流程校验、权限检查 | Application层 | 流程前置条件、权限验证 |
| 业务规则校验 | Domain层 | 业务规则验证、领域约束 |
| 系统异常 | Infrastructure层 | 技术异常转换 |