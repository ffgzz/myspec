#!/usr/bin/env bash
set -euo pipefail

# generate-release-notes.sh
# Usage: generate-release-notes.sh <new_version> <last_tag>

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <new_version> <last_tag>" >&2
  exit 1
fi

NEW_VERSION="$1"
LAST_TAG="$2"

# 获取 Commit 日志
if [ "$LAST_TAG" = "v0.0.0" ]; then
  COMMITS=$(git log --oneline --pretty=format:"- %s" HEAD)
else
  COMMITS=$(git log --oneline --pretty=format:"- %s" $LAST_TAG..HEAD)
fi

# 生成 Markdown 格式的日志
cat > release_notes.md << EOF
## Changelog

$COMMITS

## Installation

Download the zip file for your AI assistant below.
EOF

echo "Generated release notes:"
cat release_notes.md