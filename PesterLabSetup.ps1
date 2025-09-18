# Pester Lab Environment Setup Script
# This script sets up the complete environment for Pester testing labs including:
# - PowerShell 7.4+, Visual Studio Code, and Git
# - Essential VSCode extensions for PowerShell, Git, Pester, and Markdown
# - Git configuration for lab exercises

Write-Host '🚀 Starting Pester Lab Environment Setup...' -ForegroundColor Green

# Install core applications via WinGet
Write-Host '📦 Installing core applications...' -ForegroundColor Cyan
$winGetPackages = 'Microsoft.Powershell', 'Git.Git', 'Microsoft.VisualStudioCode'
foreach ($winGetPackage in $winGetPackages)
{
    Write-Host "  Installing $winGetPackage..." -ForegroundColor Yellow
    Invoke-Expression "winget install $winGetPackage --accept-package-agreements --accept-source-agreements"
}

Write-Host '✅ Core applications installed. You may need to restart your console before continuing.' -ForegroundColor Green
Write-Host 'Press any key to continue with VSCode extensions setup...' -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey()

# Install VSCode extensions for comprehensive lab environment
Write-Host '🔧 Installing VSCode extensions...' -ForegroundColor Cyan
$vscodeExtensions = @(
    # Core PowerShell and Git extensions
    'ms-vscode.powershell',                    # PowerShell language support
    'github.remotehub',                        # GitHub integration
    'github.vscode-pull-request-github',       # GitHub Pull Request support
    'ms-vscode.remote-repositories',           # Remote repository support
    
    # Pester testing extensions
    'pspester.pester-test',                    # Pester Test Runner
    'ms-vscode.test-adapter-converter',        # Test adapter for Pester integration
    
    # Markdown support for lab documentation
    'yzhang.markdown-all-in-one',             # Comprehensive Markdown support
    'davidanson.vscode-markdownlint',         # Markdown linting
    'bierner.markdown-preview-github-styles', # GitHub-style Markdown preview
    
    # Additional productivity extensions
    'ms-vscode.vscode-json',                   # JSON language support
    'redhat.vscode-yaml',                      # YAML language support
    'aaron-bond.better-comments'              # Enhanced comment highlighting
)

foreach ($extension in $vscodeExtensions)
{
    Write-Host "  Installing extension: $extension..." -ForegroundColor Yellow
    try
    {
        Invoke-Expression "code --install-extension $extension" 2>$null
        Write-Host "    ✅ $extension installed successfully" -ForegroundColor Green
    }
    catch
    {
        Write-Warning "    ❌ Failed to install $extension"
    }
}

# Configure Git for lab exercises
Write-Host '⚙️ Configuring Git...' -ForegroundColor Cyan
# Change the name to your name if desired
$name = 'Student.Name'
Write-Host "  Setting up Git configuration for: $name" -ForegroundColor Yellow

git config --global user.name $name
git config --global user.email "$name@contoso.com"
git config --global core.editor 'code --wait'

# Install and configure Pester module
Write-Host '🧪 Installing Pester module...' -ForegroundColor Cyan
try
{
    # Check if Pester is already installed
    $pesterModule = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
    
    if ($pesterModule -and $pesterModule.Version -ge [Version]'5.7.0')
    {
        Write-Host "  ✅ Pester $($pesterModule.Version) is already installed" -ForegroundColor Green
    }
    else
    {
        Write-Host '  Installing latest Pester module...' -ForegroundColor Yellow
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
        Write-Host '  ✅ Pester module installed successfully' -ForegroundColor Green
    }
}
catch
{
    Write-Warning "  ❌ Failed to install Pester module: $($_.Exception.Message)"
}

# Verify PowerShell version for lab requirements
Write-Host '🔍 Verifying PowerShell version...' -ForegroundColor Cyan
$psVersion = $PSVersionTable.PSVersion
Write-Host "  Current PowerShell Version: $psVersion" -ForegroundColor Yellow

if ($psVersion -ge [Version]'7.4.0')
{
    Write-Host '  ✅ PowerShell version meets lab requirements (7.4+)' -ForegroundColor Green
}
else
{
    Write-Warning "  ⚠️ PowerShell version $psVersion is below recommended 7.4+ for Lab 3"
    Write-Host '  Some advanced labs may require PowerShell 7.4+ for .NET 8+ features' -ForegroundColor Yellow
}

# Display setup summary
Write-Host "`n🎉 Pester Lab Environment Setup Complete!" -ForegroundColor Green
Write-Host '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' -ForegroundColor Gray

Write-Host '📋 Setup Summary:' -ForegroundColor Cyan
Write-Host '  ✅ PowerShell 7, VSCode, and Git installed' -ForegroundColor White
Write-Host '  ✅ PowerShell and Git extensions configured' -ForegroundColor White
Write-Host '  ✅ Pester testing extensions installed' -ForegroundColor White
Write-Host '  ✅ Markdown documentation support added' -ForegroundColor White
Write-Host '  ✅ Pester module installed/verified' -ForegroundColor White
Write-Host '  ✅ Git configured for lab exercises' -ForegroundColor White

Write-Host "`n📚 Next Steps:" -ForegroundColor Cyan
Write-Host '  1. Restart your console if applications were just installed' -ForegroundColor White
Write-Host '  2. Open VSCode and verify extensions are loaded' -ForegroundColor White
Write-Host '  3. Navigate to the Pester Labs folder' -ForegroundColor White
Write-Host '  4. Start with Lab1.md for basic Pester concepts' -ForegroundColor White

Write-Host "`n🔧 Lab Environment Ready!" -ForegroundColor Green
Write-Host "You can now run 'code .' in any lab folder to start working with full Pester support." -ForegroundColor Yellow

# Optional: Open VSCode in the current directory if we're in a lab folder
$currentPath = Get-Location
if ($currentPath.Path -like '*Pester*' -or $currentPath.Path -like '*Lab*')
{
    Write-Host "`n❓ Would you like to open VSCode in the current directory? (y/n): " -ForegroundColor Cyan -NoNewline
    $response = Read-Host
    if ($response -eq 'y' -or $response -eq 'Y')
    {
        Write-Host '🚀 Opening VSCode...' -ForegroundColor Green
        code .
    }
}