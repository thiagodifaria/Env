BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . "$projectRoot\core\utils.ps1"
    . "$projectRoot\installers\terminal-env.ps1"
    . "$projectRoot\installers\modern-tools.ps1"
    . "$projectRoot\installers\git-env.ps1"
}

Describe "Terminal Setup Functions" {
    Context "Get-OhMyPoshThemes" {
        It "Should return array of theme names" {
            Mock Get-ChildItem {
                return @(
                    @{ BaseName = "theme1" },
                    @{ BaseName = "theme2" }
                )
            }

            $result = Get-OhMyPoshThemes
            $result | Should -BeOfType [array]
        }
    }

    Context "Get-StarshipPresets" {
        It "Should return array of preset configurations" {
            $result = Get-StarshipPresets
            $result | Should -BeOfType [array]
            $result.Count | Should -BeGreaterThan 0
        }

        It "Should have Name and Description properties" {
            $result = Get-StarshipPresets
            $result[0] | Should -HaveProperty Name
            $result[0] | Should -HaveProperty Description
        }
    }

    Context "Install-NerdFont" {
        It "Should accept valid font name parameter" {
            Mock Invoke-WebRequest { }
            Mock Expand-Archive { }
            Mock Copy-Item { }

            { Install-NerdFont -FontName "CascadiaCode" } | Should -Not -Throw
        }

        It "Should validate font name from set" {
            { Install-NerdFont -FontName "InvalidFont" } | Should -Throw
        }
    }
}

Describe "Modern Tools Functions" {
    Context "Install-Bat" {
        It "Should check if bat is already installed" {
            Mock Get-Command { return $true } -ParameterFilter { $Name -eq "bat" }

            $result = Install-Bat
            $result | Should -Be $true
        }

        It "Should attempt installation if not found" {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "bat" }
            Mock Get-Command { return $true } -ParameterFilter { $Name -eq "choco" }
            Mock choco { }

            Install-Bat
        }
    }

    Context "Install-Eza" {
        It "Should verify eza command after installation" {
            Mock Get-Command { return $true } -ParameterFilter { $Name -eq "eza" }

            $result = Install-Eza
            $result | Should -Be $true
        }
    }

    Context "Install-Fzf" {
        It "Should return boolean result" {
            Mock Get-Command { return $true } -ParameterFilter { $Name -eq "fzf" }

            $result = Install-Fzf
            $result | Should -BeOfType [bool]
        }
    }

    Context "Install-Ripgrep" {
        It "Should handle already installed scenario" {
            Mock Get-Command { return $true } -ParameterFilter { $Name -eq "rg" }

            $result = Install-Ripgrep
            $result | Should -Be $true
        }
    }

    Context "Install-Zoxide" {
        It "Should return installation status" {
            Mock Get-Command { return $true } -ParameterFilter { $Name -eq "zoxide" }

            $result = Install-Zoxide
            $result | Should -BeOfType [bool]
        }
    }

    Context "Install-AllModernTools" {
        It "Should return hashtable with results for all tools" {
            Mock Install-Bat { return $true }
            Mock Install-Eza { return $true }
            Mock Install-Fzf { return $true }
            Mock Install-Ripgrep { return $true }
            Mock Install-Zoxide { return $true }

            $result = Install-AllModernTools

            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'bat'
            $result.Keys | Should -Contain 'eza'
            $result.Keys | Should -Contain 'fzf'
            $result.Keys | Should -Contain 'ripgrep'
            $result.Keys | Should -Contain 'zoxide'
        }
    }
}

Describe "Git Setup Functions" {
    Context "Install-Git" {
        It "Should detect existing Git installation" {
            Mock Get-Command { return $true } -ParameterFilter { $Name -eq "git" }

            $result = Install-Git
            $result | Should -Be $true
        }

        It "Should attempt installation via winget or choco" {
            Mock Get-Command { return $null } -ParameterFilter { $Name -eq "git" }
            Mock Get-Command { return $true } -ParameterFilter { $Name -eq "winget" }
            Mock winget { }

            Install-Git
        }
    }

    Context "Configure-GitUser" {
        It "Should accept valid name and email" {
            Mock git { }

            { Configure-GitUser -Name "Test User" -Email "test@example.com" } | Should -Not -Throw
        }

        It "Should require non-empty name parameter" {
            { Configure-GitUser -Name "" -Email "test@example.com" } | Should -Throw
        }

        It "Should require non-empty email parameter" {
            { Configure-GitUser -Name "Test User" -Email "" } | Should -Throw
        }
    }

    Context "Set-GitAliases" {
        It "Should configure standard Git aliases" {
            Mock git { }

            $result = Set-GitAliases
            $result | Should -Be $true
        }
    }

    Context "Configure-GitCredentials" {
        It "Should accept valid credential helper" {
            Mock git { }

            { Configure-GitCredentials -Helper "manager-core" } | Should -Not -Throw
        }

        It "Should validate helper parameter from set" {
            { Configure-GitCredentials -Helper "invalid-helper" } | Should -Throw
        }
    }

    Context "Initialize-GitConfig" {
        It "Should set default Git configurations" {
            Mock git { }

            $result = Initialize-GitConfig
            $result | Should -Be $true
        }
    }

    Context "Import-GitAliases" {
        It "Should accept custom config path" {
            Mock Test-Path { return $true }
            Mock git { }

            { Import-GitAliases -ConfigPath "C:\custom\path\aliases.gitconfig" } | Should -Not -Throw
        }

        It "Should warn on missing config file" {
            Mock Test-Path { return $false }

            $result = Import-GitAliases -ConfigPath "C:\nonexistent\aliases.gitconfig"
            $result | Should -Be $false
        }
    }
}

Describe "Installer Integration Tests" {
    Context "Modern Tools Status" {
        It "Should report status of all modern tools" {
            . "$projectRoot\config\shell-integration.ps1"

            $result = Get-ModernToolsStatus

            $result | Should -BeOfType [hashtable]
            $result.Keys.Count | Should -BeGreaterThan 0
        }
    }

    Context "Terminal Configuration Files" {
        It "Should have Oh My Posh theme file" {
            $themePath = "$projectRoot\config\terminal-themes\oh-my-posh\env-default.omp.json"
            Test-Path $themePath | Should -Be $true
        }

        It "Should have Starship configuration file" {
            $starshipPath = "$projectRoot\config\terminal-themes\starship\starship.toml"
            Test-Path $starshipPath | Should -Be $true
        }

        It "Should have valid JSON in Oh My Posh theme" {
            $themePath = "$projectRoot\config\terminal-themes\oh-my-posh\env-default.omp.json"
            $content = Get-Content $themePath -Raw
            { $content | ConvertFrom-Json } | Should -Not -Throw
        }
    }
}