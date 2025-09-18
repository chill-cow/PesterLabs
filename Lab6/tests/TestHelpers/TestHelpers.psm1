# Test helper functions for consistent testing across the PowerShell Module project

function New-TestDataSet {
    <#
    .SYNOPSIS
        Creates standardized test data sets for consistent testing.
    
    .DESCRIPTION
        Generates test data sets of various types and sizes for comprehensive testing
        scenarios. Provides consistent, predictable data for unit and integration tests.
    
    .PARAMETER Type
        The type of test data to generate:
        - Small: Simple short strings
        - Medium: Medium-length strings with additional content
        - Large: Long strings for performance testing
        - Email: Realistic email addresses with various domains
        - Computer: Computer names in standard format
    
    .PARAMETER Size
        The number of items to generate in the dataset.
    
    .EXAMPLE
        New-TestDataSet -Type 'Email' -Size 5
        
        Generates 5 email addresses for testing.
    
    .EXAMPLE
        New-TestDataSet -Type 'Large' -Size 100
        
        Generates 100 large strings for performance testing.
    #>
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Small', 'Medium', 'Large', 'Email', 'Computer')]
        [string]$Type,
        
        [Parameter()]
        [ValidateRange(1, 10000)]
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
                "LargeTestDataSet$_ " + ("x" * 100) + " with extended content for testing performance"
            }
        }
        'Email' {
            1..$Size | ForEach-Object { 
                $domains = @('example.com', 'test.org', 'sample.net', 'company.biz', 'demo.info')
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
    
    .DESCRIPTION
        Executes a script block and verifies it completes within the specified
        time duration. Returns the result of the script block execution while
        asserting performance requirements.
    
    .PARAMETER ScriptBlock
        The script block to execute and time.
    
    .PARAMETER MaxDuration
        The maximum allowed execution time as a TimeSpan object.
    
    .PARAMETER Because
        Optional reason for the performance requirement.
    
    .EXAMPLE
        $result = Assert-PerformanceWithin -MaxDuration ([timespan]::FromSeconds(5)) -ScriptBlock {
            Get-DemoComputers -Count 100
        }
        
        Executes the script block and verifies it completes within 5 seconds.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory)]
        [timespan]$MaxDuration,
        
        [Parameter()]
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
        Tests function parameter characteristics for validation.
    
    .DESCRIPTION
        Validates that a function has the expected parameter with specified
        characteristics such as mandatory status, pipeline input support, and type.
    
    .PARAMETER FunctionName
        The name of the function to test.
    
    .PARAMETER ParameterName
        The name of the parameter to validate.
    
    .PARAMETER Mandatory
        Switch to test if the parameter is mandatory.
    
    .PARAMETER ValueFromPipeline
        Switch to test if the parameter accepts pipeline input.
    
    .PARAMETER Type
        The expected type of the parameter.
    
    .EXAMPLE
        Test-FunctionParameter -FunctionName 'Get-EmailAddress' -ParameterName 'EmailAddress' -Mandatory -ValueFromPipeline
        
        Tests that Get-EmailAddress has a mandatory EmailAddress parameter that accepts pipeline input.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,
        
        [Parameter(Mandatory)]
        [string]$ParameterName,
        
        [Parameter()]
        [switch]$Mandatory,
        
        [Parameter()]
        [switch]$ValueFromPipeline,
        
        [Parameter()]
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
        $isMandatory | Should -Not -BeNullOrEmpty -Because "Parameter '$ParameterName' should be mandatory"
    }
    
    if ($ValueFromPipeline) {
        $acceptsPipeline = $parameter.Attributes |
            Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
            Where-Object { $_.ValueFromPipeline }
        $acceptsPipeline | Should -Not -BeNullOrEmpty -Because "Parameter '$ParameterName' should accept pipeline input"
    }
    
    if ($Type) {
        $parameter.ParameterType | Should -Be $Type -Because "Parameter '$ParameterName' should have correct type"
    }
}

function Invoke-WithRetry {
    <#
    .SYNOPSIS
        Executes a script block with retry logic for flaky operations.
    
    .DESCRIPTION
        Attempts to execute a script block multiple times with configurable
        retry delays. Useful for testing operations that might be temporarily
        unavailable or have intermittent failures.
    
    .PARAMETER ScriptBlock
        The script block to execute with retry logic.
    
    .PARAMETER MaxRetries
        The maximum number of retry attempts. Defaults to 3.
    
    .PARAMETER RetryDelay
        The delay between retry attempts. Defaults to 1 second.
    
    .EXAMPLE
        $result = Invoke-WithRetry -ScriptBlock {
            Test-Connection -ComputerName 'server.domain.com' -Count 1 -Quiet
        } -MaxRetries 5 -RetryDelay ([timespan]::FromSeconds(2))
        
        Tests connection with up to 5 retries, waiting 2 seconds between attempts.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3,
        
        [Parameter()]
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
            
            Write-Verbose "Attempt $attempt failed, retrying in $($RetryDelay.TotalSeconds) seconds... Error: $_"
            Start-Sleep $RetryDelay
            $attempt++
        }
    } while ($attempt -le $MaxRetries)
}

