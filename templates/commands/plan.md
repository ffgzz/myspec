---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
handoffs: 
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: speckit.checklist
    prompt: Create a checklist for the following domain...
scripts:
  sh: scripts/bash/setup-plan.sh --json
  ps: scripts/powershell/setup-plan.ps1 -Json
agent_scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **设置**：从仓库根目录运行 `{SCRIPT}` 脚本，并解析其 JSON 输出以获取 `FEATURE_SPEC`（功能规范）、`IMPL_PLAN`（实施计划）、`SPECS_DIR`（规范目录）、`BRANCH`（分支）等信息。对于参数中的单引号（如 “I‘m Groot”），请使用转义语法，例如 `'I'\''m Groot'`（或尽可能使用双引号：`"I‘m Groot"`）。
2. **加载上下文**：读取 `FEATURE_SPEC`（功能规范）和 `/memory/constitution.md`（章程）。加载 `IMPL_PLAN` 模板（该模板已复制到相应位置）。
3. **执行计划工作流**：遵循 `IMPL_PLAN` 模板中的结构，完成以下工作：
   - 填写“技术上下文”部分（将未知项标记为“需要澄清”）。
   - 根据章程填写“章程检查”部分。
   - 评估各个“关卡”（如果发现违反章程且无正当理由，则报错）。
   - **阶段 0**：生成 `research.md` 文件（解决所有“需要澄清”的问题）。
   - **阶段 1**：生成 `data-model.md`、`contracts/` 目录下的文件、`quickstart.md`。
   - **阶段 1**：运行代理脚本，更新代理上下文。
   - 在设计完成后，重新评估“章程检查”。
4. **停止并报告**：该命令在完成阶段 2 的计划后结束。报告分支信息、`IMPL_PLAN` 文件路径以及生成的所有产出物。

## 各阶段详情

### 阶段 0：大纲与研究

1. **从上面的“技术上下文”中提取未知项**：

   - 对于每个“需要澄清” → 创建一个研究任务。
   - 对于每个依赖项 → 创建一个最佳实践研究任务。
   - 对于每个集成项 → 创建一个模式研究任务。

2. **生成并派发研究任务**：

   text

   ```
   对于技术上下文中的每个未知项：
     任务：“为 {功能上下文} 研究 {未知项}”
   对于每项技术选型：
     任务：“查找 {领域} 中关于 {技术} 的最佳实践”
   ```

   

3. **在 `research.md` 中整合研究发现**，使用以下格式：

   - **决策**：[选择了什么]
   - **理由**：[为什么这样选择]
   - **考虑的替代方案**：[评估了哪些其他选项]

   **输出**：包含所有“需要澄清”问题解决方案的 `research.md` 文件。

### 阶段 1：设计与契约

**前提条件**：`research.md` 已完成。

1. **从功能规范中提取实体** → 生成 `data-model.md`：
   - 实体名称、字段、关系。
   - 根据需求推导的验证规则。
   - 如适用，包含状态转换。
2. **根据功能需求生成 API 契约**：
   - 每个用户动作 → 对应一个端点。
   - 使用标准的 REST/GraphQL 模式。
   - 将 OpenAPI/GraphQL 模式输出到 `/contracts/` 目录。
3. **更新代理上下文**：
   - 运行 `{AGENT_SCRIPT}` 脚本。
   - 这些脚本会检测当前使用的是哪种 AI 代理。
   - 更新相应的代理特定上下文文件。
   - 仅添加当前计划中涉及的新技术。
   - 保留标记之间的手动添加内容。

**输出**：`data-model.md`、`/contracts/*` 下的文件、`quickstart.md`、代理特定文件。

## 关键规则

- 使用绝对路径。
- 当“关卡”检查失败或存在未解决的“需要澄清”问题时，报错。
