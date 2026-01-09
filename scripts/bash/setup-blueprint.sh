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
    echo "Error: Spec directory for branch '$CURRENT_BRANCH' not found. Please run specify & plan first." >&2
    exit 1
fi

TEMPLATES_DIR="$REPO_ROOT/templates"

# --- 核心逻辑 ---

# 1. 检查依赖文件是否存在 (Plan 是 Blueprint 的前提)
if [ ! -f "$FEATURE_DIR/plan.md" ]; then
    echo "Error: plan.md not found. Blueprint phase requires a Technical Plan." >&2
    exit 1
fi

# 2. 创建 blueprint.md
TARGET_FILE="$FEATURE_DIR/blueprint.md"
TEMPLATE_FILE="$TEMPLATES_DIR/blueprint-template.md"

if [ ! -f "$TARGET_FILE" ]; then
    if [ -f "$TEMPLATE_FILE" ]; then
        cp "$TEMPLATE_FILE" "$TARGET_FILE"
        echo "Created blueprint.md from template"
    else
        echo "Warning: Template my-blueprint-template.md not found. Creating empty file."
        touch "$TARGET_FILE"
    fi
else
    echo "Skipped blueprint.md (Already exists)"
fi

echo "✅ Blueprint phase initialized in $FEATURE_DIR"
echo "   Next step: AI will scaffold code files based on plan.md Structure."