#!/usr/bin/env bash
set -euo pipefail

# create-release-packages.sh
# Build Spec Kit template release archives for each supported AI assistant and script type.

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <version-with-v-prefix>" >&2
  exit 1
fi
NEW_VERSION="$1"
if [[ ! $NEW_VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must look like v0.0.0" >&2
  exit 1
fi

echo "Building release packages for $NEW_VERSION"

# Create and use .genreleases directory for all build artifacts
GENRELEASES_DIR=".genreleases"
mkdir -p "$GENRELEASES_DIR"
rm -rf "$GENRELEASES_DIR"/* || true

# --- 路径重写逻辑 ---
rewrite_paths() {
  sed -E \
    -e 's@(/?)memory/@context/@g' \
    -e 's@(/?)scripts/@.specify/scripts/@g' \
    -e 's@(/?)templates/@.specify/templates/@g'
}

# --- 核心生成逻辑 ---
generate_commands() {
  local agent=$1 ext=$2 arg_format=$3 output_dir=$4 script_variant=$5
  mkdir -p "$output_dir"
  # 遍历 templates/commands 下的所有 md 文件
  for template in templates/commands/*.md; do
    [[ -f "$template" ]] || continue
    local name description script_command agent_script_command body
    name=$(basename "$template" .md)

    # 读取文件并移除 Windows 换行符
    file_content=$(tr -d '\r' < "$template")

    # 提取 description
    description=$(printf '%s\n' "$file_content" | awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}')
    # 提取对应脚本命令 (sh 或 ps)
    script_command=$(printf '%s\n' "$file_content" | awk -v sv="$script_variant" '/^[[:space:]]*'"$script_variant"':[[:space:]]*/ {sub(/^[[:space:]]*'"$script_variant"':[[:space:]]*/, ""); print; exit}')

    if [[ -z $script_command ]]; then
      echo "Warning: no script command found for $script_variant in $template" >&2
      script_command="(Missing script command for $script_variant)"
    fi

    # 替换 {SCRIPT} 占位符
    body=$(printf '%s\n' "$file_content" | sed "s|{SCRIPT}|${script_command}|g")

    # 移除 frontmatter 中的 scripts: 部分，防止 AI 困惑
    body=$(printf '%s\n' "$body" | awk '
      /^---$/ { print; if (++dash_count == 1) in_frontmatter=1; else in_frontmatter=0; next }
      in_frontmatter && /^scripts:$/ { skip_scripts=1; next }
      in_frontmatter && /^agent_scripts:$/ { skip_scripts=1; next }
      in_frontmatter && /^[a-zA-Z].*:/ && skip_scripts { skip_scripts=0 }
      in_frontmatter && skip_scripts && /^[[:space:]]/ { next }
      { print }
    ')

    # 应用路径重写和参数替换
    body=$(printf '%s\n' "$body" | sed "s/{ARGS}/$arg_format/g" | sed "s/__AGENT__/$agent/g" | rewrite_paths)

    # 根据扩展名生成文件
    case $ext in
      toml)
        # TOML 格式转义 (针对 Gemini/Qwen)
        body=$(printf '%s\n' "$body" | sed 's/\\/\\\\/g')
        { echo "description = \"$description\""; echo; echo "prompt = \"\"\""; echo "$body"; echo "\"\"\""; } > "$output_dir/speckit.$name.$ext" ;;
      md)
        # Markdown 格式 (针对 Claude/Cursor)
        echo "$body" > "$output_dir/speckit.$name.$ext" ;;
    esac
  done
}

# --- 构建逻辑 ---
build_variant() {
  local agent=$1 script=$2
  local base_dir="$GENRELEASES_DIR/sdd-${agent}-package-${script}"
  echo "Building $agent ($script) package..."
  mkdir -p "$base_dir"

  # 隐藏目录 .specify (存放 scripts 和 templates)
  SPEC_DIR="$base_dir/.specify"
  mkdir -p "$SPEC_DIR"

  # Context: 复制到根目录
  if [[ -d context ]]; then
      cp -r context "$base_dir/"
      echo "Copied context -> root"
  fi

  # Scripts: 放入 .specify/scripts
  if [[ -d scripts ]]; then
    mkdir -p "$SPEC_DIR/scripts"
    case $script in
      sh)
        [[ -d scripts/bash ]] && cp -r scripts/bash "$SPEC_DIR/scripts/"
        find scripts -maxdepth 1 -type f -exec cp {} "$SPEC_DIR/scripts/" \; 2>/dev/null || true
        ;;
      ps)
        [[ -d scripts/powershell ]] && cp -r scripts/powershell "$SPEC_DIR/scripts/"
        find scripts -maxdepth 1 -type f -exec cp {} "$SPEC_DIR/scripts/" \; 2>/dev/null || true
        ;;
    esac
  fi

  # Templates: 放入 .specify/templates
  # 排除 commands 目录，因为它们已经被处理成 AI 命令文件了
  if [[ -d templates ]]; then
    mkdir -p "$SPEC_DIR/templates"
    find templates -type f -not -path "templates/commands/*" -not -name "vscode-settings.json" -exec cp --parents {} "$SPEC_DIR"/ \;
  fi

  # --- 生成 claude 的配置文件 ---
  case $agent in
    claude)
      # 生成 .claude/commands/*.md
      mkdir -p "$base_dir/.claude/commands"
      generate_commands claude md "\$ARGUMENTS" "$base_dir/.claude/commands" "$script"
      ;;
    cursor-agent)
      # 生成 .cursor/rules/*.md (注：原版可能是 commands，视 Cursor 版本而定，这里沿用原版逻辑)
      mkdir -p "$base_dir/.cursor/commands"
      generate_commands cursor-agent md "\$ARGUMENTS" "$base_dir/.cursor/commands" "$script"
      ;;
    gemini)
      mkdir -p "$base_dir/.gemini/commands"
      generate_commands gemini toml "{{args}}" "$base_dir/.gemini/commands" "$script"
      ;;
    # ... 其他 Agent 可以按需保留 ...
  esac

  # 打包 Zip
  ( cd "$base_dir" && zip -r "../spec-kit-template-${agent}-${script}-${NEW_VERSION}.zip" . )
  echo "Created $GENRELEASES_DIR/spec-kit-template-${agent}-${script}-${NEW_VERSION}.zip"
}

# --- 执行构建 ---

# 默认构建 Claude 和 Cursor，支持 sh 和 ps
AGENTS=(claude cursor-agent)
SCRIPTS=(sh ps)

echo "Agents: ${AGENTS[*]}"
echo "Scripts: ${SCRIPTS[*]}"

for agent in "${AGENTS[@]}"; do
  for script in "${SCRIPTS[@]}"; do
    build_variant "$agent" "$script"
  done
done

echo "Archives in $GENRELEASES_DIR:"
ls -1 "$GENRELEASES_DIR"/spec-kit-template-*-"${NEW_VERSION}".zip