function Get-StateFilePath {
    [CmdletBinding()]
    param()

    try {
        $stateDir = "$PSScriptRoot\..\data\state"

        if (-not (Test-Path $stateDir)) {
            Write-Verbose "Criando diretório de estado: $stateDir"
            New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
        }

        return Join-Path $stateDir "state.json"
    }
    catch {
        Write-Error "Erro ao obter caminho do arquivo de estado: $_"
        throw
    }
}


function Get-InstallationState {
    [CmdletBinding()]
    param()

    try {
        Write-Verbose "Obtendo estado de instalação"

        $stateFile = Get-StateFilePath

        if (-not (Test-Path $stateFile)) {
            Write-Verbose "Arquivo de estado não existe, criando estado inicial"
            return Initialize-InstallationState
        }

        $state = Get-Content $stateFile -Raw | ConvertFrom-Json

        Write-Verbose "Estado carregado: $($state.InstalledPackages.Count) packages instalados"

        return $state
    }
    catch {
        Write-Error "Erro ao obter estado de instalação: $_"
        return Initialize-InstallationState
    }
}

function Initialize-InstallationState {
    [CmdletBinding()]
    param()

    try {
        Write-Verbose "Inicializando estado de instalação"

        $state = [PSCustomObject]@{
            Version = "1.0"
            Created = (Get-Date).ToString("o")
            LastModified = (Get-Date).ToString("o")
            InstalledPackages = @()
            Sessions = @()
            CurrentSessionId = $null
        }

        Save-InstallationState -State $state

        return $state
    }
    catch {
        Write-Error "Erro ao inicializar estado: $_"
        throw
    }
}

function Save-InstallationState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [PSCustomObject]$State
    )

    try {
        Write-Verbose "Salvando estado de instalação"

        $State.LastModified = (Get-Date).ToString("o")

        $stateFile = Get-StateFilePath
        $State | ConvertTo-Json -Depth 10 | Set-Content $stateFile -Force

        Write-Verbose "Estado salvo em: $stateFile"

        return $true
    }
    catch {
        Write-Error "Erro ao salvar estado: $_"
        return $false
    }
}


function Start-InstallationSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Description = "Installation Session"
    )

    try {
        Write-Verbose "Iniciando sessão de instalação: $Description"

        $state = Get-InstallationState

        $sessionId = [guid]::NewGuid().ToString()

        $session = [PSCustomObject]@{
            SessionId = $sessionId
            Description = $Description
            StartTime = (Get-Date).ToString("o")
            EndTime = $null
            Status = "InProgress"
            PackagesInstalled = @()
            PackagesFailed = @()
        }

        $state.Sessions += $session
        $state.CurrentSessionId = $sessionId

        Save-InstallationState -State $state

        Write-Host "Sessão de instalação iniciada: $sessionId" -ForegroundColor Green

        return $sessionId
    }
    catch {
        Write-Error "Erro ao iniciar sessão de instalação: $_"
        throw
    }
}

function Stop-InstallationSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$SessionId,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Completed', 'Failed', 'Cancelled')]
        [string]$Status = 'Completed'
    )

    try {
        Write-Verbose "Finalizando sessão de instalação"

        $state = Get-InstallationState

        if (-not $SessionId) {
            $SessionId = $state.CurrentSessionId
        }

        if (-not $SessionId) {
            throw "Nenhuma sessão ativa encontrada"
        }

        $session = $state.Sessions | Where-Object { $_.SessionId -eq $SessionId }

        if (-not $session) {
            throw "Sessão não encontrada: $SessionId"
        }

        $session.EndTime = (Get-Date).ToString("o")
        $session.Status = $Status

        if ($state.CurrentSessionId -eq $SessionId) {
            $state.CurrentSessionId = $null
        }

        Save-InstallationState -State $state

        Write-Host "Sessão finalizada: $SessionId ($Status)" -ForegroundColor Green

        return $true
    }
    catch {
        Write-Error "Erro ao finalizar sessão: $_"
        return $false
    }
}

