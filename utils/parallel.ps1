function Invoke-ParallelInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [array]$Packages,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 10)]
        [int]$MaxThreads = 3
    )

    try {
        Write-Host "`nInstalação paralela iniciada..." -ForegroundColor Cyan
        Write-Host "Packages: $($Packages.Count) | Threads: $MaxThreads" -ForegroundColor Gray

        if ($Packages.Count -eq 0) {
            Write-Host "Nenhum package para instalar" -ForegroundColor Yellow
            return @{ Success = @(); Failed = @() }
        }

        $results = @{
            Success = @()
            Failed = @()
        }

        $independentPackages = $Packages | Where-Object { -not $_.dependencies -or $_.dependencies.Count -eq 0 }
        $dependentPackages = $Packages | Where-Object { $_.dependencies -and $_.dependencies.Count -gt 0 }

        if ($independentPackages.Count -gt 0) {
            Write-Host "`nInstalando $($independentPackages.Count) packages independentes em paralelo..." -ForegroundColor Cyan

            $jobs = @()

            foreach ($pkg in $independentPackages) {
                while ((Get-Job -State Running).Count -ge $MaxThreads) {
                    Start-Sleep -Milliseconds 500
                    Get-Job -State Completed | ForEach-Object {
                        $jobResult = Receive-Job -Job $_ -Keep
                        Remove-Job -Job $_

                        if ($jobResult.Success) {
                            $results.Success += $jobResult.PackageName
                        }
                        else {
                            $results.Failed += $jobResult.PackageName
                        }
                    }
                }

                $job = Start-Job -ScriptBlock {
                    param($package, $scriptRoot)

                    try {
                        . "$scriptRoot\..\core\packages.ps1"

                        $installResult = Install-PackageWithFallback -Package $package

                        return @{
                            Success = $installResult.Success
                            PackageName = $package.name
                            Manager = $installResult.Manager
                        }
                    }
                    catch {
                        return @{
                            Success = $false
                            PackageName = $package.name
                            Error = $_.Exception.Message
                        }
                    }
                } -ArgumentList $pkg, $PSScriptRoot

                $jobs += $job
                Write-Verbose "Job iniciado para: $($pkg.name)"
            }

            while ((Get-Job -State Running).Count -gt 0) {
                Start-Sleep -Milliseconds 500
                Get-Job -State Completed | ForEach-Object {
                    $jobResult = Receive-Job -Job $_ -Keep
                    Remove-Job -Job $_

                    if ($jobResult.Success) {
                        $results.Success += $jobResult.PackageName
                        Write-Host "  ✓ $($jobResult.PackageName)" -ForegroundColor Green
                    }
                    else {
                        $results.Failed += $jobResult.PackageName
                        Write-Host "  ✗ $($jobResult.PackageName)" -ForegroundColor Red
                    }
                }
            }

            Get-Job | Remove-Job -Force
        }

        if ($dependentPackages.Count -gt 0) {
            Write-Host "`nInstalando $($dependentPackages.Count) packages com dependências sequencialmente..." -ForegroundColor Cyan

            $sortedPackages = Resolve-PackageDependencies -Packages $dependentPackages -InstalledPackages $results.Success

            foreach ($pkg in $sortedPackages) {
                Write-Host "Instalando $($pkg.name)..." -ForegroundColor Yellow

                try {
                    . "$PSScriptRoot\..\core\packages.ps1"
                    $installResult = Install-PackageWithFallback -Package $pkg

                    if ($installResult.Success) {
                        $results.Success += $pkg.name
                        Write-Host "  ✓ $($pkg.name)" -ForegroundColor Green
                    }
                    else {
                        $results.Failed += $pkg.name
                        Write-Host "  ✗ $($pkg.name)" -ForegroundColor Red
                    }
                }
                catch {
                    $results.Failed += $pkg.name
                    Write-Host "  ✗ $($pkg.name): $_" -ForegroundColor Red
                }
            }
        }

        Write-Host "`nResumo da instalação paralela:" -ForegroundColor Cyan
        Write-Host "  Sucesso: $($results.Success.Count)" -ForegroundColor Green
        Write-Host "  Falhas: $($results.Failed.Count)" -ForegroundColor Red

        return $results
    }
    catch {
        Write-Error "Erro na instalação paralela: $_"
        return @{ Success = @(); Failed = @() }
    }
}

