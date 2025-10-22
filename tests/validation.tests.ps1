BeforeAll {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
    
    # carrego os módulos
    . "$ProjectRoot\core\utils.ps1"
    . "$ProjectRoot\core\logger.ps1"
    . "$ProjectRoot\core\state.ps1"
    . "$ProjectRoot\core\ui.ps1"
    . "$ProjectRoot\core\validator.ps1"
}

Describe "Estrutura do Projeto" {
    
    It "Pasta config existe" {
        Test-Path "$ProjectRoot\config" | Should -Be $true
    }
    
    It "Pasta core existe" {
        Test-Path "$ProjectRoot\core" | Should -Be $true
    }
    
    It "Pasta installers existe" {
        Test-Path "$ProjectRoot\installers" | Should -Be $true
    }
    
    It "Pasta logs existe" {
        Test-Path "$ProjectRoot\logs" | Should -Be $true
    }
    
    It "Pasta state existe" {
        Test-Path "$ProjectRoot\state" | Should -Be $true
    }
    
    It "env.ps1 existe" {
        Test-Path "$ProjectRoot\env.ps1" | Should -Be $true
    }
}

Describe "Arquivos de Configuração" {
    
    It "packages.json existe" {
        Test-Path "$ProjectRoot\config\packages.json" | Should -Be $true
    }
    
    It "packages.json é JSON válido" {
        { Get-Content "$ProjectRoot\config\packages.json" | ConvertFrom-Json } | Should -Not -Throw
    }
    
    It "presets.json existe" {
        Test-Path "$ProjectRoot\config\presets.json" | Should -Be $true
    }
    
    It "presets.json é JSON válido" {
        { Get-Content "$ProjectRoot\config\presets.json" | ConvertFrom-Json } | Should -Not -Throw
    }
    
    It "strings.json existe" {
        Test-Path "$ProjectRoot\config\strings.json" | Should -Be $true
    }
    
    It "strings.json é JSON válido" {
        { Get-Content "$ProjectRoot\config\strings.json" | ConvertFrom-Json } | Should -Not -Throw
    }
    
    It "strings.json tem idioma pt-br" {
        $strings = Get-Content "$ProjectRoot\config\strings.json" | ConvertFrom-Json
        $strings.'pt-br' | Should -Not -BeNullOrEmpty
    }
    
    It "strings.json tem idioma en" {
        $strings = Get-Content "$ProjectRoot\config\strings.json" | ConvertFrom-Json
        $strings.en | Should -Not -BeNullOrEmpty
    }
}

Describe "Módulos Core" {
    
    It "utils.ps1 existe" {
        Test-Path "$ProjectRoot\core\utils.ps1" | Should -Be $true
    }
    
    It "logger.ps1 existe" {
        Test-Path "$ProjectRoot\core\logger.ps1" | Should -Be $true
    }
    
    It "state.ps1 existe" {
        Test-Path "$ProjectRoot\core\state.ps1" | Should -Be $true
    }
    
    It "ui.ps1 existe" {
        Test-Path "$ProjectRoot\core\ui.ps1" | Should -Be $true
    }
    
    It "validator.ps1 existe" {
        Test-Path "$ProjectRoot\core\validator.ps1" | Should -Be $true
    }
}

