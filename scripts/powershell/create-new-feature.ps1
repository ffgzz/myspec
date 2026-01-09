<#
.SYNOPSIS
    create-new-feature.ps1
    Automates the setup of a new feature for TDD workflow.
#>
param (
    [switch]$Json,
    
    [Alias("short-name")]
    [string]$ShortName,
    
    [Alias("number")]
    [string]$BranchNumber,
    
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$DescriptionParts
)

$ErrorActionPreference = 'Stop'

# Construct description from remaining args if provided
$FeatureDescription = $DescriptionParts -join " "

# --- Helper Functions ---
function Clean-BranchName {
    param ([string]$inputStr)
    $cleaned = $inputStr.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-', '' -replace '-$', ''
    return $cleaned
}

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

# --- Main Logic ---

# 1. Setup Paths
$REPO_ROOT = Get-RepoRoot
if ([string]::IsNullOrEmpty($REPO_ROOT)) {
    Write-Error "Error: Not in a specify/git repository."
    exit 1
}
Set-Location $REPO_ROOT
$SPECS_DIR = Join-Path $REPO_ROOT "specs"
if (-not (Test-Path $SPECS_DIR)) {
    New-Item -Path $SPECS_DIR -ItemType Directory | Out-Null
}

# 2. Determine Branch Name & Number
if (-not [string]::IsNullOrEmpty($ShortName)) {
    $BRANCH_SUFFIX = Clean-BranchName $ShortName
} else {
    # Simple fallback: first 3 words joined by hyphens
    # Handle case where description might be empty
    if ([string]::IsNullOrEmpty($FeatureDescription)) {
        $BRANCH_SUFFIX = "new-feature"
    } else {
        $words = $FeatureDescription -split '\s+' | Select-Object -First 3
        $BRANCH_SUFFIX = Clean-BranchName ($words -join "-")
    }
}

if ([string]::IsNullOrEmpty($BranchNumber)) {
    # Auto-increment logic
    # Find directories starting with 3 digits
    $dirs = Get-ChildItem -Path $SPECS_DIR -Directory | Where-Object { $_.Name -match '^\d{3}-' }
    
    $highestNum = 0
    foreach ($d in $dirs) {
        if ($d.Name -match '^(\d{3})') {
            $currentNum = [int]$matches[1]
            if ($currentNum -gt $highestNum) {
                $highestNum = $currentNum
            }
        }
    }
    
    $nextNum = $highestNum + 1
    $FEATURE_NUM = "{0:D3}" -f $nextNum
} else {
    # Pad input number to 3 digits
    $FEATURE_NUM = "{0:D3}" -f [int]$BranchNumber
}

$BRANCH_NAME = "${FEATURE_NUM}-${BRANCH_SUFFIX}"
$FEATURE_DIR = Join-Path $SPECS_DIR $BRANCH_NAME

# 3. Create Artifacts
if (-not (Test-Path $FEATURE_DIR)) {
    New-Item -Path $FEATURE_DIR -ItemType Directory | Out-Null
}

$SPEC_FILE = Join-Path $FEATURE_DIR "spec.md"
$TEMPLATE = Join-Path $REPO_ROOT "templates/spec-template.md"

if (Test-Path $TEMPLATE) {
    Copy-Item -Path $TEMPLATE -Destination $SPEC_FILE -Force
} else {
    if (-not (Test-Path $SPEC_FILE)) {
        New-Item -Path $SPEC_FILE -ItemType File | Out-Null
    }
}

# 4. Git Operations
if (git rev-parse --is-inside-work-tree *>$null 2>&1) {
    # Check if branch exists
    git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Branch $BRANCH_NAME already exists. Checking out..." 
        git checkout "$BRANCH_NAME"
    } else {
        Write-Host "Creating and checking out branch $BRANCH_NAME..." 
        git checkout -b "$BRANCH_NAME"
    }
} else {
    Write-Warning "Not a git repository. Skipping branch creation."
}

# 5. Output
if ($Json) {
    # JSON Output
    $outputObj = @{
        branch_name = $BRANCH_NAME
        spec_file   = $SPEC_FILE
        feature_num = $FEATURE_NUM
        feature_dir = $FEATURE_DIR
    }
    # ConvertTo-Json -Compress creates a single line JSON string
    $outputObj | ConvertTo-Json -Compress
} else {
    Write-Host "✅ Feature Initialized:"
    Write-Host "   Branch: $BRANCH_NAME"
    Write-Host "   Spec:   $SPEC_FILE"
}