function Export-Dotfiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination
    )

    try {
        Write-Host "Exportando dotfiles..." -ForegroundColor Cyan

        if (-not (Test-Path $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }

        $dotfiles = @(
            @{ Source = $PROFILE; Dest = "PowerShell\profile.ps1" }
            @{ Source = "$env:USERPROFILE\.gitconfig"; Dest = ".gitconfig" }
            @{ Source = "$env:APPDATA\bat\config"; Dest = "bat\config" }
            @{ Source = "$env:USERPROFILE\.config\starship.toml"; Dest = "starship.toml" }
        )

        $exported = 0

        foreach ($file in $dotfiles) {
            if (Test-Path $file.Source) {
                $destPath = Join-Path $Destination $file.Dest
                $destDir = Split-Path $destPath -Parent

                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }

                Copy-Item -Path $file.Source -Destination $destPath -Force
                $exported++
                Write-Host "  ✓ $($file.Dest)" -ForegroundColor Green
            }
        }

        Write-Host "`n✓ $exported dotfiles exportados para: $Destination" -ForegroundColor Green
        return $Destination
    }
    catch {
        Write-Error "Erro ao exportar dotfiles: $_"
        return $null
    }
}

function Import-Dotfiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Source
    )

    try {
        Write-Host "Importando dotfiles de: $Source..." -ForegroundColor Cyan

        if (-not (Test-Path $Source)) {
            throw "Diretório não encontrado: $Source"
        }

        $dotfiles = @(
            @{ Source = "PowerShell\profile.ps1"; Dest = $PROFILE }
            @{ Source = ".gitconfig"; Dest = "$env:USERPROFILE\.gitconfig" }
            @{ Source = "bat\config"; Dest = "$env:APPDATA\bat\config" }
            @{ Source = "starship.toml"; Dest = "$env:USERPROFILE\.config\starship.toml" }
        )

        $imported = 0

        foreach ($file in $dotfiles) {
            $sourcePath = Join-Path $Source $file.Source

            if (Test-Path $sourcePath) {
                $destDir = Split-Path $file.Dest -Parent

                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }

                Copy-Item -Path $sourcePath -Destination $file.Dest -Force
                $imported++
                Write-Host "  ✓ $($file.Source)" -ForegroundColor Green
            }
        }

        Write-Host "`n✓ $imported dotfiles importados" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erro ao importar dotfiles: $_"
        return $false
    }
}

function Sync-Dotfiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RemoteRepo
    )

    try {
        Write-Host "Sincronizando dotfiles com: $RemoteRepo..." -ForegroundColor Cyan

        $dotfilesDir = Join-Path $env:USERPROFILE "dotfiles"

        if (-not (Test-Path $dotfilesDir)) {
            git clone $RemoteRepo $dotfilesDir
            Write-Host "✓ Repositório clonado" -ForegroundColor Green
        }
        else {
            Push-Location $dotfilesDir
            git pull origin main
            Pop-Location
            Write-Host "✓ Repositório atualizado" -ForegroundColor Green
        }

        Import-Dotfiles -Source $dotfilesDir

        return $true
    }
    catch {
        Write-Error "Erro ao sincronizar dotfiles: $_"
        return $false
    }
}

function Initialize-DotfilesRepo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RemoteUrl
    )

    try {
        $dotfilesDir = Join-Path $env:USERPROFILE "dotfiles"

        if (Test-Path $dotfilesDir) {
            Write-Host "Repositório dotfiles já existe em: $dotfilesDir" -ForegroundColor Yellow
            return $dotfilesDir
        }

        New-Item -ItemType Directory -Path $dotfilesDir -Force | Out-Null

        Export-Dotfiles -Destination $dotfilesDir

        Push-Location $dotfilesDir

        git init
        git add .
        git commit -m "Initial dotfiles commit"
        git branch -M main
        git remote add origin $RemoteUrl
        git push -u origin main

        Pop-Location

        Write-Host "✓ Repositório dotfiles inicializado: $dotfilesDir" -ForegroundColor Green
        return $dotfilesDir
    }
    catch {
        Write-Error "Erro ao inicializar repositório: $_"
        Pop-Location
        return $null
    }
}

function Push-Dotfiles {
    [CmdletBinding()]
    param()

    try {
        $dotfilesDir = Join-Path $env:USERPROFILE "dotfiles"

        if (-not (Test-Path $dotfilesDir)) {
            throw "Repositório dotfiles não encontrado. Execute Initialize-DotfilesRepo primeiro."
        }

        Export-Dotfiles -Destination $dotfilesDir

        Push-Location $dotfilesDir

        git add .
        git commit -m "Update dotfiles $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        git push origin main

        Pop-Location

        Write-Host "✓ Dotfiles enviados para o repositório" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erro ao enviar dotfiles: $_"
        Pop-Location
        return $false
    }
}

function Pull-Dotfiles {
    [CmdletBinding()]
    param()

    try {
        $dotfilesDir = Join-Path $env:USERPROFILE "dotfiles"

        if (-not (Test-Path $dotfilesDir)) {
            throw "Repositório dotfiles não encontrado"
        }

        Push-Location $dotfilesDir
        git pull origin main
        Pop-Location

        Import-Dotfiles -Source $dotfilesDir

        Write-Host "✓ Dotfiles atualizados do repositório" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erro ao atualizar dotfiles: $_"
        Pop-Location
        return $false
    }
}