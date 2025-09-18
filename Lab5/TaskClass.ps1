class Task {
    # Properties
    [string] $Id
    [string] $Title
    [string] $Status
    [datetime] $CreatedDate
    
    # Static counter
    static [int] $TotalTasks = 0
    
    # Constructor
    Task([string] $title) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Title = $title
        $this.Status = "New"
        $this.CreatedDate = Get-Date
        [Task]::TotalTasks++
    }
    
    # Methods
    [void] Complete() {
        if ($this.Status -ne "New") {
            throw "Task must be in 'New' status to complete"
        }
        $this.Status = "Completed"
    }
    
    [bool] CanComplete() {
        return $this.Status -eq "New"
    }
    
    [Task] SetTitle([string] $newTitle) {
        $this.Title = $newTitle
        return $this  # For method chaining
    }
    
    # Static method
    static [int] GetTotalTasks() {
        return [Task]::TotalTasks
    }
    
    static [void] ResetCounter() {
        [Task]::TotalTasks = 0
    }
}

# Derived class
class UrgentTask : Task {
    [bool] $IsUrgent
    
    UrgentTask([string] $title) : base($title) {
        $this.IsUrgent = $true
    }
    
    [void] Complete() {
        # Override base behavior
        $this.Status = "Completed"
        Write-Host "Urgent task '$($this.Title)' completed!" -ForegroundColor Red
    }
}