---
standard_id: "data-table"
domain: "data"
---

# data-table

**规范分段**：`data-table`

### 规范条文

# 数据表设计规范

## 数据库技术选型

- 数据库：PostgreSQL
- 输出完整可执行 SQL

---

## 企业级命名规范（强制执行）⭐

### 表名命名规范
- **前缀**：`{项目代码}_`（如：`ars_`）
- **后缀**：`_t`
- **格式**：`{项目代码}_{业务实体}_t`
- **示例**：
  - ✅ `ars_tag_definition_t`
  - ✅ `ars_person_basic_info_t`
  - ❌ `tag_definition`（缺少前缀和后缀）
  - ❌ `ars_tag_definition`（缺少后缀）

### 字段命名规范
- **布尔字段**：使用 `xxx_flag` 格式
  - ✅ `deleted_flag`, `auto_sync_flag`, `has_level_flag`
  - ❌ `is_deleted`, `is_auto_sync`, `has_level`（禁止 `is_xxx` 格式）
- **布尔值**：`Y`（是）/ `N`（否）
- **时间字段**：`xxx_time` 或 `xxx_date`
- **状态字段**：`xxx_status` 或 `status`
- **编码字段**：`xxx_code`

### 主键ID规范（强制执行）⭐
- **字段名**：`id`（所有表统一使用 `id`，不使用 `xxx_id`）
- **字段类型**：`VARCHAR(64)`（禁止使用 INT/BIGINT 作为主键）
- **约束名**：`pk_<table_name>_id`
- **生成方式**：应用层ID生成器二方件生成唯一ID
- **示例**：
  ```sql
  id VARCHAR(64) NOT NULL,
  CONSTRAINT pk_ars_tag_definition_t_id PRIMARY KEY (id)
  ```

### 索引命名规范
- **索引名**：`idx_<table_name>_<column_name>`
- **组合索引**：`idx_<table_name>_<col1>_<col2>`

---

## 标准审计字段（必备公共字段）

所有表必须包含以下6个审计字段：

```sql
created_by       INT8          NOT NULL,
creation_date    TIMESTAMP(6)  NOT NULL,
deleted_flag     CHAR(1)       NOT NULL DEFAULT 'N',
last_updated_by  INT8          NOT NULL,
last_update_date TIMESTAMP(6)  NOT NULL,
renter_id        VARCHAR(64)   NULL DEFAULT NULL
```

**审计字段说明**：
| 字段名 | 类型 | 说明 |
|--------|------|------|
| `created_by` | INT8 | 创建人ID |
| `creation_date` | TIMESTAMP(6) | 创建时间 |
| `deleted_flag` | CHAR(1) | 删除标识（'N'-未删除 / 'Y'-已删除） |
| `last_updated_by` | INT8 | 最后更新人ID |
| `last_update_date` | TIMESTAMP(6) | 最后更新时间 |
| `renter_id` | VARCHAR(64) | 租户ID（多租户场景） |

---

## 数据库设计核心原则（强制执行）⭐

### 原则1：不使用外键约束
- ❌ 禁止使用 `FOREIGN KEY` 约束
- ✅ 使用逻辑关联，在注释中说明关联关系
- ✅ 在应用层保证数据一致性

### 原则2：必填项最小原则

**默认必填字段**：
- 主键 `id`
- 逻辑外键 ID（如 `user_id`, `tag_id`, `order_id`)
- 审计字段：`created_by`, `creation_date`, `deleted_flag`, `last_updated_by`, `last_update_date`

**默认选填字段**：
- 所有业务字段默认 `NULL`（选填）
- 仅当 PRD 明确标注"必填"时才设为 `NOT NULL`

**理由**：根据业务逻辑灵活控制字段是否赋值，避免数据库层面过度约束。

### 原则3：枚举类型优先使用数字编码
- ✅ 优先使用 `INT4` + `DEFAULT` 值
- ✅ 示例：`tag_type INT4 DEFAULT 1 -- 标签使用场景(1=资源调度, 2=其他场景)`
- ❌ 仅当枚举值频繁变化或字符编码更易理解时才使用 `VARCHAR`

---

## 字段类型选择

| 场景 | 推荐类型 |
|------|---------|
| 主键 | VARCHAR(64) |
| 逻辑外键 | VARCHAR(64) 或根据来源系统确定 |
| 状态枚举 | INT4，注释说明每个值含义 |
| 金额 | DECIMAL(18,2) |
| 短文本（<=255） | VARCHAR |
| 长文本 | TEXT，避免在 WHERE 中使用 |
| 时间 | TIMESTAMP(6) |
| 布尔 | CHAR(1)，'Y'/'N' |
| JSON 结构 | JSON 类型 |
| 人员ID | INT8（HR系统标准） |

---

## 索引设计原则

