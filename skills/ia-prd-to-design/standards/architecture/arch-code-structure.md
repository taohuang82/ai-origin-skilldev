---
standard_id: "arch-code-structure"
domain: "architecture"
---

# arch-code-structure

**规范分段**：`arch-code-structure`

### 规范条文

# 代码架构规范（TDD 第1章 §1.5）

> **仅在 build 模式下输出。**

## 1.5 代码架构规范

### 分层结构（DDD 四层）

```
src/
├── interfaces/        # 接口层：Controller / DTO / Converter / 参数校验
├── application/       # 应用层：Service 接口 + ServiceImpl / CommandHandler / EventHandler
├── domain/            # 领域层：Entity / Repository 接口 / DomainEvent / 枚举
└── infrastructure/    # 基础设施层：RepositoryImpl / MQ Producer / FeignClient / 缓存操作
```

### 依赖方向约束

- Domain 层禁止依赖 Infrastructure
- Application 层禁止直接操作数据库（通过 Repository 接口）
- Interface 层禁止包含业务逻辑
- 使用防腐层（ACL）隔离外部模型，禁止将外部 DTO 直接渗透到内部领域层

### 包命名规范

- 根包：`com.{company}.{product}.{service}`
- 模块包：`com.{company}.{product}.{service}.{module}`（如 `order`、`user`）

### 模块划分规则

- 按业务模块划分子包，不按技术层次划分（如 `order/`, `user/`，不是 `controller/`, `service/`）
- 跨模块调用通过 Application 层接口，不直接依赖其他模块的 Infrastructure

---

## 项目规范摘录（`规范/` 目录 · IT 设计文档 §4.2.2）

> 来源：`{WORKSPACE_ROOT}/规范/examples/it_design_doc.md`「新引入三/二方库声明」。

- 代码架构确定后，新引入依赖须声明：**坐标与版本**、**引入目的**、**替代方案评估**。

## 输出骨架
# 代码架构设计（TDD 第1章 §1.5）

> **仅 build 模式输出。** 本文件确定后，后续版本迭代不重新生成，变更需走架构评审。

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

## 新引入三/二方库声明（模板 · `规范/examples/it_design_doc.md` §4.2.2）

> 迭代版本中若新增依赖，按行填写；无则写「无」。

| 库名称与版本 | 引入目的 | 替代方案评估 | 许可证 | 稳定性与成熟度 | 兼容性 | 性能与安全 |
|----------------|----------|--------------|--------|----------------|--------|--------------|
| | | | | | | |