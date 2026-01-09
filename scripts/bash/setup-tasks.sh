#!/usr/bin/env bash
set -e

# --- 基础函数 ---
find_repo_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -d "$dir/.specify" ]; then echo "$dir"; return 0; fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# --- 路径设置 ---
REPO_ROOT="$(find_repo_root)"
if [ -z "$REPO_ROOT" ]; then
    echo "Error: Not in a valid repository." >&2
    exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)
FEATURE_DIR="$REPO_ROOT/specs/$CURRENT_BRANCH"

if [ ! -d "$FEATURE_DIR" ]; then
    echo "Error: Spec directory for branch '$CURRENT_BRANCH' not found. Please run specify -> plan -> blueprint first." >&2
    exit 1
fi

TEMPLATES_DIR="$REPO_ROOT/templates"

# --- 核心逻辑 ---

# 1. 检查必要的前置文件 (Blueprint 是 Tasks 的前提)
if [ ! -f "$FEATURE_DIR/blueprint.md" ]; then
    echo "Error: blueprint.md not found. Task phase requires a Blueprint Contract." >&2
    exit 1
fi

# 2. 创建 tasks.md
TARGET_FILE="$FEATURE_DIR/tasks.md"
TEMPLATE_FILE="$TEMPLATES_DIR/tasks-template.md"

if [ ! -f "$TARGET_FILE" ]; then
    if [ -f "$TEMPLATE_FILE" ]; then
        cp "$TEMPLATE_FILE" "$TARGET_FILE"
        echo "Created tasks.md from template"
    else
        echo "Warning: Template my-tasks-template.md not found. Creating empty file."
        touch "$TARGET_FILE"
    fi
else
    echo "Skipped tasks.md (Already exists)"
fi

echo "✅ Task phase initialized in $FEATURE_DIR"