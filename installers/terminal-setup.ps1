function Install-OhMyPosh {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    try {
        Write-Host "Instalando Oh My Posh..." -ForegroundColor Cyan

        if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and -not $Force) {
            Write-Host "Oh My Posh já está instalado" -ForegroundColor Yellow
            return $true
        }

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Verbose "Instalando via Winget"
            winget install JanDeDobbeleer.OhMyPosh -s winget --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        }
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Verbose "Instalando via Chocolatey"
            choco install oh-my-posh -y 2>&1 | Out-Null
        }
        else {
            throw "Nenhum gerenciador de pacotes disponível (Winget ou Chocolatey necessário)"
        }

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
            Write-Host "[OK] Oh My Posh instalado com sucesso" -ForegroundColor Green
            return $true
        }
        else {
            throw "Oh My Posh foi instalado mas não está disponível no PATH"
        }
    }
    catch {
        Write-Error "Erro ao instalar Oh My Posh: $_"
        return $false
    }
}

function Install-NerdFont {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('CascadiaCode', 'FiraCode', 'Meslo', 'JetBrainsMono', 'Hack')]
        [string]$FontName = 'CascadiaCode'
    )

    try {
        Write-Host "Instalando Nerd Font: $FontName..." -ForegroundColor Cyan

        oh-my-posh font install $FontName 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Nerd Font $FontName instalada" -ForegroundColor Green
            Write-Host "Configure sua fonte no terminal para: $FontName Nerd Font" -ForegroundColor Yellow
            return $true
        }
        else {
            Write-Warning "Instalação da fonte pode ter falhado. Verifique manualmente."
            return $false
        }
    }
    catch {
        Write-Error "Erro ao instalar Nerd Font: $_"
        return $false
    }
}

function Set-OhMyPoshTheme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$ThemeName = 'paradox',

        [Parameter(Mandatory=$false)]
        [switch]$AddToProfile
    )

    try {
        Write-Host "Configurando tema Oh My Posh: $ThemeName..." -ForegroundColor Cyan

        if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
            throw "Oh My Posh não está instalado"
        }

        $themePath = "$env:POSH_THEMES_PATH\$ThemeName.omp.json"

        if (-not (Test-Path $themePath)) {
            Write-Warning "Tema não encontrado em: $themePath"
            Write-Host "Tentando tema customizado..." -ForegroundColor Yellow

            $customThemePath = "$PSScriptRoot\..\config\terminal-themes\oh-my-posh\$ThemeName.omp.json"

            if (Test-Path $customThemePath) {
                $themePath = $customThemePath
                Write-Verbose "Usando tema customizado: $themePath"
            }
            else {
                throw "Tema não encontrado: $ThemeName"
            }
        }

        $initCommand = "oh-my-posh init pwsh --config '$themePath' | Invoke-Expression"

        Invoke-Expression $initCommand

        Write-Host "[OK] Tema Oh My Posh configurado: $ThemeName" -ForegroundColor Green

        if ($AddToProfile) {
            $profilePath = $PROFILE

            if (-not (Test-Path $profilePath)) {
                New-Item -ItemType File -Path $profilePath -Force | Out-Null
            }

            $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

            if ($profileContent -notlike "*oh-my-posh init*") {
                Add-Content -Path $profilePath -Value "`n$initCommand"
                Write-Host "[OK] Oh My Posh adicionado ao perfil do PowerShell" -ForegroundColor Green
            }
            else {
                Write-Host "Oh My Posh já está no perfil" -ForegroundColor Yellow
            }
        }

        return $true
    }
    catch {
        Write-Error "Erro ao configurar tema Oh My Posh: $_"
        return $false
    }
}

function Get-OhMyPoshThemes {
    [CmdletBinding()]
    param()

    try {
        Write-Host "`nTemas Oh My Posh disponíveis:" -ForegroundColor Cyan

        if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
            throw "Oh My Posh não está instalado"
        }

        $themesPath = $env:POSH_THEMES_PATH

        if (-not (Test-Path $themesPath)) {
            throw "Diretório de temas não encontrado: $themesPath"
        }

        $themes = Get-ChildItem -Path $themesPath -Filter "*.omp.json" | Select-Object -ExpandProperty BaseName

        Write-Host "`nTemas oficiais ($($themes.Count)):" -ForegroundColor Yellow
        $themes | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }

        $customThemesPath = "$PSScriptRoot\..\config\terminal-themes\oh-my-posh"

        if (Test-Path $customThemesPath) {
            $customThemes = Get-ChildItem -Path $customThemesPath -Filter "*.omp.json" | Select-Object -ExpandProperty BaseName

            if ($customThemes.Count -gt 0) {
                Write-Host "`nTemas customizados ($($customThemes.Count)):" -ForegroundColor Yellow
                $customThemes | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
            }
        }

        Write-Host "`nPara testar um tema: Set-OhMyPoshTheme -ThemeName 'nome_do_tema'" -ForegroundColor Cyan

        return $themes + $customThemes
    }
    catch {
        Write-Error "Erro ao listar temas: $_"
        return $null
    }
}

