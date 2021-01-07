$disks = Get-Disk | Where partitionstyle -eq 'raw' | sort number
$disks | 
        Initialize-Disk -PartitionStyle MBR -PassThru |
        New-Partition -UseMaximumSize -DriveLetter "F" |
        Format-Volume -FileSystem NTFS -NewFileSystemLabel "data1" -Confirm:$false -Force