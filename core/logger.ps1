$script:LogFile = $null

function Initialize-Log {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $script:LogFile = "$PSScriptRoot\..\logs\install_$timestamp.log"
    
    New-Item -Path $script:LogFile -ItemType File -Force | Out-Null
    
    Write-Log "=== Env Setup Iniciado ===" "INFO"
    Write-Log "Data: $(Get-Date)" "INFO"
    
    Clear-OldLogs
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($script:LogFile) {
        Add-Content -Path $script:LogFile -Value $logMessage
    }
    
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "DEBUG" { "Gray" }
        default { "White" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

function Clear-OldLogs {
    $logsPath = "$PSScriptRoot\..\logs"
    $logs = Get-ChildItem -Path $logsPath -Filter "*.log" | Sort-Object LastWriteTime -Descending
    
    if ($logs.Count -gt 5) {
        $logs | Select-Object -Skip 5 | Remove-Item -Force
    }
}

function Export-LogReport {
    param([hashtable]$Report)
    
    Write-Log " RELATÓRIO FINAL " "INFO"
    Write-Log "Instalados: $($Report.Success.Count)" "SUCCESS"
    Write-Log "Falharam: $($Report.Failed.Count)" "ERROR"
    Write-Log "Já existiam: $($Report.Skipped.Count)" "INFO"
    
    if ($Report.Failed.Count -gt 0) {
        Write-Log "Pacotes que falharam:" "ERROR"
        $Report.Failed | ForEach-Object { Write-Log "  - $_" "ERROR" }
    }
    
    Write-Log "Log salvo em: $script:LogFile" "INFO"
}