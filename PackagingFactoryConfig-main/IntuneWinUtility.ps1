$app = "IntuneWinUtility"
$zip = $false
$filename = "IntuneWinUtility.msi"
$exefilename = "C:\windows\system32\msiexec.exe"
$Argument = "/i " + [char]34 + "IntuneWinUtility.msi" + [char]34 + " /qb"

$EventLogName = "Accenture"
$EventLogSource = "$app Install Script"

# Create Error Trap
trap {
    Write-Error $error[0]
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    break
}

# Enable Logging to the EventLog
New-EventLog -LogName $EventlogName -Source $EventlogSource
Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting $app Install Script"

# Load Modules and Connect to Azure
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading NuGet module"
Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading Az.Storage module"
Install-Module -Name Az.Storage -Force -ErrorAction Stop
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to connect to Azure"    
Connect-AzAccount -identity -ErrorAction Stop -Subscription 1c3b43a4-90da-4988-9598-cab119913f5d

# Copy zip file to local drive and install
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Atempting to download $app from Azure storage account to C:\Windows\Temp"

$StorAcc = get-azstorageaccount -resourcegroupname rg-wl-prod-packaging -name wlprodeusprodpkgstr01tmp
if ($zip) {
    $Result = Get-AzStorageBlobContent -Container data -Blob "./Media/$filename" -destination "c:\Windows\temp\" -context $StorAcc.context
    If ($Result.Name -eq "Media/$filename") {
        Expand-Archive -Path "C:\Windows\Temp\Media\$filename" -DestinationPath C:\Windows\Temp\Media\$app\ -Force
        cd C:\Windows\Temp\Media\$app\
        Start-Process -FilePath "$exefilename" -ArgumentList $Argument -Wait -ErrorAction Stop
    }
    Else {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download $app"
    }
}
else {
    $Result = Get-AzStorageBlobContent -Container data -Blob "./Media/$filename" -Destination "c:\Windows\temp\" -Context $StorAcc.context
    If ($Result.Name -eq "Media/$filename") {
        cd C:\Windows\Temp\Media\
        Start-Process -FilePath "$exefilename" -ArgumentList $Argument -Wait -ErrorAction Stop
    }
    Else {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download $app"
    }
}
Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Information -Message "Completed $app Install Script"
