$script:StatePath = "$PSScriptRoot\..\state\env.state.json"

function Initialize-State {
    if (-not (Test-Path $script:StatePath)) {
        $initialState = @{
            version = "1.0.0"
            last_run = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            installed_packages = @()
        }
        
        $initialState | ConvertTo-Json | Set-Content $script:StatePath
        Write-Log "Estado inicializado" "INFO"
    }
}

function Get-StateData {
    if (Test-Path $script:StatePath) {
        return Get-Content $script:StatePath | ConvertFrom-Json
    }
    return $null
}

function Update-StateData {
    param(
        [array]$InstalledPackages
    )
    
    $state = @{
        version = "1.0.0"
        last_run = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        installed_packages = $InstalledPackages
    }
    
    $state | ConvertTo-Json | Set-Content $script:StatePath
    Write-Log "Estado atualizado" "INFO"
}

function Add-InstalledPackage {
    param([string]$PackageName)
    
    $state = Get-StateData
    
    if ($state -and $state.installed_packages -notcontains $PackageName) {
        $state.installed_packages += $PackageName
        Update-StateData -InstalledPackages $state.installed_packages
    }
}

function Get-InstalledPackages {
    $state = Get-StateData
    if ($state) {
        return $state.installed_packages
    }
    return @()
}

function Test-PackageInState {
    param([string]$PackageName)
    
    $installed = Get-InstalledPackages
    return $installed -contains $PackageName
}

function Compare-StateWithSystem {
    $statePackages = Get-InstalledPackages
    $actualPackages = @()
    
    foreach ($pkg in $statePackages) {
        if (Test-PackageInstalled -PackageName $pkg) {
            $actualPackages += $pkg
        }
    }
    
    if ($actualPackages.Count -ne $statePackages.Count) {
        Update-StateData -InstalledPackages $actualPackages
        Write-Log "Estado sincronizado com sistema" "INFO"
    }
    
    return $actualPackages
}