$scriptname = "EnableHyperV.ps1"
$EventlogName = "Accenture"
$EventlogSource = "Enable Hyper-V Script"

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    break
}

New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Running $scriptname Script"

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Enable Hyper-V"
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Enable Management Tools"
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools

$StorAcc = Get-AzStorageAccount -ResourceGroupName rg-wl-prod-eucpackaging2 -Name stwleucpackaging02
$Result1 = Get-AzStorageBlobContent -Container data -Blob "LocalCred.xml" -Destination "c:\Windows\temp\" -Context $StorAcc.context
$Result2 = Get-AzStorageBlobContent -Container data -Blob "DomainCred.xml" -Destination "c:\Windows\temp\" -Context $StorAcc.context

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $scriptname"
