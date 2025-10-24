function Test-PackageInstalled {
    param(
        [string]$PackageName,
        [string]$Command = $null
    )

    $chocoInstalled = Test-ChocoPackage -PackageName $PackageName

    if ($chocoInstalled) {
        return $true
    }

    if ($Command) {
        $commandExists = Test-CommandAvailable -Command $Command
        if ($commandExists) {
            return $true
        }
    }

    return $false
}

function Test-ChocoPackage {
    param([string]$PackageName)

    try {
        $installed = choco list --local-only $PackageName --exact --limit-output 2>$null
        return $installed -match "^$PackageName\|"
    }
    catch {
        return $false
    }
}

function Test-CommandAvailable {
    param([string]$Command)

    $result = Get-Command $Command -ErrorAction SilentlyContinue
    return $null -ne $result
}

function Test-ServiceRunning {
    param([string]$ServiceName)

    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        return $service.Status -eq "Running"
    }
    catch {
        return $false
    }
}

function Get-InstalledVersion {
    param([string]$PackageName)

    try {
        $output = choco list --local-only $PackageName --exact --limit-output 2>$null
        if ($output -match "^$PackageName\|(.+)$") {
            return $matches[1]
        }
    }
    catch {
        return "Unknown"
    }

    return "Unknown"
}


function Test-FileChecksum {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ExpectedHash,

        [Parameter(Mandatory=$false)]
        [ValidateSet('SHA256', 'SHA1', 'MD5', 'SHA512')]
        [string]$Algorithm = 'SHA256'
    )

    try {
        if (-not (Test-Path $FilePath)) {
            throw "Arquivo não encontrado: $FilePath"
        }

        Write-Verbose "Calculando hash $Algorithm para $FilePath"
        $fileHash = (Get-FileHash -Path $FilePath -Algorithm $Algorithm).Hash

        $match = $fileHash -eq $ExpectedHash

        if ($match) {
            Write-Verbose "Checksum validado com sucesso"
        }
        else {
            Write-Warning "Checksum não corresponde!"
            Write-Warning "Esperado: $ExpectedHash"
            Write-Warning "Obtido:   $fileHash"
        }

        return $match
    }
    catch {
        Write-Error "Erro ao validar checksum: $_"
        throw
    }
}

function Get-PackageChecksum {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageId,

        [Parameter(Mandatory=$false)]
        [ValidateSet('chocolatey', 'winget', 'scoop')]
        [string]$Source = 'chocolatey'
    )

    try {
        Write-Verbose "Obtendo checksum para $PackageId de $Source"

        switch ($Source) {
            'chocolatey' {
                if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                    throw "Chocolatey não está instalado"
                }

                $info = choco info $PackageId --limit-output 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Package não encontrado: $PackageId"
                }

                return @{
                    Source = 'chocolatey'
                    PackageId = $PackageId
                    Available = $true
                }
            }
            'winget' {
                if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                    throw "Winget não está instalado"
                }

                $info = winget show $PackageId 2>&1
                if ($LASTEXITCODE -ne 0) {
                    throw "Package não encontrado: $PackageId"
                }

                return @{
                    Source = 'winget'
                    PackageId = $PackageId
                    Available = $true
                }
            }
            'scoop' {
                if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                    throw "Scoop não está instalado"
                }

                return @{
                    Source = 'scoop'
                    PackageId = $PackageId
                    Available = $true
                }
            }
        }
    }
    catch {
        Write-Error "Erro ao obter checksum: $_"
        return @{
            Source = $Source
            PackageId = $PackageId
            Available = $false
            Error = $_.Exception.Message
        }
    }
}

function Show-SecurityDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$PackageName = "Package"
    )

    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host "  AVISO DE SEGURANÇA" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Package: $PackageName" -ForegroundColor Cyan
    Write-Host "Problema: $Message" -ForegroundColor Yellow
    Write-Host "`nOpções:" -ForegroundColor White
    Write-Host "  [A] Abortar instalação" -ForegroundColor Red
    Write-Host "  [C] Continuar mesmo assim" -ForegroundColor Yellow
    Write-Host "  [P] Pular este package" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Yellow

    do {
        $choice = Read-Host "Escolha uma opção (A/C/P)"
        $choice = $choice.ToUpper()
    } while ($choice -notin @('A', 'C', 'P'))

    return $choice
}


