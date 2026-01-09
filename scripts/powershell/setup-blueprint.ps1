<#
.SYNOPSIS
    setup-blueprint.ps1
#>
$ErrorActionPreference = 'Stop'

# --- 基础函数 ---
function Get-RepoRoot {
    $dir = Get-Location
    while ($dir -ne $null -and $dir.Path -ne $dir.Root) {
        if ((Test-Path "$($dir.Path)/.git") -or (Test-Path "$($dir.Path)/.specify")) {
            return $dir.Path
        }
        $dir = Split-Path -Parent $dir.Path
    }
    return $null
}

# --- 路径设置 ---
$REPO_ROOT = Get-RepoRoot
if ([string]::IsNullOrEmpty($REPO_ROOT)) {
    Write-Error "Error: Not in a valid repository."
    exit 1
}

$CURRENT_BRANCH = (git branch --show-current).Trim()
$FEATURE_DIR = Join-Path $REPO_ROOT "specs/$CURRENT_BRANCH"

if (-not (Test-Path $FEATURE_DIR)) {
    Write-Error "Error: Spec directory for branch '$CURRENT_BRANCH' not found. Please run specify & plan first."
    exit 1
}

$TEMPLATES_DIR = Join-Path $REPO_ROOT "templates"

# --- 核心逻辑 ---

# 1. 检查依赖文件是否存在 (Plan 是 Blueprint 的前提)
if (-not (Test-Path "$FEATURE_DIR/plan.md")) {
    Write-Error "Error: plan.md not found. Blueprint phase requires a Technical Plan."
    exit 1
}

# 2. 创建 blueprint.md
$TARGET_FILE = Join-Path $FEATURE_DIR "blueprint.md"
$TEMPLATE_FILE = Join-Path $TEMPLATES_DIR "blueprint-template.md"

if (-not (Test-Path $TARGET_FILE)) {
    if (Test-Path $TEMPLATE_FILE) {
        Copy-Item -Path $TEMPLATE_FILE -Destination $TARGET_FILE
        Write-Host "Created blueprint.md from template"
    } else {
        Write-Warning "Template blueprint-template.md not found. Creating empty file."
        New-Item -Path $TARGET_FILE -ItemType File | Out-Null
    }
} else {
    Write-Host "Skipped blueprint.md (Already exists)"
}

Write-Host "✅ Blueprint phase initialized in $FEATURE_DIR"
Write-Host "   Next step: AI will scaffold code files based on plan.md Structure."