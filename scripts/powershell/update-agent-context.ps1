<#
.SYNOPSIS
    update-agent-context.ps1
#>
$ErrorActionPreference = 'Stop'

# --- Setup ---
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

$REPO_ROOT = Get-RepoRoot
if ([string]::IsNullOrEmpty($REPO_ROOT)) {
    Write-Error "Error: Not in a valid repository."
    exit 1
}

$CURRENT_BRANCH = (git branch --show-current).Trim()
$FEATURE_DIR = Join-Path $REPO_ROOT "specs/$CURRENT_BRANCH"
$CLAUDE_MD = Join-Path $REPO_ROOT "CLAUDE.md"

if (-not (Test-Path -Path $FEATURE_DIR)) {
    Write-Host "No feature directory found for current branch."
    exit 0
}

# --- Helper: Read File Content ---
function Get-FileContentFormatted {
    param ($filePath)
    if (Test-Path $filePath) {
        $fileName = Split-Path $filePath -Leaf
        return "`n### Content of $fileName`:`n$(Get-Content $filePath -Raw)`n"
    }
    return ""
}

# --- Update CLAUDE.md Only ---
# 1. Ensure CLAUDE.md exists
if (-not (Test-Path $CLAUDE_MD)) {
    Set-Content -Path $CLAUDE_MD -Value "# Project Context" -Encoding UTF8
}

# 2. Prepare new context block
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("## Current Feature Context: $CURRENT_BRANCH")
[void]$sb.AppendLine("Updated: $(Get-Date)")

# Inject critical Plan artifacts
[void]$sb.Append((Get-FileContentFormatted "$FEATURE_DIR/spec.md"))
[void]$sb.Append((Get-FileContentFormatted "$FEATURE_DIR/plan.md"))
[void]$sb.Append((Get-FileContentFormatted "$FEATURE_DIR/data-model.md"))
[void]$sb.Append((Get-FileContentFormatted "$FEATURE_DIR/api.md"))
[void]$sb.Append((Get-FileContentFormatted "$FEATURE_DIR/quickstart.md"))

$NEW_CONTEXT_BLOCK = $sb.ToString()

# 3. Replace or Append in CLAUDE.md
$claudeContent = Get-Content -Path $CLAUDE_MD -Raw -ErrorAction SilentlyContinue
if ($null -eq $claudeContent) { $claudeContent = "" }

# Logic: If a context block exists, replace it. Otherwise append.
# 使用正则 (?s) 开启单行模式（点号匹配换行符）来匹配现有块及其后的所有内容
$pattern = "(?s)## Current Feature Context.*$"

if ($claudeContent -match $pattern) {
    # Replace existing block
    $updatedContent = $claudeContent -replace $pattern, $NEW_CONTEXT_BLOCK
    Set-Content -Path $CLAUDE_MD -Value $updatedContent -Encoding UTF8
} else {
    # Append to end
    Add-Content -Path $CLAUDE_MD -Value "`n$NEW_CONTEXT_BLOCK" -Encoding UTF8
}

Write-Host "✅ CLAUDE.md updated with Plan context."