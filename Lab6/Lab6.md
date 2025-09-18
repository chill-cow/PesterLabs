# Lab 6: CI/CD Integration with GitHub Actions

## Lab Overview

In this lab, you'll learn how to integrate Pester testing into a CI/CD pipeline using GitHub Actions. This lab targets GitHub as requested and covers:

- **GitHub Actions workflow setup** for PowerShell testing
- **Multi-platform testing** (Windows, Linux, macOS)
- **Automated test execution** on push and pull requests
- **Test result reporting** and artifact management
- **Code coverage integration** with Pester and codecov
- **Quality gates** and branch protection rules
- **Release automation** with semantic versioning

## Prerequisites

- **GitHub account** and repository access
- **PowerShell 7.4 or later**
- Pester v5.7.1 or later
- Labs 1-5 completion
- Basic understanding of Git and GitHub
- Understanding of CI/CD concepts

## Lab Setup

### Step 1: Repository Structure

Create a proper repository structure for CI/CD integration:

```
PowerShell-Testing-Project/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── release.yml
│       └── code-quality.yml
├── src/
│   ├── Public/
│   │   ├── ConvertTo-UpperCase.ps1
│   │   ├── Get-EmailAddress.ps1
│   │   └── Get-DemoComputers.ps1
│   └── Private/
│       └── Helper-Functions.ps1
├── tests/
│   ├── Unit/
│   │   ├── ConvertTo-UpperCase.Tests.ps1
│   │   ├── Get-EmailAddress.Tests.ps1
│   │   └── Get-DemoComputers.Tests.ps1
│   ├── Integration/
│   │   └── Module.Integration.Tests.ps1
│   └── TestHelpers/
│       └── TestHelpers.psm1
├── docs/
│   └── README.md
├── PowerShellModule.psd1
├── PowerShellModule.psm1
├── README.md
├── .gitignore
└── CHANGELOG.md
```

### Step 2: Create Module Manifest

Create `PowerShellModule.psd1`:

```powershell
@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'PowerShellModule.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Core', 'Desktop')
    
    # ID used to uniquely identify this module
    GUID = '12345678-1234-1234-1234-123456789012'
    
    # Author of this module
    Author = 'Your Name'
    
    # Company or vendor of this module
    CompanyName = 'Your Company'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Your Company. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'A sample PowerShell module with comprehensive testing'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '7.4'
    
    # Functions to export from this module
    FunctionsToExport = @(
        'ConvertTo-UpperCase',
        'Get-EmailAddress', 
        'Get-DemoComputers'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Testing', 'Pester', 'CI/CD', 'PowerShell')
            
            # A URL to the license for this module.
            LicenseUri = 'https://github.com/YourUsername/PowerShell-Testing-Project/blob/main/LICENSE'
            
            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/YourUsername/PowerShell-Testing-Project'
            
            # Release notes for this module
            ReleaseNotes = 'Initial release with comprehensive testing framework'
        }
    }
}
```

### Step 3: Main Module File

Create `PowerShellModule.psm1`:

```powershell
#Requires -Version 7.4

# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot\src\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\src\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
        Write-Verbose "Imported $($import.FullName)"
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName

# Module initialization
Write-Verbose "PowerShell Testing Module loaded successfully"
```

## Part 1: Basic CI/CD Workflow

### Step 4: Create Basic CI Workflow

Create `.github/workflows/ci.yml`:

