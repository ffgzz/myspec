---
description: 提交当前功能分支，合并到 main 分支并推送到远程仓库。
scripts:
  sh: scripts/bash/submit-feature.sh "{ARGS}"
  ps: scripts/powershell/submit-feature.ps1 -Message "{ARGS}"
---

## 用户输入（User Input）

```text
$ARGUMENTS
```

## 大纲

分析用户的输入（`$ARGUMENTS`），这将被用作本次提交的 **Commit Message（提交信息）**。

遵循此执行流程：

1.  **验证输入 (Validation)**：
    * 如果 `$ARGUMENTS` 为空，**停止执行**，并要求用户提供一段简短的提交信息来描述所做的更改。

2.  **执行提交 (Execute Submission)**：
    * 运行 Frontmatter 中配置的平台特定脚本（`submit-feature`）。
    * 将用户的输入字符串作为参数传递给脚本。
    * *注意：该脚本将负责处理完整的 Git 工作流：包括暂存文件、使用该信息提交、切换回 main 分支、拉取最新代码、合并功能分支以及推送到远程仓库。*

3.  **报告状态 (Report Status)**：
    * 如果脚本执行**成功**，向用户确认功能分支已被合并到 `main` 并已推送。
    * 如果脚本执行**失败**（例如出现合并冲突），将错误输出展示给用户，并建议他们手动解决冲突。