function Show-Banner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Language = "pt-br"
    )

    Clear-Host

    $banner = @"

 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣷⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡔⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠭⣿⣿⣿⣶⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡿⣿⡿⣿⣿⣿⣿⣦⣴⣶⣶⣶⣶⣦⣤⣤⣀⣀⠀⠀⠀⠀⠀⢀⣀⣤⣲⣿⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⡝⢿⣌⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣤⣾⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠲⡝⡷⣮⣝⣻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣛⣿⣿⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣦⣝⠓⠭⣿⡿⢿⣿⣿⣛⠻⣿⠿⠿⣿⣿⣿⣿⣿⣿⡿⣇⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣤⡀⠈⠉⠚⠺⣿⠯⢽⣿⣷⣄⣶⣷⢾⣿⣯⣾⣿⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⡟⠀⠀⣴⣿⣿⣼⠈⠉⠃⠋⢹⠁⢀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⢿⣿⡟⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⣀⣀⣀⣀⣴⣿⣿⡿⣿⠀⠀⠀⠀⠇⠀⣼⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠑⢿⢿⣾⣿⣿⡿⠿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠿⢿⡄⢦⣤⣤⣶⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠘⠛⠋⠁⠁⣀⢉⡉⢻⡻⣯⣻⣿⢻⣿⣀⠀⠀⠀⢠⣾⣿⣿⣿⣹⠉⣍⢁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠠⠔⠒⠋⠀⡈⠀⠠⠤⠀⠓⠯⣟⣻⣻⠿⠛⠁⠀⠀⠣⢽⣿⡻⠿⠋⠰⠤⣀⡈⠒⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠔⠊⠁⠀⣀⠔⠈⠁⠀⠀⠀⠀⠀⣶⠂⠀⠀⠀⢰⠆⠀⠀⠀⠈⠒⢦⡀⠉⠢⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠊⠀⠀⠀⠀⠎⠁⠀⠀⠀⠀⠀⠀⠀⠀⠋⠀⠀⠀⠰⠃⠀⠀⠀⠀⠀⠀⠀⠈⠂⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣄⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠿⠭⠯⠭⠽⠿


                         Env v1.0.0 - Setup Automatizado
                          Windows Environment Builder

                          Created by Thiago Di Faria
                           github.com/thiagodifaria

"@

    Write-Host $banner -ForegroundColor Cyan
}

function Show-MainMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Language = "pt-br"
    )

    Write-Host "     $(Get-String 'main_menu' $Language)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. $(Get-String 'preset_complete' $Language)" -ForegroundColor White
    Write-Host "  2. $(Get-String 'preset_developer' $Language)" -ForegroundColor White
    Write-Host "  3. $(Get-String 'preset_personal' $Language)" -ForegroundColor White
    Write-Host "  4. $(Get-String 'custom_install' $Language)" -ForegroundColor White
    Write-Host "  5. $(Get-String 'exit' $Language)" -ForegroundColor White
    Write-Host ""
    Write-Host "$(Get-String 'choose_option' $Language): " -ForegroundColor Yellow -NoNewline

    $choice = Read-Host
    return $choice
}

function Show-CategoryMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Language = "pt-br",

        [Parameter(Mandatory=$false)]
        [hashtable]$Categories
    )

    Clear-Host
    Write-Host "      Seleção de Categorias" -ForegroundColor Cyan
    Write-Host ""

    if ($Categories) {
        $categoryNames = $Categories.Keys | Sort-Object
        $i = 1

        foreach ($cat in $categoryNames) {
            $count = $Categories[$cat].Count
            Write-Host "  $i. " -ForegroundColor Yellow -NoNewline
            Write-Host "$cat " -ForegroundColor White -NoNewline
            Write-Host "($count packages)" -ForegroundColor Gray
            $i++
        }

        Write-Host ""
        Write-Host "Escolha uma categoria (número) ou [Q] para sair" -ForegroundColor Yellow

        $input = Read-Host "`nCategoria"

        if ($input -eq 'Q' -or $input -eq 'q') {
            return $null
        }

        $index = [int]$input - 1
        if ($index -ge 0 -and $index -lt $categoryNames.Count) {
            return $categoryNames[$index]
        }

        return $null
    }
    else {
        $categories = @(
            @{Id=1; Name="Languages"; Display="linguagens_title"}
            @{Id=2; Name="DevTools"; Display="devtools_title"}
            @{Id=3; Name="WebTools"; Display="webtools_title"}
            @{Id=4; Name="DBTools"; Display="dbtools_title"}
            @{Id=5; Name="Observability"; Display="observability_title"}
            @{Id=6; Name="Personal"; Display="personal_title"}
            @{Id=7; Name="WSL"; Display="wsl_title"}
            @{Id=8; Name="NPM"; Display="npm_title"}
        )

        foreach ($cat in $categories) {
            Write-Host "  [$($cat.Id)] $(Get-String $cat.Display $Language)" -ForegroundColor White
        }

        Write-Host ""
        Write-Host "$(Get-String 'select_numbers' $Language) " -ForegroundColor Yellow -NoNewline

        $selection = Read-Host
        return $selection
    }
}

