function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity = 'Error'
    )

    try {
        $logDir = "$PSScriptRoot\..\data\logs"

        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        $logFile = Join-Path $logDir "error-$(Get-Date -Format 'yyyy-MM-dd').log"

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Severity] $Message"

        if ($ErrorRecord) {
            $logEntry += "`n  Exception: $($ErrorRecord.Exception.Message)"
            $logEntry += "`n  StackTrace: $($ErrorRecord.ScriptStackTrace)"
        }

        Add-Content -Path $logFile -Value $logEntry

        Write-Verbose "Erro logado em: $logFile"
    }
    catch {
        Write-Warning "Falha ao logar erro: $_"
    }
}

function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory=$false)]
        [int]$DelaySeconds = 5,

        [Parameter(Mandatory=$false)]
        [string]$ErrorMessage = "Operação falhou"
    )

    $attempt = 0

    while ($attempt -lt $MaxRetries) {
        $attempt++

        try {
            Write-Verbose "Tentativa $attempt de $MaxRetries"
            $result = & $ScriptBlock
            return $result
        }
        catch {
            if ($attempt -eq $MaxRetries) {
                Write-ErrorLog -Message "$ErrorMessage após $MaxRetries tentativas" -ErrorRecord $_ -Severity 'Critical'
                throw
            }

            Write-Warning "Tentativa $attempt falhou: $_"
            Write-Host "Aguardando $DelaySeconds segundos antes de tentar novamente..." -ForegroundColor Yellow
            Start-Sleep -Seconds $DelaySeconds
        }
    }
}

function Test-Prerequisites {
    [CmdletBinding()]
    param()

    try {
        $issues = @()

        if (-not (Test-Administrator)) {
            $issues += "Privilégios de administrador necessários"
        }

        if (-not (Test-DiskSpace -RequiredGB 10)) {
            $issues += "Espaço em disco insuficiente (mínimo 10GB)"
        }

        if (-not (Test-NetworkConnection)) {
            $issues += "Sem conexão com a internet"
        }

        if ($issues.Count -gt 0) {
            Write-Host "`nProblemas detectados:" -ForegroundColor Red
            foreach ($issue in $issues) {
                Write-Host "  ✗ $issue" -ForegroundColor Yellow
            }
            return $false
        }

        Write-Host "✓ Todos os pré-requisitos atendidos" -ForegroundColor Green
        return $true
    }
    catch {
        Write-ErrorLog -Message "Erro ao verificar pré-requisitos" -ErrorRecord $_ -Severity 'Error'
        return $false
    }
}

function Get-ErrorReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$LastDays = 7
    )

    try {
        $logDir = "$PSScriptRoot\..\data\logs"

        if (-not (Test-Path $logDir)) {
            Write-Host "Nenhum log de erro encontrado" -ForegroundColor Yellow
            return @()
        }

        $cutoffDate = (Get-Date).AddDays(-$LastDays)
        $logFiles = Get-ChildItem -Path $logDir -Filter "error-*.log" | Where-Object { $_.LastWriteTime -gt $cutoffDate }

        if ($logFiles.Count -eq 0) {
            Write-Host "Nenhum erro nos últimos $LastDays dias" -ForegroundColor Green
            return @()
        }

        $errors = @()

        foreach ($file in $logFiles) {
            $content = Get-Content $file.FullName
            $errors += $content
        }

        Write-Host "`nErros encontrados (últimos $LastDays dias):" -ForegroundColor Cyan
        Write-Host "Total de entradas: $($errors.Count)" -ForegroundColor White

        return $errors
    }
    catch {
        Write-Error "Erro ao obter relatório de erros: $_"
        return @()
    }
}

function Clear-ErrorLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$OlderThanDays = 30
    )

    try {
        $logDir = "$PSScriptRoot\..\data\logs"

        if (-not (Test-Path $logDir)) {
            Write-Host "Nenhum log encontrado" -ForegroundColor Yellow
            return $true
        }

        $cutoffDate = (Get-Date).AddDays(-$OlderThanDays)
        $oldLogs = Get-ChildItem -Path $logDir -Filter "*.log" | Where-Object { $_.LastWriteTime -lt $cutoffDate }

        if ($oldLogs.Count -eq 0) {
            Write-Host "Nenhum log antigo para remover" -ForegroundColor Yellow
            return $true
        }

        Write-Host "Logs a remover: $($oldLogs.Count)" -ForegroundColor Cyan

        foreach ($log in $oldLogs) {
            Remove-Item $log.FullName -Force
            Write-Verbose "Removido: $($log.Name)"
        }

        Write-Host "✓ $($oldLogs.Count) logs antigos removidos" -ForegroundColor Green

        return $true
    }
    catch {
        Write-Error "Erro ao limpar logs: $_"
        return $false
    }
}