```yaml
name: Continuous Integration

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

env:
  POWERSHELL_TELEMETRY_OPTOUT: 1

jobs:
  test:
    name: Test on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        
    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4
      
    - name: Install PowerShell (Linux/macOS)
      if: runner.os != 'Windows'
      shell: bash
      run: |
        if [[ "${{ runner.os }}" == "Linux" ]]; then
          # Install PowerShell on Ubuntu
          wget -q "https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb"
          sudo dpkg -i packages-microsoft-prod.deb
          sudo apt-get update
          sudo apt-get install -y powershell
        elif [[ "${{ runner.os }}" == "macOS" ]]; then
          # Install PowerShell on macOS
          brew install --cask powershell
        fi
        
    - name: Verify PowerShell Installation
      shell: pwsh
      run: |
        Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
        Write-Host "Platform: $($PSVersionTable.Platform)"
        Write-Host "OS: $($PSVersionTable.OS)"
        
    - name: Install Pester
      shell: pwsh
      run: |
        Set-PSRepository PSGallery -InstallationPolicy Trusted
        Install-Module -Name Pester -MinimumVersion 5.7.1 -Force -Scope CurrentUser
        Import-Module Pester -Force
        Write-Host "Pester Version: $(Get-Module Pester | Select-Object -ExpandProperty Version)"
        
    - name: Install Additional Modules
      shell: pwsh
      run: |
        # Install modules required by tests
        $modules = @('PSScriptAnalyzer', 'platyPS')
        foreach ($module in $modules) {
          try {
            Install-Module -Name $module -Force -Scope CurrentUser
            Write-Host "✅ Installed $module"
          }
          catch {
            Write-Warning "❌ Failed to install $module : $_"
          }
        }
        
    - name: Run PSScriptAnalyzer
      shell: pwsh
      run: |
        Write-Host "🔍 Running PSScriptAnalyzer..." -ForegroundColor Cyan
        
        $analysisResults = @()
        $sourceFiles = Get-ChildItem -Path .\src -Filter *.ps1 -Recurse
        
        foreach ($file in $sourceFiles) {
          $results = Invoke-ScriptAnalyzer -Path $file.FullName -Severity Warning
          if ($results) {
            $analysisResults += $results
            Write-Warning "Issues found in $($file.Name):"
            $results | ForEach-Object {
              Write-Warning "  Line $($_.Line): $($_.Message)"
            }
          }
        }
        
        if ($analysisResults.Count -gt 0) {
          Write-Host "❌ PSScriptAnalyzer found $($analysisResults.Count) issues" -ForegroundColor Red
          # Don't fail the build for warnings, but report them
        } else {
          Write-Host "✅ PSScriptAnalyzer passed - no issues found" -ForegroundColor Green
        }
        
    - name: Run Unit Tests
      shell: pwsh
      run: |
        Write-Host "🧪 Running Unit Tests..." -ForegroundColor Cyan
        
        $pesterConfig = [PesterConfiguration]::Default
        $pesterConfig.Run.Path = '.\tests\Unit'
        $pesterConfig.Run.Passthru = $true
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
        $pesterConfig.TestResult.OutputPath = '.\TestResults-Unit.xml'
        $pesterConfig.CodeCoverage.Enabled = $true
        $pesterConfig.CodeCoverage.Path = '.\src\**\*.ps1'
        $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
        $pesterConfig.CodeCoverage.OutputPath = '.\coverage-unit.xml'
        $pesterConfig.Output.Verbosity = 'Detailed'
        
        $testResults = Invoke-Pester -Configuration $pesterConfig
        
        if ($testResults.FailedCount -gt 0) {
          Write-Host "❌ Unit tests failed: $($testResults.FailedCount) failures" -ForegroundColor Red
          exit 1
        } else {
          Write-Host "✅ All unit tests passed ($($testResults.PassedCount) tests)" -ForegroundColor Green
        }
        
    - name: Run Integration Tests
      shell: pwsh
      run: |
        Write-Host "🔗 Running Integration Tests..." -ForegroundColor Cyan
        
        $pesterConfig = [PesterConfiguration]::Default
        $pesterConfig.Run.Path = '.\tests\Integration'
        $pesterConfig.Run.Passthru = $true
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
        $pesterConfig.TestResult.OutputPath = '.\TestResults-Integration.xml'
        $pesterConfig.Output.Verbosity = 'Detailed'
        
        # Skip integration tests on non-Windows for AD-dependent tests
        if ($IsWindows) {
          $testResults = Invoke-Pester -Configuration $pesterConfig
          
          if ($testResults.FailedCount -gt 0) {
            Write-Host "❌ Integration tests failed: $($testResults.FailedCount) failures" -ForegroundColor Red
            exit 1
          } else {
            Write-Host "✅ All integration tests passed ($($testResults.PassedCount) tests)" -ForegroundColor Green
          }
        } else {
          Write-Host "⚠️ Skipping integration tests on non-Windows platform" -ForegroundColor Yellow
        }
        
    - name: Upload Test Results
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: test-results-${{ matrix.os }}
        path: |
          TestResults-*.xml
          coverage-*.xml
        retention-days: 30
        
    - name: Upload Coverage to Codecov
      uses: codecov/codecov-action@v4
      if: runner.os == 'Windows'  # Only upload from one platform
      with:
        files: ./coverage-unit.xml
        flags: unittests
        name: codecov-umbrella
        fail_ci_if_error: false

  publish-test-results:
    name: Publish Test Results
    runs-on: ubuntu-latest
    needs: test
    if: always()
    
    steps:
    - name: Download Test Results
      uses: actions/download-artifact@v4
      with:
        pattern: test-results-*
        merge-multiple: true
        
    - name: Publish Test Results
      uses: EnricoMi/publish-unit-test-result-action@v2
      if: always()
      with:
        files: "TestResults-*.xml"
        comment_mode: create new
        check_name: "Test Results"
        report_individual_runs: true
```

