<#
.SYNOPSIS
    setup-plan.ps1
#>
$ErrorActionPreference = 'Stop'

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

# --- 主要设置逻辑 ---
$REPO_ROOT = Get-RepoRoot
if ([string]::IsNullOrEmpty($REPO_ROOT)) {
    Write-Error "Error: Not in a valid repository."
    exit 1
}

# 检测当前分支以找到规范目录
$CURRENT_BRANCH = (git branch --show-current).Trim()
$FEATURE_DIR = Join-Path $REPO_ROOT "specs/$CURRENT_BRANCH"

if (-not (Test-Path $FEATURE_DIR)) {
    Write-Error "Error: Spec directory for branch '$CURRENT_BRANCH' not found."
    Write-Error "Expected: $FEATURE_DIR"
    exit 1
}

$TEMPLATES_DIR = Join-Path $REPO_ROOT "templates"

# 根据模板创建文件
function New-FileFromTemplate {
    param ($templateName, $outputName)
    $targetPath = Join-Path $FEATURE_DIR $outputName
    
    if (-not (Test-Path $targetPath)) {
        $templatePath = Join-Path $TEMPLATES_DIR $templateName
        if (Test-Path $templatePath) {
            Copy-Item -Path $templatePath -Destination $targetPath
            Write-Host "Created $outputName from template"
        } else {
            Write-Warning "Template $templateName not found. Creating empty file."
            New-Item -Path $targetPath -ItemType File | Out-Null
        }
    } else {
        Write-Host "Skipped $outputName (Already exists)"
    }
}

# 用于简单创建一个空文件（供AI填充）
function New-EmptyFile {
    param ($outputName)
    $targetPath = Join-Path $FEATURE_DIR $outputName
    
    if (-not (Test-Path $targetPath)) {
        New-Item -Path $targetPath -ItemType File | Out-Null
        Write-Host "Created empty $outputName"
    } else {
        Write-Host "Skipped $outputName (Already exists)"
    }
}

New-FileFromTemplate -templateName "plan-template.md" -outputName "plan.md"

New-EmptyFile -outputName "api.md"
New-EmptyFile -outputName "data-model.md"
New-EmptyFile -outputName "quickstart.md"

Write-Host "✅ Plan phase initialized in $FEATURE_DIR"