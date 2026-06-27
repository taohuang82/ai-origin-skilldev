---
standard_id: "integration-notification"
domain: "integration"
---

# integration-notification

**规范分段**：`integration-notification`

### 规范条文

# 消息通知设计规范（TDD 第5章 §5.3）

## 适用场景

本要素覆盖所有**系统向用户发出通知**的设计，包括：
- 应用号通知（IEspaceRpcService）
- W3待办（ITodosService）

## 通知渠道选型

| 渠道 | 适用场景 | 实时性 | 成本 | 使用原则 |
|------|---------|--------|------|----------|
| 应用号通知 | 通用消息通知，适用于大多数业务通知场景 | 极高 | 低 | **默认选择**，除非有特殊要求才考虑其他渠道 |
| W3待办 | 需要用户进行下一步操作的场景（审批、确认、处理等） | 高 | 低 | 仅在有明确**待办操作**需求时使用 |

### 渠道使用决策逻辑

```markdown
通知需求分析流程：
1. 是否需要用户执行下一步操作？
   ✓ → 使用 W3待办（可叠加应用号通知）
   ✗ → 使用应用号通知（默认选择）
```

### 渠道组合使用

业务场景可能需要多渠道组合通知：
- **重要待办**：应用号通知 + W3待办（双重提醒）

**组合原则**：
- 至少包含应用号通知作为基础渠道
- 需要用户操作时叠加W3待办，避免过度通知

## SDK依赖配置

### Maven依赖

```xml
<!-- 应用号消息SDK -->
<dependency>
    <groupId>com.huawei</groupId>
    <artifactId>iaudit-comp-comp-notify-client</artifactId>
    <version>${version}</version>
</dependency>

<!-- W3待办SDK -->
<dependency>
    <groupId>com.huawei.iaudit.iaone.common</groupId>
    <artifactId>iaudit-comp-notify-client</artifactId>
</dependency>
```

### SDK接口位置

**应用号消息SDK**：
- SDK接口：`com.huawei.iaudit.component.notify.Service.IEspaceRpcService`
- 功能实现：`com.huawei.mbs.iaudit.iaudit.iaone.tenantcommon.facade.IEspaceRpcService`
- 核心方法：`sendEspaceApp()`（发送）、`revocationEspaceApp()`（撤回）

**W3待办SDK**：
- SDK接口：`com.huawei.iaudit.component.notify.Service.ITodosService`
- 核心方法：`create()`、`list()`、`delete()`、`cancel()`、`update()`、`findByApplicationCode()`、`count()`

## 应用号消息SDK详解

### 数据模型

**EspaceAppCommand - 发送消息参数**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| toUserAccount | String | 是 | 消息接收人工号，多人时逗号分割 |
| title | String | 是 | 消息标题 |
| content | String | 是 | 消息内容 |
| jumpUrl | String | 否 | 消息详情跳转链接 |
| fromUserAccount | String | 否 | 当前操作人工号 |
| titleIconUrl | String | 否 | 标题图片路径 |
| themeId | String | 否 | 应用ID |
| appId | String | 否 | 应用ID |
| type | String | 否 | 事件类型：1通知类，2订阅类（固定填1） |
| tenantId | String | 否 | 领域注册时的领域id |
| image_url | String | 否 | 内容图片Url（仅文件号使用） |
| businessFromUrl | String | 否 | 业务来源Url（应用号不需要） |
| businessFromName | String | 否 | 来源（应用号不需要） |

**RevocationCommand - 撤回消息参数**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| appId | String | 是 | 应用ID |
| themeId | String | 是 | 主题ID |
| tenantId | String | 是 | 租户ID |
| userEvents | List<UserEvent> | 是 | 用户事件列表 |

**UserEvent内部类**：

| 字段 | 类型 | 说明 |
|------|------|------|
| feedId | String | 消息ID |
| userAccounts | List<String> | 用户账号列表 |

**ResEspaceMsgVO - 返回结果**：

| 字段 | 类型 | 说明 |
|------|------|------|
| code | String | 错误码 |
| message | String | 消息 |
| data | String | 数据（上游格式问题，无法转换feedId） |
| total | int | 总数 |
| feedId | String | 消息ID（用于后续撤回操作） |

### 使用示例