Describe "Funções Utilitárias" {
    
    It "Test-Administrator está definida" {
        Get-Command Test-Administrator -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It "Test-DiskSpace está definida" {
        Get-Command Test-DiskSpace -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It "Test-NetworkConnection está definida" {
        Get-Command Test-NetworkConnection -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    
    It "Get-SystemInfo retorna hashtable" {
        $info = Get-SystemInfo
        $info | Should -BeOfType [hashtable]
    }
    
    It "Get-SystemInfo contém OS" {
        $info = Get-SystemInfo
        $info.OS | Should -Not -BeNullOrEmpty
    }
    
    It "Get-String retorna string" {
        $result = Get-String -Key "banner" -Language "pt-br"
        $result | Should -BeOfType [string]
    }
}

Describe "Sistema de Logging" {
    
    BeforeAll {
        # crio log temporário para testes
        $script:LogFile = "$ProjectRoot\logs\test_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        New-Item -Path $script:LogFile -ItemType File -Force | Out-Null
    }
    
    It "Write-Log escreve no arquivo" {
        Write-Log "Teste de log" "INFO"
        Test-Path $script:LogFile | Should -Be $true
    }
    
    It "Log contém mensagem escrita" {
        $content = Get-Content $script:LogFile -Raw
        $content | Should -Match "Teste de log"
    }
    
    AfterAll {
        # limpo log de teste
        if (Test-Path $script:LogFile) {
            Remove-Item $script:LogFile -Force
        }
    }
}

Describe "Sistema de Estado" {
    
    It "Initialize-State cria arquivo" {
        $testStatePath = "$ProjectRoot\state\test.state.json"
        
        # força criação
        $initialState = @{
            version = "1.0.0"
            last_run = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            installed_packages = @()
        }
        $initialState | ConvertTo-Json | Set-Content $testStatePath
        
        Test-Path $testStatePath | Should -Be $true
        
        # limpo
        Remove-Item $testStatePath -Force -ErrorAction SilentlyContinue
    }
    
    It "Get-StateData retorna objeto" {
        # crio estado temporário
        $testStatePath = "$ProjectRoot\state\test.state.json"
        $state = @{
            version = "1.0.0"
            installed_packages = @("test-package")
        }
        $state | ConvertTo-Json | Set-Content $testStatePath
        
        # mudo temporariamente o caminho do estado
        $originalPath = $script:StatePath
        $script:StatePath = $testStatePath
        
        $result = Get-StateData
        $result | Should -Not -BeNullOrEmpty
        
        # restauro e limpo
        $script:StatePath = $originalPath
        Remove-Item $testStatePath -Force -ErrorAction SilentlyContinue
    }
}

Describe "Sistema de Validação" {
    
    It "Test-CommandAvailable detecta PowerShell" {
        $result = Test-CommandAvailable -Command "powershell"
        $result | Should -Be $true
    }
    
    It "Test-CommandAvailable retorna false para comando inexistente" {
        $result = Test-CommandAvailable -Command "comando-que-nao-existe-xyz123"
        $result | Should -Be $false
    }
}

Describe "Installers" {
    
    It "languages.ps1 existe" {
        Test-Path "$ProjectRoot\installers\languages.ps1" | Should -Be $true
    }
    
    It "devtools.ps1 existe" {
        Test-Path "$ProjectRoot\installers\devtools.ps1" | Should -Be $true
    }
    
    It "webtools.ps1 existe" {
        Test-Path "$ProjectRoot\installers\webtools.ps1" | Should -Be $true
    }
    
    It "dbtools.ps1 existe" {
        Test-Path "$ProjectRoot\installers\dbtools.ps1" | Should -Be $true
    }
    
    It "observability.ps1 existe" {
        Test-Path "$ProjectRoot\installers\observability.ps1" | Should -Be $true
    }
    
    It "personal.ps1 existe" {
        Test-Path "$ProjectRoot\installers\personal.ps1" | Should -Be $true
    }
    
    It "wsl.ps1 existe" {
        Test-Path "$ProjectRoot\installers\wsl.ps1" | Should -Be $true
    }
    
    It "npm-packages.ps1 existe" {
        Test-Path "$ProjectRoot\installers\npm-packages.ps1" | Should -Be $true
    }
}

Describe "Packages.json Estrutura" {
    
    BeforeAll {
        $packages = Get-Content "$ProjectRoot\config\packages.json" | ConvertFrom-Json
    }
    
    It "Contém categoria languages" {
        $packages.languages | Should -Not -BeNullOrEmpty
    }
    
    It "Contém categoria devtools" {
        $packages.devtools | Should -Not -BeNullOrEmpty
    }
    
    It "Contém categoria webtools" {
        $packages.webtools | Should -Not -BeNullOrEmpty
    }
    
    It "Contém categoria dbtools" {
        $packages.dbtools | Should -Not -BeNullOrEmpty
    }
    
    It "Contém categoria observability" {
        $packages.observability | Should -Not -BeNullOrEmpty
    }
    
    It "Contém categoria personal" {
        $packages.personal | Should -Not -BeNullOrEmpty
    }
    
    It "Contém categoria npm" {
        $packages.npm | Should -Not -BeNullOrEmpty
    }
    
    It "Packages têm campos obrigatórios" {
        $firstLang = $packages.languages[0]
        $firstLang.id | Should -Not -BeNullOrEmpty
        $firstLang.name | Should -Not -BeNullOrEmpty
        $firstLang.choco_package | Should -Not -BeNullOrEmpty
        $firstLang.version | Should -Not -BeNullOrEmpty
    }
}

Describe "Presets.json Estrutura" {
    
    BeforeAll {
        $presets = Get-Content "$ProjectRoot\config\presets.json" | ConvertFrom-Json
    }
    
    It "Contém preset difaria" {
        $presets.difaria | Should -Not -BeNullOrEmpty
    }
    
    It "Contém preset developer" {
        $presets.developer | Should -Not -BeNullOrEmpty
    }
    
    It "Contém preset minimal" {
        $presets.minimal | Should -Not -BeNullOrEmpty
    }
    
    It "Preset difaria tem categorias" {
        $presets.difaria.categories | Should -Not -BeNullOrEmpty
    }
    
    It "Preset developer tem categorias" {
        $presets.developer.categories | Should -Not -BeNullOrEmpty
    }
}

Write-Host ""
Write-Host "Para executar os testes:" -ForegroundColor Cyan
Write-Host "  Invoke-Pester -Path .\tests\validation.tests.ps1" -ForegroundColor White
Write-Host ""