function Show-OptionsMenu {
    [CmdletBinding()]
    param()

    try {
        Clear-Host
        Write-Host "      ENV - Opções" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  1. Instalar packages" -ForegroundColor White
        Write-Host "  2. Ver estado de instalações" -ForegroundColor White
        Write-Host "  3. Gerenciar backups" -ForegroundColor White
        Write-Host "  4. Configurar terminal" -ForegroundColor White
        Write-Host "  5. Ferramentas modernas" -ForegroundColor White
        Write-Host "  6. Ver cache" -ForegroundColor White
        Write-Host "  7. Rollback" -ForegroundColor White
        Write-Host "  Q. Sair" -ForegroundColor White
        Write-Host ""

        $choice = Read-Host "Escolha uma opção"

        return $choice
    }
    catch {
        Write-Error "Erro ao exibir menu de opções: $_"
        return $null
    }
}

function Show-PackageMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [array]$Packages
    )

    try {
        $selected = @()
        $currentPage = 0
        $pageSize = 10
        $totalPages = [math]::Ceiling($Packages.Count / $pageSize)

        while ($true) {
            Clear-Host
            Write-Host "      Seleção de Packages" -ForegroundColor Cyan
            Write-Host "Página $($currentPage + 1) de $totalPages | Selecionados: $($selected.Count)" -ForegroundColor Gray
            Write-Host ""

            $startIndex = $currentPage * $pageSize
            $endIndex = [math]::Min($startIndex + $pageSize, $Packages.Count)

            for ($i = $startIndex; $i -lt $endIndex; $i++) {
                $pkg = $Packages[$i]
                $number = $i + 1
                $isSelected = $selected -contains $pkg.id

                if ($isSelected) {
                    Write-Host "  [✓] " -ForegroundColor Green -NoNewline
                }
                else {
                    Write-Host "  [ ] " -ForegroundColor Gray -NoNewline
                }

                Write-Host "$number. " -ForegroundColor Yellow -NoNewline
                Write-Host "$($pkg.name)" -ForegroundColor White
            }

            Write-Host "Comandos:" -ForegroundColor Yellow
            Write-Host "  [número] - Toggle seleção" -ForegroundColor Gray
            Write-Host "  [A] - Selecionar todos" -ForegroundColor Gray
            Write-Host "  [N] - Próxima página" -ForegroundColor Gray
            Write-Host "  [P] - Página anterior" -ForegroundColor Gray
            Write-Host "  [C] - Confirmar seleção" -ForegroundColor Gray
            Write-Host "  [Q] - Cancelar" -ForegroundColor Gray

            $input = Read-Host "`nComando"

            if ($input -eq 'Q' -or $input -eq 'q') {
                return @()
            }
            elseif ($input -eq 'C' -or $input -eq 'c') {
                return $selected
            }
            elseif ($input -eq 'A' -or $input -eq 'a') {
                $selected = $Packages | Select-Object -ExpandProperty id
            }
            elseif ($input -eq 'N' -or $input -eq 'n') {
                if ($currentPage -lt ($totalPages - 1)) {
                    $currentPage++
                }
            }
            elseif ($input -eq 'P' -or $input -eq 'p') {
                if ($currentPage -gt 0) {
                    $currentPage--
                }
            }
            elseif ($input -match '^\d+$') {
                $index = [int]$input - 1
                if ($index -ge 0 -and $index -lt $Packages.Count) {
                    $pkgId = $Packages[$index].id
                    if ($selected -contains $pkgId) {
                        $selected = $selected | Where-Object { $_ -ne $pkgId }
                    }
                    else {
                        $selected += $pkgId
                    }
                }
            }
        }
    }
    catch {
        Write-Error "Erro ao exibir menu: $_"
        return @()
    }
}