```java
@Autowired
private IEspaceRpcService espaceRpcService;

// 发送应用号消息
public String sendAppNotification() {
    EspaceAppCommand command = new EspaceAppCommand();
    command.setToUserAccount("user001,user002");  // 接收人工号，多人逗号分隔
    command.setTitle("消息标题");
    command.setContent("消息内容");
    command.setJumpUrl("https://example.com/detail");  // 可选：跳转链接
    command.setFromUserAccount("sender001");  // 可选：发送人工号
    command.setThemeId("theme123");  // 可选：应用ID
    command.setAppId("app456");  // 可选：应用ID
    command.setType("1");  // 事件类型：1通知类
    command.setTenantId("tenant789");  // 可选：租户ID
    
    ResEspaceMsgVO result = espaceRpcService.sendEspaceApp(command);
    
    // 保存feedId用于后续撤回操作
    String feedId = result.getFeedId();
    return feedId;
}

// 撤回应用号消息
public void revokeAppNotification() {
    RevocationCommand command = new RevocationCommand();
    command.setAppId("app456");
    command.setThemeId("theme123");
    command.setTenantId("tenant789");
    
    List<RevocationCommand.UserEvent> userEvents = new ArrayList<>();
    RevocationCommand.UserEvent userEvent = new RevocationCommand.UserEvent();
    userEvent.setFeedId("feed123");  // 要撤回的消息ID
    userEvent.setUserAccounts(Arrays.asList("user001", "user002"));
    userEvents.add(userEvent);
    command.setUserEvents(userEvents);
    
    ApiResponse<String> result = espaceRpcService.revocationEspaceApp(command);
}
```

## W3待办SDK详解

### 数据模型

**ParamAuditTodosCrtDTO - 创建待办参数**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| appId | String | 是 | 应用ID |
| serviceId | String | 是 | 业务ID |
| applicationCode | String | 是 | 申请单号（必须唯一） |
| name | String | 是 | 待办名称 |
| todoUrl | String | 是 | 待办处理URL |
| detailUrl | String | 是 | 详情URL |
| applicationBy | Long | 是 | 申请人ID |
| currentHandler | Long | 否 | 当前处理人（单人） |
| currentHandlers | List<Long> | 否 | 当前处理人列表（多人审批） |
| applicationStatus | String | 是 | 申请状态 |
| type | String | 是 | 待办类型 |
| activeFlag | String | 否 | 激活标识：Y/N |

**IauditTodosDTO - 待办数据对象**：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | 待办ID |
| appId | String | 应用ID |
| serviceId | String | 业务ID |
| applicationCode | String | 申请单号 |
| name | String | 待办名称 |
| todoUrl | String | 待办处理URL |
| detailUrl | String | 详情URL |
| applicationBy | Long | 申请人ID |
| currentHandler | String | 当前处理人 |
| applicationStatus | String | 申请状态 |
| type | String | 待办类型 |
| activeFlag | String | 激活标识 |

### 核心方法

| 方法 | 入参 | 返回值 | 说明 |
|------|------|--------|------|
| create | ParamAuditTodosCrtDTO | ApiResponse<String> | 创建待办，返回待办ID |
| list | ParamAuditTodosListDTO, PageVO | ApiResponse<PagedResult<ResTodosListDTO>> | 查询待办列表 |
| delete | ParamAuditTodosDelDTO | ApiResponse<Integer> | 删除待办，返回删除数量 |
| cancel | ParamAuditTodosDelDTO | ApiResponse<Integer> | 取消待办 |
| update | IauditTodosDTO | ApiResponse<String> | 更新待办信息 |
| findByApplicationCode | String applicationCode, String appId | ApiResponse<List<IauditTodosDTO>> | 根据申请编码查询待办 |
| count | String id | ApiResponse<Long> | 查询待办数量 |

### 待办状态管理

常见待办状态：
- `PENDING`：待处理
- `PROCESSING`：处理中
- `SUCCESS`：成功
- `REJECTED`：驳回
- `RECALLED`：撤回
- `COMPLETED`：已完成

### TodoService领域服务设计

在Domain层的 `domain/share/todo/` 目录下设计待办领域服务：

**目录结构**：
```
domain/share/todo/
├── enums/
│   └── TodoBizResponse.java          # 待办异常枚举
├── service/
│   └── TodoService.java              # 待办领域服务
```

**TodoBizResponse枚举**：