function Resolve-PackageDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Packages,

        [Parameter(Mandatory=$false)]
        [array]$InstalledPackages = @()
    )

    try {
        Write-Verbose "Resolvendo dependências de packages"

        $sorted = @()
        $visited = @{}
        $visiting = @{}

        function Visit-Package($pkg) {
            if ($visited.ContainsKey($pkg.id)) {
                return
            }

            if ($visiting.ContainsKey($pkg.id)) {
                throw "Dependência circular detectada: $($pkg.id)"
            }

            $visiting[$pkg.id] = $true

            if ($pkg.dependencies) {
                foreach ($depId in $pkg.dependencies) {
                    if ($depId -in $InstalledPackages) {
                        continue
                    }

                    $depPkg = $Packages | Where-Object { $_.id -eq $depId }

                    if ($depPkg) {
                        Visit-Package $depPkg
                    }
                }
            }

            $visiting.Remove($pkg.id)
            $visited[$pkg.id] = $true
            $sorted += $pkg
        }

        foreach ($pkg in $Packages) {
            if (-not $visited.ContainsKey($pkg.id)) {
                Visit-Package $pkg
            }
        }

        Write-Verbose "Dependências resolvidas: $($sorted.Count) packages ordenados"

        return $sorted
    }
    catch {
        Write-Error "Erro ao resolver dependências: $_"
        return $Packages
    }
}

function Test-ParallelInstallPerformance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Packages
    )

    try {
        Write-Host "`nTestando performance de instalação..." -ForegroundColor Cyan

        Write-Host "`nInstalação sequencial:" -ForegroundColor Yellow
        $sequentialStart = Get-Date
        $sequentialResults = @{ Success = @(); Failed = @() }

        foreach ($pkg in $Packages) {
            Write-Host "  Simulando instalação de $($pkg.name)..." -ForegroundColor Gray
            Start-Sleep -Milliseconds 500
            $sequentialResults.Success += $pkg.name
        }

        $sequentialDuration = (Get-Date) - $sequentialStart
        Write-Host "Tempo: $([math]::Round($sequentialDuration.TotalSeconds, 2))s" -ForegroundColor Cyan

        Write-Host "`nInstalação paralela (3 threads):" -ForegroundColor Yellow
        $parallelStart = Get-Date

        $jobs = @()
        $MaxThreads = 3

        foreach ($pkg in $Packages) {
            while ((Get-Job -State Running).Count -ge $MaxThreads) {
                Start-Sleep -Milliseconds 100
            }

            $job = Start-Job -ScriptBlock {
                param($packageName)
                Start-Sleep -Milliseconds 500
                return $packageName
            } -ArgumentList $pkg.name

            $jobs += $job
        }

        $parallelResults = @()
        while ((Get-Job -State Running).Count -gt 0) {
            Start-Sleep -Milliseconds 100
            Get-Job -State Completed | ForEach-Object {
                $parallelResults += (Receive-Job -Job $_)
                Remove-Job -Job $_
            }
        }

        Get-Job | Remove-Job -Force

        $parallelDuration = (Get-Date) - $parallelStart
        Write-Host "Tempo: $([math]::Round($parallelDuration.TotalSeconds, 2))s" -ForegroundColor Cyan

        $improvement = [math]::Round((1 - ($parallelDuration.TotalSeconds / $sequentialDuration.TotalSeconds)) * 100, 2)

        Write-Host "`nMelhoria: $improvement%" -ForegroundColor Green

        return @{
            SequentialTime = $sequentialDuration.TotalSeconds
            ParallelTime = $parallelDuration.TotalSeconds
            Improvement = $improvement
        }
    }
    catch {
        Write-Error "Erro no teste de performance: $_"
        return $null
    }
}