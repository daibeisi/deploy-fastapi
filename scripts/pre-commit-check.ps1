# ============================================
# Windows PowerShell 版本的提交前检查脚本
# ============================================

$ErrorActionPreference = "Continue"

# 计数器
$TotalChecks = 0
$PassedChecks = 0
$FailedChecks = 0

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  代码质量检查 - Pre-commit Check" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 检查 1: Flake8
Write-Host "[1/4] 运行 Flake8 代码规范检查..." -ForegroundColor Blue
$TotalChecks++
try {
    flake8 app/ --count --select=E9,F63,F7,F82 --show-source --statistics
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Flake8 检查通过" -ForegroundColor Green
        $PassedChecks++
    } else {
        throw "Flake8 检查失败"
    }
} catch {
    Write-Host "✗ Flake8 检查失败" -ForegroundColor Red
    Write-Host "修复建议: 检查语法错误、未定义变量等问题" -ForegroundColor Yellow
    $FailedChecks++
}
Write-Host ""

# 检查 2: Black
Write-Host "[2/4] 运行 Black 代码格式检查..." -ForegroundColor Blue
$TotalChecks++
try {
    black --check app/
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Black 格式检查通过" -ForegroundColor Green
        $PassedChecks++
    } else {
        throw "Black 检查失败"
    }
} catch {
    Write-Host "⚠ 代码格式不符合规范" -ForegroundColor Yellow
    Write-Host "自动修复: black app/" -ForegroundColor Yellow
    $FailedChecks++
}
Write-Host ""

# 检查 3: Bandit
Write-Host "[3/4] 运行 Bandit 安全扫描..." -ForegroundColor Blue
$TotalChecks++
try {
    bandit -r app/ -ll -q
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 安全扫描通过" -ForegroundColor Green
        $PassedChecks++
    } else {
        throw "Bandit 扫描发现问题"
    }
} catch {
    Write-Host "⚠ 发现潜在安全问题" -ForegroundColor Yellow
    Write-Host "查看详情: bandit -r app/ -ll" -ForegroundColor Yellow
    $FailedChecks++
}
Write-Host ""

# 检查 4: 单元测试
Write-Host "[4/4] 运行单元测试..." -ForegroundColor Blue
$TotalChecks++
try {
    pytest tests/ -q
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 单元测试通过" -ForegroundColor Green
        $PassedChecks++
    } else {
        throw "单元测试失败"
    }
} catch {
    Write-Host "✗ 单元测试失败" -ForegroundColor Red
    Write-Host "查看详情: pytest tests/ -v" -ForegroundColor Yellow
    $FailedChecks++
}
Write-Host ""

# 总结
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  检查结果汇总" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "总计: $TotalChecks 项"
Write-Host "通过: $PassedChecks 项" -ForegroundColor Green
Write-Host "失败: $FailedChecks 项" -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if ($FailedChecks -gt 0) {
    Write-Host "❌ 代码检查未通过，请修复后再提交" -ForegroundColor Red
    Write-Host ""
    exit 1
} else {
    Write-Host "✅ 所有检查通过，可以安全提交！" -ForegroundColor Green
    Write-Host ""
    exit 0
}
