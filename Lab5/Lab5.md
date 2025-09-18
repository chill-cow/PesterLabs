# Lab 5: Class Testing with Pester

## Lab Overview

In this lab, you'll learn the fundamentals of testing PowerShell classes. You'll master:

- **Constructor testing** with different parameter sets
- **Property validation** and type checking
- **Method behavior testing** for business logic
- **Class state management** testing
- **String representation** testing

## Prerequisites

- PowerShell 7.4 or later
- Pester v5.7.1 or later
- Labs 1-4 completion
- Basic understanding of PowerShell classes

## Lab Setup

### Step 1: Task Class

We'll test a simple Task management class. Create `Task.ps1`:

```powershell
class Task {
    [int] $Id
    [string] $Title
    [string] $Description
    [bool] $IsCompleted
    [datetime] $CreatedDate
    [datetime] $DueDate
    
    # Constructor
    Task([string] $title, [string] $description) {
        $this.Id = Get-Random -Minimum 1 -Maximum 10000
        $this.Title = $title
        $this.Description = $description
        $this.IsCompleted = $false
        $this.CreatedDate = Get-Date
        $this.DueDate = (Get-Date).AddDays(7) # Default 7 days from now
    }
    
    # Constructor with due date
    Task([string] $title, [string] $description, [datetime] $dueDate) {
        $this.Id = Get-Random -Minimum 1 -Maximum 10000
        $this.Title = $title
        $this.Description = $description
        $this.IsCompleted = $false
        $this.CreatedDate = Get-Date
        $this.DueDate = $dueDate
    }
    
    # Mark task as completed
    [void] Complete() {
        $this.IsCompleted = $true
    }
    
    # Check if task is overdue
    [bool] IsOverdue() {
        return (-not $this.IsCompleted) -and ($this.DueDate -lt (Get-Date))
    }
    
    # Get days until due
    [int] DaysUntilDue() {
        $timeSpan = $this.DueDate - (Get-Date)
        return [Math]::Ceiling($timeSpan.TotalDays)
    }
    
    # Get task status
    [string] GetStatus() {
        if ($this.IsCompleted) {
            return "Completed"
        }
        elseif ($this.IsOverdue()) {
            return "Overdue"
        }
        elseif ($this.DaysUntilDue() -le 1) {
            return "Due Soon"
        }
        else {
            return "Active"
        }
    }
    
    # String representation
    [string] ToString() {
        return "$($this.Title) - $($this.GetStatus())"
    }
}
```

### Step 2: Class Tests

Create `Task.Tests.ps1`:

```powershell
BeforeAll {
    # Import the Task class
    . "$PSScriptRoot\Task.ps1"
}

Describe 'Task Class Tests' {
    
    Context 'Constructor Tests' {
        It 'Should create task with title and description' {
            $task = [Task]::new("Test Task", "Test Description")
            
            $task.Title | Should -Be "Test Task"
            $task.Description | Should -Be "Test Description"
            $task.IsCompleted | Should -Be $false
            $task.Id | Should -BeGreaterThan 0
        }
        
        It 'Should create task with due date' {
            $dueDate = (Get-Date).AddDays(5)
            $task = [Task]::new("Test Task", "Test Description", $dueDate)
            
            $task.DueDate.Date | Should -Be $dueDate.Date
        }
        
        It 'Should set created date to today' {
            $task = [Task]::new("Test Task", "Test Description")
            
            $task.CreatedDate.Date | Should -Be (Get-Date).Date
        }
    }
    
    Context 'Property Tests' {
        BeforeEach {
            $script:task = [Task]::new("Sample Task", "Sample Description")
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
            $script:task = [Task]::new("Sample Task", "Sample Description")
        }
        
        It 'Should complete task when Complete() is called' {
            $task.Complete()
            
            $task.IsCompleted | Should -Be $true
        }
        
        It 'Should detect overdue tasks' {
            # Create overdue task
            $pastDate = (Get-Date).AddDays(-1)
            $overdueTask = [Task]::new("Overdue Task", "Description", $pastDate)
            
            $overdueTask.IsOverdue() | Should -Be $true
        }
        
        It 'Should not detect completed tasks as overdue' {
            $pastDate = (Get-Date).AddDays(-1)
            $task = [Task]::new("Task", "Description", $pastDate)
            $task.Complete()
            
            $task.IsOverdue() | Should -Be $false
        }
        
        It 'Should calculate days until due correctly' {
            $futureDate = (Get-Date).AddDays(3)
            $task = [Task]::new("Future Task", "Description", $futureDate)
            
            $task.DaysUntilDue() | Should -Be 3
        }
    }
    
    Context 'Status Tests' {
        It 'Should return "Completed" for completed tasks' {
            $task = [Task]::new("Task", "Description")
            $task.Complete()
            
            $task.GetStatus() | Should -Be "Completed"
        }
        
        It 'Should return "Overdue" for overdue tasks' {
            $pastDate = (Get-Date).AddDays(-1)
            $task = [Task]::new("Overdue Task", "Description", $pastDate)
            
            $task.GetStatus() | Should -Be "Overdue"
        }
        
        It 'Should return "Due Soon" for tasks due within 1 day' {
            $soonDate = (Get-Date).AddDays(1)
            $task = [Task]::new("Soon Task", "Description", $soonDate)
            
            $task.GetStatus() | Should -Be "Due Soon"
        }
        
        It 'Should return "Active" for normal tasks' {
            $futureDate = (Get-Date).AddDays(5)
            $task = [Task]::new("Active Task", "Description", $futureDate)
            
            $task.GetStatus() | Should -Be "Active"
        }
    }
    
    Context 'String Representation Tests' {
        It 'Should return formatted string with title and status' {
            $task = [Task]::new("My Task", "Description")
            
            $task.ToString() | Should -Match "My Task - Active"
        }
        
        It 'Should show correct status in string representation' {
            $task = [Task]::new("Test Task", "Description")
            $task.Complete()
            
            $task.ToString() | Should -Match "Test Task - Completed"
        }
    }
}
```

