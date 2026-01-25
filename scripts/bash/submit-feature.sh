#!/usr/bin/env bash
#
# Feature Submission Script (Bash Version)
# Commits changes, merges feature branch into main, and pushes to remote.
#

set -euo pipefail

# 检查参数
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <commit-message>" >&2
    exit 1
fi

MESSAGE="$1"

# 1. 获取当前分支
CURRENT_BRANCH=$(git branch --show-current)
if [[ -z "$CURRENT_BRANCH" ]]; then
    echo "❌ Error: Failed to get current branch." >&2
    exit 1
fi

# 2. 检查是否误在主分支操作
if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
    echo "❌ Error: You are on '$CURRENT_BRANCH'. Please run this command from a feature branch." >&2
    exit 1
fi

echo "🚀 Starting submission workflow for branch: $CURRENT_BRANCH"

# 3. 提交当前更改
echo "📦 Staging and committing changes..."
git add .
if ! git commit -m "$MESSAGE"; then
    echo "⚠️  Nothing to commit or commit failed, proceeding to merge..."
fi

# 4. 切换到 main 并更新
echo "🔄 Switching to main and pulling latest changes..."
git checkout main
git pull origin main

# 5. 合并
echo "🔀 Merging $CURRENT_BRANCH into main..."
git merge "$CURRENT_BRANCH"

# 6. 推送
echo "⬆️  Pushing to remote..."
git push origin main

echo "✅ Success! Feature '$CURRENT_BRANCH' has been merged and pushed."
echo "💡 Tip: You can now delete the local branch with: git branch -d $CURRENT_BRANCH"
