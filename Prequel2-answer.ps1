Function Get-DiskInfo {
    [cmdletbinding()]
    Param(
        [Parameter(Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelinebyName)]
        [ValidateNotNullorEmpty()]
        [string]$Computername,
        [ValidatePattern("[C..G]")]
        [string]$Drive = "C",
        [string]$LogPath = $env:temp
    )
    Begin {
        Write-Verbose "Starting $($myinvocation.mycommand)"
        $filename = "{0}_DiskInfo_Errors.txt" -f (Get-Date -format "YYYYMMddhhmm")
        $errorLog = Join-Path -path $LogPath -ChildPath $filename
    }
    Process {
        foreach ($computer in $computername) {
            Write-Verbose "Getting disk information from $computer for drive $($drive.toUpper())"
            try {
                $data = Get-Volume -DriveLetter $drive -CimSession $computr
                $data | Select  Drive,@{Name="SizeGB";Expression = {$_.Size/1gb -as [int]}},
                @{Name="FreeGB";Expression = {$_.SizeRemaining/1GB}},@{Name="PctFree";Expression = {($_.SizeRemaining/$_.size*100)}}
                HealthStatus,@{Name = "Computername";Expression = {$_.PSComputername.toUpper}}
            }
            catch {
                Add-Content -path $errorlog -Value "[$(Get-Date)] Failed to get disk data for drive $drive from $computername"
                Add-Content -path $errorlog -Value "[$(Get-Date)] $($_.exception.message)"
                $newErrors = $True
            }
        }
    }
    End {
        If ((Test-Path -path $errorLog) -AND $newErrors) {
            Write-Warning "Errors have been logged to $errorlog"
        }
 
        Write-Verbose "Ending $($myinvocation.MyCommand)"
    }
}