### Step 3: Test Runner

Test runner is already created as `RunLabTests.ps1`

## Lab Exercises

### Exercise 1: Basic Class Testing
1. Run the tests: `.\RunLabTests.ps1`
2. Observe how constructors are tested with different parameters
3. Understand property type validation

### Exercise 2: Method Testing
1. Add a new method to the Task class: `SetPriority([string] $priority)`
2. Write tests to validate the method works correctly
3. Test edge cases (empty strings, invalid values)

### Exercise 3: State Testing
1. Create tests that verify task state changes correctly
2. Test the interaction between `Complete()` and `IsOverdue()`
3. Verify that status changes appropriately

### Exercise 4: Business Logic Testing
1. Test the `DaysUntilDue()` calculation with various dates
2. Verify that overdue logic works for edge cases
3. Test the `GetStatus()` method with different scenarios

## Key Learning Points

### 1. Constructor Testing
```powershell
# Test different constructor overloads
It 'Should create task with basic parameters' {
    $task = [Task]::new("Title", "Description")
    $task.Title | Should -Be "Title"
}

It 'Should create task with due date' {
    $dueDate = (Get-Date).AddDays(5)
    $task = [Task]::new("Title", "Description", $dueDate)
    $task.DueDate.Date | Should -Be $dueDate.Date
}
```

### 2. Property Validation
```powershell
# Test property types and initial values
It 'Should have correct property types' {
    $task.Id | Should -BeOfType [int]
    $task.IsCompleted | Should -BeOfType [bool]
    $task.CreatedDate | Should -BeOfType [datetime]
}
```

### 3. Method Behavior Testing
```powershell
# Test method state changes
It 'Should change state when method is called' {
    $task.Complete()
    $task.IsCompleted | Should -Be $true
}
```

### 4. Business Logic Testing
```powershell
# Test complex business rules
It 'Should detect overdue tasks correctly' {
    $pastDate = (Get-Date).AddDays(-1)
    $task = [Task]::new("Task", "Desc", $pastDate)
    $task.IsOverdue() | Should -Be $true
}
```

## Summary

This Lab 5 teaches you:
- ✅ How to test PowerShell class constructors
- ✅ Property validation and type checking
- ✅ Method behavior and state change testing
- ✅ Business logic validation patterns
- ✅ Class string representation testing

Understanding these patterns is essential for testing object-oriented PowerShell code!

## Next Steps
- Try adding inheritance to the Task class
- Create collections of tasks and test them
- Implement interfaces and test their contracts
- Move on to Lab 6 for advanced integration testing

---
**Estimated Time**: 45-60 minutes  
**Difficulty**: Intermediate