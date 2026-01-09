---
description: 基于 Blueprint 和全量设计文档，生成一份包含并行策略的原子化任务清单 (tasks.md)。
handoffs:
  - label: 填充实施
    agent: speckit.implement
    prompt: 读取 tasks.md，按顺序或并行执行编码任务
scripts:
  sh: scripts/bash/setup-tasks.sh
  ps: scripts/powershell/setup-tasks.ps1
---

## User Input
```text
$ARGUMENTS
```

## 注意事项：

**Dynamic Content Rule (No Copying)**: 模板中的所有文件路径（如 `src/models/user.ts`）、实现步骤和验证命令均为 **格式示例 (Placeholders)**。

- **严禁照抄**: 你必须忽略模板中的具体业务内容。
- **真实生成**: 必须依照当前的项目实际来填充模板的内容。
- **数量动态**: 步骤和检查项等的条目数量应根据任务的实际复杂度决定，不要死板地对应模板中的行数。

## Preflight Analysis (Context Loading)

**Step 1: Load Full Context** 读取当前分支下的所有设计资产，构建完整上下文：

1. **Spec** (`spec.md`): 获取 User Stories 优先级和验收标准。
2. **Plan** (`plan.md`): 获取技术栈和分层架构决策。
3. **Data Model** (`data-model.md`): 获取实体定义。
4. **API** (`api.md`): 获取接口契约。
5. **Quickstart** (`quickstart.md`): 获取启动和测试命令。
6. **Blueprint** (`blueprint.md` & code stubs): 获取已生成的物理代码桩路径。

## Execution Steps

### 1. Initialization

执行脚本 `{SCRIPT}`。

- 该脚本会在 `specs/<branch>/` 下创建 `tasks.md` 模板。

### 2. Dependency & Parallelism Analysis (依赖与并行分析)

在生成任务前，先构建依赖图 (DAG)：

- **依赖原则**:
  - Model (实体) -> Service (逻辑) -> API/UI (表现)。
  - Infrastructure (基础) -> Feature (功能)。
- **并行原则 ([P])**:
  - 如果两个任务修改的是完全不同的文件，且没有逻辑依赖（例如：实现 User 模块 vs 实现 Product 模块），则标记为 **Parallel**。
  - 同一模块的 Unit Test 和 Implementation 往往不能完全并行（通常先 Test 后 Code），但在 TDD 中可视作紧密配合的原子操作。

### 3. Task Generation Strategy

**Strategy Rules (Generation Logic):**

- **Infrastructure First**: 任何 User Story 相关的任务生成前，必须先生成完所有的 **Infrastructure & Setup** 任务。
- **TDD Enforcement**: 在每个 User Story 内部，必须遵循 `Test (if needed) -> Model/Type -> Service -> API/UI` 的生成顺序。
- **Dependency Linking**: 如果有依赖的话，后续步骤的任务必须在 `Depends On` 字段中显式引用依赖的前置任务的 ID。

在 `tasks.md` 中按以下结构填充内容：

#### A. Executive Dashboard (看板)

- 生成一个紧凑的任务列表。
- **格式**: `- [ ] [ID] [P] 任务标题 (Depends on: X)`
- **[P] 标记**: 仅当任务可并行时（处理不同文件，且不依赖于未完成的任务），打上 `[P]`标记。
- **Organization Rule (Phased Approach)**: 任务必须严格按照以下 **阶段 (Phases)** 进行**分组**，严禁混杂，下面**Detailed Task Definitions (详情)**里的任务顺序也必须按这个阶段顺序排列，与看板对应：
  - **Phase 1: Infrastructure & Setup**: 必须作为第一阶段。汇总 `plan.md` (技术栈搭建) 和 `quickstart.md` (环境配置) 中的所有基础任务。这些任务是后续所有工作的**阻塞性依赖**。
  - **Phase 2..N: User Story [X]**: 根据 `spec.md` 中的 User Stories，为每个故事创建一个独立的 Phase。按优先级 (P1, P2...) 排序。每个 Story 包含的任务都必须包含在该 Phase 内。

#### B. Detailed Task Definitions (详情)

为每个任务生成详细的执行卡片。

* **Priority**: 任务优先级
* **Parallel**: 任务是否可并行
* **Depends On**: 依赖的任务ID列表

* **Objective**: 描述任务目标

- **Target Files**:
  - **优先**: 引用 Blueprint 阶段已生成的物理文件路径。
  - **新增**: 如果 Blueprint 阶段未生成（如 UI 组件、Helper 函数等等），则根据 Plan 的目录结构和当前任务的需要来指定新的路径。
- **Context & References**: 列出该任务需要参考的设计文档（如 `api.md`）。
- **Verification**: 必须包含明确的测试命令或验证标准。

### 4. Quality Gate

- [ ] 是否读取了所有 6 个前置文档？
- [ ] 是否正确识别了可并行的任务并打上了 `[P]` 标记？
- [ ] 任务详情中的 `Target Files` 路径是否准确（优先复用 Blueprint）？
- [ ] 是否包含 `Verification` 步骤（TDD 闭环）？

## Output

汇报生成的 `tasks.md` 路径及任务总数（含并行任务数）。