function Show-ProgressBar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Title = "Progresso",

        [Parameter(Mandatory=$true)]
        [int]$Current,

        [Parameter(Mandatory=$true)]
        [int]$Total,

        [Parameter(Mandatory=$false)]
        [string]$Status = "Processando...",

        [Parameter(Mandatory=$false)]
        [string]$Activity
    )

    try {
        $percentComplete = [math]::Min(100, [math]::Round(($Current / $Total) * 100))

        if ($Activity) {
            $barLength = 40
            $filled = [math]::Round(($percentComplete / 100) * $barLength)
            $empty = $barLength - $filled

            $bar = "█" * $filled + "░" * $empty

            Write-Host "`r[$bar] $percentComplete% - $Activity" -NoNewline -ForegroundColor Green
        }
        else {
            Write-Progress -Activity $Title -Status "$Status ($Current de $Total)" -PercentComplete $percentComplete
        }
    }
    catch {
        Write-Warning "Erro ao exibir progress bar: $_"
    }
}

function Show-CategoryProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Category,

        [Parameter(Mandatory=$true)]
        [int]$Current,

        [Parameter(Mandatory=$true)]
        [int]$Total
    )

    try {
        $percent = [math]::Round(($Current / $Total) * 100)
        $barLength = 20
        $filled = [math]::Round(($percent / 100) * $barLength)
        $empty = $barLength - $filled

        $bar = "█" * $filled + "░" * $empty

        Write-Host "  $Category`: [$bar] $percent% ($Current/$Total)" -ForegroundColor Cyan
    }
    catch {
        Write-Warning "Erro ao exibir progresso de categoria: $_"
    }
}

function Show-GlobalProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$CurrentCategory,

        [Parameter(Mandatory=$true)]
        [int]$TotalCategories,

        [Parameter(Mandatory=$true)]
        [string]$CategoryName
    )

    try {
        $percent = [math]::Round(($CurrentCategory / $TotalCategories) * 100)
        $barLength = 40
        $filled = [math]::Round(($percent / 100) * $barLength)
        $empty = $barLength - $filled

        $bar = "█" * $filled + "░" * $empty

        Write-Host ""
        Write-Host "Progresso Global: [$bar] $percent% ($CurrentCategory/$TotalCategories categorias)" -ForegroundColor Magenta
        Write-Host "Categoria atual: $CategoryName" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Warning "Erro ao exibir progresso global: $_"
    }
}

function Show-DownloadProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Url,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination
    )

    try {
        $fileName = Split-Path $Url -Leaf

        Write-Host "Baixando $fileName..." -ForegroundColor Cyan

        $webClient = New-Object System.Net.WebClient

        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier WebClient.DownloadProgressChanged -Action {
            $percent = $EventArgs.ProgressPercentage
            $received = $EventArgs.BytesReceived / 1MB
            $total = $EventArgs.TotalBytesToReceive / 1MB

            Write-Progress -Activity "Download em progresso" -Status "$fileName ($([math]::Round($received, 2)) MB de $([math]::Round($total, 2)) MB)" -PercentComplete $percent
        } | Out-Null

        $webClient.DownloadFileAsync($Url, $Destination)

        while ($webClient.IsBusy) {
            Start-Sleep -Milliseconds 100
        }

        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
        $webClient.Dispose()

        Write-Progress -Activity "Download em progresso" -Completed
        Write-Host "✓ Download concluído: $fileName" -ForegroundColor Green

        return $true
    }
    catch {
        Write-Error "Erro ao baixar arquivo: $_"
        return $false
    }
}