function Test-JsonSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$JsonPath,

        [Parameter(Mandatory=$false)]
        [string]$SchemaPath
    )

    try {
        if (-not (Test-Path $JsonPath)) {
            throw "Arquivo JSON não encontrado: $JsonPath"
        }

        Write-Verbose "Validando JSON: $JsonPath"
        $jsonContent = Get-Content $JsonPath -Raw

        try {
            $null = $jsonContent | ConvertFrom-Json -ErrorAction Stop
            Write-Verbose "JSON possui sintaxe válida"
        }
        catch {
            throw "Erro de sintaxe no JSON: $($_.Exception.Message)"
        }

        if ($SchemaPath -and (Test-Path $SchemaPath)) {
            Write-Verbose "Schema encontrado: $SchemaPath"
            Write-Host "Validação contra schema disponível em: $SchemaPath" -ForegroundColor Cyan
        }

        Write-Host "JSON validado com sucesso" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erro ao validar JSON: $_"
        return $false
    }
}

function Test-PackagesConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ConfigPath = "$PSScriptRoot\..\config\packages.json",

        [Parameter(Mandatory=$false)]
        [string]$SchemaPath = "$PSScriptRoot\..\config\packages.schema.json"
    )

    try {
        Write-Verbose "Validando configuração de packages"

        if (-not (Test-Path $ConfigPath)) {
            throw "Arquivo de configuração não encontrado: $ConfigPath"
        }

        $valid = Test-JsonSchema -JsonPath $ConfigPath -SchemaPath $SchemaPath

        if ($valid) {
            $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            $totalPackages = 0

            foreach ($category in $config.PSObject.Properties.Name) {
                if ($config.$category -is [Array]) {
                    $totalPackages += $config.$category.Count
                }
            }

            Write-Host "Configuração válida: $totalPackages packages em $($config.PSObject.Properties.Count) categorias" -ForegroundColor Green
        }

        return $valid
    }
    catch {
        Write-Error "Erro ao validar configuração: $_"
        return $false
    }
}


function Test-ConflictingPackages {
    param([array]$PackageList)

    $conflicts = @()

    $conflictMap = @{
        "python" = @("python", "python3")
        "nodejs" = @("nodejs", "node")
    }

    foreach ($pkg in $PackageList) {
        if ($pkg -match "python") {
            $storePython = Get-Command python -ErrorAction SilentlyContinue | Where-Object { $_.Source -match "WindowsApps" }
            if ($storePython) {
                $conflicts += @{
                    Package = $pkg
                    Conflict = "Python from Microsoft Store"
                    Action = "Remove Store version or skip Chocolatey install"
                }
            }
        }
    }

    return $conflicts
}

function Show-ConflictDialog {
    param(
        [hashtable]$Conflict,
        [string]$Language = "pt-br"
    )

    Write-Host ""
    Write-Host "⚠ Conflito detectado:" -ForegroundColor Yellow
    Write-Host "  Package: $($Conflict.Package)" -ForegroundColor White
    Write-Host "  Conflito: $($Conflict.Conflict)" -ForegroundColor White
    Write-Host "  Ação: $($Conflict.Action)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Escolha uma opção:" -ForegroundColor Yellow
    Write-Host "  [S] Skip - Pular instalação" -ForegroundColor White
    Write-Host "  [R] Replace - Substituir existente" -ForegroundColor White
    Write-Host "  [C] Cancel - Cancelar tudo" -ForegroundColor White
    Write-Host ""
    Write-Host "Opção: " -ForegroundColor Yellow -NoNewline

    $choice = Read-Host
    return $choice.ToUpper()
}

