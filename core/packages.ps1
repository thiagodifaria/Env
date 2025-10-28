function Get-BestPackageManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [PSCustomObject]$Package
    )

    try {
        Write-Verbose "Determinando melhor gerenciador de pacotes para $($Package.name)"

        $availableManagers = @()

        if (Get-Command choco -ErrorAction SilentlyContinue) {
            $availableManagers += @{
                Name = 'chocolatey'
                Priority = 1
                Available = $true
            }
        }

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            $availableManagers += @{
                Name = 'winget'
                Priority = 2
                Available = $true
            }
        }

        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            $availableManagers += @{
                Name = 'scoop'
                Priority = 3
                Available = $true
            }
        }

        if ($availableManagers.Count -eq 0) {
            throw "Nenhum gerenciador de pacotes disponível"
        }

        if ($Package.managers) {
            foreach ($manager in $Package.managers) {
                $available = $availableManagers | Where-Object { $_.Name -eq $manager.type }
                if ($available) {
                    Write-Verbose "Selecionado: $($manager.type)"
                    return @{
                        Type = $manager.type
                        Id = $manager.id
                        Priority = if ($manager.priority) { $manager.priority } else { 1 }
                    }
                }
            }
        }

        if ($Package.choco_package -and ($availableManagers | Where-Object { $_.Name -eq 'chocolatey' })) {
            return @{ Type = 'chocolatey'; Id = $Package.choco_package; Priority = 1 }
        }

        if ($Package.winget_id -and ($availableManagers | Where-Object { $_.Name -eq 'winget' })) {
            return @{ Type = 'winget'; Id = $Package.winget_id; Priority = 2 }
        }

        if ($Package.scoop_name -and ($availableManagers | Where-Object { $_.Name -eq 'scoop' })) {
            return @{ Type = 'scoop'; Id = $Package.scoop_name; Priority = 3 }
        }

        throw "Nenhum gerenciador compatível encontrado para $($Package.name)"
    }
    catch {
        Write-Error "Erro ao determinar gerenciador: $_"
        throw
    }
}

function Install-PackageWithFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [PSCustomObject]$Package
    )

    try {
        Write-Verbose "Instalando package com fallback: $($Package.name)"

        $managers = @()

        if ($Package.managers) {
            $managers = $Package.managers | Sort-Object -Property priority
        }
        else {
            if ($Package.choco_package) {
                $managers += @{ type = 'chocolatey'; id = $Package.choco_package; priority = 1 }
            }
            if ($Package.winget_id) {
                $managers += @{ type = 'winget'; id = $Package.winget_id; priority = 2 }
            }
            if ($Package.scoop_name) {
                $managers += @{ type = 'scoop'; id = $Package.scoop_name; priority = 3 }
            }
        }

        if ($managers.Count -eq 0) {
            throw "Nenhum gerenciador configurado para $($Package.name)"
        }

        $lastError = $null

        foreach ($manager in $managers) {
            try {
                Write-Host "Tentando instalar $($Package.name) via $($manager.type)..." -ForegroundColor Cyan

                $result = Install-PackageWithManager -Package $Package -Manager $manager

                if ($result.Success) {
                    Write-Host "[OK] $($Package.name) instalado com sucesso via $($manager.type)" -ForegroundColor Green
                    return @{
                        Success = $true
                        Manager = $manager.type
                        PackageName = $Package.name
                    }
                }
            }
            catch {
                $lastError = $_
                Write-Warning "Falha ao instalar via $($manager.type): $_"
                continue
            }
        }

        throw "Todas as tentativas de instalação falharam para $($Package.name). Último erro: $lastError"
    }
    catch {
        Write-Error "Erro ao instalar package: $_"
        return @{
            Success = $false
            PackageName = $Package.name
            Error = $_.Exception.Message
        }
    }
}

function Install-PackageWithManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [PSCustomObject]$Package,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [PSCustomObject]$Manager
    )

    try {
        Write-Verbose "Instalando $($Package.name) via $($Manager.type)"

        switch ($Manager.type) {
            'chocolatey' {
                if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                    throw "Chocolatey não está instalado"
                }

                $packageArgs = @($Manager.id, '-y', '--no-progress')

                if ($Package.checksum -and $Package.checksum -ne "") {
                    $packageArgs += "--checksum=$($Package.checksum)"
                    $packageArgs += "--checksum-type=$($Package.checksumType)"
                }

                choco install @packageArgs 2>&1 | Out-Null

                if ($LASTEXITCODE -eq 0) {
                    return @{ Success = $true }
                }
                else {
                    throw "Chocolatey retornou código de erro: $LASTEXITCODE"
                }
            }
            'winget' {
                if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                    throw "Winget não está instalado"
                }

                winget install --id $Manager.id --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null

                if ($LASTEXITCODE -eq 0) {
                    return @{ Success = $true }
                }
                else {
                    throw "Winget retornou código de erro: $LASTEXITCODE"
                }
            }
            'scoop' {
                if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                    throw "Scoop não está instalado"
                }

                scoop install $Manager.id 2>&1 | Out-Null

                if ($LASTEXITCODE -eq 0) {
                    return @{ Success = $true }
                }
                else {
                    throw "Scoop retornou código de erro: $LASTEXITCODE"
                }
            }
            default {
                throw "Gerenciador desconhecido: $($Manager.type)"
            }
        }
    }
    catch {
        Write-Error "Erro ao instalar via $($Manager.type): $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Test-PackageManagerHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('chocolatey', 'winget', 'scoop', 'all')]
        [string]$Manager = 'all'
    )

    try {
        $results = @{}

        if ($Manager -eq 'all' -or $Manager -eq 'chocolatey') {
            $chocoAvailable = $null -ne (Get-Command choco -ErrorAction SilentlyContinue)
            $results.chocolatey = @{
                Available = $chocoAvailable
                Healthy = $chocoAvailable
            }
        }

        if ($Manager -eq 'all' -or $Manager -eq 'winget') {
            $wingetAvailable = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
            $results.winget = @{
                Available = $wingetAvailable
                Healthy = $wingetAvailable
            }
        }

        if ($Manager -eq 'all' -or $Manager -eq 'scoop') {
            $scoopAvailable = $null -ne (Get-Command scoop -ErrorAction SilentlyContinue)
            $results.scoop = @{
                Available = $scoopAvailable
                Healthy = $scoopAvailable
            }
        }

        Write-Verbose "Package manager health check completo"
        return $results
    }
    catch {
        Write-Error "Erro ao verificar saúde dos gerenciadores: $_"
        return $null
    }
}