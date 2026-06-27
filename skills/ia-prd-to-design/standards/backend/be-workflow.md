---
standard_id: "be-workflow"
domain: "backend"
---

# be-workflow

**规范分段**：`be-workflow`

### 规范条文

# 审批流配置规范（TDD 第3章 §3.7）

## 3.7 审批流规范

仅当 PRD 包含需要人工审批的业务场景时输出。

### SDK依赖

```xml
<dependency>
    <groupId>com.huawei</groupId>
    <artifactId>iaudit-comp-approval</artifactId>
</dependency>
```

**接口位置**：
- SDK接口：`com.huawei.iaudit.component.approval.service.StarlingApprovalProcessService`（流程操作）
- SDK接口：`com.huawei.iaudit.component.approval.service.StarlingApprovalQueryService`（流程查询）
- REST接口：`/approval/process/*`（流程操作）、`/approval/query/*`（流程查询）

### BPMN 流程引擎

- 推荐使用 Activiti 7 / Flowable 6.x
- 流程定义用 BPMN 2.0 XML 文件管理，随代码版本控制
- 流程变量（process variables）传递业务 ID，不传整个对象

### 流程启动规范

**必填字段**：
- `processKey`：流程定义键，对应流程定义的唯一标识
- `businessKey`：业务键，用于关联业务数据
- `startUser`：启动用户，流程发起人的用户标识

**待办配置必填字段**：
- `applicationCode`：申请单号，必须唯一，用于标识每次申请
- `todoUrl`：待办跳转链接，审批人点击待办时的跳转地址
- `detailUrl`：详情跳转链接，查看申请详情的跳转地址
- `applicationCn`：申请人，申请人的姓名或标识
- `applicationStatus`：申请单状态，如"待审批"、"审批中"等

**参数传递规范**：
- 流程变量命名采用驼峰命名法
- 只传递业务主键（ID），不传递完整对象（避免序列化问题）
- 审批结论（通过/驳回）和审批意见作为标准变量传递

### 审批节点设计约定

- 审批人获取策略：硬编码用户 ID / 按角色 / 动态获取（调用组织架构服务）
- 会签（AND）：所有审批人通过才继续；或签（OR）：任一审批人通过即继续
- 会签控制：通过 `countersignPass` 参数控制会签是否通过
- 驳回行为：驳回到发起人 / 驳回到指定节点（通过 `targetNodeId` 指定，不填则默认上一节点）
- 撤销：在特定状态下允许发起人撤销，通过流程监听器处理

### 审批操作规范

**必填字段**：
- `applicationCode`：申请单号
- `businessKey`：业务键
- `operatorById`：操作人ID，必须是当前操作人的真实用户ID

**参数一致性要求**：
- 同一流程的所有操作必须使用相同的 `applicationCode` 和 `businessKey`
- 流程参数 `parameters` 在不同操作间可以传递和更新

**支持的审批操作**：
1. **审批通过（approval）**：审批人同意申请
2. **转审（transfer）**：将审批任务转交给其他人处理
3. **驳回（rejected）**：驳回到指定节点或上一节点
4. **撤回（revoke）**：发起人撤回已提交的申请
5. **终止（cancel）**：终止流程实例
6. **管理员转审（adminTransfer）**：管理员强制转审

### 查询功能规范

**查询方式**：
- 可通过 `applicationCode`、`businessKey` 或 `processInstanceId` 查询
- 至少需要提供 `applicationCode` 或 `businessKey` 其中之一

**支持查询内容**：
- 流程日志（findProcessLogs）：查询审批历史记录
- 流程图（findProcessGraph）：查询流程图及当前节点状态
- 任务详情（queryTaskDetail）：查询当前任务详细信息
- 流程实例详情：查询流程实例状态

### 超时处理

- 每个审批节点设置超时时间，超时后自动驳回或升级处理
- 超时提醒通过 MQ + 通知服务发送（见 integration/notification.md）

### 流程变量规范

- 流程变量命名采用驼峰命名法
- 只传递业务主键（ID），不传递完整对象（避免序列化问题）
- 审批结论（通过/驳回）和审批意见作为标准变量传递

### 错误处理规范

- 通过 `ApiResponse` 的 `code` 和 `message` 字段判断操作结果
- `code` 为 "200" 表示操作成功，其他值表示失败
- 操作失败时，`message` 字段包含详细的错误信息
- 建议在业务层对错误进行统一处理和日志记录

### 性能优化建议

