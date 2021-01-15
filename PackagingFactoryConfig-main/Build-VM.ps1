$scriptname = "Build-VM.ps1"
$EventlogName = "HigginsonConsultancy"
$EventlogSource = "VM Build Script"

$VMDrive = "C:"
$VMFolder = "Virtual Machines"
$VHDFolder = "Virtual Hard Disks"
$VMCheckpointFolder = "Checkpoints"
$VMCount = 10                                                   # Specify number of VMs to be provisioned
$VmNamePrefix = "EUC-PROD-"                                            # Specifies the first part of the VM name (usually alphabetic)
$VmNumberStart = 101                                                # Specifies the second part of the VM name (usually numeric)

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
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VM Switch"
    $VMSwitch = Get-VMSwitch -Name "Packaging Switch"
    if(!$VMSwitch) {
        New-VMSwitch -Name "Packaging Switch" -SwitchType Internal
    }
}
catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
}
function Delete-VM {
    Param([Parameter(Mandatory)][int]$VmNumber)

    $VMName = "$VmNamePrefix$VmNumber"
    
    $VM = Get-VM -Name $VMName | select *
       
    Remove-VM -Name $VMName -Force
    Remove-Item -Path "$VMDrive\Hyper-V\$VMFolder\$VMName" -Recurse -Force
    Remove-Item -Path "$VMDrive\Hyper-V\$VHDFolder\$VMName" -Recurse -Force
}

function Create-VM {
    Param([Parameter(Mandatory = $true)][int]$VmNumber)

    $VMName = "$VmNamePrefix$VmNumber"

    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format hh:mm

    $VM = @{
        Name = $VMName
        MemoryStartupBytes = 4GB
        Generation = 1
        NewVHDPath = "$VMDrive\Hyper-V\$VHDFolder\$VMName\$VMName.vhdx"
        NewVHDSizeBytes = 60GB
        BootDevice = "VHD"
        Path = "$VMDrive\Hyper-V\$VMFolder\$VMName"
        SwitchName = (Get-VMSwitch -Name "Packaging Switch").Name
    }

    $VMObject = New-VM @VM
 
    $VMObject | Set-VM -ProcessorCount 4
    $VMObject | Set-VM -StaticMemory
    $VMObject | Set-VM -AutomaticCheckpointsEnabled $false
    $VMObject | Set-VM -SnapshotFileLocation "$VMDrive\Hyper-V\Checkpoints"
    $VMObject | Checkpoint-VM -SnapshotName "Base Config ($Date - $Time)"
}

try {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VMs"
    $i=0
    while ($i -lt $VMCount) {
        $VMNumber = $VmNumberStart+$i
        Create-VM -VmNumber $VMNumber
        $i++
    }
    Format-Table
}
catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
}

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Completed $scriptname"
