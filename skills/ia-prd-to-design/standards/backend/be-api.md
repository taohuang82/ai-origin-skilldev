---
standard_id: "be-api"
domain: "backend"
---

# be-api

**规范分段**：`be-api`

### 规范条文

# API 设计规范

## 风格规范

- 遵循 RESTful 语义：资源名用复数名词，操作用 HTTP 方法表达
- 路径全小写，单词间用连字符 `-` 分隔
- **禁止使用版本号路径**（如 `/v1/`、`/v2/`）
- 资源嵌套不超过两层：`/orders/{id}/items`
- **第二层路径使用复数形式**（如 `/orders/`，而不是 `/order/`）

## API 路径规范

### 路径格式
- **UI API路径**：`/uiapi/<资源复数>[/<子路径>]`
- **Public API路径**：`/publicservices/<资源复数>[/<子路径>]`
- **Private API路径**：`/services/<资源复数>[/<子路径>]`
- **定时任务接口**：使用 `/publicservices/` 前缀

### 路径命名原则
- 使用名词，不使用动词
- 使用小写字母
- 使用连字符分隔单词（如 `/order-items/`）
- 清晰反映资源类型

### 路径示例
✅ 正确示例：
- `/uiapi/orders` - 订单列表
- `/uiapi/orders/{id}` - 订单详情
- `/uiapi/order-items` - 订单明细
- `/publicservices/order-sync` - 订单同步任务

❌ 错误示例：
- `/uiapi/v1/orders` - 包含版本号
- `/uiapi/order` - 第二层使用单数
- `/uiapi/getOrders` - 使用动词

## 导入 API 规范

Excel 批量导入使用 **Jalor 框架内置 Servlet 接口**，路径不走 `/uiapi/` 前缀；设计文档中须按下列固定契约描述，不得自行发明 REST 风格导入路径。

> 实现细节（Provider 类、XML 配置、临时表机制）见 Excel 导入二方件规范；权限码与 `config-permission` 中 `import` 操作对齐。

### 导入 API

| 操作 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 上传导入 | POST | `/servlet/upload?ulType=ExcelImport&excelType={excelId}` | 上传 Excel 文件并触发异步导入 |


## 接口类型说明

### UI API
- **用途**：用于前端页面交互
- **路径前缀**：`/uiapi/`
- **调用方**：前端页面、用户操作
- **权限控制**：需要用户权限校验
- **鉴权方式**：JWT Token

### Public API
- **用途**：第三方系统集成
- **路径前缀**：`/publicservices/`
- **调用方**：第三方系统
- **权限控制**：sgov
- **鉴权方式**：API Key

### Private API
- **用途**：内部系统跨模块调用
- **路径前缀**：`/services/`
- **调用方**：内部系统跨模块调用
- **权限控制**：jwt
- **鉴权方式**：jwt token

## HTTP 方法语义

| 方法 | 语义 | 幂等 |
|------|------|------|
| GET | 查询，不修改状态 | 是 |
| POST | 创建资源 / 复杂操作 | 否 |
| PUT | 全量更新 | 是 |
| PATCH | 部分更新 | 否 |
| DELETE | 删除 | 是 |

## 请求参数规范

### 参数分类
- **路径参数**：资源唯一标识，如 `{id}`
- **Query 参数**：过滤、分页、排序，如 `?page=1&size=20&sortBy=createTime`
- **Body 参数**：JSON 格式，字段名驼峰命名

### 分页参数规范
- 统一命名：`page`（从 1 开始）、`size`（默认 20，最大 100）
- 列表接口统一支持分页，不提供无分页的全量查询接口

### 参数校验规则
- 必填字段明确标注
- 字段长度限制（如最大255字符）
- 字段格式要求（如日期格式 YYYY-MM-DD）
- 枚举值范围明确

## 响应规范

### 成功响应结构
```json
{
  "error": null,
  "status": "SUCCESS",
  "data": { }
}
```

### 错误响应结构
```json
{
  "error": [{
    "errorCode": "错误码",
    "errorMsg": "错误信息",
    "sourceId": "来源ID"
  }],
  "status": "ERROR",
  "data": null
}
```

### 分页响应结构
```json
{
  "error": null,
  "status": "SUCCESS",
  "data": {
    "pageVO": {
      "totalRows": 0,
      "curPage": 0,
      "pageSize": 0,
      "resultMode": 0,
      "startIndex": 0,
      "endIndex": 0,
      "orderBy": "string",
      "filterStr": "string"
    },
    "result": []
  }
}
```

### 字段格式规范
- **空数据**：返回 `null` 或空对象/数组，不返回 `undefined`
- **时间字段**：ISO 8601 格式字符串，如 `2024-01-01T00:00:00Z`
- **枚举字段**：同时返回 code（数字）和 label（显示文本）
- **敏感字段**：手机号、身份证在响应中脱敏处理

## 错误处理规范

### HTTP 状态码与业务错误码双轨
- HTTP 状态码：4xx/5xx
- 业务错误码：`4xxxx`（参数错误）、`5xxxx`（服务错误）

### 错误场景分类