function Show-InstallationProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [array]$Packages,

        [Parameter(Mandatory=$false)]
        [int]$CurrentIndex = 0
    )

    try {
        $total = $Packages.Count
        $percentComplete = [math]::Round(($CurrentIndex / $total) * 100)

        $currentPkg = if ($CurrentIndex -lt $total) { $Packages[$CurrentIndex].name } else { "Concluído" }

        Write-Progress -Activity "Instalação de Packages" -Status "Instalando: $currentPkg ($($CurrentIndex + 1) de $total)" -PercentComplete $percentComplete -Id 1

        return $true
    }
    catch {
        Write-Warning "Erro ao exibir progresso de instalação: $_"
        return $false
    }
}

function Show-MultiProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [hashtable]$Tasks
    )

    try {
        $taskNames = $Tasks.Keys
        $id = 1

        foreach ($taskName in $taskNames) {
            $task = $Tasks[$taskName]
            $percent = [math]::Round(($task.Current / $task.Total) * 100)

            Write-Progress -Activity $taskName -Status "$($task.Status) ($($task.Current)/$($task.Total))" -PercentComplete $percent -Id $id

            $id++
        }

        return $true
    }
    catch {
        Write-Warning "Erro ao exibir múltiplos progress: $_"
        return $false
    }
}

function Complete-Progress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$Id = 0
    )

    try {
        Write-Progress -Activity "Concluído" -Completed -Id $Id
    }
    catch {
        Write-Verbose "Erro ao completar progress: $_"
    }
}


function Show-Spinner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [scriptblock]$Task
    )

    try {
        $spinChars = @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏')
        $job = Start-Job -ScriptBlock $Task

        $i = 0
        while ($job.State -eq "Running") {
            Write-Host "`r$($spinChars[$i % $spinChars.Count]) $Message" -NoNewline -ForegroundColor Cyan
            Start-Sleep -Milliseconds 100
            $i++
        }

        $result = Receive-Job -Job $job
        Remove-Job -Job $job

        Write-Host "`r" -NoNewline
        return $result
    }
    catch {
        Write-Error "Erro durante execução: $_"
        return $null
    }
}

function Show-SpinnerWhile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory=$false)]
        [string]$Message = "Processando..."
    )

    try {
        $spinnerChars = @('|', '/', '-', '\')
        $i = 0

        $job = Start-Job -ScriptBlock $ScriptBlock

        while ($job.State -eq 'Running') {
            $char = $spinnerChars[$i % $spinnerChars.Count]
            Write-Host "`r$char $Message" -NoNewline -ForegroundColor Cyan
            $i++
            Start-Sleep -Milliseconds 100
        }

        $result = Receive-Job -Job $job
        Remove-Job -Job $job

        Write-Host "`r✓ $Message - Concluído" -ForegroundColor Green

        return $result
    }
    catch {
        Write-Error "Erro durante execução: $_"
        return $null
    }
}


function Write-Status {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Type = "INFO"
    )

    $symbol = switch ($Type) {
        "SUCCESS" { "✓"; $color = "Green" }
        "ERROR" { "✗"; $color = "Red" }
        "SKIP" { "⟲"; $color = "Cyan" }
        "WORKING" { "➜"; $color = "Yellow" }
        "WARNING" { "⚠"; $color = "Yellow" }
        default { "•"; $color = "White" }
    }

    Write-Host "  $symbol $Message" -ForegroundColor $color
}

function Show-Box {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Color = "Cyan"
    )

    try {
        $length = $Message.Length + 4
        $border = "═" * $length

        Write-Host ""
        Write-Host "╔$border╗" -ForegroundColor $Color
        Write-Host "║  $Message  ║" -ForegroundColor $Color
        Write-Host "╚$border╝" -ForegroundColor $Color
        Write-Host ""
    }
    catch {
        Write-Warning "Erro ao exibir box: $_"
    }
}

function Clear-LastLine {
    Write-Host "`r$(' ' * 80)`r" -NoNewline
}


