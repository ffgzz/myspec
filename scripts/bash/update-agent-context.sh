#!/usr/bin/env bash
set -e

# --- Setup ---
# 同样内联基础路径查找逻辑，确保独立性
find_repo_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -d "$dir/.specify" ]; then echo "$dir"; return 0; fi
        dir="$(dirname "$dir")"
    done
    return 1
}

REPO_ROOT="$(find_repo_root)"
CURRENT_BRANCH=$(git branch --show-current)
FEATURE_DIR="$REPO_ROOT/specs/$CURRENT_BRANCH"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

if [ ! -d "$FEATURE_DIR" ]; then
    echo "No feature directory found for current branch."
    exit 0
fi

# --- Helper: Read File Content ---
read_file_content() {
    local file="$1"
    if [ -f "$file" ]; then
        echo ""
        echo "### Content of $(basename "$file"):"
        cat "$file"
        echo ""
    fi
}

# --- Update CLAUDE.md Only ---
# 1. Ensure CLAUDE.md exists
if [ ! -f "$CLAUDE_MD" ]; then
    echo "# Project Context" > "$CLAUDE_MD"
fi

# 2. Prepare new context block
TEMP_CONTEXT=$(mktemp)
echo "## Current Feature Context: $CURRENT_BRANCH" >> "$TEMP_CONTEXT"
echo "Updated: $(date)" >> "$TEMP_CONTEXT"

# Inject critical Plan artifacts
read_file_content "$FEATURE_DIR/spec.md" >> "$TEMP_CONTEXT"
read_file_content "$FEATURE_DIR/plan.md" >> "$TEMP_CONTEXT"
read_file_content "$FEATURE_DIR/data-model.md" >> "$TEMP_CONTEXT"
read_file_content "$FEATURE_DIR/api.md" >> "$TEMP_CONTEXT"
read_file_content "$FEATURE_DIR/quickstart.md" >> "$TEMP_CONTEXT"

# 3. Replace or Append in CLAUDE.md
# Logic: If a context block exists, replace it. Otherwise append.
if grep -q "## Current Feature Context" "$CLAUDE_MD"; then
    # Create temp file with content BEFORE the context block
    sed '/## Current Feature Context/q' "$CLAUDE_MD" | head -n -1 > "${CLAUDE_MD}.tmp"
    cat "$TEMP_CONTEXT" >> "${CLAUDE_MD}.tmp"
    mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"
else
    echo "" >> "$CLAUDE_MD"
    cat "$TEMP_CONTEXT" >> "$CLAUDE_MD"
fi

rm "$TEMP_CONTEXT"
echo "✅ CLAUDE.md updated with Plan context."