- **主键索引**：自动创建，无需手动添加
- **关联ID字段**：必须创建索引（如 `ref_id`、`order_id`）
- **查询频繁字段**：选择性添加索引（如查询条件、排序字段）
- **组合索引**：多个字段联合查询时考虑组合索引
- 避免在低基数字段（如 `deleted_flag`、`status`）上单独建索引
- 联合索引遵循最左前缀原则，将区分度高的字段放前面
- 单表索引数量不超过 5 个

---

## 范式与反范式

- 核心业务表满足 3NF
- 允许对高频查询场景做适度冗余（需在字段说明中注明冗余来源）
- 大字段（TEXT/BLOB/JSON）拆分到子表，避免影响主表查询性能

---

## 逻辑删除

- 统一使用 `deleted_flag` 字段，禁止物理删除业务数据
- 逻辑删除值：'Y'（已删除）/ 'N'（未删除）
- 逻辑删除时同步更新 `last_update_date`
- 查询时统一附加 `WHERE deleted_flag = 'N'`

---

## 注释规范

- 每个表必须有 `COMMENT ON TABLE`
- 每个字段必须有 `COMMENT ON COLUMN`
- 注释内容清晰准确，说明字段用途
- 枚举值在注释中说明（格式：值1-说明 / 值2-说明）
- 逻辑关联关系在注释中说明（如：逻辑关联 yyy_table.id）

---

## 常见设计模式

### 主表设计
主表存储核心业务数据，包含完整审计字段。

### 关联表设计
关联表存储实体间的关联关系，包含：
- 双方实体ID（逻辑关联）
- 关联类型（如适用）
- 完整审计字段

### 配置表设计
配置表存储系统配置数据，包含：
- 配置项编码（唯一标识）
- 配置项名称
- 配置项值
- 配置项类型
- 完整审计字段

---

## ER 图规范

- 使用 Mermaid `erDiagram` 语法
- 标注关系类型：`||--o{`（一对多）、`}|--|{`（多对多）
- 仅画核心实体，辅助表（日志、配置）不纳入 ER 图

---

## 项目规范摘录（`规范/` 目录 · IT 设计文档 §4.3）

> 来源：`{WORKSPACE_ROOT}/规范/examples/it_design_doc.md` 中「数据库及文件持久化设计」相关约束。与上文冲突时以 `docs/extend-rule/` 覆盖规范为准。

- **表结构设计**：说明核心表是新建还是沿用既有模式；说明与现有核心表的关系（文字或关系图）。
- **字段说明**：标出与项目通用字段（如 `creation_date`、`last_update_date` 等）对齐的字段；枚举与约束须写明出处或规范。
- **存量表结构修改**（若涉及）：必须列出「修改表 / 修改字段 / 修改原因 / 影响评估（含迁移与兼容）」。
- **文件存储**（若涉及）：目录与命名须说明是否遵循项目既有存储与权限模式。

## 输出骨架
# 数据表设计

<!--
变更标注约定（增量模式使用，全量模式所有内容均为新增可省略标注）：
- ✨ 新增：本次新增的表或字段
- 🔧 修改：在现有基础上有变更（字段类型/约束/索引等）
-->

## 变更概要

| 动作 | 对象 | 说明 |
|------|------|------|
| ✨ 新增 | | |
| 🔧 修改 | | |

---

## 表清单

> **与 PRD 实体对齐**：每张表须在「对应 PRD 实体」列标注其设计依据来自 PRD **「四、信息架构 → 4.1 业务对象/逻辑实体」** 表格中的**实体编号**（如 `E001`）。该表字段含「实体编号、实体名称、实体说明、对应业务对象、主键」等；设计时以实体编号为稳定锚点。  
> - 一表主要承载**一个**逻辑实体：填单个编号，如 `E003`。  
> - 关联表 / 拆分表同时落多个实体属性：填多个编号，中文顿号分隔，如 `E001、E005`。  
> - PRD 未列实体、纯技术表（如流水、配置扩展）：填 `—`，并在「说明」中简要注明依据（章节或需求点）。

| 序号 | 表名 | 中文名 | 对应 PRD 实体 | 所属模块 | 动作 | 说明 |
|------|------|--------|---------------|---------|------|------|
| 1 | | | E001 | | ✨/🔧 | |

---

## 实体关系图

```mermaid
erDiagram
```

---

## 表详细设计

### ✨/🔧 {表名}

> 🔧 **变更说明**：{仅修改时填写，说明变更点及原因，新增时删除此行}

**说明**：{表的业务用途}

#### 字段设计

