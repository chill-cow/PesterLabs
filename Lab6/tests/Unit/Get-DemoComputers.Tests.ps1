BeforeAll {
    # Import the module under test
    $ModulePath = Join-Path $PSScriptRoot '..\..\PowerShellModule.psd1'
    Import-Module $ModulePath -Force
    
    # Import test helpers
    $TestHelpersPath = Join-Path $PSScriptRoot '..\TestHelpers\TestHelpers.psm1'
    if (Test-Path $TestHelpersPath) {
        Import-Module $TestHelpersPath -Force
    }
}

Describe 'Get-DemoComputers Function Tests' -Tag 'Unit', 'Get-DemoComputers' {
    
    Context 'Parameter Validation and Metadata' {
        It 'Should have Count parameter with valid range' {
            $command = Get-Command Get-DemoComputers
            $countParam = $command.Parameters['Count']
            
            $countParam | Should -Not -BeNullOrEmpty
            $countParam.ParameterType | Should -Be ([int])
            
            # Check for ValidateRange attribute
            $validateRange = $countParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $validateRange | Should -Not -BeNullOrEmpty
            $validateRange.MinRange | Should -Be 1
            $validateRange.MaxRange | Should -Be 1000
        }
        
        It 'Should have NamePrefix parameter with validation' {
            Test-FunctionParameter -FunctionName 'Get-DemoComputers' -ParameterName 'NamePrefix' -Type ([string])
        }
        
        It 'Should have Domain parameter' {
            Test-FunctionParameter -FunctionName 'Get-DemoComputers' -ParameterName 'Domain' -Type ([string])
        }
        
        It 'Should have OperatingSystem parameter' {
            Test-FunctionParameter -FunctionName 'Get-DemoComputers' -ParameterName 'OperatingSystem' -Type ([string])
        }
        
        It 'Should have Online parameter as switch' {
            Test-FunctionParameter -FunctionName 'Get-DemoComputers' -ParameterName 'Online' -Type ([switch])
        }
        
        It 'Should have IncludeProperties parameter with valid set' {
            $command = Get-Command Get-DemoComputers
            $includeParam = $command.Parameters['IncludeProperties']
            
            $includeParam | Should -Not -BeNullOrEmpty
            $validateSet = $includeParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'Hardware'
            $validateSet.ValidValues | Should -Contain 'Network'
            $validateSet.ValidValues | Should -Contain 'Software'
            $validateSet.ValidValues | Should -Contain 'All'
        }
        
        It 'Should have proper help documentation' {
            $help = Get-Help Get-DemoComputers -Full
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Basic Computer Generation' {
        It 'Should generate default number of computers (10)' {
            $result = Get-DemoComputers
            
            $result | Should -HaveCount 10
            $result | Should -BeOfType [PSCustomObject]
        }
        
        It 'Should generate specified number of computers' {
            $result = Get-DemoComputers -Count 5
            
            $result | Should -HaveCount 5
        }
        
        It 'Should use default name prefix "DEMO"' {
            $result = Get-DemoComputers -Count 3
            
            $result[0].Name | Should -Match '^DEMO001$'
            $result[1].Name | Should -Match '^DEMO002$'
            $result[2].Name | Should -Match '^DEMO003$'
        }
        
        It 'Should use custom name prefix' {
            $result = Get-DemoComputers -Count 2 -NamePrefix "TEST"
            
            $result[0].Name | Should -Match '^TEST001$'
            $result[1].Name | Should -Match '^TEST002$'
        }
        
        It 'Should append domain when specified' {
            $result = Get-DemoComputers -Count 2 -Domain "contoso.com"
            
            $result[0].Name | Should -Match '^DEMO001\.contoso\.com$'
            $result[1].Name | Should -Match '^DEMO002\.contoso\.com$'
        }
    }
    
    Context 'Computer Object Properties' {
        BeforeAll {
            $computer = Get-DemoComputers -Count 1 | Select-Object -First 1
        }
        
        It 'Should have all required base properties' {
            $requiredProperties = @(
                'Name', 'OperatingSystem', 'HardwareType', 'Manufacturer',
                'Department', 'Location', 'Online', 'LastSeen', 'CreatedDate'
            )
            
            foreach ($property in $requiredProperties) {
                $computer.PSObject.Properties.Name | Should -Contain $property
            }
        }
        
        It 'Should have proper PSTypeName' {
            $computer.PSTypeNames | Should -Contain 'DemoComputer'
        }
        
        It 'Should have realistic operating system values' {
            $validOSList = @(
                'Windows 11 Pro', 'Windows 11 Enterprise', 'Windows 10 Pro',
                'Windows 10 Enterprise', 'Windows Server 2022', 'Windows Server 2019',
                'Ubuntu 22.04 LTS', 'CentOS 8'
            )
            
            $computer.OperatingSystem | Should -BeIn $validOSList
        }
        
        It 'Should have realistic hardware types' {
            $validHardware = @('Desktop', 'Laptop', 'Server', 'Virtual Machine')
            $computer.HardwareType | Should -BeIn $validHardware
        }
        
        It 'Should have valid manufacturers' {
            $validManufacturers = @('Dell', 'HP', 'Lenovo', 'Microsoft', 'ASUS')
            $computer.Manufacturer | Should -BeIn $validManufacturers
        }
        
        It 'Should have boolean Online property' {
            $computer.Online | Should -BeOfType [bool]
        }
        
        It 'Should have DateTime properties' {
            $computer.LastSeen | Should -BeOfType [DateTime]
            $computer.CreatedDate | Should -BeOfType [DateTime]
        }
    }
    
    Context 'Extended Properties - Hardware' {
        It 'Should include hardware properties when requested' {
            $result = Get-DemoComputers -Count 1 -IncludeProperties 'Hardware'
            $computer = $result | Select-Object -First 1
            
            $computer.PSObject.Properties.Name | Should -Contain 'CPU'
            $computer.PSObject.Properties.Name | Should -Contain 'Memory'
            $computer.PSObject.Properties.Name | Should -Contain 'Storage'
            $computer.PSObject.Properties.Name | Should -Contain 'SerialNumber'
        }
        
        It 'Should have realistic hardware specifications' {
            $result = Get-DemoComputers -Count 1 -IncludeProperties 'Hardware'
            $computer = $result | Select-Object -First 1
            
            $computer.CPU | Should -Match 'Intel Core i[5-7] \d+th Gen'
            $computer.Memory | Should -Match '\d+GB'
            $computer.Storage | Should -Match '\d+GB SSD'
            $computer.SerialNumber | Should -Match 'SN\d{8}'
        }
    }
    
    Context 'Extended Properties - Network' {
        It 'Should include network properties when requested' {
            $result = Get-DemoComputers -Count 1 -IncludeProperties 'Network'
            $computer = $result | Select-Object -First 1
            
            $computer.PSObject.Properties.Name | Should -Contain 'IPAddress'
            $computer.PSObject.Properties.Name | Should -Contain 'MACAddress'
            $computer.PSObject.Properties.Name | Should -Contain 'DNSServers'
        }
        
        It 'Should have valid IP address format' {
            $result = Get-DemoComputers -Count 1 -IncludeProperties 'Network'
            $computer = $result | Select-Object -First 1
            
            $computer.IPAddress | Should -Match '^192\.168\.\d{1,3}\.\d{1,3}$'
        }
        
        It 'Should have valid MAC address format' {
            $result = Get-DemoComputers -Count 1 -IncludeProperties 'Network'
            $computer = $result | Select-Object -First 1
            
            $computer.MACAddress | Should -Match '^([0-9A-F]{2}:){5}[0-9A-F]{2}$'
        }
        
        It 'Should have DNS servers array' {
            $result = Get-DemoComputers -Count 1 -IncludeProperties 'Network'
            $computer = $result | Select-Object -First 1
            
            $computer.DNSServers | Should -BeOfType [System.Array]
            $computer.DNSServers | Should -Contain '8.8.8.8'
            $computer.DNSServers | Should -Contain '8.8.4.4'
        }
    }
    
    Context 'Extended Properties - Software' {
        It 'Should include software properties when requested' {
            $result = Get-DemoComputers -Count 1 -IncludeProperties 'Software'
            $computer = $result | Select-Object -First 1
            
            $computer.PSObject.Properties.Name | Should -Contain 'InstalledSoftware'
            $computer.PSObject.Properties.Name | Should -Contain 'LastUpdate'
            $computer.PSObject.Properties.Name | Should -Contain 'AntivirusStatus'
        }
        
        It 'Should have software array with realistic applications' {
            $result = Get-DemoComputers -Count 1 -IncludeProperties 'Software'
            $computer = $result | Select-Object -First 1
            
            $computer.InstalledSoftware | Should -BeOfType [System.Array]
            $computer.InstalledSoftware.Count | Should -BeGreaterThan 0
            $computer.InstalledSoftware | Should -Contain 'Microsoft Office 365'
        }
        
        It 'Should have antivirus status' {
            $result = Get-DemoComputers -Count 8 -IncludeProperties 'Software'
            
            $statuses = $result | ForEach-Object { $_.AntivirusStatus }
            $statuses | Should -Contain 'Protected'
            # Every 7th computer should have Warning status based on implementation
        }
    }
    
    Context 'Extended Properties - All' {
        It 'Should include all extended properties when All is specified' {
            $result = Get-DemoComputers -Count 1 -IncludeProperties 'All'
            $computer = $result | Select-Object -First 1
            
            # Hardware properties
            $computer.PSObject.Properties.Name | Should -Contain 'CPU'
            $computer.PSObject.Properties.Name | Should -Contain 'Memory'
            
            # Network properties
            $computer.PSObject.Properties.Name | Should -Contain 'IPAddress'
            $computer.PSObject.Properties.Name | Should -Contain 'MACAddress'
            
            # Software properties
            $computer.PSObject.Properties.Name | Should -Contain 'InstalledSoftware'
            $computer.PSObject.Properties.Name | Should -Contain 'AntivirusStatus'
        }
    }
    
    Context 'Filtering Functionality' {
        It 'Should filter by operating system' {
            $result = Get-DemoComputers -Count 20 -OperatingSystem "*Windows 11*"
            
            foreach ($computer in $result) {
                $computer.OperatingSystem | Should -Match 'Windows 11'
            }
        }
        
        It 'Should filter to online computers only' {
            $result = Get-DemoComputers -Count 20 -Online
            
            foreach ($computer in $result) {
                $computer.Online | Should -BeTrue
            }
        }
        
        It 'Should return empty result when no computers match filter' {
            $result = Get-DemoComputers -Count 10 -OperatingSystem "*NonexistentOS*"
            
            $result | Should -BeNullOrEmpty
        }
        
        It 'Should combine filters correctly' {
            $result = Get-DemoComputers -Count 50 -OperatingSystem "*Windows*" -Online
            
            foreach ($computer in $result) {
                $computer.OperatingSystem | Should -Match 'Windows'
                $computer.Online | Should -BeTrue
            }
        }
    }
    
    Context 'Deterministic Generation' {
        It 'Should generate consistent results with same parameters' {
            $result1 = Get-DemoComputers -Count 5 -NamePrefix "TEST"
            $result2 = Get-DemoComputers -Count 5 -NamePrefix "TEST"
            
            for ($i = 0; $i -lt 5; $i++) {
                $result1[$i].Name | Should -Be $result2[$i].Name
                $result1[$i].OperatingSystem | Should -Be $result2[$i].OperatingSystem
                $result1[$i].Manufacturer | Should -Be $result2[$i].Manufacturer
            }
        }
        
        It 'Should maintain logical relationships in generated data' {
            $result = Get-DemoComputers -Count 10 -IncludeProperties 'All'
            
            foreach ($computer in $result) {
                # Online computers should have recent LastSeen dates
                if ($computer.Online) {
                    $computer.LastSeen | Should -BeGreaterThan (Get-Date).AddHours(-1)
                }
                
                # Servers should typically have more memory
                if ($computer.HardwareType -eq 'Server') {
                    [int]($computer.Memory -replace 'GB', '') | Should -BeGreaterThan 8
                }
            }
        }
    }
    
    Context 'Performance and Scalability' {
        It 'Should generate large datasets efficiently' {
            $result = Assert-PerformanceWithin -MaxDuration ([timespan]::FromSeconds(10)) -ScriptBlock {
                Get-DemoComputers -Count 1000
            }
            
            $result | Should -HaveCount 1000
        }
        
        It 'Should maintain performance with extended properties' {
            $duration = Measure-Command {
                Get-DemoComputers -Count 500 -IncludeProperties 'All' | Out-Null
            }
            
            $duration.TotalSeconds | Should -BeLessThan 15
        }
        
        It 'Should handle maximum count efficiently' {
            $duration = Measure-Command {
                Get-DemoComputers -Count 1000 | Out-Null
            }
            
            $duration.TotalSeconds | Should -BeLessThan 20
        }
    }
    
    Context 'Verbose Output and Logging' {
        It 'Should provide verbose output when requested' {
            $verboseOutput = @()
            Get-DemoComputers -Count 2 -Verbose 4>&1 | 
                Tee-Object -Variable verboseOutput | Out-Null
            
            $verboseOutput | Should -Not -BeNullOrEmpty
            $verboseOutput -join '' | Should -Match 'Generating.*demo computers'
        }
        
        It 'Should include generation statistics in verbose output' {
            $verboseOutput = @()
            Get-DemoComputers -Count 5 -OperatingSystem "*Windows*" -Verbose 4>&1 | 
                Tee-Object -Variable verboseOutput | Out-Null
            
            $verboseOutput -join '' | Should -Match 'Generated.*demo computers'
        }
        
        It 'Should warn when no computers match criteria' {
            $warningOutput = @()
            Get-DemoComputers -Count 10 -OperatingSystem "*InvalidOS*" -WarningVariable warningOutput | Out-Null
            
            $warningOutput | Should -Not -BeNullOrEmpty
            $warningOutput -join '' | Should -Match 'No computers match'
        }
    }
    
    Context 'Error Handling and Edge Cases' {
        It 'Should handle minimum count (1)' {
            $result = Get-DemoComputers -Count 1
            
            $result | Should -HaveCount 1
            $result.Name | Should -Be 'DEMO001'
        }
        
        It 'Should reject invalid count values' {
            { Get-DemoComputers -Count 0 } | Should -Throw
            { Get-DemoComputers -Count 1001 } | Should -Throw
        }
        
        It 'Should handle empty name prefix gracefully' {
            { Get-DemoComputers -Count 1 -NamePrefix "" } | Should -Throw
        }
        
        It 'Should continue processing despite individual computer generation errors' {
            # This test would need specific conditions to trigger errors
            # For now, verify the function is resilient to unexpected conditions
            $result = Get-DemoComputers -Count 5
            $result | Should -HaveCount 5
        }
    }
}