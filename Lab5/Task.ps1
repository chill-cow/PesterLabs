class Task
{
    [int] $Id
    [string] $Title
    [string] $Description
    [bool] $IsCompleted
    [datetime] $CreatedDate
    [datetime] $DueDate
    
    # Constructor
    Task([string] $title, [string] $description)
    {
        $this.Id = Get-Random -Minimum 1 -Maximum 10000
        $this.Title = $title
        $this.Description = $description
        $this.IsCompleted = $false
        $this.CreatedDate = Get-Date
        $this.DueDate = (Get-Date).AddDays(7) # Default 7 days from now
    }
    
    # Constructor with due date
    Task([string] $title, [string] $description, [datetime] $dueDate)
    {
        $this.Id = Get-Random -Minimum 1 -Maximum 10000
        $this.Title = $title
        $this.Description = $description
        $this.IsCompleted = $false
        $this.CreatedDate = Get-Date
        $this.DueDate = $dueDate
    }
    
    # Mark task as completed
    [void] Complete()
    {
        $this.IsCompleted = $true
    }
    
    # Check if task is overdue
    [bool] IsOverdue()
    {
        return (-not $this.IsCompleted) -and ($this.DueDate -lt (Get-Date))
    }
    
    # Get days until due
    [int] DaysUntilDue()
    {
        $timeSpan = $this.DueDate - (Get-Date)
        return [Math]::Ceiling($timeSpan.TotalDays)
    }
    
    # Get task status
    [string] GetStatus()
    {
        if ($this.IsCompleted)
        {
            return 'Completed'
        }
        elseif ($this.IsOverdue())
        {
            return 'Overdue'
        }
        elseif ($this.DaysUntilDue() -le 1)
        {
            return 'Due Soon'
        }
        else
        {
            return 'Active'
        }
    }
    
    # String representation
    [string] ToString()
    {
        return "$($this.Title) - $($this.GetStatus())"
    }
}