### Step 5: Create Source Files

Create the source files in the `src/Public/` directory. I'll use the functions from previous labs:

Create `src/Public/ConvertTo-UpperCase.ps1`:

```powershell
function ConvertTo-UpperCase {
    <#
    .SYNOPSIS
        Converts strings to uppercase.
    
    .DESCRIPTION
        Converts one or more strings to uppercase with comprehensive error handling
        and parameter validation.
    
    .PARAMETER InputString
        The string(s) to convert to uppercase.
    
    .PARAMETER PassThru
        Returns the original string along with the converted string.
    
    .EXAMPLE
        ConvertTo-UpperCase -InputString "hello world"
        Returns "HELLO WORLD"
    
    .EXAMPLE
        "hello", "world" | ConvertTo-UpperCase
        Returns "HELLO" and "WORLD"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [AllowEmptyString()]
        [string[]]$InputString,
        
        [Parameter()]
        [switch]$PassThru
    )
    
    begin {
        Write-Verbose "Starting ConvertTo-UpperCase processing"
        $processedCount = 0
    }
    
    process {
        foreach ($string in $InputString) {
            try {
                $result = $string.ToUpper()
                $processedCount++
                
                if ($PassThru) {
                    [PSCustomObject]@{
                        Original = $string
                        Converted = $result
                    }
                } else {
                    $result
                }
                
                Write-Verbose "Converted: '$string' -> '$result'"
            }
            catch {
                Write-Error "Failed to convert string: $_"
                continue
            }
        }
    }
    
    end {
        Write-Verbose "Completed processing $processedCount strings"
    }
}
```

### Step 6: Create Test Files

Create `tests/Unit/ConvertTo-UpperCase.Tests.ps1`:

