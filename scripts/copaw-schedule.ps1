# copaw-schedule.ps1 - 设置 Copaw 自动修复定时任务
# 使用方式: .\copaw-schedule.ps1 -Action install  (安装定时任务)
#          .\copaw-schedule.ps1 -Action uninstall (卸载定时任务)

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("install", "uninstall")]
    [string]$Action
)

$taskName = "CopawAutoFix"
$scriptPath = Join-Path $PSScriptRoot "copaw-auto-fix.ps1"

if ($Action -eq "install") {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   安装 Copaw 自动修复定时任务" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan

    # 检查脚本是否存在
    if (-not (Test-Path $scriptPath)) {
        Write-Host "❌ 错误: 找不到 $scriptPath" -ForegroundColor Red
        exit 1
    }

    # 检查任务是否已存在
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "⚠️ 定时任务已存在，正在更新..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # 创建触发器 - 每天早上 9:00
    $trigger = New-ScheduledTaskTrigger -Daily -At "09:00"

    # 创建操作 - 运行 PowerShell 脚本
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -AutoFix"

    # 创建设置
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable:$false `
        -DontStopOnIdleEnd

    # 注册任务
    Register-ScheduledTask `
        -TaskName $taskName `
        -Description "Copaw/Ollama 自动修复 - 每天早上检查并修复常见故障" `
        -Trigger $trigger `
        -Action $action `
        -Settings $settings `
        -RunLevel Limited

    Write-Host "✅ 定时任务已安装!" -ForegroundColor Green
    Write-Host "`n任务详情:" -ForegroundColor White
    Write-Host "  名称: $taskName" -ForegroundColor Gray
    Write-Host "  执行时间: 每天 09:00" -ForegroundColor Gray
    Write-Host "  执行操作: 自动修复 Ollama/Docker/容器故障" -ForegroundColor Gray

    Write-Host "`n管理命令:" -ForegroundColor White
    Write-Host "  查看任务: Get-ScheduledTask -TaskName $taskName" -ForegroundColor Gray
    Write-Host "  手动运行: Start-ScheduledTask -TaskName $taskName" -ForegroundColor Gray
    Write-Host "  卸载任务: .\copaw-schedule.ps1 -Action uninstall" -ForegroundColor Gray

} elseif ($Action -eq "uninstall") {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "   卸载 Copaw 自动修复定时任务" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan

    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "✅ 定时任务已卸载!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ 定时任务不存在，无需卸载。" -ForegroundColor Yellow
    }
}
