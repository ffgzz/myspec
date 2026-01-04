#!/usr/bin/env bash
set -euo pipefail

# update-version.sh
# Update version in pyproject.toml

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version>" >&2
  exit 1
fi

VERSION="$1"

# Remove 'v' prefix for Python versioning
PYTHON_VERSION=${VERSION#v}

if [ -f "pyproject.toml" ]; then
  # 简单粗暴的正则替换，确保你的 pyproject.toml 里有 version = "..." 这一行
  sed -i "s/version = \".*\"/version = \"$PYTHON_VERSION\"/" pyproject.toml
  echo "Updated pyproject.toml version to $PYTHON_VERSION"
else
  echo "Warning: pyproject.toml not found, skipping version update"
fi