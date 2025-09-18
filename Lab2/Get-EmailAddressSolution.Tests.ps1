#Requires -Modules @{ ModuleName="Pester"; MaximumVersion="5.7.1" }
[CmdletBinding()]
param()

BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}

Describe 'Get-EmailAddress' -Tag 'Unit' {
    Context 'When extracting email addresses from text' {
        It 'Should extract valid email addresses from text' {
            # Arrange
            $text = 'Contact john.doe@example.com or jane@test.org for more info'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -HaveCount 2
            $result | Should -Contain 'john.doe@example.com'
            $result | Should -Contain 'jane@test.org'
        }

        It 'Should handle single email address' {
            # Arrange
            $text = 'Email us at support@company.com'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -Be 'support@company.com'
        }

        It 'Should return empty array when no emails found' {
            # Arrange
            $text = 'This text contains no email addresses'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should handle empty string input' {
            # Act
            $result = Get-EmailAddress -string ''
            
            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should handle null input' {
            # Act
            $result = Get-EmailAddress -string $null
            
            # Assert
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When validating email formats' {
        It 'Should extract emails with valid TLD (2+ characters)' {
            # Arrange
            $text = 'Valid: user@domain.com, user@domain.co.uk'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -HaveCount 2
            $result | Should -Contain 'user@domain.com'
            $result | Should -Contain 'user@domain.co.uk'
        }

        It 'Should reject emails with single character TLD' {
            # Arrange
            $text = 'Invalid: user@domain.c'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -BeNullOrEmpty
        }

        It 'Should handle emails with numbers and special characters' {
            # Arrange
            $text = 'Contact test123+tag@example-site.org'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -Be 'test123+tag@example-site.org'
        }

        It 'Should handle emails with underscores and dots' {
            # Arrange
            $text = 'Email: first.last_name@sub.domain.com'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -Be 'first.last_name@sub.domain.com'
        }

        It 'Should handle emails with percentage signs' {
            # Arrange
            $text = 'Special: user%name@domain.com'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -Be 'user%name@domain.com'
        }
    }

    Context 'When filtering invalid email patterns' {
        It 'Should filter out emails with consecutive dots (..)' {
            # Arrange
            $text = 'Invalid: user..name@domain.com'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -BeNullOrEmpty -Because 'consecutive dots should invalidate email'
        }

        It 'Should filter out emails with dot immediately before @ (user.@domain.com)' {
            # Arrange
            $text = 'Invalid: user.@domain.com'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -BeNullOrEmpty -Because 'dot before @ should invalidate email'
        }

        It 'Should filter out emails with dot immediately after @ (user@.domain.com)' {
            # Arrange
            $text = 'Invalid: user@.domain.com'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -BeNullOrEmpty -Because 'dot after @ should invalidate email'
        }

        It 'Should filter out emails with local part longer than 64 characters' {
            # Arrange
            $longLocal = 'a' * 65  # 65 characters
            $text = "Invalid: $longLocal@domain.com"
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -BeNullOrEmpty -Because 'local part over 64 chars should be invalid'
        }

        It 'Should accept emails with local part exactly 64 characters' {
            # Arrange
            $longLocal = 'a' * 64  # 64 characters
            $text = "Valid: $longLocal@domain.com"
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -Be "$longLocal@domain.com" -Because 'local part of exactly 64 chars should be valid'
        }

        It 'Should filter out emails with dot-at-dot pattern (.@.)' {
            # Arrange
            $text = 'Invalid: user.@.domain.com'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -BeNullOrEmpty -Because 'dot-at-dot pattern should invalidate email'
        }

        It 'Should filter out multiple invalid dot patterns in one text' {
            # Arrange
            $text = 'Invalid emails: user.@domain.com, user@.domain.com, user.@.domain.com'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -BeNullOrEmpty -Because 'all emails have invalid dot patterns'
        }

        It 'Should accept valid emails with dots not adjacent to @' {
            # Arrange
            $text = 'Valid: user.name@domain.com, user@sub.domain.com'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -HaveCount 2 -Because 'dots not adjacent to @ should be valid'
            $result | Should -Contain 'user.name@domain.com'
            $result | Should -Contain 'user@sub.domain.com'
        }

        It 'Should accept emails with local part less than 64 characters' {
            # Arrange
            $shortLocal = 'a' * 32  # 32 characters
            $text = "Valid: $shortLocal@domain.com"
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -Be "$shortLocal@domain.com" -Because 'local part under 64 chars should be valid'
        }
    }

    Context 'When handling duplicate email addresses' {
        It 'Should remove duplicate email addresses (exact matches)' {
            # Arrange
            $text = 'Contact john@example.com or john@example.com again'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -HaveCount 1 -Because 'duplicates should be removed'
            $result | Should -Be 'john@example.com'
        }

        It 'Should preserve case when removing duplicates (case-sensitive uniqueness)' {
            # Arrange
            $text = 'Emails: john@example.com and JOHN@EXAMPLE.COM'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            # The regex captures both cases separately, Select-Object -Unique preserves both
            $result | Should -HaveCount 2 -Because 'case differences should be preserved'
            $result | Should -Contain 'john@example.com'
            $result | Should -Contain 'JOHN@EXAMPLE.COM'
        }
    }

    Context 'When using delimiter functionality' {
        It 'Should join emails with semicolon delimiter' {
            # Arrange
            $text = 'Contact john@example.com or jane@test.org'
            
            # Act
            $result = Get-EmailAddress -string $text -Delimiter ';'
            
            # Assert
            $result | Should -Be 'john@example.com;jane@test.org'
        }

        It 'Should join emails with comma delimiter' {
            # Arrange
            $text = 'Contact john@example.com or jane@test.org'
            
            # Act
            $result = Get-EmailAddress -string $text -Delimiter ','
            
            # Assert
            $result | Should -Be 'john@example.com,jane@test.org'
        }

        It 'Should join emails with custom delimiter' {
            # Arrange
            $text = 'Contact john@example.com or jane@test.org'
            
            # Act
            $result = Get-EmailAddress -string $text -Delimiter ' | '
            
            # Assert
            $result | Should -Be 'john@example.com | jane@test.org'
        }

        It 'Should return single email without delimiter when only one email' {
            # Arrange
            $text = 'Contact support@company.com'
            
            # Act
            $result = Get-EmailAddress -string $text -Delimiter ';'
            
            # Assert
            $result | Should -Be 'support@company.com'
        }

        It 'Should return empty string with delimiter when no emails found' {
            # Arrange
            $text = 'No emails here'
            
            # Act
            $result = Get-EmailAddress -string $text -Delimiter ';'
            
            # Assert
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When processing pipeline input' {
        It 'Should accept pipeline input from array of strings' {
            # Arrange
            $textArray = @(
                'First email: john@example.com',
                'Second email: jane@test.org',
                'Third email: bob@company.net'
            )
            
            # Act
            $result = $textArray | Get-EmailAddress
            
            # Assert
            $result | Should -HaveCount 3
            $result | Should -Contain 'john@example.com'
            $result | Should -Contain 'jane@test.org'
            $result | Should -Contain 'bob@company.net'
        }

        It 'Should handle mixed content in pipeline' {
            # Arrange
            $textArray = @(
                'Valid email: user@domain.com',
                'No email here',
                'Another email: test@site.org',
                ''
            )
            
            # Act
            $result = $textArray | Get-EmailAddress
            
            # Assert
            $result | Should -HaveCount 2
            $result | Should -Contain 'user@domain.com'
            $result | Should -Contain 'test@site.org'
        }

        It 'Should handle empty strings in pipeline gracefully' {
            # Arrange
            $textArray = @('', $null, 'user@domain.com', '')
            
            # Act
            $result = $textArray | Get-EmailAddress
            
            # Assert
            $result | Should -HaveCount 1
            $result | Should -Be 'user@domain.com'
        }
    }

    Context 'When processing complex email scenarios' {
        It 'Should extract multiple emails from complex text' {
            # Arrange
            $text = @'
Dear Team,

Please contact the following people:
- John Doe: john.doe+work@company-name.co.uk
- Jane Smith: j.smith123@university.edu
- Bob Wilson: bob_wilson@non-profit.org

For support, email: support@help-desk.com or backup@site.net

Best regards,
Admin Team
'@
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -HaveCount 5
            $result | Should -Contain 'john.doe+work@company-name.co.uk'
            $result | Should -Contain 'j.smith123@university.edu'
            $result | Should -Contain 'bob_wilson@non-profit.org'
            $result | Should -Contain 'support@help-desk.com'
            $result | Should -Contain 'backup@site.net'
        }

        It 'Should handle emails in different formats within same text' {
            # Arrange
            $text = 'Contacts: user1@domain.com, user2@site.org, user3@company.net, user4@test.co.uk'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -HaveCount 4
            $result | Should -Contain 'user1@domain.com'
            $result | Should -Contain 'user2@site.org'
            $result | Should -Contain 'user3@company.net'
            $result | Should -Contain 'user4@test.co.uk'
        }

        It 'Should handle international domain names' {
            # Arrange
            $text = 'International: user@muenchen.de, test@japan.jp'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -HaveCount 2
            $result | Should -Contain 'user@muenchen.de'
            $result | Should -Contain 'test@japan.jp'
        }
    }

    Context 'When validating function parameters' {
        BeforeAll {
            $function = Get-Command Get-EmailAddress
        }

        It 'Should have mandatory string parameter' {
            # Act
            $stringParam = $function.Parameters['string']
            $mandatoryAttribute = $stringParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            
            # Assert
            $mandatoryAttribute.Mandatory | Should -BeTrue -Because 'string parameter should be mandatory'
        }

        It 'Should accept pipeline input for string parameter' {
            # Act
            $stringParam = $function.Parameters['string']
            $pipelineAttribute = $stringParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            
            # Assert
            $pipelineAttribute.ValueFromPipeline | Should -BeTrue -Because 'string parameter should accept pipeline input'
        }

        It 'Should allow null and empty string input' {
            # Act
            $stringParam = $function.Parameters['string']
            $allowNullAttribute = $stringParam.Attributes | Where-Object { $_ -is [System.Management.Automation.AllowNullAttribute] }
            $allowEmptyAttribute = $stringParam.Attributes | Where-Object { $_ -is [System.Management.Automation.AllowEmptyStringAttribute] }
            
            # Assert
            $allowNullAttribute | Should -Not -BeNullOrEmpty -Because 'should allow null input'
            $allowEmptyAttribute | Should -Not -BeNullOrEmpty -Because 'should allow empty string input'
        }

        It 'Should have optional Delimiter parameter' {
            # Act
            $delimiterParam = $function.Parameters['Delimiter']
            
            # Assert
            $delimiterParam | Should -Not -BeNullOrEmpty -Because 'Delimiter parameter should exist'
            $delimiterParam.ParameterType | Should -Be ([string]) -Because 'Delimiter should be string type'
        }

        It 'Should support cmdlet binding' {
            # Assert
            $function.CmdletBinding | Should -BeTrue -Because 'function should use CmdletBinding'
        }
    }

    Context 'When testing verbose output' {
        It 'Should write verbose message when skipping null/empty strings' {
            # Arrange
            $textArray = @('user@domain.com', '', $null, 'test@site.org')
            
            # Act
            $result = $textArray | Get-EmailAddress -Verbose 4>&1
            
            # Assert - Check that we get the expected emails
            $emails = $result | Where-Object { $_ -is [string] -and $_ -like '*@*' }
            $emails | Should -HaveCount 2 -Because 'should extract 2 valid emails'
            
            # Assert - Check that verbose messages are generated for empty/null strings
            $verboseMessages = $result | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }
            $verboseMessages | Should -Not -BeNullOrEmpty -Because 'verbose messages should be generated for empty/null input'
        }
    }

    Context 'When handling edge cases and error conditions' {
        It 'Should handle very long input strings' {
            # Arrange
            $longText = 'a' * 10000 + ' user@domain.com ' + 'b' * 10000
            
            # Act
            $result = Get-EmailAddress -string $longText
            
            # Assert
            $result | Should -Be 'user@domain.com' -Because 'should extract email from very long text'
        }

        It 'Should handle strings with many potential false positives' {
            # Arrange
            $text = 'Not emails: 123@456, @domain.com, user@, user.domain.com, user@domain'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -BeNullOrEmpty -Because 'none of these should be valid emails'
        }

        It 'Should filter out emails with invalid dot placements' {
            # Arrange
            $text = 'Invalid patterns: .user@domain.com, user.@domain.com, user@.domain.com, user@domain.com.'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            # Only user@domain.com. should be captured (trailing dot is outside the word boundary)
            $result | Should -HaveCount 1 -Because 'only one email should pass validation'
            $result | Should -Contain 'user@domain.com'
        }

        It 'Should handle mixed valid and invalid emails with dots' {
            # Arrange
            $text = 'Mixed: valid@domain.com, user.@invalid.com, good.user@domain.com, bad@.invalid.com'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -HaveCount 2 -Because 'only valid emails should be extracted'
            $result | Should -Contain 'valid@domain.com'
            $result | Should -Contain 'good.user@domain.com'
        }

        It 'Should handle special characters in surrounding text' {
            # Arrange
            $text = 'Special chars around: user@domain.com with symbols'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result | Should -Be 'user@domain.com' -Because 'surrounding text should not affect email extraction'
        }

        It 'Should maintain order when no delimiter specified' {
            # Arrange
            $text = 'First: zebra@domain.com, Second: alpha@domain.com'
            
            # Act
            $result = Get-EmailAddress -string $text
            
            # Assert
            $result[0] | Should -Be 'zebra@domain.com' -Because 'first email should be first in results'
            $result[1] | Should -Be 'alpha@domain.com' -Because 'second email should be second in results'
        }
    }
}
