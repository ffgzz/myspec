param (
    [Parameter(Mandatory=$true)]
    [string]$Message
)

$ErrorActionPreference = "Stop" # 遇到错误立即停止

# 1. 获取当前分支
$currentBranch = git branch --show-current
if (-not $?) { Write-Error "Failed to get current branch."; exit 1 }
$currentBranch = $currentBranch.Trim()

# 2. 检查是否误在主分支操作
if ($currentBranch -eq "main" -or $currentBranch -eq "master") {
    Write-Error "❌ Error: You are on '$currentBranch'. Please run this command from a feature branch."
    exit 1
}

Write-Host "🚀 Starting submission workflow for branch: $currentBranch" -ForegroundColor Cyan

# 3. 提交当前更改
Write-Host "📦 Staging and committing changes..." -ForegroundColor Yellow
git add .
try {
    git commit -m "$Message"
} catch {
    Write-Warning "⚠️  Nothing to commit or commit failed, proceeding to merge..."
}

# 4. 切换到 main 并更新
Write-Host "🔄 Switching to main and pulling latest changes..." -ForegroundColor Yellow
git checkout main
git pull origin main

# 5. 合并
Write-Host "🔀 Merging $currentBranch into main..." -ForegroundColor Yellow
git merge "$currentBranch"

# 6. 推送
Write-Host "⬆️  Pushing to remote..." -ForegroundColor Yellow
git push origin main

Write-Host "✅ Success! Feature '$currentBranch' has been merged and pushed." -ForegroundColor Green
Write-Host "💡 Tip: You can now delete the local branch with: git branch -d $currentBranch" -ForegroundColor Gray