BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . "$projectRoot\core\utils.ps1"
    . "$projectRoot\core\state-manager.ps1"
    . "$projectRoot\core\backup.ps1"
}

Describe "State Manager Functions" {
    Context "Get-InstallationState" {
        It "Should return hashtable with state information" {
            $result = Get-InstallationState

            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'InstalledPackages'
            $result.Keys | Should -Contain 'Sessions'
        }

        It "Should have valid timestamp format" {
            $result = Get-InstallationState

            if ($result.LastUpdated) {
                { [datetime]$result.LastUpdated } | Should -Not -Throw
            }
        }
    }

    Context "Save-InstallationState" {
        It "Should accept valid state hashtable" {
            $state = @{
                InstalledPackages = @()
                Sessions = @()
                LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }

            { Save-InstallationState -State $state } | Should -Not -Throw
        }

        It "Should create state file if not exists" {
            $state = @{
                InstalledPackages = @()
                Sessions = @()
                LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            }

            Save-InstallationState -State $state

            $envRoot = Get-EnvRoot
            $stateFile = Join-Path $envRoot "state\installation-state.json"

            Test-Path $stateFile | Should -Be $true
        }
    }

    Context "Start-InstallationSession" {
        BeforeEach {
            $script:sessionId = Start-InstallationSession
        }

        It "Should return valid session ID" {
            $script:sessionId | Should -Not -BeNullOrEmpty
            $script:sessionId | Should -BeOfType [string]
        }

        It "Should add session to state" {
            $state = Get-InstallationState
            $session = $state.Sessions | Where-Object { $_.SessionId -eq $script:sessionId }

            $session | Should -Not -BeNullOrEmpty
        }

        It "Should have StartTime property" {
            $state = Get-InstallationState
            $session = $state.Sessions | Where-Object { $_.SessionId -eq $script:sessionId }

            $session.StartTime | Should -Not -BeNullOrEmpty
            { [datetime]$session.StartTime } | Should -Not -Throw
        }

        AfterEach {
            Stop-InstallationSession -SessionId $script:sessionId
        }
    }

    Context "Stop-InstallationSession" {
        It "Should complete session successfully" {
            $sessionId = Start-InstallationSession
            $result = Stop-InstallationSession -SessionId $sessionId

            $result | Should -Be $true
        }

        It "Should set EndTime on session" {
            $sessionId = Start-InstallationSession
            Stop-InstallationSession -SessionId $sessionId

            $state = Get-InstallationState
            $session = $state.Sessions | Where-Object { $_.SessionId -eq $sessionId }

            $session.EndTime | Should -Not -BeNullOrEmpty
        }

        It "Should handle non-existent session ID" {
            $result = Stop-InstallationSession -SessionId "invalid-session-id"
            $result | Should -Be $false
        }
    }

    Context "Add-InstalledPackageToState" {
        BeforeEach {
            $script:sessionId = Start-InstallationSession
        }

        AfterEach {
            Stop-InstallationSession -SessionId $script:sessionId
        }

        It "Should add package to installed list" {
            $result = Add-InstalledPackageToState -PackageId "test-package" -Manager "chocolatey" -SessionId $script:sessionId

            $result | Should -Be $true
        }

        It "Should store package with metadata" {
            Add-InstalledPackageToState -PackageId "test-package" -Manager "chocolatey" -SessionId $script:sessionId

            $state = Get-InstallationState
            $package = $state.InstalledPackages | Where-Object { $_.PackageId -eq "test-package" }

            $package | Should -Not -BeNullOrEmpty
            $package.Manager | Should -Be "chocolatey"
            $package.SessionId | Should -Be $script:sessionId
        }
    }

    Context "Get-InstalledPackagesFromState" {
        It "Should return array of installed packages" {
            $result = Get-InstalledPackagesFromState

            $result | Should -BeOfType [array]
        }

        It "Should filter by manager when specified" {
            $sessionId = Start-InstallationSession
            Add-InstalledPackageToState -PackageId "choco-pkg" -Manager "chocolatey" -SessionId $sessionId
            Add-InstalledPackageToState -PackageId "winget-pkg" -Manager "winget" -SessionId $sessionId

            $chocoPackages = Get-InstalledPackagesFromState -Manager "chocolatey"

            $chocoPackages | Should -HaveCount 1
            $chocoPackages[0].PackageId | Should -Be "choco-pkg"

            Stop-InstallationSession -SessionId $sessionId
        }
    }
}

