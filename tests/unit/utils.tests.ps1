BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . "$projectRoot\utils\cache.ps1"
    . "$projectRoot\utils\parallel.ps1"
    . "$projectRoot\utils\dotfiles.ps1"
    . "$projectRoot\core\utils.ps1"
}

Describe "Cache Functions" {
    Context "Get-CacheDirectory" {
        It "Should return valid cache directory path" {
            $result = Get-CacheDirectory

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeLike "*cache*"
        }

        It "Should create directory if not exists" {
            $cacheDir = Get-CacheDirectory

            Test-Path $cacheDir | Should -Be $true
        }
    }

    Context "Set-CachedData and Get-CachedData" {
        BeforeEach {
            $script:testKey = "test-cache-key"
            $script:testData = @{ Value = "Test Data"; Number = 42 }
        }

        It "Should cache data successfully" {
            $result = Set-CachedData -Key $script:testKey -Data $script:testData -TTL 3600

            $result | Should -Be $true
        }

        It "Should retrieve cached data" {
            Set-CachedData -Key $script:testKey -Data $script:testData -TTL 3600

            $result = Get-CachedData -Key $script:testKey

            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be "Test Data"
            $result.Number | Should -Be 42
        }

        It "Should return null for non-existent key" {
            $result = Get-CachedData -Key "nonexistent-key"

            $result | Should -BeNullOrEmpty
        }

        It "Should respect TTL expiration" {
            Set-CachedData -Key "expire-test" -Data @{ Value = "Expires" } -TTL 1

            Start-Sleep -Seconds 2

            $result = Get-CachedData -Key "expire-test"

            $result | Should -BeNullOrEmpty
        }

        AfterEach {
            Clear-PackageCache
        }
    }

    Context "Set-CachedPackage and Get-CachedPackage" {
        BeforeEach {
            $script:packageId = "test-package"
            $script:packageInfo = @{
                Name = "Test Package"
                Version = "1.0.0"
                Manager = "chocolatey"
            }
        }

        It "Should cache package information" {
            $result = Set-CachedPackage -PackageId $script:packageId -PackageInfo $script:packageInfo

            $result | Should -Be $true
        }

        It "Should retrieve cached package" {
            Set-CachedPackage -PackageId $script:packageId -PackageInfo $script:packageInfo

            $result = Get-CachedPackage -PackageId $script:packageId

            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be "Test Package"
            $result.Manager | Should -Be "chocolatey"
        }

        AfterEach {
            Clear-PackageCache
        }
    }

    Context "Get-CacheInfo" {
        It "Should return cache statistics" {
            $result = Get-CacheInfo

            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'TotalItems'
            $result.Keys | Should -Contain 'TotalSize'
        }

        It "Should count cached items correctly" {
            Clear-PackageCache

            Set-CachedData -Key "item1" -Data @{ Value = 1 } -TTL 3600
            Set-CachedData -Key "item2" -Data @{ Value = 2 } -TTL 3600

            $result = Get-CacheInfo

            $result.TotalItems | Should -BeGreaterOrEqual 2
        }
    }

    Context "Clear-PackageCache" {
        It "Should clear all cached data" {
            Set-CachedData -Key "clear-test" -Data @{ Value = "Test" } -TTL 3600

            Clear-PackageCache

            $result = Get-CachedData -Key "clear-test"
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe "Parallel Installation Functions" {
    Context "Resolve-PackageDependencies" {
        It "Should return ordered package list" {
            $packages = @(
                @{ id = "pkg1"; dependencies = @() },
                @{ id = "pkg2"; dependencies = @("pkg1") },
                @{ id = "pkg3"; dependencies = @("pkg1", "pkg2") }
            )

            $result = Resolve-PackageDependencies -Packages $packages

            $result | Should -BeOfType [array]
            $result.Count | Should -Be 3
        }

        It "Should handle packages with no dependencies" {
            $packages = @(
                @{ id = "independent1"; dependencies = @() },
                @{ id = "independent2"; dependencies = @() }
            )

            $result = Resolve-PackageDependencies -Packages $packages

            $result.Count | Should -Be 2
        }

        It "Should detect circular dependencies" {
            $packages = @(
                @{ id = "pkg1"; dependencies = @("pkg2") },
                @{ id = "pkg2"; dependencies = @("pkg1") }
            )

            { Resolve-PackageDependencies -Packages $packages } | Should -Throw
        }
    }

    Context "Invoke-ParallelInstall" {
        It "Should accept array of packages" {
            Mock Start-Job { return @{ Id = 1 } }
            Mock Wait-Job { }
            Mock Receive-Job { return @{ Success = $true } }
            Mock Remove-Job { }

            $packages = @(
                @{ id = "test1"; name = "Test 1"; manager = "chocolatey" }
            )

            { Invoke-ParallelInstall -Packages $packages -MaxConcurrent 2 } | Should -Not -Throw
        }

        It "Should validate MaxConcurrent range" {
            $packages = @(@{ id = "test"; name = "Test"; manager = "chocolatey" })

            { Invoke-ParallelInstall -Packages $packages -MaxConcurrent 0 } | Should -Throw
            { Invoke-ParallelInstall -Packages $packages -MaxConcurrent 11 } | Should -Throw
        }
    }
}

Describe "Dotfiles Functions" {
    Context "Export-Dotfiles" {
        BeforeEach {
            $script:tempDest = Join-Path $env:TEMP "dotfiles-test-$(Get-Random)"
        }

        AfterEach {
            if (Test-Path $script:tempDest) {
                Remove-Item $script:tempDest -Recurse -Force
            }
        }

        It "Should create destination directory" {
            Export-Dotfiles -Destination $script:tempDest

            Test-Path $script:tempDest | Should -Be $true
        }

        It "Should export existing dotfiles" {
            $result = Export-Dotfiles -Destination $script:tempDest

            $result | Should -Be $script:tempDest
        }

        It "Should create subdirectories for organized files" {
            Export-Dotfiles -Destination $script:tempDest

            $powerShellDir = Join-Path $script:tempDest "PowerShell"
            if (Test-Path $PROFILE) {
                Test-Path $powerShellDir | Should -Be $true
            }
        }
    }

    Context "Import-Dotfiles" {
        BeforeEach {
            $script:tempSource = Join-Path $env:TEMP "dotfiles-import-$(Get-Random)"
            New-Item -ItemType Directory -Path $script:tempSource -Force | Out-Null

            $psDir = Join-Path $script:tempSource "PowerShell"
            New-Item -ItemType Directory -Path $psDir -Force | Out-Null

            "# Test profile" | Out-File -FilePath (Join-Path $psDir "profile.ps1")
        }

        AfterEach {
            if (Test-Path $script:tempSource) {
                Remove-Item $script:tempSource -Recurse -Force
            }
        }

        It "Should import dotfiles from source" {
            { Import-Dotfiles -Source $script:tempSource } | Should -Not -Throw
        }

        It "Should handle non-existent source directory" {
            { Import-Dotfiles -Source "C:\NonExistent\Path" } | Should -Throw
        }
    }

    Context "Initialize-DotfilesRepo" {
        It "Should validate remote URL parameter" {
            Mock Test-Path { return $false }
            Mock New-Item { }
            Mock Export-Dotfiles { return "C:\test" }
            Mock Push-Location { }
            Mock Pop-Location { }
            Mock git { }

            { Initialize-DotfilesRepo -RemoteUrl "https://github.com/user/dotfiles.git" } | Should -Not -Throw
        }

        It "Should handle existing dotfiles directory" {
            Mock Test-Path { return $true }

            $result = Initialize-DotfilesRepo -RemoteUrl "https://github.com/user/dotfiles.git"

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Sync-Dotfiles" {
        It "Should clone repository if not exists" {
            Mock Test-Path { return $false }
            Mock git { }
            Mock Import-Dotfiles { return $true }

            { Sync-Dotfiles -RemoteRepo "https://github.com/user/dotfiles.git" } | Should -Not -Throw
        }

        It "Should pull updates if repository exists" {
            Mock Test-Path { return $true }
            Mock Push-Location { }
            Mock Pop-Location { }
            Mock git { }
            Mock Import-Dotfiles { return $true }

            { Sync-Dotfiles -RemoteRepo "https://github.com/user/dotfiles.git" } | Should -Not -Throw
        }
    }
}

Describe "Shell Integration Functions" {
    BeforeAll {
        . "$projectRoot\config\shell-integration.ps1"
    }

    Context "Get-ModernToolsStatus" {
        It "Should return status of all modern tools" {
            $result = Get-ModernToolsStatus

            $result | Should -BeOfType [hashtable]
        }

        It "Should check for bat, eza, fzf, ripgrep, zoxide" {
            $result = Get-ModernToolsStatus

            $result.Keys | Should -Contain 'bat'
            $result.Keys | Should -Contain 'eza'
            $result.Keys | Should -Contain 'fzf'
            $result.Keys | Should -Contain 'ripgrep'
            $result.Keys | Should -Contain 'zoxide'
        }

        It "Should have boolean Installed property" {
            $result = Get-ModernToolsStatus

            foreach ($tool in $result.Keys) {
                $result[$tool].Installed | Should -BeOfType [bool]
            }
        }
    }

    Context "Initialize-ShellIntegration" {
        It "Should setup shell integration" {
            Mock Add-ToProfile { return $true }

            { Initialize-ShellIntegration } | Should -Not -Throw
        }
    }
}