function Get-PromptTemplates {
    [CmdletBinding()]
    param()

    try {
        $templates = @{
            minimal = @{
                Name = "Minimal"
                Description = "Prompt minimalista com path e git"
                Function = "Set-MinimalPrompt"
            }
            developer = @{
                Name = "Developer"
                Description = "Prompt com informações de desenvolvimento"
                Function = "Set-DeveloperPrompt"
            }
            gitfocused = @{
                Name = "Git-Focused"
                Description = "Prompt focado em informações do Git"
                Function = "Set-GitFocusedPrompt"
            }
            powerline = @{
                Name = "Powerline"
                Description = "Estilo powerline com múltiplos segmentos"
                Function = "Set-PowerlinePrompt"
            }
        }

        Write-Host "`nTemplates de Prompt disponíveis:" -ForegroundColor Cyan
        foreach ($key in $templates.Keys) {
            $template = $templates[$key]
            Write-Host "  [$key]" -ForegroundColor Yellow -NoNewline
            Write-Host " - $($template.Description)" -ForegroundColor Gray
        }

        Write-Host "`nUso: Set-CustomPrompt -Template 'nome_template'" -ForegroundColor Cyan

        return $templates
    }
    catch {
        Write-Error "Erro ao listar templates: $_"
        return $null
    }
}

function Set-CustomPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('minimal', 'developer', 'gitfocused', 'powerline')]
        [string]$Template,

        [Parameter(Mandatory=$false)]
        [switch]$AddToProfile
    )

    try {
        Write-Host "Configurando prompt: $Template..." -ForegroundColor Cyan

        switch ($Template) {
            'minimal' { Set-MinimalPrompt }
            'developer' { Set-DeveloperPrompt }
            'gitfocused' { Set-GitFocusedPrompt }
            'powerline' { Set-PowerlinePrompt }
        }

        if ($AddToProfile) {
            $profilePath = $PROFILE

            if (-not (Test-Path $profilePath)) {
                New-Item -ItemType File -Path $profilePath -Force | Out-Null
            }

            $functionCall = ". `"$PSScriptRoot\ui.ps1`"`nSet-CustomPrompt -Template '$Template'"

            $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

            if ($profileContent -notlike "*Set-CustomPrompt*") {
                Add-Content -Path $profilePath -Value "`n$functionCall"
                Write-Host "✓ Prompt adicionado ao perfil" -ForegroundColor Green
            }
            else {
                Write-Host "Prompt já configurado no perfil" -ForegroundColor Yellow
            }
        }

        Write-Host "✓ Prompt configurado: $Template" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erro ao configurar prompt: $_"
        return $false
    }
}

function Set-MinimalPrompt {
    [CmdletBinding()]
    param()

    function global:prompt {
        $location = Get-Location
        $path = $location.Path.Replace($HOME, "~")

        $gitBranch = ""
        if (Test-Path .git) {
            try {
                $branch = git rev-parse --abbrev-ref HEAD 2>$null
                if ($branch) {
                    $gitBranch = " ($branch)"
                }
            }
            catch {}
        }

        Write-Host "$path" -NoNewline -ForegroundColor Cyan
        Write-Host "$gitBranch" -NoNewline -ForegroundColor Yellow
        Write-Host " >" -NoNewline -ForegroundColor Green

        return " "
    }

    Write-Verbose "Prompt minimalista configurado"
}

