#!/usr/bin/env bash
set -euo pipefail

# create-release-packages.sh
# 为项目构建发布包

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version-with-v-prefix>" >&2
  exit 1
fi

NEW_VERSION="$1"
if [[ ! $NEW_VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must look like v0.0.0" >&2
  exit 1
fi

echo "Building release package for $NEW_VERSION"

# 创建发布目录
GENRELEASES_DIR=".genreleases"
mkdir -p "$GENRELEASES_DIR"
rm -rf "$GENRELEASES_DIR"/* || true

# 构建发布包
build_package() {
  local base_dir="$GENRELEASES_DIR/my-spec-claude-${NEW_VERSION}"
  echo "Building package in $base_dir..."
  mkdir -p "$base_dir"

  # 创建 .claude 目录
  CLAUDE_DIR="$base_dir/.claude"
  mkdir -p "$CLAUDE_DIR"

  # 1. agents/ → .claude/agents/
  if [[ -d agents ]]; then
    cp -r agents "$CLAUDE_DIR/"
    echo "Copied agents → .claude/agents"
  fi

  # 2. skills/ → .claude/skills/
  if [[ -d skills ]]; then
    cp -r skills "$CLAUDE_DIR/"
    echo "Copied skills → .claude/skills"
  fi

  # 3. templates/commands/ → .claude/commands/
  if [[ -d templates/commands ]]; then
    cp -r templates/commands "$CLAUDE_DIR/"
    echo "Copied templates/commands → .claude/commands"
  fi

  # 4. templates/（排除 commands）→ templates/
  if [[ -d templates ]]; then
    mkdir -p "$base_dir/templates"
    find templates -maxdepth 1 -type f -exec cp {} "$base_dir/templates/" \;
    echo "Copied templates (excluding commands) → templates"
  fi

  # 5. scripts/ → scripts/（原封不动）
  if [[ -d scripts ]]; then
    cp -r scripts "$base_dir/"
    echo "Copied scripts → scripts"
  fi

  # 打包 Zip
  ( cd "$base_dir" && zip -r "../my-spec-cli-${NEW_VERSION}.zip" . )
  echo "Created $GENRELEASES_DIR/my-spec-cli-${NEW_VERSION}.zip"
}

# 执行构建
build_package

echo ""
echo "Release package created:"
ls -la "$GENRELEASES_DIR"/*.zip