```java
@Getter
@AllArgsConstructor
public enum TodoBizResponse implements BusinessExceptionAssert {
    TODO_API_CALL_EXCEPTION(500, "todo.service.0000001", "待办接口调用异常"),
    TODO_PARAMETERS_CANNOT_BE_EMPTY(400, "todo.service.0000002", "待办参数不能为空");
    
    private final Integer httpCode;
    private final String code;
    private final String message;
}
```

**TodoService领域服务**：

```java
@Slf4j
@Service
public class TodoService {
    @Autowired
    private ITodosService iTodosService;
    
    private static final Logger log = LoggerFactory.getLogger(TodoService.class);
    
    /**
     * 创建待办
     */
    public void createTodo(ParamAuditTodosCrtDTO todo) {
        TodoBizResponse.TODO_PARAMETERS_CANNOT_BE_EMPTY.assertIsFalse(todo == null);
        try {
            iTodosService.create(todo);
        } catch (ApplicationException e) {
            log.error("创建待办时发生异常", e);
            TodoBizResponse.TODO_API_CALL_EXCEPTION.assertIsTrue(false, e);
        }
    }
    
    /**
     * 删除待办
     */
    public void deleteTodo(String appId, String serviceId, String type) {
        ParamAuditTodosDelDTO deleteParam = new ParamAuditTodosDelDTO();
        deleteParam.setAppId(appId);
        deleteParam.setServiceId(serviceId);
        deleteParam.setType(type);
        try {
            iTodosService.delete(deleteParam);
        } catch (Exception e) {
            log.error("待办删除失败", e);
            TodoBizResponse.TODO_API_CALL_EXCEPTION.assertIsTrue(false, e);
        }
    }
    
    /**
     * 根据申请编码查询待办
     */
    public List<IauditTodosDTO> findTodosByApplicationCode(String applicationCode, String appId) {
        List<IauditTodosDTO> data = new ArrayList<>();
        try {
            data = iTodosService.findByApplicationCode(applicationCode, appId).getData();
        } catch (Exception e) {
            log.error("查询待办时发生异常", e);
            TodoBizResponse.TODO_API_CALL_EXCEPTION.assertIsTrue(false, e);
        }
        return data;
    }
    
    /**
     * 管理待办状态
     */
    public void manageTodoStatus(String applicationCode, String appId, String action) {
        List<IauditTodosDTO> todos = findTodosByApplicationCode(applicationCode, appId);
        
        for (IauditTodosDTO todo : todos) {
            switch (action) {
                case "AGREE":
                case "REJECT":
                case "WITHDRAW":
                    deleteTodo(todo.getId());
                    break;
            }
        }
    }
}
```

### 配置文件

**remoteServer.properties**：

```properties
tenantBasicService=http://S00000000000000000000000000000513:iaudit-tenant-cs
tenantServiceContextRoot=/iaudit/common-tenant
server.com.huawei.mbs.iaudit.iaudit.iape.apr.infrastructure.common.rpc.TodosRPC=${tenantBasicService}/${tenantServiceContextRoot}/services
```

## 通知模板规范

- 模板变量用 `{variableName}` 占位
- 模板必须支持多语言（`i18n` key 管理）
- 模板变更需要走审核流程（避免随意修改通知文案）
- 区分通知标题和正文

## 频控策略（防打扰）

- 同一用户同一通知类型在时间窗口内不重复发送（如 10 分钟内不重复推送）
- 频控配置通过动态配置管理（见 config/app-config.md）
- 用户可设置免打扰时段（通知服务统一处理）
- 聚合通知：短时间内多条同类通知合并为一条（如"5 个订单待审批"）

## 解耦设计

- 通知发送应与主业务解耦，通过 MQ 消费状态事件后触发（见 `integration.md` 内 MQ 分节）
- 通知发送失败不影响主业务流程，只记录失败日志并重试
- 通知微服务统一承担所有渠道的发送逻辑，业务服务不直接调用第三方 SDK

## 通知幂等

- 每条通知有唯一 `notificationId`（`{业务ID}_{事件类型}_{时间窗口}`）
- 消费 MQ 时以 `notificationId` 去重，防止重复通知

## 重要注意事项

### 应用号消息注意事项
1. `toUserAccount`、`title`、`content` 为必填字段
2. 多个接收人使用逗号分隔
3. `type` 字段固定填 "1"（通知类）
4. 发送成功后，保存返回的 `feedId` 用于后续撤回操作

