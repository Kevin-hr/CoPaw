# copaw-diagnose.ps1 - Copaw 故障排查诊断脚本
# 使用方式: .\copaw-diagnose.ps1

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Copaw 故障排查 - 环境诊断工具" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$results = @{}

# 1. 检查本地 Ollama
Write-Host "`n[1/5] 检查本地 Ollama..." -ForegroundColor Yellow
$ollamaProc = Get-Process ollama -ErrorAction SilentlyContinue
$ollamaCmd = Get-Command ollama -ErrorAction SilentlyContinue

if ($ollamaProc) {
    Write-Host "  [OK] Ollama 进程运行中 (PID: $($ollamaProc.Id))" -ForegroundColor Green
    $results.LocalOllama = "运行中"
} elseif ($ollamaCmd) {
    Write-Host "  [WARN] 本地安装存在但进程未运行" -ForegroundColor Yellow
    $results.LocalOllama = "未运行"
} else {
    Write-Host "  [FAIL] 未安装 Ollama" -ForegroundColor Red
    $results.LocalOllama = "未安装"
}

# 2. 检查 Docker
Write-Host "`n[2/5] 检查 Docker..." -ForegroundColor Yellow
$dockerProc = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
$dockerRunning = docker info 2>$null

if ($dockerProc) {
    Write-Host "  [OK] Docker Desktop 进程存在" -ForegroundColor Green
    if ($dockerRunning) {
        Write-Host "  [OK] Docker 服务运行正常" -ForegroundColor Green
        $results.Docker = "运行中"
    } else {
        Write-Host "  [WARN] Docker 服务未就绪" -ForegroundColor Yellow
        $results.Docker = "进程存在但服务未就绪"
    }
} else {
    Write-Host "  [FAIL] Docker Desktop 未启动" -ForegroundColor Red
    $results.Docker = "未启动"
}

# 3. 检查容器
Write-Host "`n[3/5] 检查 Ollama 容器..." -ForegroundColor Yellow
$containerRunning = docker ps --filter "name=ollama" --format "{{.Names}}" 2>$null
$containerExists = docker ps -a --filter "name=ollama" --format "{{.Names}}" 2>$null

if ($containerRunning) {
    Write-Host "  [OK] 容器 '$containerRunning' 运行中" -ForegroundColor Green
    $results.Container = "运行中: $containerRunning"
} elseif ($containerExists) {
    Write-Host "  [WARN] 容器 '$containerExists' 存在但未运行" -ForegroundColor Yellow
    $results.Container = "已停止: $containerExists"
} else {
    Write-Host "  [INFO] 未找到 Ollama 容器" -ForegroundColor Gray
    $results.Container = "不存在"
}

# 4. 检查端口
Write-Host "`n[4/5] 检查端口 11434..." -ForegroundColor Yellow
$portCheck = Test-NetConnection -ComputerName localhost -Port 11434 -WarningAction SilentlyContinue

if ($portCheck.TcpTestSucceeded) {
    Write-Host "  [OK] 端口 11434 开放" -ForegroundColor Green
    $results.Port11434 = "开放"
} else {
    Write-Host "  [FAIL] 端口 11434 未开放" -ForegroundColor Red
    $results.Port11434 = "未开放"
}

# 5. API 测试
Write-Host "`n[5/5] 测试 Ollama API..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  [OK] API 响应正常" -ForegroundColor Green
    $models = $response.models | ForEach-Object { $_.name }
    if ($models) {
        Write-Host "  已安装模型: $($models -join ', ')" -ForegroundColor Cyan
        $results.API = "正常 ($($models.Count) 个模型)"
    } else {
        Write-Host "  已安装模型: (无)" -ForegroundColor Gray
        $results.API = "正常 (无模型)"
    }
} catch {
    Write-Host "  [FAIL] API 无响应: $($_.Exception.Message)" -ForegroundColor Red
    $results.API = "无响应"
}

# 结果汇总
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "              诊断结果汇总" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$results.GetEnumerator() | ForEach-Object {
    $color = if ($_.Value -match "运行中|正常") { "Green" }
              elseif ($_.Value -match "未运行|未启动|未开放|无响应") { "Red" }
              else { "Yellow" }
    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor $color
}

# 建议
Write-Host "`n==========================================" -ForegroundColor Cyan

$issues = @()
if ($results.LocalOllama -eq "未运行" -or $results.LocalOllama -eq "未安装") { $issues += "Ollama" }
if ($results.Docker -eq "未启动") { $issues += "Docker" }
if ($results.Container -match "已停止|不存在") { $issues += "容器" }
if ($results.Port11434 -eq "未开放") { $issues += "端口11434" }
if ($results.API -eq "无响应") { $issues += "API" }

if ($issues.Count -eq 0) {
    Write-Host "  ✅ 所有检查通过！Copaw 应该可以正常使用。" -ForegroundColor Green
    Write-Host "  如果仍然报错，请尝试运行自动修复:" -ForegroundColor Gray
    Write-Host "  .\copaw-auto-fix.ps1 -AutoFix" -ForegroundColor White
} else {
    Write-Host "  ❌ 发现问题: $($issues -join ', ')" -ForegroundColor Red
    Write-Host "  运行以下命令自动修复:" -ForegroundColor Yellow
    Write-Host "  .\copaw-auto-fix.ps1 -AutoFix" -ForegroundColor White
}
