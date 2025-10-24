function Install-Git {
    [CmdletBinding()]
    param()

    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            Write-Host "Git já está instalado" -ForegroundColor Yellow
            return $true
        }

        Write-Host "Instalando Git..." -ForegroundColor Cyan

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        }
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install git -y --no-progress 2>&1 | Out-Null
        }
        else {
            throw "Winget ou Chocolatey necessário"
        }

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        if (Get-Command git -ErrorAction SilentlyContinue) {
            Write-Host "✓ Git instalado com sucesso" -ForegroundColor Green
            return $true
        }

        return $false
    }
    catch {
        Write-Error "Erro ao instalar Git: $_"
        return $false
    }
}

function Configure-GitUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Email
    )

    try {
        git config --global user.name $Name
        git config --global user.email $Email

        Write-Host "✓ Usuário Git configurado" -ForegroundColor Green
        Write-Host "  Nome: $Name" -ForegroundColor Gray
        Write-Host "  Email: $Email" -ForegroundColor Gray

        return $true
    }
    catch {
        Write-Error "Erro ao configurar usuário Git: $_"
        return $false
    }
}

function Set-GitAliases {
    [CmdletBinding()]
    param()

    try {
        $aliases = @{
            'st' = 'status'
            'co' = 'checkout'
            'br' = 'branch'
            'ci' = 'commit'
            'unstage' = 'reset HEAD --'
            'last' = 'log -1 HEAD'
            'visual' = '!gitk'
        }

        foreach ($alias in $aliases.Keys) {
            git config --global alias.$alias $aliases[$alias]
        }

        Write-Host "✓ Aliases Git configurados" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erro ao configurar aliases: $_"
        return $false
    }
}

function Configure-GitCredentials {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('manager-core', 'wincred', 'cache')]
        [string]$Helper = 'manager-core'
    )

    try {
        git config --global credential.helper $Helper

        Write-Host "✓ Git credential helper configurado: $Helper" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erro ao configurar credentials: $_"
        return $false
    }
}

function Import-GitAliases {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ConfigPath = "$PSScriptRoot\..\config\git-config\aliases.gitconfig"
    )

    try {
        if (-not (Test-Path $ConfigPath)) {
            Write-Warning "Arquivo de config não encontrado: $ConfigPath"
            return $false
        }

        git config --global --add include.path $ConfigPath

        Write-Host "✓ Aliases importados de: $ConfigPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erro ao importar aliases: $_"
        return $false
    }
}

function Initialize-GitConfig {
    [CmdletBinding()]
    param()

    try {
        git config --global init.defaultBranch main
        git config --global core.autocrlf true
        git config --global pull.rebase false
        git config --global core.editor "code --wait"

        Write-Host "✓ Configurações Git padrão aplicadas" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erro ao inicializar config: $_"
        return $false
    }
}