```powershell
BeforeAll {
    # Import the module
    Import-Module $PSScriptRoot\..\..\PowerShellModule.psd1 -Force
}

Describe 'ConvertTo-UpperCase' -Tag 'Unit' {
    Context 'Parameter Validation' {
        It 'Should have InputString parameter' {
            Get-Command ConvertTo-UpperCase | Should -HaveParameter InputString -Mandatory
        }
        
        It 'Should have PassThru parameter' {
            Get-Command ConvertTo-UpperCase | Should -HaveParameter PassThru -Type SwitchParameter
        }
        
        It 'Should accept pipeline input' {
            (Get-Command ConvertTo-UpperCase).Parameters['InputString'].Attributes | 
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -ExpandProperty ValueFromPipeline | Should -BeTrue
        }
    }
    
    Context 'Basic Functionality' {
        It 'Should convert single string to uppercase' {
            $result = ConvertTo-UpperCase -InputString "hello world"
            $result | Should -Be "HELLO WORLD"
        }
        
        It 'Should convert multiple strings to uppercase' {
            $result = ConvertTo-UpperCase -InputString @("hello", "world")
            $result | Should -HaveCount 2
            $result[0] | Should -Be "HELLO"
            $result[1] | Should -Be "WORLD"
        }
        
        It 'Should handle empty strings' {
            $result = ConvertTo-UpperCase -InputString ""
            $result | Should -Be ""
        }
        
        It 'Should work with pipeline input' {
            $result = "hello", "world" | ConvertTo-UpperCase
            $result | Should -HaveCount 2
            $result[0] | Should -Be "HELLO"
            $result[1] | Should -Be "WORLD"
        }
    }
    
    Context 'PassThru Functionality' {
        It 'Should return object with PassThru switch' {
            $result = ConvertTo-UpperCase -InputString "hello" -PassThru
            $result | Should -BeOfType [PSCustomObject]
            $result.Original | Should -Be "hello"
            $result.Converted | Should -Be "HELLO"
        }
    }
    
    Context 'Edge Cases' {
        It 'Should handle already uppercase strings' {
            $result = ConvertTo-UpperCase -InputString "ALREADY UPPER"
            $result | Should -Be "ALREADY UPPER"
        }
        
        It 'Should handle mixed case strings' {
            $result = ConvertTo-UpperCase -InputString "MiXeD cAsE"
            $result | Should -Be "MIXED CASE"
        }
        
        It 'Should handle special characters' {
            $result = ConvertTo-UpperCase -InputString "hello@world!123"
            $result | Should -Be "HELLO@WORLD!123"
        }
    }
}
```

## Part 2: Advanced CI/CD Features

### Step 7: Code Quality Workflow

Create `.github/workflows/code-quality.yml`:

```yaml
name: Code Quality

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  code-quality:
    name: Code Quality Checks
    runs-on: windows-latest
    
    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4
      
    - name: Install PowerShell Modules
      shell: pwsh
      run: |
        Set-PSRepository PSGallery -InstallationPolicy Trusted
        $modules = @('PSScriptAnalyzer', 'Pester', 'platyPS')
        foreach ($module in $modules) {
          Install-Module -Name $module -Force -Scope CurrentUser
        }
        
    - name: Run PSScriptAnalyzer
      shell: pwsh
      run: |
        $results = @()
        $sourceFiles = Get-ChildItem -Path .\src -Filter *.ps1 -Recurse
        
        foreach ($file in $sourceFiles) {
          $analysis = Invoke-ScriptAnalyzer -Path $file.FullName -Severity @('Error', 'Warning', 'Information')
          if ($analysis) {
            $results += $analysis
          }
        }
        
        if ($results) {
          $results | Format-Table -AutoSize
          
          # Create GitHub annotations
          foreach ($result in $results) {
            $level = switch ($result.Severity) {
              'Error' { 'error' }
              'Warning' { 'warning' }
              default { 'notice' }
            }
            Write-Host "::$level file=$($result.ScriptPath),line=$($result.Line),col=$($result.Column)::$($result.Message)"
          }
          
          $errorCount = ($results | Where-Object Severity -eq 'Error').Count
          if ($errorCount -gt 0) {
            Write-Host "❌ PSScriptAnalyzer found $errorCount errors" -ForegroundColor Red
            exit 1
          }
        }
        
    - name: Check Module Manifest
      shell: pwsh
      run: |
        $manifestPath = ".\PowerShellModule.psd1"
        
        try {
          $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
          Write-Host "✅ Module manifest is valid" -ForegroundColor Green
          Write-Host "Module: $($manifest.Name) v$($manifest.Version)"
        }
        catch {
          Write-Host "❌ Module manifest validation failed: $_" -ForegroundColor Red
          exit 1
        }
        
    - name: Test Module Import
      shell: pwsh
      run: |
        try {
          Import-Module .\PowerShellModule.psd1 -Force -ErrorAction Stop
          $functions = Get-Command -Module PowerShellModule
          Write-Host "✅ Module imported successfully" -ForegroundColor Green
          Write-Host "Exported functions: $($functions.Name -join ', ')"
        }
        catch {
          Write-Host "❌ Module import failed: $_" -ForegroundColor Red
          exit 1
        }
        
    - name: Generate Documentation
      shell: pwsh
      run: |
        Import-Module .\PowerShellModule.psd1 -Force
        
        if (-not (Test-Path .\docs)) {
          New-Item -Path .\docs -ItemType Directory
        }
        
        # Generate markdown help
        New-MarkdownHelp -Module PowerShellModule -OutputFolder .\docs -Force
        Write-Host "✅ Documentation generated" -ForegroundColor Green
        
    - name: Validate Help Content
      shell: pwsh
      run: |
        Import-Module .\PowerShellModule.psd1 -Force
        
        $functions = Get-Command -Module PowerShellModule
        $helpIssues = @()
        
        foreach ($function in $functions) {
          $help = Get-Help $function.Name
          
          if (-not $help.Synopsis -or $help.Synopsis -eq $function.Name) {
            $helpIssues += "$($function.Name): Missing or default synopsis"
          }
          
          if (-not $help.Description) {
            $helpIssues += "$($function.Name): Missing description"
          }
          
          if (-not $help.Examples) {
            $helpIssues += "$($function.Name): Missing examples"
          }
        }
        
        if ($helpIssues) {
          Write-Host "⚠️ Help content issues found:" -ForegroundColor Yellow
          $helpIssues | ForEach-Object { Write-Host "  $_" }
        } else {
          Write-Host "✅ All functions have proper help content" -ForegroundColor Green
        }
```