| HTTP状态码 | 业务错误码 | 说明 |
|-----------|-----------|------|
| 400 | 4xxxx | 请求参数不完整或格式错误 |
| 401 | - | 未授权，Token无效或已过期 |
| 403 | - | 无权限，用户缺少相应权限 |
| 404 | - | 资源不存在 |
| 409 | - | 资源冲突（如重复创建） |
| 500 | 5xxxx | 服务器内部错误 |

### 错误消息原则
- 错误 message 面向开发者，不直接展示给用户
- 包含错误详情和解决建议

## 安全规范

- 所有涉及数据修改的接口必须认证
- 接口需声明所需权限标识（对应权限设计中的权限码）
- 敏感字段（手机号、身份证）在响应中脱敏处理
- 禁止在 GET 请求的 URL 中传递敏感信息

## 幂等性规范

- POST 创建接口通过幂等键（`X-Idempotency-Key` Header）保证幂等
- 支付、状态变更等关键操作必须设计幂等机制

## 权限校验双层机制

### 第1层：框架权限校验（操作权限）
- **目的**：校验用户是否有操作权限（读/写/审批/导入/导出）
- **实现方式**：使用 `@JalorOperation` 注解
- **示例**：`@JalorOperation(operationCode = RequestConstants.READ)`
- **校验内容**：用户是否有该接口的操作权限，由 Jalor 框架自动完成

### 第2层：业务权限校验（数据权限）
- **目的**：校验用户可以查看/操作哪些数据
- **校验逻辑**：根据 PRD 文档中的角色权限矩阵设计
  - 哪些角色可以看到哪些数据
  - 哪些角色可以操作哪些数据
  - 数据范围限制（全局数据/部门数据/个人数据）

## 项目规范摘录（`规范/` 目录 · IT 设计文档 §4.4）

> 来源：`{WORKSPACE_ROOT}/规范/examples/it_design_doc.md`「接口描述」章节。

- **接口说明形式**：除本仓库 API 要素表格外，可用 **YAML（OpenAPI/Swagger 风格）** 描述路径、出入参含义与约束，与实现保持一致。
- **存量接口修改**（若涉及）：列出「修改接口 / 修改内容 / 修改原因 / 影响评估（向后兼容、调用方）」。
- **测试要点**：结合项目现有测试框架，说明本接口的验证要点与边界条件。

## 输出骨架
# API 设计

<!--
变更标注约定（增量模式使用，全量模式所有内容均为新增可省略标注）：
- ✨ 新增：本次新增的接口
- 🔧 修改：在现有基础上有变更（参数/响应/认证等）

PRD 溯源约定（与 `element-registry.yaml` 中 `be-api.prd_sources` 对齐）：
- **特性分类编号**：`TC-{两位}`（见 PRD「特性分类总览」表，如 TC-01）
- **子特性编号**：`FR-…`（以 PRD 正文中的子特性编号为准，如 FR-01-01-001）
- 一条接口可支撑多个子特性：同一格内用顿号「、」列举 FR；TC 写所属分类（多个 TC 时顿号分隔或与 FR 成对说明）
- 若 PRD 未给出 TC/FR 编号：填「未编号」并附 PRD 小节标题或段落锚点（如「§5.2 xxx」），不得留空
-->

## 变更概要

| 动作 | 接口 | PRD 溯源 | 说明 |
|------|------|---------|------|
| ✨ 新增 | | TC-… / FR-… | |
| 🔧 修改 | | TC-… / FR-… | |

---

## 接口清单

| 序号 | 模块 | 方法 | 路径 | 功能说明 | PRD 溯源（TC / FR） | 认证 | 动作 |
|------|------|------|------|---------|-------------------|------|------|
| 1 | | GET | | | TC-01 / FR-01-01-001 | Y/N | ✨/🔧 |

## 通用约定

- **Base URL**：`/uiapi/资源复数`
- **认证方式**：{Bearer Token / Cookie Session / 无}
- **Content-Type**：`application/json`

### 统一响应格式

```json
{
  "error": [{
    "errorCode": "错误码",
    "errorMsg": "错误信息",
    "sourceId": "来源ID"
   }],
  "status": "SUCCESS/ERROR",
  "data": {}
}
```

### 错误码

> 完整错误码定义见 `config/dict-error.md`（TDD §6.2）。
> 本节仅列出本次接口设计新增/变更的错误码，不重复定义已有错误码。

| 错误码 | HTTP 状态码 | 含义 | 动作 |
|--------|------------|------|------|
| `APP-{MOD}-BIZ-001` | 400 | {业务错误说明} | ✨ |

### 权限标识符

> 完整权限矩阵定义见 `config/permission.md`（TDD §6.3）。
> 本节接口的 `权限` 列中填写权限标识符，格式：`{模块}:{资源}:{操作}`。

---

## 接口详细设计

### ✨/🔧 {接口名称}

> 🔧 **变更说明**：{仅修改时填写，说明变更点（新增参数/响应字段变化/认证方式调整等）及原因}

