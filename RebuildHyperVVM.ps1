Param(
    [Parameter(Mandatory = $false)][string]$RVMVMName = ""
)

#region Setup
$scriptname = "Build-VM.ps1"                                    # This file's filename
$EventlogName = "Accenture"                                     # Event Log Folder Name
$EventlogSource = "Hyper-V VM Build Script"                     # Event Log Source Name

$VMDrive = "F:"                                                 # Specify the root disk drive to use
$VMFolder = "Virtual Machines"                                  # Specify the folder to store the VM data
$VHDFolder = "Virtual Hard Disks"                               # Specify the folder to store the VHDs
$VMCheckpointFolder = "Checkpoints"                             # Specify the folder to store the Checkpoints
$VmNamePrefix = "EUC-UAT-"
$VMRamSize = 2GB
$VMVHDSize = 100GB
$VMCPUCount = 4
$VMSwitchName = "Packaging Switch"

$LocalCredUser = "DESKTOP-7O8HROP\admin"
$DomainCredUser = "space\administrator"

$Domain = "space"
#$OUPath = "OU=Workstations,OU=Computers,OU=Space,DC=space,DC=dan"

$Domain = "wella.team"
$OUPath = "OU=Packaging,OU=Servers,DC=wella,DC=team"

$IPAddress = ""
$IPSubnetPrefix = "26"
$IPGateway = "10.22.255.129"
$IPDNS = @("10.21.224.10","10.21.224.11","10.21.239.196")

$VMListData = Import-Csv .\hyperv-vms.csv

cd $PSScriptRoot

#if($LocalCred) {Remove-Variable LocalCred;$LocalCred = Get-Credential -Credential $LocalCredUser;$LocalCred | Export-CliXml -Path .\LocalCred.xml} else{$LocalCred = Get-Credential -Credential $LocalCredUser;$LocalCred | Export-CliXml -Path .\LocalCred.xml}
#if($DomainCred) {Remove-Variable DomainCred;$DomainCred = Get-Credential -Credential $DomainCredUser;$DomainCred | Export-CliXml -Path .\DomainCred.xml} else{$DomainCred = Get-Credential -Credential $DomainCredUser;$DomainCred | Export-CliXml -Path .\DomainCred.xml}
$LocalCred = Import-CliXml -Path .\PackagingFactoryConfig-main\LocalCred.xml
$DomainCred = Import-CliXml -Path .\PackagingFactoryConfig-main\DomainCred.xml

if(!$DomainCred) {
    exit
}

New-EventLog -LogName $EventlogName -Source $EventlogSource -ErrorAction SilentlyContinue
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Running $scriptname Script"
 
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Importing Hyper-V Module"
Import-Module Hyper-V -Force -ErrorAction Stop
#endregion Setup

function Delete-VM {
    Param([Parameter(Mandatory)][string]$VMName)
    trap {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
        break
    }
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
    Param([Parameter(Mandatory = $true)][string]$VMName)
    trap {
        Write-Error $error[0]
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
        break
    }
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

    $IPAddress = ($VMListData | where {$_.Name -eq $VMName}).IPAddress

        # Pre Domain Join
    Remove-Variable erroric -ErrorAction SilentlyContinue
    Invoke-Command -VMName $VMName -Credential $LocalCred -ErrorVariable erroric -ScriptBlock {
        $NetAdapter = Get-NetAdapter -Physical | where {$_.Status -eq "Up"}
        if (($NetAdapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
            $NetAdapter | Remove-NetIPAddress -AddressFamily IPv4 -Confirm:$false
        }
        if (($NetAdapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
            $NetAdapter | Remove-NetRoute -AddressFamily IPv4 -Confirm:$false
        }
        $NetAdapter | New-NetIPAddress -AddressFamily IPv4 -IPAddress $Using:IPAddress -PrefixLength $Using:IPSubnetPrefix -DefaultGateway $Using:IPGateway
        $NetAdapter | Set-DnsClientServerAddress -ServerAddresses $Using:IPDNS

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
                #Add-Computer -LocalCredential $Using:LocalCred -DomainName $Using:Domain -Credential $Using:DomainCred -Restart -Verbose -ErrorAction Stop -OUPath $Using:OUPath
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
    #Invoke-Command -VMName $VMName -Credential $DomainCred -ErrorVariable erroric -ScriptBlock {}
    if($erroric) {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }  
    $Date = Get-Date -Format yyyy-MM-dd
    $Time = Get-Date -Format hh:mm
    $VMObject | Checkpoint-VM -SnapshotName "Domain Joined ($Date - $Time)"
}

#region Main
Write-Host "Running RebuildHyperVVM.ps1"

if($RVMVMName -eq "") {
    #$VMList = Get-VM -Name *
    $VMList = $VMListData
    $RVMVMName = ($VMList | where { $_.Name -like "$VmNamePrefix*" } | select * | ogv -Title "Select Virtual Machine to Rebuild" -PassThru).Name
}

Write-Host "Rebuilding $RVMVMName"
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Rebuilding $RVMVMName VM"
Delete-VM -VMName $RVMVMName
Create-VM -VMName $RVMVMName
Write-Host "Completed RebuildHyperVVM.ps1"
#endregion Main