function Resolve-Conflicts {
    param(
        [array]$Conflicts,
        [string]$Language = "pt-br"
    )

    $resolutions = @()

    foreach ($conflict in $Conflicts) {
        $choice = Show-ConflictDialog -Conflict $conflict -Language $Language

        switch ($choice) {
            "S" {
                $resolutions += @{
                    Package = $conflict.Package
                    Action = "Skip"
                }
                Write-Status "Pulando $($conflict.Package)" "SKIP"
            }
            "R" {
                $resolutions += @{
                    Package = $conflict.Package
                    Action = "Replace"
                }
                Write-Status "Substituindo $($conflict.Package)" "WARNING"
            }
            "C" {
                Write-Host ""
                Write-Host "Instalação cancelada pelo usuário" -ForegroundColor Red
                exit 0
            }
            default {
                Write-Status "Opção inválida, pulando $($conflict.Package)" "SKIP"
                $resolutions += @{
                    Package = $conflict.Package
                    Action = "Skip"
                }
            }
        }
        Write-Host ""
    }

    return $resolutions
}


function Get-ValidationReport {
    param(
        [array]$PackagesToInstall,
        [string]$Language = "pt-br"
    )

    Write-Host ""
    Write-Host "Analisando sistema..." -ForegroundColor Yellow
    Write-Host ""

    $report = @{
        AlreadyInstalled = @()
        ToInstall = @()
        Conflicts = @()
    }

    $current = 0
    foreach ($pkg in $PackagesToInstall) {
        $current++
        Show-ProgressBar -Current $current -Total $PackagesToInstall.Count -Activity "Verificando $($pkg.name)..."

        if (Test-PackageInstalled -PackageName $pkg.choco_package -Command $pkg.command) {
            $report.AlreadyInstalled += $pkg
        } else {
            $report.ToInstall += $pkg
        }

        Start-Sleep -Milliseconds 100
    }

    Write-Host ""
    Write-Host ""

    if ($report.ToInstall.Count -gt 0) {
        $conflicts = Test-ConflictingPackages -PackageList $report.ToInstall.choco_package
        $report.Conflicts = $conflicts
    }

    return $report
}

function Show-ValidationReport {
    param(
        [hashtable]$Report,
        [string]$Language = "pt-br"
    )

    Write-Host "       RELATÓRIO DE VALIDAÇÃO           " -ForegroundColor Cyan
    Write-Host ""

    if ($Report.AlreadyInstalled.Count -gt 0) {
        Write-Host "✓ Já instalados: $($Report.AlreadyInstalled.Count) pacotes" -ForegroundColor Green
        foreach ($pkg in $Report.AlreadyInstalled | Select-Object -First 5) {
            Write-Host "  ⟲ $($pkg.name)" -ForegroundColor Cyan
        }
        if ($Report.AlreadyInstalled.Count -gt 5) {
            Write-Host "  ... e mais $($Report.AlreadyInstalled.Count - 5) pacotes" -ForegroundColor Gray
        }
        Write-Host ""
    }

    if ($Report.ToInstall.Count -gt 0) {
        Write-Host "➜ Serão instalados: $($Report.ToInstall.Count) pacotes" -ForegroundColor Yellow
        foreach ($pkg in $Report.ToInstall | Select-Object -First 5) {
            Write-Host "  • $($pkg.name)" -ForegroundColor White
        }
        if ($Report.ToInstall.Count -gt 5) {
            Write-Host "  ... e mais $($Report.ToInstall.Count - 5) pacotes" -ForegroundColor Gray
        }
        Write-Host ""
    }

    if ($Report.Conflicts.Count -gt 0) {
        Write-Host "⚠ Conflitos detectados: $($Report.Conflicts.Count)" -ForegroundColor Yellow
        foreach ($conflict in $Report.Conflicts) {
            Write-Host "  ⚠ $($conflict.Package) - $($conflict.Conflict)" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    $totalPackages = $Report.AlreadyInstalled.Count + $Report.ToInstall.Count
    Write-Host "Total de pacotes: $totalPackages" -ForegroundColor White
    Write-Host ""
}