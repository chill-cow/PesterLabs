# PowerShell CI/CD Module

A comprehensive PowerShell module demonstrating CI/CD best practices with GitHub Actions, automated testing, and quality gates.

## 📋 Overview

This module is part of **Lab 6 - CI/CD Integration with GitHub Actions** and demonstrates:

- Multi-platform PowerShell module development
- Comprehensive testing with Pester
- GitHub Actions CI/CD workflows
- Code quality analysis with PSScriptAnalyzer
- Automated documentation generation
- Security scanning and vulnerability assessment
- Automated release management

## 🚀 Features

### Core Functions

- **ConvertTo-UpperCase**: Advanced string conversion with PassThru mode and comprehensive error handling
- **Get-EmailAddress**: Email validation and formatting with multiple output options
- **Get-DemoComputers**: Demo computer object generator for testing scenarios

### CI/CD Pipeline

- **Continuous Integration**: Automated testing on Windows, Linux, and macOS
- **Code Quality**: PSScriptAnalyzer integration with customizable rules
- **Security Scanning**: Trivy vulnerability assessment
- **Documentation**: Automated help generation with platyPS
- **Release Management**: Semantic versioning and automated GitHub releases

## 📦 Requirements

- PowerShell 7.4 or later
- Pester 5.7.1 or later
- PSScriptAnalyzer (for code quality)
- Git (for version control)
- GitHub account (for CI/CD workflows)

## 🛠️ Installation

### From Source

```powershell
# Clone the repository
git clone https://github.com/yourusername/powershell-cicd-module.git
cd powershell-cicd-module

# Import the module
Import-Module .\PowerShellModule.psd1
```

### From PowerShell Gallery (when published)

```powershell
Install-Module -Name PowerShellModule -Scope CurrentUser
Import-Module PowerShellModule
```

## 📖 Usage

### Basic Examples

```powershell
# Convert strings to uppercase
"hello world" | ConvertTo-UpperCase
# Output: HELLO WORLD

# Validate and format email addresses
"User@Example.COM" | Get-EmailAddress -Format Lower
# Output: user@example.com

# Generate demo computer objects
Get-DemoComputers -Count 5 -IncludeProperties Basic
```

### Advanced Usage

```powershell
# Use PassThru mode for detailed processing
$results = @("test1", "test2", "invalid`0") | ConvertTo-UpperCase -PassThru
$results | Where-Object Success | ForEach-Object { $_.Result }

# Email validation with strict mode
Get-EmailAddress -EmailAddress "user@domain.com" -Format Domain -Strict

# Generate computers with extended properties
Get-DemoComputers -Count 10 -IncludeProperties All -AsJob
```

## 🧪 Testing

### Quick Test Run

```powershell
# Run all tests
.\RunLabTests.ps1

# Run specific test types
.\RunLabTests.ps1 -TestType Unit -CodeCoverage
.\RunLabTests.ps1 -TestType Integration -Verbose
.\RunLabTests.ps1 -TestType Performance
```

### Test Categories

- **Unit Tests**: Individual function testing with comprehensive parameter validation
- **Integration Tests**: Cross-function workflows and module integration
- **Performance Tests**: Execution speed and memory efficiency validation
- **Quality Tests**: Code analysis and best practices compliance

### Code Coverage

The module maintains >90% code coverage across all functions:

```powershell
# Generate coverage report
.\RunLabTests.ps1 -TestType Unit -CodeCoverage -GenerateReport
```

## 🔄 CI/CD Workflows

### GitHub Actions

The repository includes three main workflows:

1. **Continuous Integration** (`.github/workflows/ci.yml`)
   - Multi-platform testing (Windows, Linux, macOS)
   - PowerShell 7.4+ compatibility validation
   - Pester test execution with coverage reporting

2. **Code Quality** (`.github/workflows/code-quality.yml`)
   - PSScriptAnalyzer static analysis
   - Security vulnerability scanning with Trivy
   - Documentation validation
   - Markdown link checking

3. **Release Management** (`.github/workflows/release.yml`)
   - Semantic version management
   - Automated changelog generation
   - GitHub release creation
   - PowerShell Gallery publishing
   - Documentation deployment

### Branch Protection

Configure branch protection rules:

```yaml
# Required status checks
- CI / Test (ubuntu-latest, 7.4)
- CI / Test (windows-latest, 7.4)
- CI / Test (macos-latest, 7.4)
- Code Quality / Analyze

# Additional settings
- Require pull request reviews
- Dismiss stale reviews
- Require status checks to pass
- Require branches to be up to date
```

### Secrets Configuration

Required repository secrets:

```
NUGET_API_KEY          # PowerShell Gallery publishing
CODECOV_TOKEN          # Code coverage reporting
GITHUB_TOKEN           # Automatic (GitHub provides)
```

## 📊 Quality Gates

### Code Quality Standards

- PSScriptAnalyzer compliance (Error/Warning level)
- Minimum 90% code coverage
- All tests must pass on all platforms
- Security vulnerability assessment
- Documentation completeness validation

### Performance Benchmarks

- ConvertTo-UpperCase: >500 items/second
- Get-EmailAddress: >200 validations/second  
- Get-DemoComputers: Generate 100 objects in <2 seconds

## 🗂️ Project Structure

```
PowerShell-CICD-Module/
├── .github/
│   └── workflows/           # GitHub Actions workflows
├── src/
│   ├── Public/             # Exported functions
│   └── Private/            # Internal helper functions
├── tests/
│   ├── Unit/               # Unit tests
│   ├── Integration/        # Integration tests
│   └── TestHelpers/        # Test utility functions
├── docs/                   # Documentation
├── PowerShellModule.psd1   # Module manifest
├── PowerShellModule.psm1   # Module loader
├── RunLabTests.ps1         # Comprehensive test runner
└── README.md              # This file
```

## 🚀 Getting Started with CI/CD

### 1. Repository Setup

```bash
# Create new repository
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/powershell-cicd-module.git
git push -u origin main
```

### 2. Enable GitHub Actions

1. Navigate to repository Settings > Actions > General
2. Set "Actions permissions" to "Allow all actions and reusable workflows"
3. Configure workflow permissions for GITHUB_TOKEN

### 3. Configure Secrets

1. Go to Settings > Secrets and variables > Actions
2. Add required secrets (see Secrets Configuration above)
3. Configure environment protection rules for production deployments

### 4. Set Up Branch Protection

1. Go to Settings > Branches
2. Add protection rule for `main` branch
3. Configure required status checks and review requirements

## 📚 Learning Objectives

This lab demonstrates:

- **PowerShell Module Development**: Best practices for structure, manifest, and exports
- **Test-Driven Development**: Comprehensive testing strategies with Pester
- **CI/CD Pipeline Design**: Multi-stage workflows with quality gates
- **Code Quality Automation**: Static analysis and security scanning
- **Release Management**: Semantic versioning and automated publishing
- **Documentation as Code**: Automated help generation and maintenance

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and add tests
4. Ensure all quality gates pass (`.\RunLabTests.ps1`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Pester team for the excellent testing framework
- PowerShell team for cross-platform PowerShell
- GitHub Actions for robust CI/CD capabilities
- Community contributors and feedback

## 🆘 Support

- 📖 [Documentation](docs/)
- 🐛 [Issues](https://github.com/yourusername/powershell-cicd-module/issues)
- 💬 [Discussions](https://github.com/yourusername/powershell-cicd-module/discussions)
- 📧 Contact: your.email@example.com

---

**Lab 6 - CI/CD Integration with GitHub Actions**  
*Part of the Advanced Pester Testing Lab Series*