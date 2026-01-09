#!/usr/bin/env bash
set -e

find_repo_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -d "$dir/.specify" ]; then echo "$dir"; return 0; fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# --- 主要设置逻辑 ---
REPO_ROOT="$(find_repo_root)"
if [ -z "$REPO_ROOT" ]; then
    echo "Error: Not in a valid repository." >&2
    exit 1
fi

# 检测当前分支以找到规范目录
CURRENT_BRANCH=$(git branch --show-current)
FEATURE_DIR="$REPO_ROOT/specs/$CURRENT_BRANCH"

if [ ! -d "$FEATURE_DIR" ]; then
    echo "Error: Spec directory for branch '$CURRENT_BRANCH' not found." >&2
    echo "Expected: $FEATURE_DIR" >&2
    exit 1
fi

TEMPLATES_DIR="$REPO_ROOT/templates"

# 根据模板创建文件
create_file_from_template() {
    local template_name="$1"
    local output_name="$2"
    local target_path="$FEATURE_DIR/$output_name"
    
    if [ ! -f "$target_path" ]; then
        if [ -f "$TEMPLATES_DIR/$template_name" ]; then
            cp "$TEMPLATES_DIR/$template_name" "$target_path"
            echo "Created $output_name from template"
        else
            echo "Warning: Template $template_name not found. Creating empty file."
            touch "$target_path"
        fi
    else
        echo "Skipped $output_name (Already exists)"
    fi
}

# 用于简单创建一个空文件（供AI填充）
create_empty_file() {
    local output_name="$1"
    local target_path="$FEATURE_DIR/$output_name"
    
    if [ ! -f "$target_path" ]; then
        touch "$target_path"
        echo "Created empty $output_name"
    else
        echo "Skipped $output_name (Already exists)"
    fi
}

create_file_from_template "plan-template.md" "plan.md"

create_empty_file "api.md"
create_empty_file "data-model.md"
create_empty_file "quickstart.md"

echo "✅ Plan phase initialized in $FEATURE_DIR"