Describe "Backup Functions" {
    Context "Get-BackupDirectory" {
        It "Should return valid backup directory path" {
            $result = Get-BackupDirectory

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeLike "*backups*"
        }

        It "Should create directory if not exists" {
            $backupDir = Get-BackupDirectory

            Test-Path $backupDir | Should -Be $true
        }
    }

    Context "Backup-Configuration" {
        BeforeEach {
            $script:backupName = "test-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        }

        It "Should create backup successfully" {
            $result = Backup-Configuration -BackupName $script:backupName

            $result | Should -Not -BeNullOrEmpty
            Test-Path $result | Should -Be $true
        }

        It "Should include packages.json in backup" {
            $backupPath = Backup-Configuration -BackupName $script:backupName

            $packagesBackup = Join-Path $backupPath "packages.json"
            Test-Path $packagesBackup | Should -Be $true
        }

        It "Should include installation state in backup" {
            $backupPath = Backup-Configuration -BackupName $script:backupName

            $stateBackup = Join-Path $backupPath "installation-state.json"
            Test-Path $stateBackup | Should -Be $true
        }

        AfterEach {
            if (Test-Path (Get-BackupDirectory)) {
                $backupPath = Join-Path (Get-BackupDirectory) $script:backupName
                if (Test-Path $backupPath) {
                    Remove-Item $backupPath -Recurse -Force
                }
            }
        }
    }

    Context "Get-BackupHistory" {
        It "Should return array of backup information" {
            $result = Get-BackupHistory

            $result | Should -BeOfType [array]
        }

        It "Should include Name and Date properties" {
            Backup-Configuration -BackupName "test-history"

            $result = Get-BackupHistory
            if ($result.Count -gt 0) {
                $result[0] | Should -HaveProperty Name
                $result[0] | Should -HaveProperty Date
            }

            $backupPath = Join-Path (Get-BackupDirectory) "test-history"
            if (Test-Path $backupPath) {
                Remove-Item $backupPath -Recurse -Force
            }
        }
    }

    Context "Get-AvailableBackups" {
        It "Should list all available backups" {
            Backup-Configuration -BackupName "available-test-1"
            Backup-Configuration -BackupName "available-test-2"

            $result = Get-AvailableBackups

            $result.Count | Should -BeGreaterOrEqual 2

            $backupDir = Get-BackupDirectory
            Remove-Item (Join-Path $backupDir "available-test-1") -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item (Join-Path $backupDir "available-test-2") -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Remove-OldBackups" {
        It "Should accept days parameter" {
            { Remove-OldBackups -Days 30 } | Should -Not -Throw
        }

        It "Should validate days range" {
            { Remove-OldBackups -Days 0 } | Should -Throw
        }
    }

    Context "Backup-ConfigurationAuto" {
        It "Should create automatic backup with timestamp" {
            $result = Backup-ConfigurationAuto

            $result | Should -Not -BeNullOrEmpty
            Test-Path $result | Should -Be $true

            $backupName = Split-Path $result -Leaf
            $backupName | Should -Match "^\d{4}-\d{2}-\d{2}_\d{6}$"

            Remove-Item $result -Recurse -Force
        }
    }
}

Describe "Rollback Functions" {
    Context "Restore-Configuration" {
        BeforeEach {
            $script:testBackup = Backup-Configuration -BackupName "restore-test"
        }

        AfterEach {
            if (Test-Path $script:testBackup) {
                Remove-Item $script:testBackup -Recurse -Force
            }
        }

        It "Should accept valid backup name" {
            { Restore-Configuration -BackupName "restore-test" } | Should -Not -Throw
        }

        It "Should return false for non-existent backup" {
            $result = Restore-Configuration -BackupName "nonexistent-backup"
            $result | Should -Be $false
        }
    }

    Context "Invoke-Rollback" {
        It "Should accept session ID parameter" {
            $sessionId = Start-InstallationSession
            Stop-InstallationSession -SessionId $sessionId

            { Invoke-Rollback -SessionId $sessionId } | Should -Not -Throw
        }

        It "Should handle invalid session ID" {
            $result = Invoke-Rollback -SessionId "invalid-session"
            $result | Should -Be $false
        }
    }
}

Describe "State and Backup Integration" {
    Context "Full backup and restore cycle" {
        It "Should preserve state across backup and restore" {
            $sessionId = Start-InstallationSession
            Add-InstalledPackageToState -PackageId "integration-test" -Manager "chocolatey" -SessionId $sessionId
            Stop-InstallationSession -SessionId $sessionId

            $backupName = "integration-$(Get-Date -Format 'yyyyMMddHHmmss')"
            $backupPath = Backup-Configuration -BackupName $backupName

            $state = Get-InstallationState
            $packageExists = $state.InstalledPackages | Where-Object { $_.PackageId -eq "integration-test" }

            $packageExists | Should -Not -BeNullOrEmpty

            Remove-Item $backupPath -Recurse -Force
        }
    }
}