### W3待办注意事项
1. `applicationCode` 必须唯一，用于待办查询和删除
2. `currentHandler` 为 `Long` 类型，不是 `String`
3. 多人审批使用 `currentHandlers`（List<Long>）
4. 使用 `setActiveFlag("Y")` 设置激活状态
5. 待办删除通过 `ids` 列表批量操作

### 异常处理
1. 使用 try-catch 捕获 `ApplicationException`
2. 应用号消息异常：记录日志，不影响主业务
3. W3待办异常：调用 `TodoBizResponse.TODO_API_CALL_EXCEPTION.assertIsTrue(false, e)`
4. 使用类级别 Logger：`LoggerFactory.getLogger(YourService.class)`

## 输出骨架

# 消息通知设计（TDD 第5章 §5.3）

<!--
变更标注约定：
- ✨ 新增：本次新增的通知场景
- 🔧 修改：渠道/模板/频控策略变更
-->

## 变更概要

| 通知场景 | 渠道 | 动作 | 说明 |
|---------|------|------|------|
| | | ✨/🔧 | |

---

## 通知场景清单

| 通知场景 | 触发事件 | 渠道 | 接收方 | 动作 |
|---------|---------|------|--------|------|
| | | 应用号/W3待办 | | ✨/🔧 |

---

## ✨/🔧 {通知场景名称}

> 🔧 **变更说明**：{仅修改时填写}

### 基本信息

| 属性 | 值 |
|------|---|
| 触发时机 | {业务事件，如订单状态变更为 APPROVED} |
| 触发来源 | MQ 消费 `{topic}/{tag}` / 直接调用通知服务 |
| 通知渠道 | 应用号通知 / W3待办 |
| 接收方 | {申请人 / 审批人 / 管理员等} |
| 通知幂等键 | `{businessId}_{eventType}_{timeWindow}` |

### 通知模板

**标题**：`{通知场景中文名}通知`

**正文模板**：

```
{通知正文，如：您提交的订单 {orderNo} 已通过审批，审批人：{approverName}，时间：{time}}
```

**模板变量**：

| 变量名 | 来源 | 说明 |
|--------|------|------|
| `{orderNo}` | 消息体 | 订单编号 |
| `{approverName}` | 查询用户服务 | 审批人姓名 |
| `{time}` | 消息体 `occurredAt` | 审批时间 |

### 频控策略

| 维度 | 时间窗口 | 最大发送次数 | 超限处理 |
|------|---------|-----------|---------|
| 同用户同类型通知 | 10 分钟 | 1 次 | 丢弃（记录日志） |
| 用户免打扰时段 | 22:00~08:00 | 0 次 | 延迟到 08:00 发送 |

**聚合通知**：

| 场景 | 聚合规则 | 合并后文案示例 |
|------|---------|---------------|
| 短时间多个同类待办 | 5分钟内同类型通知合并 | "您有 {count} 个订单待审批" |
| 批量状态变更通知 | 按批次合并 | "批次 {batchNo} 的 {count} 条数据已处理完成" |

### 失败处理

| 场景 | 处理方式 |
|------|---------|
| 发送失败（网络/SDK 异常） | 重试 3 次（指数退避），超限记录失败日志，不影响主业务 |
| W3待办创建失败 | 仅记录日志，应用号通知仍需发送 |

### 待办状态管理（仅W3待办场景）

| 操作 | 待办处理 | 业务状态更新 |
|------|---------|------------|
| 同意（AGREE） | 删除待办 → `todoService.manageTodoStatus()` | 更新为 SUCCESS |
| 驳回（REJECT） | 删除待办 → `todoService.manageTodoStatus()` | 更新为 REJECTED |
| 撤回（WITHDRAW） | 删除待办 → `todoService.manageTodoStatus()` | 更新为 RECALLED |

### 国际化配置

**配置文件**：`i18n/notification_{language}.properties`

```properties
# notification_zh_CN.properties
order.approved.title=订单审批通过通知
order.approved.body=您提交的订单 {orderNo} 已通过审批，审批人：{approverName}

# notification_en_US.properties
order.approved.title=Order Approval Notification
order.approved.body=Your order {orderNo} has been approved by {approverName}
```