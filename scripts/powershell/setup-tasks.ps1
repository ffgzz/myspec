<#
.SYNOPSIS
    setup-tasks.ps1
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
    Write-Error "Error: Spec directory for branch '$CURRENT_BRANCH' not found. Please run specify -> plan -> blueprint first."
    exit 1
}

$TEMPLATES_DIR = Join-Path $REPO_ROOT "templates"

# --- 核心逻辑 ---

# 1. 检查必要的前置文件 (Blueprint 是 Tasks 的前提)
if (-not (Test-Path "$FEATURE_DIR/blueprint.md")) {
    Write-Error "Error: blueprint.md not found. Task phase requires a Blueprint Contract."
    exit 1
}

# 2. 创建 tasks.md
$TARGET_FILE = Join-Path $FEATURE_DIR "tasks.md"
$TEMPLATE_FILE = Join-Path $TEMPLATES_DIR "tasks-template.md"

if (-not (Test-Path $TARGET_FILE)) {
    if (Test-Path $TEMPLATE_FILE) {
        Copy-Item -Path $TEMPLATE_FILE -Destination $TARGET_FILE
        Write-Host "Created tasks.md from template"
    } else {
        Write-Warning "Template tasks-template.md not found. Creating empty file."
        New-Item -Path $TARGET_FILE -ItemType File | Out-Null
    }
} else {
    Write-Host "Skipped tasks.md (Already exists)"
}

Write-Host "✅ Task phase initialized in $FEATURE_DIR"