# Sysprep /generalize /oobe /mode:vm

$scriptname = "Build-VM.ps1"                                    # This file's filename
$EventlogName = "Accenture"                                     # Event Log Folder Name
$EventlogSource = "Hyper-V VM Build Script"                     # Event Log Source Name

$VMDrive = "C:"                                                 # Specify the root disk drive to use
$VMFolder = "Virtual Machines"                                  # Specify the folder to store the VM data
$VHDFolder = "Virtual Hard Disks"                               # Specify the folder to store the VHDs
$VMCheckpointFolder = "Checkpoints"                             # Specify the folder to store the Checkpoints
$VMCount = 1                                                    # Specify number of VMs to be provisioned
$VmNamePrefix = "EUC-PROD-"                                     # Specifies the first part of the VM name (usually alphabetic)
$VmNumberStart = 101                                            # Specifies the second part of the VM name (usually numeric)
$VMRamSize = 2GB
$VMVHDSize = 100GB
$VMCPUCount = 4
$VMSwitchName = "Packaging Switch"

$LocalCredUser = "DESKTOP-7O8HROP\admin"
$DomainCredUser = "space\administrator"
$Domain = "space"
$OUPath = "OU=Workstations,OU=Computers,OU=Space,DC=space,DC=dan"

cd $PSScriptRoot

#if($LocalCred) {Remove-Variable LocalCred;$LocalCred = Get-Credential -Credential $LocalCredUser;$LocalCred | Export-CliXml -Path .\LocalCred.xml} else{$LocalCred = Get-Credential -Credential $LocalCredUser;$LocalCred | Export-CliXml -Path .\LocalCred.xml}
#if($DomainCred) {Remove-Variable DomainCred;$DomainCred = Get-Credential -Credential $DomainCredUser;$DomainCred | Export-CliXml -Path .\DomainCred.xml} else{$DomainCred = Get-Credential -Credential $DomainCredUser;$DomainCred | Export-CliXml -Path .\DomainCred.xml}
$LocalCred = Import-CliXml -Path .\LocalCred.xml
$DomainCred = Import-CliXml -Path .\DomainCred.xml

if(!$DomainCred) {
    exit
}

New-EventLog -LogName $EventlogName -Source $EventlogSource -ErrorAction SilentlyContinue
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Running $scriptname Script"
 
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Importing Hyper-V Module"
Import-Module Hyper-V -Force -ErrorAction Stop

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VM Switch"
$VMSwitch = Get-VMSwitch -Name $VMSwitchName
if(!$VMSwitch) {
    New-VMSwitch -Name $VMSwitchName -SwitchType Internal -ErrorAction Stop
}

function Delete-VM {
    Param([Parameter(Mandatory)][int]$VmNumber)
    trap {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
        break
    }
    $VMName = "$VmNamePrefix$VmNumber"
    $VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue | select *
    
    if($VM) {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Removing VM $VMName"
        if($VM.State -eq "Running") {
            Stop-VM -Name $VMName -Force -TurnOff -Verbose -ErrorAction Stop
        }
        Remove-VM -Name $VMName -Force -Verbose -ErrorAction Stop
        Remove-Item -Path "$VMDrive\Hyper-V\$VMFolder\$VMName" -Recurse -Force
        Remove-Item -Path "$VMDrive\Hyper-V\$VHDFolder\$VMName" -Recurse -Force
    }
}

function Create-VM {
    Param([Parameter(Mandatory = $true)][int]$VmNumber)
    trap {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
        break
    }
    $VMName = "$VmNamePrefix$VmNumber"
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VM $VMName"
    
    $VM = @{
        Name = $VMName
        MemoryStartupBytes = $VMRamSize
        Generation = 1
        #NewVHDPath = "$VMDrive\Hyper-V\$VHDFolder\$VMName\$VMName.vhdx"
        #NewVHDSizeBytes = $VMVHDSize
        BootDevice = "VHD"
        Path = "$VMDrive\Hyper-V\$VMFolder\$VMName"
        SwitchName = (Get-VMSwitch -Name $VMSwitchName).Name
    }

    $VMObject = New-VM @VM -NoVHD -Verbose -ErrorAction Stop
    
    New-Item -Path $VMDrive\Hyper-V\$VHDFolder\ -Name $VMName -ItemType Directory -Force -Verbose | Out-null
    Copy-Item -Path $VMDrive\Hyper-V\$VHDFolder\Vanilla-Windows10-Base.vhdx -Destination $VMDrive\Hyper-V\$VHDFolder\$VMName\$VMName.vhdx -Force -Verbose
    
    $VMObject | Set-VM -ProcessorCount $VMCPUCount
    $VMObject | Set-VM -StaticMemory
    $VMObject | Set-VM -AutomaticCheckpointsEnabled $false
    $VMObject | Set-VM -SnapshotFileLocation "$VMDrive\Hyper-V\$VMCheckpointFolder"
    $VMObject | Add-VMHardDiskDrive -Path $VMDrive\Hyper-V\$VHDFolder\$VMName\$VMName.vhdx
    
    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format hh:mm
    $VMObject | Checkpoint-VM -SnapshotName "Base Config ($Date - $Time)"

    $VMObject | Start-VM -Verbose -ErrorAction Stop
    Start-Sleep -Seconds 60

        # Pre Domain Join
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalCred -ErrorVariable erroric -ScriptBlock {
        if(!(Test-Connection "1.1.1.1" -Quiet)) { Write-Error "Internet Issue" }
        if(!(Test-Connection "google.com" -Quiet)) { Write-Error "DNS Issue" }
    }
    if($erroric) {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalCred -ErrorVariable erroric -ScriptBlock {
        Get-AppxPackage -Name Microsoft.MicrosoftOfficeHub | Remove-AppxPackage
        Rename-Computer -NewName $Using:VMName -LocalCredential $Using:LocalCred -Restart -Verbose
    }
    if($erroric) {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }  
    Start-Sleep -Seconds 90
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalCred -ErrorVariable erroric -ScriptBlock {
        Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6
        $joined=$false
        $attempts = 0
        while($joined -eq $false) {
            $joined = $true
            $attempts++
            try {
                Add-Computer -LocalCredential $Using:LocalCred -DomainName $Using:Domain -Credential $Using:DomainCred -Restart -Verbose -ErrorAction Stop -OUPath $Using:OUPath
                # -NewName $CP -OUPath $OU 
            } catch {              
                $joined = $false
                Write-Output $_.Exception.Message
                if($attempts -eq 20) {
                    throw "Cannot Join the Domain"
                    break
                }
                Start-Sleep -Seconds 5
            }
        }
    }
    if($erroric) {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }    
        # Post Domain Join - LocalCred wont work anymore.
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $DomainCred -ErrorVariable erroric -ScriptBlock {

    }
    if($erroric) {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }  
    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format hh:mm
    $VMObject | Checkpoint-VM -SnapshotName "Domain Joined ($Date - $Time)"
}

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Creating VMs"
$i=0
while ($i -lt $VMCount) {
    $VMNumber = $VmNumberStart+$i
    Delete-VM -VmNumber $VMNumber
    Create-VM -VmNumber $VMNumber
    $i++
}

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Completed $scriptname"