### Step 8: Release Workflow

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to release (e.g., v1.2.3)'
        required: true
        type: string

env:
  POWERSHELL_TELEMETRY_OPTOUT: 1

jobs:
  validate:
    name: Validate Release
    runs-on: windows-latest
    
    outputs:
      version: ${{ steps.version.outputs.version }}
      
    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4
      
    - name: Determine Version
      id: version
      shell: pwsh
      run: |
        if ("${{ github.event_name }}" -eq "workflow_dispatch") {
          $version = "${{ github.event.inputs.version }}"
        } else {
          $version = "${{ github.ref_name }}"
        }
        
        # Remove 'v' prefix if present
        $version = $version -replace '^v', ''
        
        Write-Host "Release version: $version"
        echo "version=$version" >> $env:GITHUB_OUTPUT
        
    - name: Install Dependencies
      shell: pwsh
      run: |
        Set-PSRepository PSGallery -InstallationPolicy Trusted
        Install-Module -Name Pester, PSScriptAnalyzer -Force -Scope CurrentUser
        
    - name: Run Full Test Suite
      shell: pwsh
      run: |
        $pesterConfig = [PesterConfiguration]::Default
        $pesterConfig.Run.Path = '.\tests'
        $pesterConfig.Run.Passthru = $true
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
        $pesterConfig.TestResult.OutputPath = '.\TestResults-Release.xml'
        $pesterConfig.Output.Verbosity = 'Detailed'
        
        $testResults = Invoke-Pester -Configuration $pesterConfig
        
        if ($testResults.FailedCount -gt 0) {
          Write-Host "❌ Release validation failed: $($testResults.FailedCount) test failures" -ForegroundColor Red
          exit 1
        }
        
        Write-Host "✅ All tests passed for release" -ForegroundColor Green
        
    - name: Update Module Version
      shell: pwsh
      run: |
        $version = "${{ steps.version.outputs.version }}"
        $manifestPath = ".\PowerShellModule.psd1"
        
        # Update module version in manifest
        $content = Get-Content $manifestPath -Raw
        $content = $content -replace "ModuleVersion\s*=\s*'[^']*'", "ModuleVersion = '$version'"
        Set-Content -Path $manifestPath -Value $content
        
        Write-Host "✅ Updated module version to $version"

  build:
    name: Build Release Artifacts
    runs-on: windows-latest
    needs: validate
    
    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4
      
    - name: Update Module Version
      shell: pwsh
      run: |
        $version = "${{ needs.validate.outputs.version }}"
        $manifestPath = ".\PowerShellModule.psd1"
        
        $content = Get-Content $manifestPath -Raw
        $content = $content -replace "ModuleVersion\s*=\s*'[^']*'", "ModuleVersion = '$version'"
        Set-Content -Path $manifestPath -Value $content
        
    - name: Create Release Package
      shell: pwsh
      run: |
        $version = "${{ needs.validate.outputs.version }}"
        $packageName = "PowerShellModule-v$version"
        $packagePath = ".\release\$packageName"
        
        # Create release directory structure
        New-Item -Path $packagePath -ItemType Directory -Force
        
        # Copy module files
        Copy-Item -Path ".\PowerShellModule.psd1" -Destination $packagePath
        Copy-Item -Path ".\PowerShellModule.psm1" -Destination $packagePath
        Copy-Item -Path ".\src" -Destination $packagePath -Recurse
        Copy-Item -Path ".\README.md" -Destination $packagePath
        Copy-Item -Path ".\CHANGELOG.md" -Destination $packagePath
        
        # Create ZIP package
        Compress-Archive -Path "$packagePath\*" -DestinationPath ".\release\$packageName.zip"
        
        Write-Host "✅ Created release package: $packageName.zip"
        
    - name: Generate Release Notes
      shell: pwsh
      run: |
        $version = "${{ needs.validate.outputs.version }}"
        
        # Extract changelog for this version
        if (Test-Path ".\CHANGELOG.md") {
          $changelog = Get-Content ".\CHANGELOG.md" -Raw
          
          # Extract section for current version
          $pattern = "## \[$version\].*?(?=## \[|\z)"
          if ($changelog -match $pattern) {
            $releaseNotes = $matches[0]
            Set-Content -Path ".\release-notes.md" -Value $releaseNotes
          } else {
            Set-Content -Path ".\release-notes.md" -Value "Release version $version"
          }
        } else {
          Set-Content -Path ".\release-notes.md" -Value "Release version $version"
        }
        
    - name: Upload Release Artifacts
      uses: actions/upload-artifact@v4
      with:
        name: release-artifacts
        path: |
          ./release/*.zip
          ./release-notes.md

  publish:
    name: Publish Release
    runs-on: windows-latest
    needs: [validate, build]
    environment: production
    
    steps:
    - name: Download Release Artifacts
      uses: actions/download-artifact@v4
      with:
        name: release-artifacts
        
    - name: Create GitHub Release
      uses: softprops/action-gh-release@v1
      with:
        tag_name: v${{ needs.validate.outputs.version }}
        name: Release v${{ needs.validate.outputs.version }}
        body_path: ./release-notes.md
        files: ./release/*.zip
        draft: false
        prerelease: false
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        
    - name: Publish to PowerShell Gallery
      if: github.repository_owner == 'YourUsername'  # Only publish from main repo
      shell: pwsh
      run: |
        # This would publish to PowerShell Gallery
        # Requires API key stored in secrets
        Write-Host "🚀 Would publish to PowerShell Gallery here"
        Write-Host "Version: ${{ needs.validate.outputs.version }}"
        
        # Uncomment and configure for actual publishing:
        # Publish-Module -Path ".\PowerShellModule" -NuGetApiKey $env:POWERSHELL_GALLERY_API_KEY
      env:
        POWERSHELL_GALLERY_API_KEY: ${{ secrets.POWERSHELL_GALLERY_API_KEY }}
```

## Part 3: Advanced Testing Scenarios

### Step 9: Create Integration Tests

Create `tests/Integration/Module.Integration.Tests.ps1`:

```powershell
BeforeAll {
    # Import the module for integration testing
    Import-Module $PSScriptRoot\..\..\PowerShellModule.psd1 -Force
    
    # Integration test configuration
    $script:integrationConfig = @{
        TestTimeout = 30
        MaxRetries = 3
    }
}

Describe 'Module Integration Tests' -Tag 'Integration' {
    Context 'Module Loading and Initialization' {
        It 'Should load module without errors' {
            { Import-Module PowerShellModule -Force } | Should -Not -Throw
        }
        
        It 'Should export expected functions' {
            $exportedFunctions = Get-Command -Module PowerShellModule
            $expectedFunctions = @('ConvertTo-UpperCase', 'Get-EmailAddress', 'Get-DemoComputers')
            
            foreach ($expectedFunction in $expectedFunctions) {
                $exportedFunctions.Name | Should -Contain $expectedFunction
            }
        }
        
        It 'Should have proper module metadata' {
            $module = Get-Module PowerShellModule
            
            $module.Version | Should -Not -BeNullOrEmpty
            $module.Author | Should -Not -BeNullOrEmpty
            $module.Description | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Cross-Function Integration' {
        It 'Should handle complex pipeline scenarios' {
            # Test multiple functions working together
            $emailAddresses = @('test@example.com', 'user@domain.org')
            
            $result = $emailAddresses | 
                Get-EmailAddress | 
                ConvertTo-UpperCase
            
            $result | Should -HaveCount 2
            $result[0] | Should -Be 'TEST@EXAMPLE.COM'
            $result[1] | Should -Be 'USER@DOMAIN.ORG'
        }
        
        It 'Should maintain consistent error handling across functions' {
            # Test that all functions handle errors consistently
            $functions = Get-Command -Module PowerShellModule
            
            foreach ($function in $functions) {
                $errorVariable = $null
                
                # Test with invalid input
                & $function -ErrorVariable errorVariable -ErrorAction SilentlyContinue 2>$null
                
                # Should not throw unhandled exceptions
                $errorVariable | Should -Not -BeNullOrEmpty
            }
        }
    }
    
    Context 'Performance Integration' {
        It 'Should complete operations within acceptable time limits' {
            $testData = 1..1000 | ForEach-Object { "test string $_" }
            
            $duration = Measure-Command {
                $result = $testData | ConvertTo-UpperCase
            }
            
            $duration.TotalSeconds | Should -BeLessThan $script:integrationConfig.TestTimeout
            Write-Host "Performance test completed in $($duration.TotalSeconds) seconds"
        }
        
        It 'Should handle concurrent operations' {
            $jobs = 1..5 | ForEach-Object {
                Start-Job -ScriptBlock {
                    Import-Module PowerShellModule
                    $data = 1..100 | ForEach-Object { "test $_" }
                    $data | ConvertTo-UpperCase
                }
            }
            
            try {
                $results = $jobs | Wait-Job -Timeout $script:integrationConfig.TestTimeout | Receive-Job
                $results | Should -Not -BeNullOrEmpty
                
                # Verify all jobs completed successfully
                $jobs | ForEach-Object {
                    $_.State | Should -Be 'Completed'
                }
            }
            finally {
                $jobs | Remove-Job -Force
            }
        }
    }
}
```

### Step 10: Create Test Helpers

Create `tests/TestHelpers/TestHelpers.psm1`:

```powershell
# Test helper functions for consistent testing across the project

function New-TestDataSet {
    <#
    .SYNOPSIS
        Creates standardized test data sets for consistent testing.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Small', 'Medium', 'Large', 'Email', 'Computer')]
        [string]$Type,
        
        [int]$Size = 10
    )
    
    switch ($Type) {
        'Small' {
            1..$Size | ForEach-Object { "test$_" }
        }
        'Medium' {
            1..$Size | ForEach-Object { "TestData$_ with some additional content" }
        }
        'Large' {
            1..$Size | ForEach-Object { 
                "LargeTestDataSet$_ " + ("x" * 100) + " with extended content for testing"
            }
        }
        'Email' {
            1..$Size | ForEach-Object { 
                $domains = @('example.com', 'test.org', 'sample.net')
                $domain = $domains[($_ - 1) % $domains.Count]
                "user$_@$domain"
            }
        }
        'Computer' {
            1..$Size | ForEach-Object { "COMPUTER$($_.ToString('D3'))" }
        }
    }
}

function Assert-PerformanceWithin {
    <#
    .SYNOPSIS
        Asserts that a script block executes within specified time limits.
    #>
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory)]
        [timespan]$MaxDuration,
        
        [string]$Because = "Performance should meet requirements"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $result = & $ScriptBlock
        return $result
    }
    finally {
        $stopwatch.Stop()
        $stopwatch.Elapsed | Should -BeLessThan $MaxDuration -Because $Because
    }
}

function Test-FunctionParameter {
    <#
    .SYNOPSIS
        Tests function parameter characteristics.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,
        
        [Parameter(Mandatory)]
        [string]$ParameterName,
        
        [switch]$Mandatory,
        [switch]$ValueFromPipeline,
        [type]$Type
    )
    
    $function = Get-Command $FunctionName -ErrorAction Stop
    $parameter = $function.Parameters[$ParameterName]
    
    if (-not $parameter) {
        throw "Parameter '$ParameterName' not found on function '$FunctionName'"
    }
    
    if ($Mandatory) {
        $isMandatory = $parameter.Attributes | 
            Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
            Where-Object { $_.Mandatory }
        $isMandatory | Should -Not -BeNullOrEmpty -Because "Parameter should be mandatory"
    }
    
    if ($ValueFromPipeline) {
        $acceptsPipeline = $parameter.Attributes |
            Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
            Where-Object { $_.ValueFromPipeline }
        $acceptsPipeline | Should -Not -BeNullOrEmpty -Because "Parameter should accept pipeline input"
    }
    
    if ($Type) {
        $parameter.ParameterType | Should -Be $Type -Because "Parameter should have correct type"
    }
}

function Invoke-WithRetry {
    <#
    .SYNOPSIS
        Executes a script block with retry logic for flaky operations.
    #>
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [int]$MaxRetries = 3,
        [timespan]$RetryDelay = [timespan]::FromSeconds(1)
    )
    
    $attempt = 1
    
    do {
        try {
            return & $ScriptBlock
        }
        catch {
            if ($attempt -ge $MaxRetries) {
                throw
            }
            
            Write-Verbose "Attempt $attempt failed, retrying in $($RetryDelay.TotalSeconds) seconds..."
            Start-Sleep $RetryDelay
            $attempt++
        }
    } while ($attempt -le $MaxRetries)
}

# Export functions
Export-ModuleMember -Function @(
    'New-TestDataSet',
    'Assert-PerformanceWithin', 
    'Test-FunctionParameter',
    'Invoke-WithRetry'
)
```

## Lab Exercises

### Exercise 1: Branch Protection Setup
Configure branch protection rules in GitHub:
- Require status checks to pass
- Require up-to-date branches
- Require review from code owners

### Exercise 2: Secrets Management
Set up repository secrets for:
- PowerShell Gallery API key
- Code coverage tokens
- Notification webhooks

### Exercise 3: Custom Actions
Create a custom GitHub Action for PowerShell module validation.

### Exercise 4: Multi-Environment Testing
Extend the workflow to test against multiple PowerShell versions and environments.

## Key Takeaways

1. **CI/CD Integration**: Automate testing and deployment with GitHub Actions
2. **Multi-Platform Testing**: Ensure compatibility across Windows, Linux, and macOS
3. **Quality Gates**: Implement code quality checks and test coverage requirements
4. **Release Automation**: Automate versioning and package publishing
5. **Documentation**: Generate and validate help content automatically
6. **Performance Monitoring**: Track performance metrics over time
7. **Security**: Implement proper secrets management and security scanning

## Next Steps

- Set up monitoring and alerting for your CI/CD pipeline
- Implement automated dependency updates with Dependabot
- Add security scanning with CodeQL
- Create automated performance benchmarking
- Implement semantic versioning with conventional commits

---

**Lab Completion Time**: 120-180 minutes  
**Difficulty Level**: Advanced  
**Prerequisites**: Labs 1-5, GitHub account, CI/CD concepts