- 批量操作时，尽量使用批量接口减少网络请求
- 查询操作时，尽量使用精确的查询条件
- 避免频繁查询流程状态，可以使用缓存机制
- 对于大量数据查询，考虑分页处理

## 输出骨架

# 审批流设计（TDD 第3章 §3.7）

> ⏭️ **跳过说明**：{若无审批流需求，填写原因，删除以下内容}

---

## 3.7 审批流设计

### 审批流清单

| 流程名称 | 流程 Key | 涉及实体 | 引擎 |
|---------|---------|---------|------|
| | | | Activiti / Flowable |

### ✨/🔧 {流程名称}

**流程启动配置**：

| 配置项 | 值 | 说明 |
|--------|------|------|
| 流程定义键（processKey） | {填写流程定义键} | 流程的唯一标识 |
| 业务键（businessKey） | {填写业务键规则} | 如：`LEAVE_{日期}_{序号}` |
| 启动用户（startUser） | {填写启动用户} | 流程发起人 |
| 申请单号（applicationCode） | {填写申请单号规则} | 必须唯一 |
| 待办跳转链接（todoUrl） | {填写待办跳转URL} | 审批人点击待办的跳转地址 |
| 详情跳转链接（detailUrl） | {填写详情跳转URL} | 查看申请详情的跳转地址 |

**流程启动参数**：

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `applicationCode` | String | 是 | 申请单号，唯一标识 |
| `applicationCn` | String | 是 | 申请人姓名 |
| `applicationStatus` | String | 是 | 申请单状态 |
| `comment` | String | 否 | 流程启动备注 |
| `parameters` | Map | 否 | 流程变量参数 |

**BPMN 流程节点**：

| 节点 | 节点类型 | 审批人策略 | 会签/或签 | 超时时间 |
|------|---------|---------|---------|---------|
| 直接上级审批 | UserTask | 调用 OrgService.getManager() | 无（单人）| 3 天 |

**审批操作设计**：

| 操作 | 触发条件 | 必填参数 | 说明 |
|------|---------|---------|------|
| 审批通过（approval） | 审批人同意申请 | `applicationCode`, `businessKey`, `operatorById`, `comment` | 更新申请状态为"已通过" |
| 转审（transfer） | 审批人转交他人处理 | `toTransfers`（目标人员列表）, `comment` | 转交给指定人员审批 |
| 驳回（rejected） | 审批人拒绝申请 | `comment`, `targetNodeId`（可选）| 可驳回到指定节点，不填则返回上一节点 |
| 撤回（revoke） | 发起人撤回申请 | `applicationCode`, `businessKey`, `operatorById` | 仅允许在特定状态撤回 |
| 终止（cancel） | 管理员或发起人终止流程 | `comment`（终止原因）| 流程实例终止 |

**驳回/撤销行为**：

| 操作 | 行为 | 说明 |
|------|------|------|
| 驳回 | 流程终止，状态 → REJECTED | 发送通知给申请人（见 integration/notification.md）|
| 撤销 | 流程终止，状态 → CANCELLED | 仅允许在 PENDING 状态 |

**查询功能需求**：

| 查询类型 | 用途 | 输入参数 |
|---------|------|---------|
| 流程日志查询 | 查看审批历史记录 | `applicationCode`, `businessKey`, `processInstanceId`（可选）|
| 流程图查询 | 查看流程图及当前节点 | `applicationCode`, `businessKey` |
| 任务详情查询 | 查询当前任务信息 | `applicationCode`, `businessKey` |

**流程变量**：

| 变量名 | 类型 | 说明 |
|--------|------|------|
| `businessId` | String | 业务主键 |
| `applicantId` | Long | 申请人 ID |
| `countersignPass` | Boolean | 会签是否通过（会签场景必填）|

**接口集成示例**：

```java
// 流程启动示例
StartRequestDTO startRequest = new StartRequestDTO();
startRequest.setStartProcessDTO(startProcessDTO);  // 流程配置
startRequest.setToDosDTO(toDosDTO);                 // 待办配置

ApiResponse<CreateInstanceResult> result =
    starlingApprovalProcessService.start(startRequest);

// 审批通过示例
ApprovalBaseRequestDTO approvalRequest = new ApprovalBaseRequestDTO();
approvalRequest.setApplicationCode("{申请单号}");
approvalRequest.setBusinessKey("{业务键}");
approvalRequest.setOperatorById({操作人ID});
approvalRequest.setComment("{审批意见}");

ApiResponse<List<TaskCompleteResult>> result =
    starlingApprovalProcessService.approval(approvalRequest);
```