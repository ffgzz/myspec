<#
.SYNOPSIS
    Implementation Phase Pre-check Script (PowerShell Version)
.DESCRIPTION
    Checks for repository root, specific branch documentation, task status, 
    and TDD prerequisites before starting implementation.
#>

$ErrorActionPreference = 'Stop'

# --- 基础函数 ---
function Find-RepoRoot {
    $currentDir = Get-Location
    
    while ($currentDir -ne $null) {
        if ((Test-Path "$currentDir\.git") -or (Test-Path "$currentDir\.specify")) {
            return $currentDir.Path
        }
        
        $parentDir = Split-Path -Path $currentDir -Parent
        # 如果父目录为空或与当前目录相同（到达根目录），则停止
        if ([string]::IsNullOrWhiteSpace($parentDir) -or ($parentDir -eq $currentDir.Path)) {
            break
        }
        $currentDir = Get-Item $parentDir
    }
    return $null
}

# --- 1. 路径与环境检查 ---
$RepoRoot = Find-RepoRoot

if (-not $RepoRoot) {
    Write-Error "Error: Not in a valid repository."
    exit 1
}

try {
    $CurrentBranch = git branch --show-current 2>$null
    if (-not $CurrentBranch) { throw "Git branch not found" }
} catch {
    Write-Error "Error: Failed to determine current git branch."
    exit 1
}

$FeatureDir = Join-Path $RepoRoot "specs\$CurrentBranch"

Write-Host "🔍 Checking implementation prerequisites for branch: $CurrentBranch" -ForegroundColor Cyan

# --- 2. 核心文档检查 ---
$RequiredFiles = @(
    "plan.md:Technical Plan (Required for Project Structure)",
    "blueprint.md:Blueprint Contract (Required for Interfaces)",
    "tasks.md:Atomic Task List (Required for Execution)"
)

$MissingFilesCount = 0

foreach ($entry in $RequiredFiles) {
    # 分割文件名和描述
    $parts = $entry -split ':', 2
    $file = $parts[0]
    $desc = $parts[1]
    
    $targetPath = Join-Path $FeatureDir $file

    if (-not (Test-Path $targetPath -PathType Leaf)) {
        Write-Host "❌ Missing: $file ($desc)" -ForegroundColor Red
        $MissingFilesCount++
    } else {
        Write-Host "✅ Found: $file" -ForegroundColor Green
    }
}

if ($MissingFilesCount -gt 0) {
    Write-Host ""
    Write-Host "🛑 Critical documents missing. Implementation cannot start." -ForegroundColor Red
    Write-Host "Please run the previous steps (Plan -> Blueprint -> Tasks) first."
    exit 1
}

# --- 3. 任务状态检查 ---
$TasksFilePath = Join-Path $FeatureDir "tasks.md"
# 读取文件内容，如果文件为空则返回空字符串
$TasksContent = Get-Content $TasksFilePath -Raw -ErrorAction SilentlyContinue
if (-not $TasksContent) { $TasksContent = "" }

# 使用正则计算待办和已完成的任务
$TotalTasks = ([regex]::Matches($TasksContent, "\- \[ \]")).Count
$CompletedTasks = ([regex]::Matches($TasksContent, "\- \[x\]")).Count

if ($TotalTasks -eq 0 -and $CompletedTasks -eq 0) {
    Write-Warning "tasks.md seems to have no tasks defined."
    exit 1
} elseif ($TotalTasks -eq 0) {
    Write-Host "🎉 All tasks in tasks.md are already marked as completed!" -ForegroundColor Green
    Write-Host ""
    $Confirmation = Read-Host "Do you want to run the verification suite again? (y/n)"
    if ($Confirmation -notmatch '^[Yy]') {
        exit 0
    }
} else {
    Write-Host "📋 Tasks to implement: $TotalTasks (Completed: $CompletedTasks)" -ForegroundColor Yellow
    Write-Host "   (Mixed Mode: Includes both 'Blueprint-Filling' and 'Greenfield-Creation' tasks)" -ForegroundColor Gray
}

# --- 4. TDD 环境预检 ---
if (Test-Path "package.json") {
    $PkgJson = Get-Content "package.json" -Raw
    # 简单的字符串匹配检查 "test":
    if ($PkgJson -notmatch '"test":') {
        Write-Warning "No 'test' script found in package.json. TDD workflow might fail."
    }
} elseif ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt")) {
    if (-not (Get-Command "pytest" -ErrorAction SilentlyContinue)) {
        Write-Warning "'pytest' not found in path. Python TDD workflow might fail."
    }
}

Write-Host "🚀 Ready for Implementation Phase!" -ForegroundColor Green