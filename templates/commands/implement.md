---
description: 执行实施计划，基于 Tasks 和 Blueprint 进行代码实现。
scripts:
  sh: scripts/bash/setup-implement.sh
  ps: scripts/powershell/setup-implement.ps1
---

## User Input
```text
$ARGUMENTS
```

## Preflight Analysis

**Step 1: Load Implementation Context** 读取以下关键文件：

1. **Tasks Manifest**: `specs/<branch>/tasks.md` (执行的总指挥)。
2. **Blueprint Contract**: `specs/<branch>/blueprint.md` (接口契约，不可违反)。
3. **Project Plan**: `specs/<branch>/plan.md` (包含 Project Structure，指导新文件创建位置)。
4. **Spec**: `specs/<branch>/spec.md` (包含 User Stories 和 Requirements)。

**Step 2: Environment Check**

- 执行 `scripts/bash/setup-implement.sh` 进行环境健康检查。

## Execution Strategy

你将按照 `tasks.md` 定义的 **Phases** 顺序执行（每个Phase的任务也按照顺序执行）。在每个 Phase 内部，遵循以下逻辑：

### 1. Task Analysis & Role Assignment

对于每一个任务，首先判断其性质：

- **Type A: Contract Fulfillment (填空)**
  - **特征**: `Target Files` 指向 Blueprint 中定义和已生成的物理文件（在 `blueprint.md` 中的 **Structure Manifest** 部分）。
  - **策略**: **严格填空**。仅实现逻辑，**严禁修改公共接口签名**。
- **Type B: **
  - **特征**: `Target Files` 指向的文件没有在blueprint中定义和生成的（在 `blueprint.md` 中的 **Structure Manifest** 部分）。
  - **策略**: **自己实现**。
    - **位置**: 必须严格遵循 `plan.md` 中定义的 **Project Structure**以及任务的**Target Files**。

### 2. Parallel Fan-Out (MapReduce)

对于标记为 `[P]` 的可并行任务，同时派发子代理（Sub-Agents）并行执行，子代理根据任务类型选择。

### 3. Implementation Protocol (TDD Guard)

无论任务类型如何，必须遵守以下流程：

#### Step A: Verify Red (验证失败)

- 根据任务的**Verification**来执行测试任务（根据**Type（A/B）**按需创建测试文件或实现Blueprint中定义的代码桩）

#### Step B: Implement (编码实现任务)

代码必须符合 `context/constitution.md` 中的代码规范（命名、注释等）。

#### Step C: Verify Green (验证通过)

- 执行任务的**Verification**中规定的测试命令或条件，确保代码通过所有测试。

### 4. Progress Tracking

- 每完成一个任务，立即编辑 `specs/<branch>/tasks.md`，将对应的 `[ ]` 标记为 `[x]`。

## Quality Gate (Done Criteria)

在结束本命令前，自查：

- [ ] 所有 Phase 的任务是否都已标记为 `[x]`？
- [ ] **契约一致性**: 确认没有修改 Blueprint 定义的任何核心 Interface/Type 签名。
- [ ] **结构一致性**: 确认新建的文件位置符合 `plan.md` 的目录结构要求。
- [ ] **代码质量**: 所有新代码无 Lint 错误。

## Output

汇报完成的任务数量，列出新创建的文件列表，并提供最终测试报告摘要。
