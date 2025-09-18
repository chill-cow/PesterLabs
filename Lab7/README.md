# Lab 7: VS Code Testing Integration with Pester

## Overview

This lab focuses on integrating Pester tests with VS Code's built-in Test Explorer, providing a comprehensive guide to modern PowerShell test-driven development using Visual Studio Code.

## What You'll Learn

- **VS Code Test Explorer setup** for seamless Pester integration
- **Test discovery and navigation** in large PowerShell projects  
- **Running and debugging tests** directly from VS Code interface
- **Continuous testing workflows** with auto-run capabilities
- **Code coverage visualization** and reporting
- **Advanced VS Code testing features** and customization

## Key Features

### Real-World Examples
- **Calculator Class**: Demonstrates class testing patterns
- **String Utilities**: Shows function testing with edge cases
- **Error Handling**: Exception testing and validation
- **Business Logic**: Complex scenarios and validation rules

### VS Code Integration
- **Test Explorer**: Visual test management and execution
- **CodeLens**: Inline test execution buttons
- **Debugging**: Full breakpoint and debugging support
- **Auto-Run**: Tests execute automatically on file changes
- **Coverage**: Line-by-line code coverage visualization

## Lab Structure

```
VSCodeTestingLab/
├── src/                    # Source code to test
│   ├── Calculator.ps1      # Calculator class with math operations
│   └── StringUtils.ps1     # String utility functions
├── tests/                  # Test files
│   ├── Calculator.Tests.ps1    # Calculator tests
│   └── StringUtils.Tests.ps1   # String utility tests
├── .vscode/               # VS Code configuration
│   ├── settings.json      # Editor and extension settings
│   └── tasks.json         # Custom build tasks
├── PesterConfig.ps1       # Pester configuration
└── RunTests.ps1          # Custom test runner
```

## Prerequisites

- PowerShell 7.4+
- Pester 5.7.1+
- VS Code with PowerShell extension
- Basic understanding of Pester (Labs 1-6)

## Lab Exercises

1. **Setup**: Install extensions and configure VS Code
2. **Discovery**: Learn how VS Code finds and organizes tests
3. **Execution**: Run tests from Test Explorer and CodeLens
4. **Debugging**: Set breakpoints and debug failing tests
5. **Navigation**: Move between tests and source code efficiently
6. **Automation**: Enable continuous testing and auto-run
7. **Coverage**: Visualize code coverage with Coverage Gutters
8. **Customization**: Create custom tasks and configurations

## Key Benefits

- **Visual Testing**: See all tests in a hierarchical tree view
- **Integrated Debugging**: Debug tests like any other PowerShell code
- **Fast Feedback**: Immediate test results without switching to terminal
- **Coverage Insights**: Understand which code paths are tested
- **Productivity**: Streamlined testing workflow in familiar IDE

## Advanced Features

- **Custom test runners** with specific configurations
- **Task integration** for complex build scenarios
- **Coverage reporting** with visual gutters
- **Multi-project support** for larger codebases
- **CI/CD integration** preparation

## Success Criteria

By completing this lab, you'll be able to:
- ✅ Set up VS Code for optimal Pester testing experience
- ✅ Discover, run, and debug tests without leaving VS Code
- ✅ Use Test Explorer for visual test management
- ✅ Enable continuous testing for immediate feedback
- ✅ Visualize code coverage and identify untested code
- ✅ Create custom testing workflows and configurations

---
**Estimated Time**: 60-75 minutes  
**Difficulty**: Intermediate to Advanced  
**Focus**: VS Code Integration & Productivity