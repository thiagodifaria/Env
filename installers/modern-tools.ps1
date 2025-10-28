function Install-Bat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    try {
        Write-Host "Instalando bat (cat melhorado)..." -ForegroundColor Cyan

        if ((Get-Command bat -ErrorAction SilentlyContinue) -and -not $Force) {
            Write-Host "bat já está instalado" -ForegroundColor Yellow
            return $true
        }

        if (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install bat -y --no-progress 2>&1 | Out-Null
        }
        elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop install bat 2>&1 | Out-Null
        }
        else {
            throw "Nenhum gerenciador de pacotes disponível"
        }

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        if (Get-Command bat -ErrorAction SilentlyContinue) {
            Write-Host "[OK] bat instalado com sucesso" -ForegroundColor Green
            return $true
        }
        else {
            throw "bat foi instalado mas não está disponível"
        }
    }
    catch {
        Write-Error "Erro ao instalar bat: $_"
        return $false
    }
}

function Install-Eza {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    try {
        Write-Host "Instalando eza (ls moderno)..." -ForegroundColor Cyan

        if ((Get-Command eza -ErrorAction SilentlyContinue) -and -not $Force) {
            Write-Host "eza já está instalado" -ForegroundColor Yellow
            return $true
        }

        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop install eza 2>&1 | Out-Null
        }
        elseif (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install eza-community.eza --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        }
        else {
            throw "Scoop ou Winget necessário para instalar eza"
        }

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        if (Get-Command eza -ErrorAction SilentlyContinue) {
            Write-Host "[OK] eza instalado com sucesso" -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "eza pode ter sido instalado mas não está disponível no PATH"
            return $false
        }
    }
    catch {
        Write-Error "Erro ao instalar eza: $_"
        return $false
    }
}

function Install-Fzf {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    try {
        Write-Host "Instalando fzf (fuzzy finder)..." -ForegroundColor Cyan

        if ((Get-Command fzf -ErrorAction SilentlyContinue) -and -not $Force) {
            Write-Host "fzf já está instalado" -ForegroundColor Yellow
            return $true
        }

        if (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install fzf -y --no-progress 2>&1 | Out-Null
        }
        elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop install fzf 2>&1 | Out-Null
        }
        else {
            throw "Chocolatey ou Scoop necessário"
        }

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        if (Get-Command fzf -ErrorAction SilentlyContinue) {
            Write-Host "[OK] fzf instalado com sucesso" -ForegroundColor Green
            return $true
        }
        else {
            throw "fzf foi instalado mas não está disponível"
        }
    }
    catch {
        Write-Error "Erro ao instalar fzf: $_"
        return $false
    }
}

function Install-Ripgrep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    try {
        Write-Host "Instalando ripgrep (grep ultra-rápido)..." -ForegroundColor Cyan

        if ((Get-Command rg -ErrorAction SilentlyContinue) -and -not $Force) {
            Write-Host "ripgrep já está instalado" -ForegroundColor Yellow
            return $true
        }

        if (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install ripgrep -y --no-progress 2>&1 | Out-Null
        }
        elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop install ripgrep 2>&1 | Out-Null
        }
        else {
            throw "Chocolatey ou Scoop necessário"
        }

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        if (Get-Command rg -ErrorAction SilentlyContinue) {
            Write-Host "[OK] ripgrep instalado com sucesso" -ForegroundColor Green
            return $true
        }
        else {
            throw "ripgrep foi instalado mas não está disponível"
        }
    }
    catch {
        Write-Error "Erro ao instalar ripgrep: $_"
        return $false
    }
}

function Install-Zoxide {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    try {
        Write-Host "Instalando zoxide (cd inteligente)..." -ForegroundColor Cyan

        if ((Get-Command zoxide -ErrorAction SilentlyContinue) -and -not $Force) {
            Write-Host "zoxide já está instalado" -ForegroundColor Yellow
            return $true
        }

        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            scoop install zoxide 2>&1 | Out-Null
        }
        elseif (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install ajeetdsouza.zoxide --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        }
        else {
            throw "Scoop ou Winget necessário"
        }

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        if (Get-Command zoxide -ErrorAction SilentlyContinue) {
            Write-Host "[OK] zoxide instalado com sucesso" -ForegroundColor Green
            return $true
        }
        else {
            throw "zoxide foi instalado mas não está disponível"
        }
    }
    catch {
        Write-Error "Erro ao instalar zoxide: $_"
        return $false
    }
}

function Install-AllModernTools {
    [CmdletBinding()]
    param()

    try {
        Write-Host "`nInstalando ferramentas CLI modernas..." -ForegroundColor Cyan

        $results = @{
            Success = @()
            Failed = @()
        }

        $tools = @(
            @{ Name = "bat"; Function = { Install-Bat } },
            @{ Name = "eza"; Function = { Install-Eza } },
            @{ Name = "fzf"; Function = { Install-Fzf } },
            @{ Name = "ripgrep"; Function = { Install-Ripgrep } },
            @{ Name = "zoxide"; Function = { Install-Zoxide } }
        )

        foreach ($tool in $tools) {
            Write-Host "`nInstalando $($tool.Name)..." -ForegroundColor Yellow

            $result = & $tool.Function

            if ($result) {
                $results.Success += $tool.Name
            }
            else {
                $results.Failed += $tool.Name
            }
        }

        Write-Host "Resumo da instalação:" -ForegroundColor Cyan
        Write-Host "  Sucesso: $($results.Success.Count)" -ForegroundColor Green
        Write-Host "  Falhas: $($results.Failed.Count)" -ForegroundColor Red

        if ($results.Success.Count -gt 0) {
            Write-Host "`nFerramentas instaladas:" -ForegroundColor Green
            foreach ($tool in $results.Success) {
                Write-Host "  [OK] $tool" -ForegroundColor Gray
            }
        }

        if ($results.Failed.Count -gt 0) {
            Write-Host "`nFalhas:" -ForegroundColor Red
            foreach ($tool in $results.Failed) {
                Write-Host "  [X] $tool" -ForegroundColor Gray
            }
        }

        return $results
    }
    catch {
        Write-Error "Erro ao instalar ferramentas modernas: $_"
        return $null
    }
}