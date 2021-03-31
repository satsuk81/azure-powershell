$scriptname = "EnableHyperV.ps1"
$EventlogName = "Accenture"
$EventlogSource = "Enable Hyper-V Script"

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting $scriptname Install Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading NuGet module"
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading Az.Storage module"
Install-Module -Name Az.Storage -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to connect to Azure"    
Connect-AzAccount -identity -ErrorAction Stop -Subscription ssss

# Install Hyper-V
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Enable Hyper-V"
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

# Install Tools
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Enable Management Tools"
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools

# Install RSAT
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Install RSAT Tools"
Install-WindowsFeature -Name RSAT-AD-Tools -IncludeAllSubFeature

mkdir -Path "F:\" -Name "Hyper-V" -Force
mkdir -Path "F:\Hyper-V" -Name "Virtual Hard Disks" -Force

$StorAcc = Get-AzStorageAccount -ResourceGroupName rrrr -Name xxxx
$Result1 = Get-AzStorageBlobContent -Container data -Blob "hyperv-vms.csv" -Destination "c:\Windows\temp\" -Context $StorAcc.context
$Result2 = Get-AzStorageBlobContent -Container data -Blob "Vanilla-Windows10-Base.vhdx" -Destination "F:\Hyper-V\Virtual Hard Disks" -Context $StorAcc.context

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"