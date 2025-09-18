@{
    # Script module or binary module file associated with this manifest.
    RootModule           = 'PowerShellModule.psm1'
    
    # Version number of this module.
    ModuleVersion        = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Core', 'Desktop')
    
    # ID used to uniquely identify this module
    GUID                 = '12345678-1234-1234-1234-123456789012'
    
    # Author of this module
    Author               = 'Your Name'
    
    # Company or vendor of this module
    CompanyName          = 'Your Company'
    
    # Copyright statement for this module
    Copyright            = '(c) 2025 Your Company. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description          = 'A sample PowerShell module with comprehensive testing and CI/CD integration'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '7.4'
    
    # Functions to export from this module
    FunctionsToExport    = @(
        'ConvertTo-UpperCase',
        'Get-EmailAddress', 
        'Get-DemoComputers'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport      = @()
    
    # Variables to export from this module
    VariablesToExport    = @()
    
    # Aliases to export from this module
    AliasesToExport      = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData          = @{
        PSData = @{
            # Tags applied to this module
            Tags         = @('Testing', 'Pester', 'CI/CD', 'PowerShell', 'GitHub-Actions')
            
            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/YourUsername/PowerShell-Testing-Project/blob/main/LICENSE'
            
            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/YourUsername/PowerShell-Testing-Project'
            
            # Release notes for this module
            ReleaseNotes = 'Initial release with comprehensive testing framework and CI/CD integration'
        }
    }
}