function Get-InstallationSessions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$Last = 0
    )

    try {
        $state = Get-InstallationState

        $sessions = $state.Sessions

        if ($Last -gt 0) {
            $sessions = $sessions | Select-Object -Last $Last
        }

        Write-Host "`nSessões de instalação:" -ForegroundColor Cyan

        foreach ($session in $sessions) {
            Write-Host "`nSessionId: $($session.SessionId)" -ForegroundColor Yellow
            Write-Host "  Descrição: $($session.Description)" -ForegroundColor White
            Write-Host "  Status: $($session.Status)" -ForegroundColor $(if ($session.Status -eq 'Completed') { 'Green' } else { 'Red' })
            Write-Host "  Início: $($session.StartTime)" -ForegroundColor Gray
            if ($session.EndTime) {
                Write-Host "  Fim: $($session.EndTime)" -ForegroundColor Gray
            }
            Write-Host "  Packages instalados: $($session.PackagesInstalled.Count)" -ForegroundColor Cyan
            Write-Host "  Packages com falha: $($session.PackagesFailed.Count)" -ForegroundColor Red
        }

        return $sessions
    }
    catch {
        Write-Error "Erro ao obter sessões: $_"
        return @()
    }
}


function Add-InstalledPackageToState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageId,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageName,

        [Parameter(Mandatory=$false)]
        [string]$Version = "unknown",

        [Parameter(Mandatory=$false)]
        [string]$Manager = "unknown",

        [Parameter(Mandatory=$false)]
        [string]$SessionId
    )

    try {
        Write-Verbose "Adicionando package ao estado: $PackageName"

        $state = Get-InstallationState

        if (-not $SessionId -and $state.CurrentSessionId) {
            $SessionId = $state.CurrentSessionId
        }

        $packageEntry = [PSCustomObject]@{
            PackageId = $PackageId
            PackageName = $PackageName
            Version = $Version
            Manager = $Manager
            InstalledAt = (Get-Date).ToString("o")
            SessionId = $SessionId
        }

        $existing = $state.InstalledPackages | Where-Object { $_.PackageId -eq $PackageId }

        if ($existing) {
            Write-Verbose "Package já existe no estado, atualizando"
            $state.InstalledPackages = $state.InstalledPackages | Where-Object { $_.PackageId -ne $PackageId }
        }

        $state.InstalledPackages += $packageEntry

        if ($SessionId) {
            $session = $state.Sessions | Where-Object { $_.SessionId -eq $SessionId }
            if ($session) {
                $session.PackagesInstalled += $PackageId
            }
        }

        Save-InstallationState -State $state

        Write-Verbose "Package adicionado ao estado: $PackageName"

        return $true
    }
    catch {
        Write-Error "Erro ao adicionar package ao estado: $_"
        return $false
    }
}

function Remove-PackageFromState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageId
    )

    try {
        Write-Verbose "Removendo package do estado: $PackageId"

        $state = Get-InstallationState

        $state.InstalledPackages = $state.InstalledPackages | Where-Object { $_.PackageId -ne $PackageId }

        Save-InstallationState -State $state

        Write-Verbose "Package removido do estado: $PackageId"

        return $true
    }
    catch {
        Write-Error "Erro ao remover package do estado: $_"
        return $false
    }
}

function Get-InstalledPackagesFromState {
    [CmdletBinding()]
    param()

    try {
        $state = Get-InstallationState

        Write-Host "`nPackages instalados (via estado):" -ForegroundColor Cyan
        Write-Host "Total: $($state.InstalledPackages.Count)" -ForegroundColor White

        if ($state.InstalledPackages.Count -gt 0) {
            foreach ($pkg in $state.InstalledPackages) {
                Write-Host "  - $($pkg.PackageName) " -NoNewline -ForegroundColor Yellow
                Write-Host "($($pkg.Version)) " -NoNewline -ForegroundColor Gray
                Write-Host "via $($pkg.Manager)" -ForegroundColor Cyan
            }
        }

        return $state.InstalledPackages
    }
    catch {
        Write-Error "Erro ao obter packages instalados: $_"
        return @()
    }
}


