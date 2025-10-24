BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . "$projectRoot\core\utils.ps1"
    . "$projectRoot\core\validation.ps1"
    . "$projectRoot\core\packages.ps1"
    . "$projectRoot\core\error-handler.ps1"
}

Describe "Core Utilities" {
    Context "Test-IsAdmin" {
        It "Should return a boolean value" {
            $result = Test-IsAdmin
            $result | Should -BeOfType [bool]
        }
    }

    Context "Get-EnvRoot" {
        It "Should return a valid directory path" {
            $result = Get-EnvRoot
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }

        It "Should return an existing directory" {
            $result = Get-EnvRoot
            Test-Path $result | Should -Be $true
        }
    }

    Context "Write-SuccessMessage and Write-ErrorMessage" {
        It "Should accept non-empty string message for success" {
            { Write-SuccessMessage -Message "Test success" } | Should -Not -Throw
        }

        It "Should accept non-empty string message for error" {
            { Write-ErrorMessage -Message "Test error" } | Should -Not -Throw
        }

        It "Should throw on null or empty message" {
            { Write-SuccessMessage -Message "" } | Should -Throw
            { Write-ErrorMessage -Message $null } | Should -Throw
        }
    }
}

Describe "Validation Functions" {
    Context "Test-FileChecksum" {
        BeforeEach {
            $testFile = New-TemporaryFile
            "Test content" | Out-File -FilePath $testFile.FullName -Encoding UTF8
            $script:tempFile = $testFile.FullName
        }

        AfterEach {
            if (Test-Path $script:tempFile) {
                Remove-Item $script:tempFile -Force
            }
        }

        It "Should calculate SHA256 checksum for valid file" {
            $result = Get-FileHash -Path $script:tempFile -Algorithm SHA256
            $checksum = $result.Hash

            Test-FileChecksum -FilePath $script:tempFile -ExpectedHash $checksum -Algorithm SHA256 | Should -Be $true
        }

        It "Should return false for incorrect checksum" {
            Test-FileChecksum -FilePath $script:tempFile -ExpectedHash "INVALIDHASH123" -Algorithm SHA256 | Should -Be $false
        }

        It "Should throw for non-existent file" {
            { Test-FileChecksum -FilePath "C:\nonexistent.txt" -ExpectedHash "ABC123" -Algorithm SHA256 } | Should -Throw
        }
    }

    Context "Test-JsonSchema" {
        It "Should validate correct JSON structure" {
            $validJson = @{
                packages = @(
                    @{ id = "test"; name = "Test"; manager = "chocolatey"; category = "test" }
                )
            } | ConvertTo-Json -Depth 10

            $tempJson = New-TemporaryFile
            $validJson | Out-File -FilePath $tempJson.FullName -Encoding UTF8

            $result = Test-JsonSchema -JsonPath $tempJson.FullName
            $result | Should -Be $true

            Remove-Item $tempJson -Force
        }
    }
}

Describe "Package Manager Functions" {
    Context "Get-BestPackageManager" {
        It "Should return a valid package manager name" {
            Mock Get-Command {
                return @{ Name = "choco.exe" }
            } -ParameterFilter { $Name -eq "choco" }

            $result = Get-BestPackageManager
            $result | Should -BeIn @('chocolatey', 'winget', 'scoop')
        }
    }

    Context "Test-PackageManagerHealth" {
        It "Should return hashtable with status information" {
            $result = Test-PackageManagerHealth

            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'chocolatey'
            $result.Keys | Should -Contain 'winget'
            $result.Keys | Should -Contain 'scoop'
        }

        It "Should have boolean Available property for each manager" {
            $result = Test-PackageManagerHealth

            $result['chocolatey'].Available | Should -BeOfType [bool]
            $result['winget'].Available | Should -BeOfType [bool]
            $result['scoop'].Available | Should -BeOfType [bool]
        }
    }
}

Describe "Error Handler Functions" {
    Context "Write-ErrorLog" {
        BeforeEach {
            $script:testError = "Test error message"
            $script:testContext = @{ Operation = "TestOp"; Package = "TestPkg" }
        }

        It "Should create error log file" {
            Write-ErrorLog -ErrorMessage $script:testError -Context $script:testContext

            $envRoot = Get-EnvRoot
            $logDir = Join-Path $envRoot "logs"

            Test-Path $logDir | Should -Be $true
        }

        It "Should accept error context hashtable" {
            { Write-ErrorLog -ErrorMessage $script:testError -Context $script:testContext } | Should -Not -Throw
        }
    }

    Context "Invoke-WithRetry" {
        It "Should execute scriptblock successfully" {
            $result = Invoke-WithRetry -ScriptBlock { return "Success" } -MaxRetries 3

            $result.Success | Should -Be $true
            $result.Result | Should -Be "Success"
        }

        It "Should retry on failure up to max retries" {
            $script:attemptCount = 0

            $result = Invoke-WithRetry -ScriptBlock {
                $script:attemptCount++
                if ($script:attemptCount -lt 3) {
                    throw "Simulated failure"
                }
                return "Success after retries"
            } -MaxRetries 5

            $result.Success | Should -Be $true
            $script:attemptCount | Should -Be 3
        }

        It "Should fail after max retries exceeded" {
            $result = Invoke-WithRetry -ScriptBlock {
                throw "Always fails"
            } -MaxRetries 2

            $result.Success | Should -Be $false
            $result.Attempts | Should -Be 2
        }
    }

    Context "Test-Prerequisites" {
        It "Should return hashtable with prerequisite checks" {
            $result = Test-Prerequisites

            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'PowerShellVersion'
            $result.Keys | Should -Contain 'IsAdmin'
            $result.Keys | Should -Contain 'InternetConnection'
        }

        It "Should verify PowerShell version is 5.1 or higher" {
            $result = Test-Prerequisites

            $result.PowerShellVersion | Should -BeGreaterOrEqual ([Version]"5.1")
        }
    }
}

Describe "Integration - Full Package Installation Flow" {
    Context "Package Installation Prerequisites" {
        It "Should have all required core modules loadable" {
            { . "$projectRoot\core\utils.ps1" } | Should -Not -Throw
            { . "$projectRoot\core\packages.ps1" } | Should -Not -Throw
            { . "$projectRoot\core\validation.ps1" } | Should -Not -Throw
            { . "$projectRoot\core\error-handler.ps1" } | Should -Not -Throw
        }

        It "Should verify package manager availability" {
            $health = Test-PackageManagerHealth
            $anyAvailable = $health.Values | Where-Object { $_.Available -eq $true }

            $anyAvailable | Should -Not -BeNullOrEmpty
        }
    }
}