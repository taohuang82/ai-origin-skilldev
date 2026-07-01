---
standard_id: "arch-feature-toggle"
domain: "architecture"
---

# arch-feature-toggle

**规范分段**：`arch-feature-toggle`

### 规范条文

# 灰度与特性开关规范（TDD 第1章 §1.4）

## 1.4 灰度与特性开关规范

### 灰度发布策略

- **流量灰度**：按用户 ID 后两位取模，控制灰度比例（如 10%）
- **租户灰度**：按租户/企业 ID 指定特定客户灰度验证
- **地区灰度**：按请求来源地区灰度（适合有地区差异的功能）

### Feature Flag（特性开关）规范

- 新功能默认关闭（`feature.{name}.enabled=false`），通过配置中心热更新开启
- 开关命名：`feature.{module}.{feature-name}.enabled`
- 开关粒度：功能级（一个 US 对应一个开关），不拆到接口级
- 灰度阶段结束后，必须及时清理 Feature Flag 代码（避免技术债）

### 开关实现约束

- 开关判断在 Application 层（Service），不在 Controller 或 Infrastructure 层
- 开关只控制功能入口，不控制数据迁移（数据层改动必须向后兼容）
- Feature Flag 的存储与热更新依赖配置中心（Nacos/Apollo），具体配置见 `config/app-config.md`

### 灰度路由约定

- 网关层读取灰度规则，按 Header/Cookie 中的用户标识路由到灰度版本服务
- 灰度服务与正式服务共享数据库，确保数据兼容性

## 输出骨架
# 灰度与特性开关设计（TDD 第1章 §1.4）

---

## 1.4 灰度与特性开关

### 灰度策略

| 灰度维度 | 规则 | 灰度比例 |
|---------|------|---------|
| 用户 ID | `userId % 100 < {N}` | {N}% |
| 租户 ID | 指定租户列表 | 白名单 |

### Feature Flag 清单

| 开关 Key | 默认值 | 控制功能 | 清理计划 |
|---------|--------|---------|---------|
| `feature.{module}.{feature}.enabled` | `false` | {功能描述} | v{X.Y} 灰度结束后删除 |

### 灰度路由配置（Nacos）

```yaml
# Nacos 路由规则示例
grayRule:
  conditions:
    - userId % 100 < 10
  routes:
    - serviceId: {service-name}
      version: {new-version}
```