function Restore-PreviousState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$SessionId
    )

    try {
        Write-Host "Iniciando restauração de estado anterior..." -ForegroundColor Cyan

        $state = Get-InstallationState

        if (-not $SessionId) {
            $sessions = $state.Sessions | Where-Object { $_.Status -eq 'Completed' } | Sort-Object StartTime -Descending
            if ($sessions.Count -eq 0) {
                throw "Nenhuma sessão completada encontrada para restaurar"
            }
            $SessionId = $sessions[0].SessionId
        }

        $session = $state.Sessions | Where-Object { $_.SessionId -eq $SessionId }

        if (-not $session) {
            throw "Sessão não encontrada: $SessionId"
        }

        Write-Host "Restaurando sessão: $($session.Description)" -ForegroundColor Yellow

        return Invoke-Rollback -SessionId $SessionId
    }
    catch {
        Write-Error "Erro ao restaurar estado: $_"
        return $false
    }
}

function Invoke-Rollback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SessionId
    )

    try {
        Write-Host "`nIniciando rollback da sessão: $SessionId" -ForegroundColor Yellow

        $state = Get-InstallationState

        $session = $state.Sessions | Where-Object { $_.SessionId -eq $SessionId }

        if (-not $session) {
            throw "Sessão não encontrada: $SessionId"
        }

        if ($session.PackagesInstalled.Count -eq 0) {
            Write-Host "Nenhum package para desinstalar nesta sessão" -ForegroundColor Yellow
            return $true
        }

        Write-Host "Packages a desinstalar: $($session.PackagesInstalled.Count)" -ForegroundColor Cyan

        $confirm = Read-Host "Deseja continuar com o rollback? (S/N)"
        if ($confirm -ne 'S' -and $confirm -ne 's') {
            Write-Host "Rollback cancelado" -ForegroundColor Yellow
            return $false
        }

        $successCount = 0
        $failCount = 0

        foreach ($packageId in $session.PackagesInstalled) {
            $packageInfo = $state.InstalledPackages | Where-Object { $_.PackageId -eq $packageId }

            if (-not $packageInfo) {
                Write-Warning "Package não encontrado no estado: $packageId"
                continue
            }

            Write-Host "Desinstalando $($packageInfo.PackageName)..." -ForegroundColor Cyan

            $result = Uninstall-PackageByManager -PackageId $packageInfo.PackageId -Manager $packageInfo.Manager

            if ($result) {
                Remove-PackageFromState -PackageId $packageId
                $successCount++
                Write-Host "  ✓ $($packageInfo.PackageName) desinstalado" -ForegroundColor Green
            }
            else {
                $failCount++
                Write-Host "  ✗ Falha ao desinstalar $($packageInfo.PackageName)" -ForegroundColor Red
            }
        }

        Write-Host "`nRollback concluído:" -ForegroundColor Cyan
        Write-Host "  Sucesso: $successCount" -ForegroundColor Green
        Write-Host "  Falhas: $failCount" -ForegroundColor Red

        return $failCount -eq 0
    }
    catch {
        Write-Error "Erro ao executar rollback: $_"
        return $false
    }
}