function New-CustomOhMyPoshTheme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ThemeName,

        [Parameter(Mandatory=$false)]
        [string]$BaseTheme = 'paradox'
    )

    try {
        Write-Host "Criando tema customizado: $ThemeName..." -ForegroundColor Cyan

        $customThemesPath = "$PSScriptRoot\..\config\terminal-themes\oh-my-posh"

        if (-not (Test-Path $customThemesPath)) {
            New-Item -ItemType Directory -Path $customThemesPath -Force | Out-Null
        }

        $baseThemePath = "$env:POSH_THEMES_PATH\$BaseTheme.omp.json"

        if (-not (Test-Path $baseThemePath)) {
            throw "Tema base não encontrado: $BaseTheme"
        }

        $customThemePath = Join-Path $customThemesPath "$ThemeName.omp.json"

        Copy-Item -Path $baseThemePath -Destination $customThemePath -Force

        Write-Host "[OK] Tema customizado criado: $customThemePath" -ForegroundColor Green
        Write-Host "Edite o arquivo para personalizar seu tema" -ForegroundColor Yellow

        return $customThemePath
    }
    catch {
        Write-Error "Erro ao criar tema customizado: $_"
        return $null
    }
}

function Install-Starship {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )

    try {
        Write-Host "Instalando Starship..." -ForegroundColor Cyan

        if ((Get-Command starship -ErrorAction SilentlyContinue) -and -not $Force) {
            Write-Host "Starship já está instalado" -ForegroundColor Yellow
            return $true
        }

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Verbose "Instalando via Winget"
            winget install --id Starship.Starship --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        }
        elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Verbose "Instalando via Chocolatey"
            choco install starship -y 2>&1 | Out-Null
        }
        elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
            Write-Verbose "Instalando via Scoop"
            scoop install starship 2>&1 | Out-Null
        }
        else {
            throw "Nenhum gerenciador de pacotes disponível"
        }

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        if (Get-Command starship -ErrorAction SilentlyContinue) {
            Write-Host "[OK] Starship instalado com sucesso" -ForegroundColor Green
            return $true
        }
        else {
            throw "Starship foi instalado mas não está disponível no PATH"
        }
    }
    catch {
        Write-Error "Erro ao instalar Starship: $_"
        return $false
    }
}

function Set-StarshipConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ConfigPath,

        [Parameter(Mandatory=$false)]
        [switch]$AddToProfile,

        [Parameter(Mandatory=$false)]
        [switch]$UseDefault
    )

    try {
        Write-Host "Configurando Starship..." -ForegroundColor Cyan

        if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
            throw "Starship não está instalado"
        }

        if ($UseDefault) {
            $ConfigPath = "$PSScriptRoot\..\config\terminal-themes\starship\starship.toml"
        }

        if ($ConfigPath -and (Test-Path $ConfigPath)) {
            $starshipConfigDir = Join-Path $env:USERPROFILE ".config"

            if (-not (Test-Path $starshipConfigDir)) {
                New-Item -ItemType Directory -Path $starshipConfigDir -Force | Out-Null
            }

            $targetConfig = Join-Path $starshipConfigDir "starship.toml"
            Copy-Item -Path $ConfigPath -Destination $targetConfig -Force

            Write-Verbose "Configuração copiada para: $targetConfig"
        }

        $initCommand = 'Invoke-Expression (&starship init powershell)'

        Invoke-Expression $initCommand

        Write-Host "[OK] Starship configurado" -ForegroundColor Green

        if ($AddToProfile) {
            $profilePath = $PROFILE

            if (-not (Test-Path $profilePath)) {
                New-Item -ItemType File -Path $profilePath -Force | Out-Null
            }

            $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

            if ($profileContent -notlike "*starship init*") {
                Add-Content -Path $profilePath -Value "`n$initCommand"
                Write-Host "[OK] Starship adicionado ao perfil do PowerShell" -ForegroundColor Green
            }
            else {
                Write-Host "Starship já está no perfil" -ForegroundColor Yellow
            }
        }

        return $true
    }
    catch {
        Write-Error "Erro ao configurar Starship: $_"
        return $false
    }
}

function Get-StarshipPresets {
    [CmdletBinding()]
    param()

    try {
        Write-Host "`nPresets Starship disponíveis:" -ForegroundColor Cyan
        Write-Host "  - nerd-font-symbols" -ForegroundColor Gray
        Write-Host "  - bracketed-segments" -ForegroundColor Gray
        Write-Host "  - plain-text-symbols" -ForegroundColor Gray
        Write-Host "  - no-runtime-versions" -ForegroundColor Gray
        Write-Host "  - pure-preset" -ForegroundColor Gray
        Write-Host "  - pastel-powerline" -ForegroundColor Gray
        Write-Host "`nPara aplicar um preset:" -ForegroundColor Cyan
        Write-Host "  starship preset <preset-name> -o ~/.config/starship.toml" -ForegroundColor Yellow

        return $true
    }
    catch {
        Write-Error "Erro ao listar presets: $_"
        return $false
    }
}