function Set-DeveloperPrompt {
    [CmdletBinding()]
    param()

    function global:prompt {
        $location = Get-Location
        $path = $location.Path.Replace($HOME, "~")

        Write-Host "[" -NoNewline -ForegroundColor DarkGray
        Write-Host (Get-Date -Format "HH:mm:ss") -NoNewline -ForegroundColor Gray
        Write-Host "]" -NoNewline -ForegroundColor DarkGray

        Write-Host " $env:USERNAME" -NoNewline -ForegroundColor Green

        Write-Host " in " -NoNewline -ForegroundColor Gray
        Write-Host "$path" -NoNewline -ForegroundColor Cyan

        if (Test-Path .git) {
            try {
                $branch = git rev-parse --abbrev-ref HEAD 2>$null
                if ($branch) {
                    Write-Host " on " -NoNewline -ForegroundColor Gray
                    Write-Host " $branch" -NoNewline -ForegroundColor Magenta

                    $status = git status --porcelain 2>$null
                    if ($status) {
                        Write-Host " ✗" -NoNewline -ForegroundColor Red
                    }
                    else {
                        Write-Host " ✓" -NoNewline -ForegroundColor Green
                    }
                }
            }
            catch {}
        }

        if (Get-Command node -ErrorAction SilentlyContinue) {
            if (Test-Path package.json) {
                Write-Host " " -NoNewline -ForegroundColor Green
            }
        }

        if (Get-Command python -ErrorAction SilentlyContinue) {
            if (Test-Path requirements.txt) {
                Write-Host " " -NoNewline -ForegroundColor Yellow
            }
        }

        Write-Host "`n└>" -NoNewline -ForegroundColor Green

        return " "
    }

    Write-Verbose "Prompt de desenvolvedor configurado"
}

function Set-GitFocusedPrompt {
    [CmdletBinding()]
    param()

    function global:prompt {
        $location = Get-Location
        $path = Split-Path -Leaf $location.Path

        Write-Host "$path" -NoNewline -ForegroundColor Cyan

        if (Test-Path .git) {
            try {
                $branch = git rev-parse --abbrev-ref HEAD 2>$null
                if ($branch) {
                    Write-Host " on " -NoNewline -ForegroundColor Gray
                    Write-Host " $branch" -NoNewline -ForegroundColor Magenta

                    $ahead = git rev-list --count '@{u}..HEAD' 2>$null
                    $behind = git rev-list --count 'HEAD..@{u}' 2>$null

                    if ($ahead -gt 0) {
                        Write-Host " ↑$ahead" -NoNewline -ForegroundColor Cyan
                    }
                    if ($behind -gt 0) {
                        Write-Host " ↓$behind" -NoNewline -ForegroundColor Yellow
                    }

                    $modified = (git diff --name-only 2>$null | Measure-Object).Count
                    $staged = (git diff --cached --name-only 2>$null | Measure-Object).Count
                    $untracked = (git ls-files --others --exclude-standard 2>$null | Measure-Object).Count

                    if ($staged -gt 0) {
                        Write-Host " +$staged" -NoNewline -ForegroundColor Green
                    }
                    if ($modified -gt 0) {
                        Write-Host " ~$modified" -NoNewline -ForegroundColor Yellow
                    }
                    if ($untracked -gt 0) {
                        Write-Host " ?$untracked" -NoNewline -ForegroundColor Red
                    }
                }
            }
            catch {}
        }

        Write-Host "`n❯" -NoNewline -ForegroundColor Green

        return " "
    }

    Write-Verbose "Prompt Git-Focused configurado"
}

function Set-PowerlinePrompt {
    [CmdletBinding()]
    param()

    function global:prompt {
        $location = Get-Location
        $path = $location.Path.Replace($HOME, "~")

        Write-Host " $env:USERNAME " -BackgroundColor DarkBlue -ForegroundColor White -NoNewline
        Write-Host "" -ForegroundColor DarkBlue -BackgroundColor DarkCyan -NoNewline

        Write-Host " $path " -BackgroundColor DarkCyan -ForegroundColor White -NoNewline

        if (Test-Path .git) {
            try {
                $branch = git rev-parse --abbrev-ref HEAD 2>$null
                if ($branch) {
                    Write-Host "" -ForegroundColor DarkCyan -BackgroundColor DarkMagenta -NoNewline
                    Write-Host "  $branch " -BackgroundColor DarkMagenta -ForegroundColor White -NoNewline

                    $status = git status --porcelain 2>$null
                    if ($status) {
                        Write-Host "✗ " -BackgroundColor DarkMagenta -ForegroundColor Red -NoNewline
                    }
                    else {
                        Write-Host "✓ " -BackgroundColor DarkMagenta -ForegroundColor Green -NoNewline
                    }

                    Write-Host "" -ForegroundColor DarkMagenta -NoNewline
                }
                else {
                    Write-Host "" -ForegroundColor DarkCyan -NoNewline
                }
            }
            catch {
                Write-Host "" -ForegroundColor DarkCyan -NoNewline
            }
        }
        else {
            Write-Host "" -ForegroundColor DarkCyan -NoNewline
        }

        Write-Host "`n>" -NoNewline -ForegroundColor Green

        return " "
    }

    Write-Verbose "Prompt Powerline configurado"
}