function Clear-FailedSessions {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Limpando sessões com falha..." -ForegroundColor Cyan

        $state = Get-InstallationState

        $failedSessions = $state.Sessions | Where-Object { $_.Status -eq 'Failed' }

        if ($failedSessions.Count -eq 0) {
            Write-Host "Nenhuma sessão com falha encontrada" -ForegroundColor Yellow
            return $true
        }

        Write-Host "Sessões com falha: $($failedSessions.Count)" -ForegroundColor Yellow

        foreach ($session in $failedSessions) {
            Write-Host "  - $($session.Description) ($($session.SessionId))" -ForegroundColor Gray
        }

        $confirm = Read-Host "Executar rollback de todas as sessões com falha? (S/N)"
        if ($confirm -ne 'S' -and $confirm -ne 's') {
            Write-Host "Operação cancelada" -ForegroundColor Yellow
            return $false
        }

        foreach ($session in $failedSessions) {
            Invoke-Rollback -SessionId $session.SessionId
        }

        return $true
    }
    catch {
        Write-Error "Erro ao limpar sessões com falha: $_"
        return $false
    }
}


function Uninstall-PackageByManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageId,

        [Parameter(Mandatory=$true)]
        [ValidateSet('chocolatey', 'winget', 'scoop', 'unknown')]
        [string]$Manager
    )

    try {
        Write-Verbose "Desinstalando $PackageId via $Manager"

        switch ($Manager) {
            'chocolatey' {
                if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                    throw "Chocolatey não está instalado"
                }

                choco uninstall $PackageId -y --no-progress 2>&1 | Out-Null

                if ($LASTEXITCODE -eq 0) {
                    return $true
                }
                else {
                    Write-Warning "Chocolatey retornou código de erro: $LASTEXITCODE"
                    return $false
                }
            }
            'winget' {
                if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                    throw "Winget não está instalado"
                }

                winget uninstall --id $PackageId --silent 2>&1 | Out-Null

                if ($LASTEXITCODE -eq 0) {
                    return $true
                }
                else {
                    Write-Warning "Winget retornou código de erro: $LASTEXITCODE"
                    return $false
                }
            }
            'scoop' {
                if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                    throw "Scoop não está instalado"
                }

                scoop uninstall $PackageId 2>&1 | Out-Null

                if ($LASTEXITCODE -eq 0) {
                    return $true
                }
                else {
                    Write-Warning "Scoop retornou código de erro: $LASTEXITCODE"
                    return $false
                }
            }
            default {
                Write-Warning "Gerenciador desconhecido: $Manager. Não é possível desinstalar."
                return $false
            }
        }
    }
    catch {
        Write-Error "Erro ao desinstalar package: $_"
        return $false
    }
}


function Initialize-State {
    return Initialize-InstallationState
}

function Get-StateData {
    return Get-InstallationState
}

function Update-StateData {
    param([array]$InstalledPackages)

    $state = Get-InstallationState

    $state.InstalledPackages = $InstalledPackages | ForEach-Object {
        [PSCustomObject]@{
            PackageId = $_
            PackageName = $_
            Version = "unknown"
            Manager = "unknown"
            InstalledAt = (Get-Date).ToString("o")
            SessionId = $null
        }
    }

    Save-InstallationState -State $state
}

function Add-InstalledPackage {
    param([string]$PackageName)

    Add-InstalledPackageToState -PackageId $PackageName -PackageName $PackageName
}

function Get-InstalledPackages {
    $state = Get-InstallationState
    if ($state -and $state.InstalledPackages) {
        return $state.InstalledPackages | Select-Object -ExpandProperty PackageName
    }
    return @()
}

function Test-PackageInState {
    param([string]$PackageName)

    $installed = Get-InstalledPackages
    return $installed -contains $PackageName
}

function Compare-StateWithSystem {
    $statePackages = Get-InstalledPackages
    $actualPackages = @()

    foreach ($pkg in $statePackages) {
        if (Test-PackageInstalled -PackageName $pkg) {
            $actualPackages += $pkg
        }
    }

    if ($actualPackages.Count -ne $statePackages.Count) {
        Update-StateData -InstalledPackages $actualPackages
        Write-Log "Estado sincronizado com sistema" "INFO"
    }

    return $actualPackages
}