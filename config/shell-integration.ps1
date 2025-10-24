function Initialize-ShellIntegration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$AddToProfile
    )

    try {
        Write-Host "Configurando integração de ferramentas modernas..." -ForegroundColor Cyan

        $integrations = @()

        if (Get-Command bat -ErrorAction SilentlyContinue) {
            Set-Alias -Name cat -Value bat -Scope Global -Option AllScope -Force
            $integrations += "bat (alias: cat)"
            Write-Verbose "Alias 'cat' configurado para bat"
        }

        if (Get-Command eza -ErrorAction SilentlyContinue) {
            Set-Alias -Name ls -Value eza -Scope Global -Option AllScope -Force
            Set-Alias -Name ll -Value eza -Scope Global -Option AllScope -Force
            $integrations += "eza (alias: ls, ll)"
            Write-Verbose "Aliases 'ls' e 'll' configurados para eza"
        }

        if (Get-Command fzf -ErrorAction SilentlyContinue) {
            Set-FzfKeybindings
            $integrations += "fzf (keybindings configurados)"
            Write-Verbose "fzf keybindings configurados"
        }

        if (Get-Command zoxide -ErrorAction SilentlyContinue) {
            Invoke-Expression (& { (zoxide init powershell | Out-String) })
            Set-Alias -Name cd -Value z -Scope Global -Option AllScope -Force
            $integrations += "zoxide (alias: cd → z)"
            Write-Verbose "zoxide inicializado"
        }

        if ($integrations.Count -gt 0) {
            Write-Host "✓ Integrações configuradas:" -ForegroundColor Green
            foreach ($integration in $integrations) {
                Write-Host "  - $integration" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "Nenhuma ferramenta moderna encontrada para integração" -ForegroundColor Yellow
        }

        if ($AddToProfile) {
            Add-ToProfile
        }

        return $true
    }
    catch {
        Write-Error "Erro ao configurar integração: $_"
        return $false
    }
}

function Set-FzfKeybindings {
    [CmdletBinding()]
    param()

    try {
        if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
            return $false
        }

        Set-PSReadLineKeyHandler -Key Ctrl+t -ScriptBlock {
            $result = Get-ChildItem -Recurse -File | Select-Object -ExpandProperty FullName | fzf
            if ($result) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
            }
        }

        Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
            $result = Get-History | Select-Object -ExpandProperty CommandLine | fzf
            if ($result) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($result)
            }
        }

        Write-Verbose "fzf keybindings configurados: Ctrl+T (arquivos), Ctrl+R (histórico)"
        return $true
    }
    catch {
        Write-Warning "Erro ao configurar fzf keybindings: $_"
        return $false
    }
}

function Add-ToProfile {
    [CmdletBinding()]
    param()

    try {
        $profilePath = $PROFILE

        if (-not (Test-Path $profilePath)) {
            New-Item -ItemType File -Path $profilePath -Force | Out-Null
        }

        $integrationScript = ". `"$PSScriptRoot\shell-integration.ps1`"`nInitialize-ShellIntegration"

        $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

        if ($profileContent -notlike "*Initialize-ShellIntegration*") {
            Add-Content -Path $profilePath -Value "`n$integrationScript"
            Write-Host "✓ Integração adicionada ao perfil PowerShell" -ForegroundColor Green
        }
        else {
            Write-Host "Integração já está no perfil" -ForegroundColor Yellow
        }

        return $true
    }
    catch {
        Write-Error "Erro ao adicionar ao perfil: $_"
        return $false
    }
}

function Get-ModernToolsStatus {
    [CmdletBinding()]
    param()

    try {
        Write-Host "`nStatus das ferramentas modernas:" -ForegroundColor Cyan

        $tools = @(
            @{ Name = "bat"; Command = "bat"; Alias = "cat" },
            @{ Name = "eza"; Command = "eza"; Alias = "ls, ll" },
            @{ Name = "fzf"; Command = "fzf"; Alias = "Ctrl+T, Ctrl+R" },
            @{ Name = "ripgrep"; Command = "rg"; Alias = "N/A" },
            @{ Name = "zoxide"; Command = "zoxide"; Alias = "cd → z" }
        )

        foreach ($tool in $tools) {
            $installed = Get-Command $tool.Command -ErrorAction SilentlyContinue

            if ($installed) {
                Write-Host "  ✓ $($tool.Name)" -ForegroundColor Green -NoNewline
                Write-Host " - $($tool.Alias)" -ForegroundColor Gray
            }
            else {
                Write-Host "  ✗ $($tool.Name)" -ForegroundColor Red -NoNewline
                Write-Host " - não instalado" -ForegroundColor Gray
            }
        }

        return $true
    }
    catch {
        Write-Error "Erro ao verificar status: $_"
        return $false
    }
}

function New-BatConfig {
    [CmdletBinding()]
    param()

    try {
        if (-not (Get-Command bat -ErrorAction SilentlyContinue)) {
            throw "bat não está instalado"
        }

        $configDir = Join-Path $env:APPDATA "bat"

        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }

        $configFile = Join-Path $configDir "config"

        $config = @"
--theme="TwoDark"
--style="numbers,changes,header"
--italic-text=always
--paging=never
"@

        $config | Set-Content $configFile -Force

        Write-Host "✓ Configuração bat criada em: $configFile" -ForegroundColor Green

        return $configFile
    }
    catch {
        Write-Error "Erro ao criar configuração bat: $_"
        return $null
    }
}

function New-EzaAlias {
    [CmdletBinding()]
    param()

    try {
        if (-not (Get-Command eza -ErrorAction SilentlyContinue)) {
            throw "eza não está instalado"
        }

        function global:ll {
            eza -la --icons --git $args
        }

        function global:lt {
            eza --tree --level=2 --icons $args
        }

        function global:la {
            eza -a --icons $args
        }

        Write-Host "✓ Aliases eza configurados:" -ForegroundColor Green
        Write-Host "  ll - lista detalhada com ícones e git" -ForegroundColor Gray
        Write-Host "  lt - visualização em árvore" -ForegroundColor Gray
        Write-Host "  la - mostrar arquivos ocultos" -ForegroundColor Gray

        return $true
    }
    catch {
        Write-Error "Erro ao criar aliases eza: $_"
        return $false
    }
}