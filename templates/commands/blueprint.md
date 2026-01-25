---
description: 基于技术方案 (Plan) 生成代码契约，包括类型定义、接口签名和测试骨架（不包含业务逻辑）。
handoffs:
  - label: 任务拆解
    agent: speckit.tasks
    prompt: 基于 blueprint.md 和生成的代码桩进行任务拆解
---

## 执行代理要求（强制）

本命令**必须由子代理 `blueprint_agent` 执行**，主线程不得直接生成蓝图或代码骨架。

执行规则：
1. 立即将本命令的全部工作委派给 `blueprint_agent`
2. 只能生成“代码桩/骨架/接口签名/测试骨架”，禁止实现业务逻辑
3. 主线程只负责输出 blueprint.md 与新增/修改文件清单
4. 若未成功委派，则必须停止并改为委派后再继续

## User Input

```text
$ARGUMENTS
```

## Preflight Analysis

**Step 1: Context Loading** 读取当前分支下的以下关键文件：

1. `plan.md`: **重点提取 Section 6 (Project Structure)** 以及 `Executive Summary` 中的技术栈 (Language/Framework)。
2. `data-model.md`: 用于生成具体的类型定义/数据库模型。
3. `api.md`: 用于生成 API 接口的函数签名。
4. `spec.md`: 用于生成测试用例的名称和 Docstring。

**Step 2: Structure Mapping** 基于 **`plan.md` 定义的项目结构**，规划代码文件的物理路径。

- *例如*: 如果 Plan 中定义了 `src/domain/models/`，那么 Blueprint 生成的实体类型必须放在该目录下。

## Execution Steps

### 1. Initialization

执行脚本 `scripts/setup-blueprint.ps1`。

- 该脚本会创建 `blueprint.md` 模板文件。

### 2. Scaffold Implementation (生成代码桩)

**关键规则：不要实现业务逻辑。只编写接口、类型和签名。**

你需要直接在项目中创建/写入以下**物理代码文件**（不仅仅是 Markdown）：

#### A. Type/Entity Definitions (基于 `data-model.md`)

- 在项目结构的对应位置（如 `types/`, `models/`）创建文件。
- 将 `data-model.md` 中的实体转换为具体语言的代码（TypeScript Interfaces, Python Pydantic Models, Go Structs）。
- 包含完整的字段类型定义和注释。

#### B. API Signatures (基于 `api.md`)

- 在项目结构的对应位置（如 `controllers/`, `api/`）创建文件。
- 定义 Controller 类或路由处理函数。
- **内容要求**:
  - 函数名、参数类型、返回值类型。
  - **Body**: 仅包含 `throw new NotImplementedError()` 或 `pass`。
  - **Docstring**: 引用 `api.md` 中的描述。

#### C. Test Skeletons (基于 `spec.md` Test Contracts)

- 在项目结构的对应位置（如 `tests/`）创建测试文件。
- **内容要求**:
  - 为 `spec.md` 中的每个 **Scenario** 生成一个测试函数。
  - 函数名应清晰描述场景（如 `test_user_checkout_success`）。
  - **Body**: 写好 Given/When/Then 的注释步骤，并放置一个 `assert False, "Test not implemented"` 或类似失败断言。

**重要事项：只生成上面提到的这些内容的代码桩，其他内容（比如前端组件、工具函数等）是在implement阶段进行代码实现的，本阶段不需要实现**

### 3. Blueprint Documentation (`blueprint.md`)

读取并填充 `blueprint.md` 模板：

- **Structure Manifest (文件清单)**: 列出你刚刚创建的**所有**文件路径及其职责。
- **Interface Signatures **: 记录核心接口的签名摘要。
- **Test Scaffolding Plan**: 测试覆盖率映射

### 4. Constitution Check (宪法检查)

检查生成的**代码桩**是否符合 `context/constitution.md`：

- 命名规范是否符合宪法要求？
- 是否引入了未被允许的外部依赖？
- 文件路径是否符合 Plan 中的定义？
- 如有冲突，修正代码桩文件，直到通过。

## Quality Checks

- [ ] 所有 `data-model.md` 中的实体是否都已生成对应的代码文件？
- [ ] 所有 `spec.md` 中的 Scenario 是否都有对应的测试函数？
- [ ] **关键检查**: 确认代码文件中**没有**包含具体的业务逻辑实现（只有类型和签名）。
- [ ] 确认生成的文件路径严格遵循了 `plan.md` 的 Section 6。

## Output

汇报生成的文件列表（包括 blueprint.md 和所有代码桩文件）。