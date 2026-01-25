#!/usr/bin/env bash
#
# Implementation Phase Pre-check Script (Bash Version)
# Checks for repository root, specific branch documentation, task status,
# and TDD prerequisites before starting implementation.
#

set -euo pipefail

# --- 基础函数 ---
find_repo_root() {
    local current_dir="$PWD"
    
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/.git" ]] || [[ -d "$current_dir/.specify" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    return 1
}

# --- 1. 路径与环境检查 ---
REPO_ROOT=$(find_repo_root) || {
    echo "Error: Not in a valid repository." >&2
    exit 1
}

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null) || {
    echo "Error: Failed to determine current git branch." >&2
    exit 1
}

FEATURE_DIR="$REPO_ROOT/specs/$CURRENT_BRANCH"

echo "🔍 Checking implementation prerequisites for branch: $CURRENT_BRANCH"

# --- 2. 核心文档检查 ---
declare -a REQUIRED_FILES=(
    "plan.md:Technical Plan (Required for Project Structure)"
    "blueprint.md:Blueprint Contract (Required for Interfaces)"
    "tasks.md:Atomic Task List (Required for Execution)"
)

MISSING_COUNT=0

for entry in "${REQUIRED_FILES[@]}"; do
    file="${entry%%:*}"
    desc="${entry#*:}"
    target_path="$FEATURE_DIR/$file"
    
    if [[ ! -f "$target_path" ]]; then
        echo "❌ Missing: $file ($desc)"
        ((MISSING_COUNT++))
    else
        echo "✅ Found: $file"
    fi
done

if [[ $MISSING_COUNT -gt 0 ]]; then
    echo ""
    echo "🛑 Critical documents missing. Implementation cannot start."
    echo "Please run the previous steps (Plan -> Blueprint -> Tasks) first."
    exit 1
fi

# --- 3. 任务状态检查 ---
TASKS_FILE="$FEATURE_DIR/tasks.md"
TASKS_CONTENT=$(cat "$TASKS_FILE" 2>/dev/null || echo "")

# 计算待办和已完成的任务数
TOTAL_TASKS=$(echo "$TASKS_CONTENT" | grep -c '\- \[ \]' || echo 0)
COMPLETED_TASKS=$(echo "$TASKS_CONTENT" | grep -c '\- \[x\]' || echo 0)

if [[ $TOTAL_TASKS -eq 0 ]] && [[ $COMPLETED_TASKS -eq 0 ]]; then
    echo "⚠️  Warning: tasks.md seems to have no tasks defined."
    exit 1
elif [[ $TOTAL_TASKS -eq 0 ]]; then
    echo "🎉 All tasks in tasks.md are already marked as completed!"
    echo ""
    read -p "Do you want to run the verification suite again? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    echo "📋 Tasks to implement: $TOTAL_TASKS (Completed: $COMPLETED_TASKS)"
    echo "   (Mixed Mode: Includes both 'Blueprint-Filling' and 'Greenfield-Creation' tasks)"
fi

# --- 4. TDD 环境预检 ---
if [[ -f "package.json" ]]; then
    if ! grep -q '"test":' package.json; then
        echo "⚠️  Warning: No 'test' script found in package.json. TDD workflow might fail."
    fi
elif [[ -f "pyproject.toml" ]] || [[ -f "requirements.txt" ]]; then
    if ! command -v pytest &>/dev/null; then
        echo "⚠️  Warning: 'pytest' not found in path. Python TDD workflow might fail."
    fi
fi

echo "🚀 Ready for Implementation Phase!"