| 字段 | 值                       |
|------|-------------------------|
| 方法 | `{GET/POST/PUT/DELETE}` |
| 路径 | `/uiapi/{资源复数}/{id}`    |
| 功能 | {接口用途}                  |
| PRD 溯源 | `TC-01`；子特性：`FR-01-01-001`（多条顿号分隔，如 `FR-01-01-001、FR-01-02-003`） |
| 认证 | 是 / 否                   |
| 权限 | {所需权限标识}                |
| 接口类型 | UI API / Public API / Private API |

**请求参数**

| 参数名 | 位置 | 类型 | 必填 | 动作 | 说明 |
|--------|------|------|------|------|------|
| | Path/Query/Body | | Y/N | ✨/🔧 | |

**请求示例**

```json
{
}
```

**响应参数**

| 参数名 | 类型 | 动作 | 说明 |
|--------|------|------|------|
| | | ✨/🔧 | |

**响应示例**

```json
{
  "error": null,
  "status": "SUCCESS",
  "data": { }
}
```

**错误码/异常场景**

| 错误码 | HTTP状态码 | 说明 | 动作 |
|--------|-----------|------|------|
| 400 | 400 | 请求参数不完整或格式错误 | ✨/🔧 |
| 401 | 401 | 未授权，Token无效或已过期 | 🔧 |
| 403 | 403 | 无权限，用户缺少相应权限 | 🔧 |
| 404 | 404 | 资源不存在 | 🔧 |
| 409 | 409 | 资源冲突（如重复创建） | ✨ |
| 500 | 500 | 服务器内部错误 | 🔧 |

**权限校验设计**

**框架权限校验（第1层）**：
- 注解：`@JalorOperation(operationCode = RequestConstants.{READ/CREATE/UPDATE/DELETE/APPROVE/IMPORT/EXPORT})`
- 校验内容：{描述校验的具体操作权限}

**业务权限校验（第2层）**：

根据 PRD 角色权限矩阵设计：

| 角色 | 数据范围 | 校验逻辑 |
|------|---------|---------|
| 系统管理员 | 全局数据 | 无额外校验 |
| 部门管理员 | 本部门数据 | {描述校验逻辑} |
| 普通用户 | 个人数据 | {描述校验逻辑} |

**实现逻辑**

**最少步骤数要求**：至少5个步骤

**标准步骤模板**：

1. **参数校验**：校验请求参数完整性（必填字段、字段格式、字段长度）
2. **框架权限校验**：校验用户操作权限（使用 @JalorOperation 校验）
3. **业务权限校验**：校验用户数据权限（根据角色过滤数据范围）
   - 系统管理员：{可操作的数据范围}
   - 部门管理员：{可操作的数据范围}（WHERE {过滤条件}）
   - 普通用户：{可操作的数据范围}（WHERE {过滤条件}）
4. **业务校验**：校验业务规则（{列出业务规则}）
5. **数据处理**：{数据处理操作}，记录操作日志
6. **返回结果**：返回处理结果

**复杂场景示例**（供参考）：

1. 校验请求参数完整性（{列出关键参数}）
2. 框架权限校验（使用 @JalorOperation 校验{操作}权限）
3. 业务权限校验（根据用户角色确定可操作范围）
   - 系统管理员：{范围说明}
   - 部门管理员：{范围说明}（WHERE {SQL条件}）
   - 普通用户：{范围说明}（WHERE {SQL条件}）
4. {其他业务校验步骤}
5. {数据处理步骤}
...
N. 返回结果

**实现依赖**

- 依赖接口：`GET /uiapi/{资源}/{id}` - {接口用途}
- 依赖接口：`GET /uiapi/{资源}/{id}` - {接口用途} 【可并行】
- 依赖服务：{ServiceName} - {服务用途}
- 依赖服务：{ServiceName} - {服务用途}（异步）


---

## 参考 OpenAPI 片段（`规范/references/api-design-template.yaml`）

> 以下为工作区 `规范/references/` 中的 **YAML 模板样例**（路径、标签、definitions 结构），可按服务名与模型替换后作为接口契约附件。

```yaml
  openapi: 3.0.0
  info:
    description: {项目名称}API文档
    version: '1.0'
    title: {项目名称} API Documentation
  servers:
    - url: http://127.0.0.1:8080/
      description: 本地开发环境

  tags:
    - name: {模块名称}
      description: {模块描述}

  paths:
    /uiapi/{资源复数}/{操作}:
      post:
        tags:
          - {模块名称}
        summary: {接口摘要}
        description: {接口详细描述}
        operationId: {操作ID}
        requestBody:
          description: {请求体描述}
          required: true
          content:
            application/json;charset=UTF-8:
              schema:
                $ref: '#/components/schemas/{RequestDTO}'
        responses:
          '200':
            description: 成功返回
            content:
              application/json;charset=UTF-8:
                schema:
                  $ref: '#/components/schemas/ApiResponse{ResponseDTO}'

  components:
    schemas:
      ApiResponse:
        type: object
        properties:
          status:
            type: string
            enum: [SUCCESS, ERROR]
          data:
            type: object
          errors:
            type: array
            items:
              $ref: '#/components/schemas/Error'

      Error:
        type: object
        properties:
          errorCode:
            type: string
          errorMsg:
            type: string
          sourceId:
            type: string
```