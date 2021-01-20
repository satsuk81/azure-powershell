$scriptname = "Build-VM.ps1"                                    # This file's filename
$EventlogName = "HigginsonConsultancy"                          # Event Log Folder Name
$EventlogSource = "VM Build Script"                             # Event Log Source Name

$VMDrive = "C:"                                                 # Specify the root disk drive to use
$VMFolder = "Virtual Machines"                                  # Specify the folder to store the VM data
$VHDFolder = "Virtual Hard Disks"                               # Specify the folder to store the VHDs
$VMCheckpointFolder = "Checkpoints"                             # Specify the folder to store the Checkpoints
$VMCount = 10                                                   # Specify number of VMs to be provisioned
$VmNamePrefix = "EUC-PROD-"                                     # Specifies the first part of the VM name (usually alphabetic)
$VmNumberStart = 101                                            # Specifies the second part of the VM name (usually numeric)
$VMRamSize = "4GB"
$VMVHDSize = "100GB"
$VMCPUCount = 4
$VMSwitchName = "Packaging Switch"

New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Running $scriptname Script"
 
Try {
    Import-Module Hyper-V -Force
} catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message $error[0].Exception
}

Try {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VM Switch"
    $VMSwitch = Get-VMSwitch -Name $VMSwitchName
    if(!$VMSwitch) {
        New-VMSwitch -Name $VMSwitchName -SwitchType Internal
    }
} catch {
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
        MemoryStartupBytes = $VMRamSize
        Generation = 1
        NewVHDPath = "$VMDrive\Hyper-V\$VHDFolder\$VMName\$VMName.vhdx"
        NewVHDSizeBytes = $VMVHDSize
        BootDevice = "VHD"
        Path = "$VMDrive\Hyper-V\$VMFolder\$VMName"
        SwitchName = (Get-VMSwitch -Name $VMSwitchName).Name
    }

    $VMObject = New-VM @VM
 
    $VMObject | Set-VM -ProcessorCount $VMCPUCount
    $VMObject | Set-VM -StaticMemory
    $VMObject | Set-VM -AutomaticCheckpointsEnabled $false
    $VMObject | Set-VM -SnapshotFileLocation "$VMDrive\Hyper-V\$VMCheckpointFolder"
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
