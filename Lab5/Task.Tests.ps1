BeforeAll {
    # Import the Task class
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}

Describe 'Task Class Tests' {
    
    Context 'Constructor Tests' {
        It 'Should create task with title and description' {
            $task = [Task]::new('Test Task', 'Test Description')
            
            $task.Title | Should -Be 'Test Task'
            $task.Description | Should -Be 'Test Description'
            $task.IsCompleted | Should -Be $false
            $task.Id | Should -BeGreaterThan 0
        }
        
        It 'Should create task with due date' {
            $dueDate = (Get-Date).AddDays(5)
            $task = [Task]::new('Test Task', 'Test Description', $dueDate)
            
            $task.DueDate.Date | Should -Be $dueDate.Date
        }
        
        It 'Should set created date to today' {
            $task = [Task]::new('Test Task', 'Test Description')
            
            $task.CreatedDate.Date | Should -Be (Get-Date).Date
        }
    }
    
    Context 'Property Tests' {
        BeforeEach {
            $script:task = [Task]::new('Sample Task', 'Sample Description')
        }
        
        It 'Should have correct property types' {
            $task.Id | Should -BeOfType [int]
            $task.Title | Should -BeOfType [string]
            $task.Description | Should -BeOfType [string]
            $task.IsCompleted | Should -BeOfType [bool]
            $task.CreatedDate | Should -BeOfType [datetime]
            $task.DueDate | Should -BeOfType [datetime]
        }
        
        It 'Should start as not completed' {
            $task.IsCompleted | Should -Be $false
        }
        
        It 'Should have default due date 7 days from creation' {
            $expectedDueDate = (Get-Date).AddDays(7).Date
            $task.DueDate.Date | Should -Be $expectedDueDate
        }
    }
    
    Context 'Method Tests' {
        BeforeEach {
            $script:task = [Task]::new('Sample Task', 'Sample Description')
        }
        
        It 'Should complete task when Complete() is called' {
            $task.Complete()
            
            $task.IsCompleted | Should -Be $true
        }
        
        It 'Should detect overdue tasks' {
            # Create overdue task
            $pastDate = (Get-Date).AddDays(-1)
            $overdueTask = [Task]::new('Overdue Task', 'Description', $pastDate)
            
            $overdueTask.IsOverdue() | Should -Be $true
        }
        
        It 'Should not detect completed tasks as overdue' {
            $pastDate = (Get-Date).AddDays(-1)
            $task = [Task]::new('Task', 'Description', $pastDate)
            $task.Complete()
            
            $task.IsOverdue() | Should -Be $false
        }
        
        It 'Should calculate days until due correctly' {
            $futureDate = (Get-Date).AddDays(3)
            $task = [Task]::new('Future Task', 'Description', $futureDate)
            
            $task.DaysUntilDue() | Should -Be 3
        }
    }
    
    Context 'Status Tests' {
        It 'Should return "Completed" for completed tasks' {
            $task = [Task]::new('Task', 'Description')
            $task.Complete()
            
            $task.GetStatus() | Should -Be 'Completed'
        }
        
        It 'Should return "Overdue" for overdue tasks' {
            $pastDate = (Get-Date).AddDays(-1)
            $task = [Task]::new('Overdue Task', 'Description', $pastDate)
            
            $task.GetStatus() | Should -Be 'Overdue'
        }
        
        It 'Should return "Due Soon" for tasks due within 1 day' {
            $soonDate = (Get-Date).AddDays(1)
            $task = [Task]::new('Soon Task', 'Description', $soonDate)
            
            $task.GetStatus() | Should -Be 'Due Soon'
        }
        
        It 'Should return "Active" for normal tasks' {
            $futureDate = (Get-Date).AddDays(5)
            $task = [Task]::new('Active Task', 'Description', $futureDate)
            
            $task.GetStatus() | Should -Be 'Active'
        }
    }
    
    Context 'String Representation Tests' {
        It 'Should return formatted string with title and status' {
            $task = [Task]::new('My Task', 'Description')
            
            $task.ToString() | Should -Match 'My Task - Active'
        }
        
        It 'Should show correct status in string representation' {
            $task = [Task]::new('Test Task', 'Description')
            $task.Complete()
            
            $task.ToString() | Should -Match 'Test Task - Completed'
        }
    }
}