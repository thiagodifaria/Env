BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . "$projectRoot\core\validation.ps1"
    . "$projectRoot\core\utils.ps1"
}

Describe "Checksum Validation" {
    Context "Test-FileChecksum with different algorithms" {
        BeforeEach {
            $script:testFile = New-TemporaryFile
            "Sample content for checksum testing" | Out-File -FilePath $script:testFile.FullName -Encoding UTF8
        }

        AfterEach {
            if (Test-Path $script:testFile.FullName) {
                Remove-Item $script:testFile.FullName -Force
            }
        }

        It "Should validate SHA256 checksum correctly" {
            $hash = (Get-FileHash -Path $script:testFile.FullName -Algorithm SHA256).Hash

            $result = Test-FileChecksum -FilePath $script:testFile.FullName -ExpectedHash $hash -Algorithm SHA256
            $result | Should -Be $true
        }

        It "Should validate SHA512 checksum correctly" {
            $hash = (Get-FileHash -Path $script:testFile.FullName -Algorithm SHA512).Hash

            $result = Test-FileChecksum -FilePath $script:testFile.FullName -ExpectedHash $hash -Algorithm SHA512
            $result | Should -Be $true
        }

        It "Should validate MD5 checksum correctly" {
            $hash = (Get-FileHash -Path $script:testFile.FullName -Algorithm MD5).Hash

            $result = Test-FileChecksum -FilePath $script:testFile.FullName -ExpectedHash $hash -Algorithm MD5
            $result | Should -Be $true
        }

        It "Should reject incorrect checksum" {
            $result = Test-FileChecksum -FilePath $script:testFile.FullName -ExpectedHash "INVALID" -Algorithm SHA256
            $result | Should -Be $false
        }

        It "Should handle case-insensitive hash comparison" {
            $hash = (Get-FileHash -Path $script:testFile.FullName -Algorithm SHA256).Hash
            $lowerHash = $hash.ToLower()

            $result = Test-FileChecksum -FilePath $script:testFile.FullName -ExpectedHash $lowerHash -Algorithm SHA256
            $result | Should -Be $true
        }
    }

    Context "Get-PackageChecksum" {
        It "Should return checksum information hashtable" {
            Mock Invoke-RestMethod {
                return @{ sha256 = "ABC123" }
            }

            $result = Get-PackageChecksum -PackageId "test-package" -Manager "chocolatey"

            $result | Should -BeOfType [hashtable]
        }

        It "Should handle missing checksum data" {
            Mock Invoke-RestMethod { return $null }

            $result = Get-PackageChecksum -PackageId "nonexistent" -Manager "chocolatey"
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe "Security Dialog" {
    Context "Show-SecurityDialog" {
        It "Should accept valid hash and filename" {
            Mock Read-Host { return "Y" }

            $result = Show-SecurityDialog -Hash "ABC123DEF456" -FileName "test.exe"
            $result | Should -BeOfType [bool]
        }

        It "Should return true for 'Y' input" {
            Mock Read-Host { return "Y" }

            $result = Show-SecurityDialog -Hash "ABC123" -FileName "test.exe"
            $result | Should -Be $true
        }

        It "Should return false for 'N' input" {
            Mock Read-Host { return "N" }

            $result = Show-SecurityDialog -Hash "ABC123" -FileName "test.exe"
            $result | Should -Be $false
        }
    }
}

Describe "JSON Schema Validation" {
    Context "Test-JsonSchema with packages.json" {
        BeforeEach {
            $script:tempJson = New-TemporaryFile
        }

        AfterEach {
            if (Test-Path $script:tempJson.FullName) {
                Remove-Item $script:tempJson.FullName -Force
            }
        }

        It "Should validate correct package structure" {
            $validPackages = @{
                packages = @(
                    @{
                        id = "git"
                        name = "Git"
                        manager = "chocolatey"
                        category = "development"
                        description = "Version control system"
                    }
                )
            } | ConvertTo-Json -Depth 10

            $validPackages | Out-File -FilePath $script:tempJson.FullName -Encoding UTF8

            $result = Test-JsonSchema -JsonPath $script:tempJson.FullName
            $result | Should -Be $true
        }

        It "Should reject JSON missing required fields" {
            $invalidPackages = @{
                packages = @(
                    @{
                        id = "test"
                    }
                )
            } | ConvertTo-Json -Depth 10

            $invalidPackages | Out-File -FilePath $script:tempJson.FullName -Encoding UTF8

            $result = Test-JsonSchema -JsonPath $script:tempJson.FullName
            $result | Should -Be $false
        }

        It "Should validate array of multiple packages" {
            $multiPackages = @{
                packages = @(
                    @{ id = "git"; name = "Git"; manager = "chocolatey"; category = "dev" },
                    @{ id = "vscode"; name = "VS Code"; manager = "winget"; category = "editor" },
                    @{ id = "nodejs"; name = "Node.js"; manager = "chocolatey"; category = "runtime" }
                )
            } | ConvertTo-Json -Depth 10

            $multiPackages | Out-File -FilePath $script:tempJson.FullName -Encoding UTF8

            $result = Test-JsonSchema -JsonPath $script:tempJson.FullName
            $result | Should -Be $true
        }

        It "Should validate optional fields" {
            $packagesWithOptional = @{
                packages = @(
                    @{
                        id = "git"
                        name = "Git"
                        manager = "chocolatey"
                        category = "development"
                        description = "Git VCS"
                        version = "2.40.0"
                        dependencies = @("dependency1")
                        arguments = "--params '/NoShellIntegration'"
                    }
                )
            } | ConvertTo-Json -Depth 10

            $packagesWithOptional | Out-File -FilePath $script:tempJson.FullName -Encoding UTF8

            $result = Test-JsonSchema -JsonPath $script:tempJson.FullName
            $result | Should -Be $true
        }
    }

    Context "Test-PackagesConfig" {
        It "Should load and validate actual packages.json" {
            $packagesPath = "$projectRoot\config\packages.json"

            if (Test-Path $packagesPath) {
                $result = Test-PackagesConfig -ConfigPath $packagesPath
                $result | Should -Be $true
            }
        }

        It "Should return hashtable with validation results" {
            $tempConfig = New-TemporaryFile
            @{ packages = @() } | ConvertTo-Json | Out-File $tempConfig.FullName

            $result = Test-PackagesConfig -ConfigPath $tempConfig.FullName

            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'IsValid'

            Remove-Item $tempConfig -Force
        }
    }
}

Describe "Parameter Validation" {
    Context "Function parameter validation" {
        It "Should enforce ValidateNotNullOrEmpty on FilePath" {
            { Test-FileChecksum -FilePath "" -ExpectedHash "ABC" -Algorithm SHA256 } | Should -Throw
        }

        It "Should enforce ValidateSet on Algorithm" {
            { Test-FileChecksum -FilePath "test.txt" -ExpectedHash "ABC" -Algorithm "InvalidAlgo" } | Should -Throw
        }

        It "Should accept valid algorithm from set" {
            Mock Test-Path { return $true }
            Mock Get-FileHash { return @{ Hash = "ABC123" } }

            { Test-FileChecksum -FilePath "test.txt" -ExpectedHash "ABC123" -Algorithm "SHA256" } | Should -Not -Throw
        }
    }
}

Describe "Edge Cases and Error Handling" {
    Context "File validation with special characters" {
        It "Should handle files with spaces in name" {
            $tempFile = New-TemporaryFile
            $newPath = Join-Path (Split-Path $tempFile.FullName) "file with spaces.txt"
            Move-Item $tempFile.FullName $newPath

            "content" | Out-File $newPath

            $hash = (Get-FileHash -Path $newPath -Algorithm SHA256).Hash
            $result = Test-FileChecksum -FilePath $newPath -ExpectedHash $hash -Algorithm SHA256

            $result | Should -Be $true

            Remove-Item $newPath -Force
        }

        It "Should handle files with unicode characters" {
            $tempFile = New-TemporaryFile
            $newPath = Join-Path (Split-Path $tempFile.FullName) "arquivo_teste_ção.txt"
            Move-Item $tempFile.FullName $newPath

            "conteúdo" | Out-File $newPath -Encoding UTF8

            $hash = (Get-FileHash -Path $newPath -Algorithm SHA256).Hash
            $result = Test-FileChecksum -FilePath $newPath -ExpectedHash $hash -Algorithm SHA256

            $result | Should -Be $true

            Remove-Item $newPath -Force
        }
    }

    Context "Large file handling" {
        It "Should handle empty files" {
            $tempFile = New-TemporaryFile

            $hash = (Get-FileHash -Path $tempFile.FullName -Algorithm SHA256).Hash
            $result = Test-FileChecksum -FilePath $tempFile.FullName -ExpectedHash $hash -Algorithm SHA256

            $result | Should -Be $true

            Remove-Item $tempFile -Force
        }
    }
}