function Reset-Prompt {
    [CmdletBinding()]
    param()

    try {
        function global:prompt {
            "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "
        }

        Write-Host "✓ Prompt resetado para padrão do PowerShell" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erro ao resetar prompt: $_"
        return $false
    }
}


function Show-ConfirmationDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [string]$Language = "pt-br"
    )

    try {
        Write-Host ""
        Write-Host "? $Message " -ForegroundColor Yellow -NoNewline
        Write-Host "[$(Get-String 'yes' $Language)/$(Get-String 'no' $Language)]: " -ForegroundColor Gray -NoNewline

        $response = Read-Host
        return $response -match "^[YySs]"
    }
    catch {
        Write-Warning "Erro ao exibir diálogo de confirmação: $_"
        return $false
    }
}


function Show-FinalReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Results,

        [Parameter(Mandatory=$true)]
        [timespan]$Duration,

        [Parameter(Mandatory=$true)]
        [string]$LogPath,

        [Parameter(Mandatory=$false)]
        [string]$Language = "pt-br"
    )

    try {
        Write-Host ""
        Write-Host "        RELATÓRIO DE INSTALAÇÃO         " -ForegroundColor Cyan
        Write-Host ""

        $successCount = $Results.Success.Count
        $failedCount = $Results.Failed.Count
        $skippedCount = $Results.Skipped.Count
        $totalCount = $successCount + $failedCount + $skippedCount

        Write-Host "Resumo:" -ForegroundColor White
        Write-Host "  ✓ Instalados com sucesso: $successCount" -ForegroundColor Green
        Write-Host "  ⟲ Já existiam (pulados): $skippedCount" -ForegroundColor Cyan
        Write-Host "  ✗ Falharam: $failedCount" -ForegroundColor Red
        Write-Host "  ─────────────────────────────" -ForegroundColor Gray
        Write-Host "  Total de pacotes: $totalCount" -ForegroundColor White
        Write-Host ""

        $minutes = [math]::Floor($Duration.TotalMinutes)
        $seconds = $Duration.Seconds
        Write-Host "Duração: ${minutes}m ${seconds}s" -ForegroundColor Gray
        Write-Host "Log salvo em: $LogPath" -ForegroundColor Gray
        Write-Host "Estado salvo em: $PSScriptRoot\..\state\env.state.json" -ForegroundColor Gray
        Write-Host ""

        if ($failedCount -gt 0) {
            Write-Host "Pacotes que falharam:" -ForegroundColor Yellow
            foreach ($pkg in $Results.Failed) {
                Write-Host "  ✗ $pkg" -ForegroundColor Red
            }
            Write-Host ""
        }

    }
    catch {
        Write-Warning "Erro ao exibir relatório final: $_"
    }
}


Export-ModuleMember -Function @(
    'Show-Banner',
    'Show-MainMenu',
    'Show-CategoryMenu',
    'Show-OptionsMenu',
    'Show-PackageMenu',

    'Show-ProgressBar',
    'Show-CategoryProgress',
    'Show-GlobalProgress',
    'Show-DownloadProgress',
    'Show-InstallationProgress',
    'Show-MultiProgress',
    'Complete-Progress',

    'Show-Spinner',
    'Show-SpinnerWhile',

    'Write-Status',
    'Show-Box',
    'Clear-LastLine',

    'Get-PromptTemplates',
    'Set-CustomPrompt',
    'Set-MinimalPrompt',
    'Set-DeveloperPrompt',
    'Set-GitFocusedPrompt',
    'Set-PowerlinePrompt',
    'Reset-Prompt',

    'Show-ConfirmationDialog',

    'Show-FinalReport'
)