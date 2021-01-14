$scriptname = "ConfigureDataDiskps1"
$EventlogName = "HigginsonConsultancy"
$EventlogSource = "VM Build Script"

New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Running $scriptname Script"
 
try {
    $disks = Get-Disk | Where partitionstyle -eq 'raw' | sort number
    $disks | 
        Initialize-Disk -PartitionStyle MBR -PassThru |
        New-Partition -UseMaximumSize -DriveLetter "F" |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel "data1" -Confirm:$false -Force
}
catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
}

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"