function New-MockEmailDataset {
    <#
    .SYNOPSIS
        Creates a mock dataset with valid and invalid email addresses for testing.
    
    .DESCRIPTION
        Generates a controlled dataset containing both valid and invalid email
        addresses in predictable patterns for comprehensive email validation testing.
    
    .PARAMETER ValidCount
        The number of valid email addresses to generate.
    
    .PARAMETER InvalidCount
        The number of invalid email addresses to generate.
    
    .PARAMETER IncludeBorderlineCases
        Switch to include email addresses that are borderline valid/invalid.
    
    .EXAMPLE
        $testEmails = New-MockEmailDataset -ValidCount 10 -InvalidCount 5
        
        Creates a dataset with 10 valid and 5 invalid email addresses.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter()]
        [ValidateRange(0, 1000)]
        [int]$ValidCount = 5,
        
        [Parameter()]
        [ValidateRange(0, 1000)]
        [int]$InvalidCount = 3,
        
        [Parameter()]
        [switch]$IncludeBorderlineCases
    )
    
    $validEmails = @()
    $invalidEmails = @()
    $borderlineEmails = @()
    
    # Generate valid emails
    for ($i = 1; $i -le $ValidCount; $i++) {
        $domains = @('example.com', 'test.org', 'company.net', 'domain.co.uk', 'sample.edu')
        $domain = $domains[($i - 1) % $domains.Count]
        $validEmails += "user$i@$domain"
    }
    
    # Generate invalid emails
    $invalidPatterns = @(
        'invalid.email.no.at',
        '@missing.local.part.com',
        'missing.domain@',
        'user@domain',
        'user space@domain.com',
        'user@domain space.com',
        '',
        'user@@double.at.com',
        'user@.starting.dot.com',
        'user@ending.dot.com.'
    )
    
    for ($i = 0; $i -lt [Math]::Min($InvalidCount, $invalidPatterns.Count); $i++) {
        $invalidEmails += $invalidPatterns[$i]
    }
    
    # Generate additional invalid emails if needed
    for ($i = $invalidPatterns.Count; $i -lt $InvalidCount; $i++) {
        $invalidEmails += "invalid$i@"
    }
    
    # Generate borderline cases if requested
    if ($IncludeBorderlineCases) {
        $borderlineEmails = @(
            'user+tag@example.com',
            'user.name+tag@example.com',
            'test@subdomain.domain.co.uk',
            'a@b.co',
            'user123456789012345678901234567890@very-long-domain-name.com'
        )
    }
    
    return @{
        Valid = $validEmails
        Invalid = $invalidEmails
        Borderline = $borderlineEmails
        All = $validEmails + $invalidEmails + $borderlineEmails
    }
}

function Test-ModuleFunction {
    <#
    .SYNOPSIS
        Validates that a module function meets basic requirements.
    
    .DESCRIPTION
        Performs standard validation checks on module functions including
        parameter validation, help content, and basic functionality tests.
    
    .PARAMETER FunctionName
        The name of the function to validate.
    
    .PARAMETER RequiredParameters
        Array of parameter names that should be present and mandatory.
    
    .PARAMETER TestInputs
        Hashtable of test inputs to validate basic functionality.
    
    .EXAMPLE
        Test-ModuleFunction -FunctionName 'ConvertTo-UpperCase' -RequiredParameters @('InputString') -TestInputs @{ 'hello' = 'HELLO' }
        
        Validates the ConvertTo-UpperCase function has required parameters and basic functionality.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,
        
        [Parameter()]
        [string[]]$RequiredParameters = @(),
        
        [Parameter()]
        [hashtable]$TestInputs = @{}
    )
    
    # Test function exists
    $function = Get-Command $FunctionName -ErrorAction SilentlyContinue
    $function | Should -Not -BeNullOrEmpty -Because "Function '$FunctionName' should exist"
    
    # Test required parameters
    foreach ($paramName in $RequiredParameters) {
        $function.Parameters.ContainsKey($paramName) | Should -BeTrue -Because "Function should have parameter '$paramName'"
    }
    
    # Test help content
    $help = Get-Help $FunctionName -ErrorAction SilentlyContinue
    $help.Synopsis | Should -Not -BeNullOrEmpty -Because "Function should have synopsis"
    $help.Description | Should -Not -BeNullOrEmpty -Because "Function should have description"
    
    # Test basic functionality with provided inputs
    foreach ($input in $TestInputs.GetEnumerator()) {
        try {
            $result = & $FunctionName -InputString $input.Key
            $result | Should -Be $input.Value -Because "Function should transform '$($input.Key)' to '$($input.Value)'"
        }
        catch {
            throw "Function '$FunctionName' failed with input '$($input.Key)': $_"
        }
    }
}

# Export all public functions
Export-ModuleMember -Function @(
    'New-TestDataSet',
    'Assert-PerformanceWithin', 
    'Test-FunctionParameter',
    'Invoke-WithRetry',
    'New-MockEmailDataset',
    'Test-ModuleFunction'
)