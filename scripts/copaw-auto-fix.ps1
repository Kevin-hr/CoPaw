# copaw-auto-fix.ps1 - Copaw 自动修复脚本
# 使用方式: .\copaw-auto-fix.ps1 -AutoFix

param(
    [switch]$AutoFix
)

if (-not $AutoFix) {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   Copaw 自动修复工具" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "`n此脚本会执行以下操作:" -ForegroundColor White
    Write-Host "  1. 启动 Ollama 进程（如未运行）" -ForegroundColor Gray
    Write-Host "  2. 启动 Docker Desktop（如未运行）" -ForegroundColor Gray
    Write-Host "  3. 启动 Ollama 容器（如已停止）" -ForegroundColor Gray
    Write-Host "  4. 验证 Ollama API 可用性" -ForegroundColor Gray
    Write-Host "`n请添加 -AutoFix 参数确认执行:" -ForegroundColor Yellow
    Write-Host "  .\copaw-auto-fix.ps1 -AutoFix" -ForegroundColor White
    exit 0
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Copaw 自动修复 - 执行中" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$fixed = @()
$failed = @()

# ========== 1. 修复 Ollama 进程 ==========
Write-Host "`n[修复 1/4] Ollama 进程..." -ForegroundColor Yellow
$ollamaProc = Get-Process ollama -ErrorAction SilentlyContinue

if ($ollamaProc) {
    Write-Host "  [SKIP] Ollama 进程已在运行" -ForegroundColor Gray
} else {
    Write-Host "  [TRY] 启动 Ollama 服务..." -ForegroundColor Cyan
    try {
        Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden -ErrorAction Stop
        Start-Sleep -Seconds 3
        if (Get-Process ollama -ErrorAction SilentlyContinue) {
            Write-Host "  [OK] Ollama 服务已启动" -ForegroundColor Green
            $fixed += "Ollama 进程"
        }
    } catch {
        Write-Host "  [FAIL] 启动失败: $($_.Exception.Message)" -ForegroundColor Red
        $failed += "Ollama 进程"
    }
}

# ========== 2. 修复 Docker ==========
Write-Host "`n[修复 2/4] Docker Desktop..." -ForegroundColor Yellow
$dockerProc = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue

if ($dockerProc) {
    Write-Host "  [SKIP] Docker Desktop 已在运行" -ForegroundColor Gray
} else {
    Write-Host "  [TRY] 启动 Docker Desktop..." -ForegroundColor Cyan
    $dockerPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        try {
            Start-Process -FilePath $dockerPath -WindowStyle Normal -ErrorAction Stop
            Write-Host "  [OK] 已启动 Docker Desktop" -ForegroundColor Green
            Write-Host "  [WAIT] 等待 Docker 初始化 (30秒)..." -ForegroundColor Cyan
            Start-Sleep -Seconds 30
            $fixed += "Docker Desktop"

            # 验证 Docker 是否就绪
            $dockerReady = $false
            for ($i = 0; $i -lt 10; $i++) {
                if (docker info 2>$null) {
                    $dockerReady = $true
                    break
                }
                Start-Sleep -Seconds 2
            }
            if ($dockerReady) {
                Write-Host "  [OK] Docker 服务已就绪" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] Docker 服务未就绪，请手动检查" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  [FAIL] 启动失败: $($_.Exception.Message)" -ForegroundColor Red
            $failed += "Docker Desktop"
        }
    } else {
        Write-Host "  [FAIL] 未找到 Docker Desktop 安装路径" -ForegroundColor Red
        $failed += "Docker Desktop"
    }
}

# ========== 3. 修复容器 ==========
Write-Host "`n[修复 3/4] Ollama 容器..." -ForegroundColor Yellow
$containerRunning = docker ps --filter "name=ollama" --format "{{.Names}}" 2>$null
$containerExists = docker ps -a --filter "name=ollama" --format "{{.Names}}" 2>$null

if ($containerRunning) {
    Write-Host "  [SKIP] 容器已在运行" -ForegroundColor Gray
} elseif ($containerExists) {
    Write-Host "  [TRY] 启动已存在的容器..." -ForegroundColor Cyan
    try {
        docker start $containerExists
        Start-Sleep -Seconds 3
        if (docker ps --filter "name=ollama" --format "{{.Names}}" 2>$null) {
            Write-Host "  [OK] 容器已启动: $containerExists" -ForegroundColor Green
            $fixed += "Ollama 容器"
        }
    } catch {
        Write-Host "  [FAIL] 启动失败: $($_.Exception.Message)" -ForegroundColor Red
        $failed += "Ollama 容器"
    }
} else {
    Write-Host "  [INFO] 无已存在的容器，跳过" -ForegroundColor Gray
}

# ========== 4. 验证 API ==========
Write-Host "`n[修复 4/4] 验证 Ollama API..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

$apiReady = $false
for ($i = 0; $i -lt 5; $i++) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5 -ErrorAction Stop
        $apiReady = $true
        break
    } catch {
        Start-Sleep -Seconds 2
    }
}

if ($apiReady) {
    Write-Host "  [OK] API 响应正常" -ForegroundColor Green
    $models = $response.models | ForEach-Object { $_.name }
    if ($models) {
        Write-Host "  已安装模型: $($models -join ', ')" -ForegroundColor Cyan
    } else {
        Write-Host "  已安装模型: (无)" -ForegroundColor Gray
    }
} else {
    Write-Host "  [FAIL] API 仍无响应" -ForegroundColor Red
    $failed += "API"
}

# ========== 结果汇总 ==========
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "              修复结果" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

if ($fixed.Count -gt 0) {
    Write-Host "`n✅ 成功修复 $($fixed.Count) 项:" -ForegroundColor Green
    $fixed | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
}

if ($failed.Count -gt 0) {
    Write-Host "`n❌ 失败 $($failed.Count) 项:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

if ($fixed.Count -gt 0 -and $failed.Count -eq 0) {
    Write-Host "`n🎉 所有问题已修复！请尝试再次使用 Copaw。" -ForegroundColor Green
} elseif ($fixed.Count -gt 0) {
    Write-Host "`n⚠️ 部分问题已修复，请检查失败项。" -ForegroundColor Yellow
} else {
    Write-Host "`n❌ 未能自动修复任何问题。" -ForegroundColor Red
    Write-Host "请手动检查 Docker 和 Ollama 的安装状态。" -ForegroundColor White
}
