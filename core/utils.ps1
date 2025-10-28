function Test-Administrator {
    [CmdletBinding()]
    param()

    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        Write-Verbose "Administrator check: $isAdmin"
        return $isAdmin
    }
    catch {
        Write-Error "Erro ao verificar privilégios de administrador: $_"
        return $false
    }
}

function Test-DiskSpace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 1000)]
        [int]$RequiredGB = 30
    )

    try {
        Write-Verbose "Verificando espaço em disco (mínimo: $RequiredGB GB)"

        $drive = Get-PSDrive C -ErrorAction Stop
        $freeGB = [math]::Round($drive.Free / 1GB, 2)

        Write-Verbose "Espaço livre: $freeGB GB"

        $hasSpace = $freeGB -ge $RequiredGB

        if (-not $hasSpace) {
            Write-Warning "Espaço insuficiente. Disponível: $freeGB GB, Necessário: $RequiredGB GB"
        }

        return $hasSpace
    }
    catch {
        Write-Error "Erro ao verificar espaço em disco: $_"
        return $false
    }
}

function Test-NetworkConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$TestHost = "google.com",

        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 10)]
        [int]$Count = 1
    )

    try {
        Write-Verbose "Testando conectividade com $TestHost"

        $result = Test-Connection -ComputerName $TestHost -Count $Count -Quiet -ErrorAction Stop

        if ($result) {
            Write-Verbose "Conexão com $TestHost bem-sucedida"
        }
        else {
            Write-Warning "Falha ao conectar com $TestHost"
        }

        return $result
    }
    catch {
        Write-Error "Erro ao testar conexão: $_"
        return $false
    }
}

function Install-Chocolatey {
    [CmdletBinding()]
    param()

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Verbose "Chocolatey já está instalado"
        return $true
    }

    $tempFile = $null

    try {
        Write-Verbose "Iniciando instalação segura do Chocolatey"

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $installUrl = 'https://community.chocolatey.org/install.ps1'
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"

        Write-Verbose "Baixando script de instalação para $tempFile"
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($installUrl, $tempFile)

        Write-Verbose "Calculando hash SHA256 do arquivo baixado"
        $fileHash = (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash

        Write-Verbose "Hash calculado: $fileHash"
        Write-Host "Verificando integridade do instalador Chocolatey..." -ForegroundColor Yellow
        Write-Host "SHA256: $fileHash" -ForegroundColor Cyan
        Write-Host "Verifique em: https://community.chocolatey.org/install.ps1" -ForegroundColor Cyan

        $continue = Read-Host "Continuar com a instalação? (S/N)"
        if ($continue -ne 'S' -and $continue -ne 's') {
            Write-Host "Instalação cancelada pelo usuário" -ForegroundColor Yellow
            return $false
        }

        Set-ExecutionPolicy Bypass -Scope Process -Force

        Write-Verbose "Executando script de instalação"
        & $tempFile

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Host "Chocolatey instalado com sucesso" -ForegroundColor Green
            return $true
        }
        else {
            throw "Chocolatey foi executado mas não está disponível no PATH"
        }
    }
    catch {
        Write-Error "Erro ao instalar Chocolatey: $_"
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Erro ao instalar Chocolatey: $($_.Exception.Message)" "ERROR"
        }
        return $false
    }
    finally {
        if ($tempFile -and (Test-Path $tempFile)) {
            Write-Verbose "Limpando arquivo temporário: $tempFile"
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-SystemInfo {
    [CmdletBinding()]
    param()

    try {
        Write-Verbose "Coletando informações do sistema"

        $os = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption
        $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory / 1GB, 2)
        $diskGB = [math]::Round((Get-PSDrive C -ErrorAction Stop).Free / 1GB, 2)
        $psVersion = $PSVersionTable.PSVersion.ToString()

        $systemInfo = @{
            OS = $os
            RAM = "$ramGB GB"
            Disk = "$diskGB GB"
            PowerShell = $psVersion
        }

        Write-Verbose "Informações do sistema coletadas com sucesso"

        return $systemInfo
    }
    catch {
        Write-Error "Erro ao coletar informações do sistema: $_"
        return $null
    }
}

function Get-String {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory=$false)]
        [ValidateSet("pt-br", "en-us", "es")]
        [string]$Language = "pt-br"
    )

    try {
        Write-Verbose "Obtendo string '$Key' para idioma '$Language'"

        $stringsPath = "$PSScriptRoot\..\config\strings.json"

        if (-not (Test-Path $stringsPath)) {
            Write-Warning "Arquivo de strings não encontrado: $stringsPath"
            return $Key
        }

        $strings = Get-Content $stringsPath -Raw -ErrorAction Stop | ConvertFrom-Json

        if ($strings.PSObject.Properties.Name -contains $Language) {
            if ($strings.$Language.PSObject.Properties.Name -contains $Key) {
                return $strings.$Language.$Key
            }
            else {
                Write-Warning "Chave '$Key' não encontrada para idioma '$Language'"
                return $Key
            }
        }
        else {
            Write-Warning "Idioma '$Language' não encontrado"
            return $Key
        }
    }
    catch {
        Write-Error "Erro ao obter string: $_"
        return $Key
    }
}