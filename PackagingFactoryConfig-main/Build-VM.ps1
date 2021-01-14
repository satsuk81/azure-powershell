$scriptname = "Build-VM.ps1"
$EventlogName = "HigginsonConsultancy"
$EventlogSource = "VM Build Script"

New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Running $scriptname Script"
 
Try {
    Import-Module Hyper-V -Force
}
catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
}

Try { 
    New-VMSwitch -Name "Packaging Switch" -SwitchType Internal
}
catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
}
function Delete-VM {
    $VMName = "VMNAME1"
    
    $VM = Get-VM -Name $VMName | select *
    $VMDisk = Get-VMHardDiskDrive -VMName $VMName
    $VMPath = ($Vm.Path)
    $VMPath = $VMPath.Substring(0, $VMPath.Length-$VMName.Length-1)
    
    Remove-VM -Name $VMName -Force
    Remove-Item -Path $VMPath -Recurse -Force
}

function Create-VM {
    $VMName = "VMNAME1"
    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format hh:mm

    $VM = @{
        Name = $VMName
        MemoryStartupBytes = 4GB
        Generation = 1
        NewVHDPath = "F:\Hyper-V\Virtual Machines\$VMName\$VMName.vhdx"
        NewVHDSizeBytes = 60GB
        BootDevice = "VHD"
        Path = "F:\Hyper-V\Virtual Machines\$VMName"
        SwitchName = (Get-VMSwitch -Name "Packaging Switch").Name
    }

    New-VM @VM
    Get-VM -Name $VMName | Set-VM -ProcessorCount 4
    Get-VM -Name $VMName | Set-VM -StaticMemory
    Get-VM -Name $VMName | Set-VM -AutomaticCheckpointsEnabled $false
    Get-VM -Name $VMName | Checkpoint-VM -SnapshotName "Base Config ($Date - $Time)"
}

try {
    Create-VM
}
catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
}
#Delete-VM

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Completed $scriptname"