| 字段名 | 类型 | 长度 | 非空 | 默认值 | 索引 | 动作 | 说明 |
|--------|------|------|------|--------|------|------|------|
| id | VARCHAR | 64 | Y | | PK | 🔧 | 主键ID（应用层生成UUID或雪花ID）|
| {业务字段} | {类型} | {长度} | Y/N | {默认值} | | ✨/🔧 | {字段说明} |
| created_by | INT8 | | Y | | | 🔧 | 创建人ID（审计字段）|
| creation_date | TIMESTAMP(6) | | Y | | | 🔧 | 创建时间（审计字段）|
| deleted_flag | CHAR | 1 | Y | 'N' | | 🔧 | 删除标识：N-未删除 / Y-已删除（审计字段）|
| last_updated_by | INT8 | | Y | | | 🔧 | 最后更新人ID（审计字段）|
| last_update_date | TIMESTAMP(6) | | Y | | | 🔧 | 最后更新时间（审计字段）|
| renter_id | VARCHAR | 64 | N | NULL | | 🔧 | 租户ID（审计字段）|

**字段设计原则说明**：
- 主键 `id` 和 审计 字段为必填字段
- 业务字段默认选填（`NULL`），仅当 PRD 明确标注"必填"时设为 `NOT NULL`
- 逻辑外键字段（如 `user_id`, `order_id`）为必填，使用 `VARCHAR(64)` 类型
- 状态枚举字段使用 `INT4` 类型，注释说明枚举值含义

#### 索引设计

| 索引名 | 类型 | 字段 | 动作 | 说明 |
|--------|------|------|------|------|
| PRIMARY | 主键 | id | 🔧 | 主键索引（自动创建）|
| uk_{表名}_{字段} | 唯一 | | ✨ | {唯一约束说明} |
| idx_{表名}_{字段} | 普通 | | ✨ | {索引用途说明} |

**索引设计原则说明**：
- 关联ID字段（如 `ref_id`, `order_id`）必须创建索引
- 查询频繁字段选择性添加索引
- 组合索引遵循最左前缀原则
- 单表索引数量不超过 5 个

#### 约束与说明

**字段约束**：
- {列出字段级约束，如唯一约束、长度约束、格式约束}

**枚举值定义**：
- `{字段名}`：{枚举值说明（格式：值1-说明 / 值2-说明）}

**业务规则**：
- {列出表级业务规则，如数据唯一性、状态流转、数据权限等}

**逻辑关联关系**：
- `{字段名}` 逻辑关联 `{关联表}.{关联字段}`（应用层维护一致性）

---

## 参考 DDL 样例（`规范/references/database-schema-template.sql`）

> 以下为工作区 `规范/references/` 中的 **模板样例**，仅作字段注释、主键/唯一键与审计类字段书写风格参考；实际表结构以本需求与默认数据表规范为准。

```sql
CREATE TABLE IF NOT EXISTS xxx_table (
    id               VARCHAR(64)   NOT NULL,
    ref_id           VARCHAR(64)   NOT NULL,   -- 逻辑关联 yyy_table.id，应用层维护
    field_name       VARCHAR(255)  NULL,       -- 业务字段默认选填
    status           INT4          DEFAULT 1,  -- 状态：1-草稿 / 2-启用 / 3-停用（数字编码）
    amount           DECIMAL(18,2) NULL,       -- 金额字段
    -- 审计字段
    created_by       INT8          NOT NULL,
    creation_date    TIMESTAMP(6)  NOT NULL,
    deleted_flag     CHAR(1)       NOT NULL DEFAULT 'N',
    last_updated_by  INT8          NOT NULL,
    last_update_date TIMESTAMP(6)  NOT NULL,
    renter_id        VARCHAR(64)   NULL DEFAULT NULL,
    CONSTRAINT pk_xxx_table_id PRIMARY KEY (id)
);

COMMENT ON TABLE  xxx_table                  IS 'XXXX表';
COMMENT ON COLUMN xxx_table.id               IS '主键ID';
COMMENT ON COLUMN xxx_table.ref_id           IS '关联ID，逻辑关联 yyy_table.id';
COMMENT ON COLUMN xxx_table.field_name       IS '字段说明';
COMMENT ON COLUMN xxx_table.status           IS '状态：1-草稿 / 2-启用 / 3-停用';
COMMENT ON COLUMN xxx_table.amount           IS '金额（单位：元）';
COMMENT ON COLUMN xxx_table.created_by       IS '创建人ID';
COMMENT ON COLUMN xxx_table.creation_date    IS '创建时间';
COMMENT ON COLUMN xxx_table.deleted_flag     IS '删除标识：N-未删除 / Y-已删除';
COMMENT ON COLUMN xxx_table.last_updated_by  IS '最后更新人ID';
COMMENT ON COLUMN xxx_table.last_update_date IS '最后更新时间';
COMMENT ON COLUMN xxx_table.renter_id        IS '租户ID';

CREATE INDEX idx_xxx_table_ref_id    ON xxx_table(ref_id);
CREATE INDEX idx_xxx_table_status    ON xxx_table(status);
```