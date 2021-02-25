$app = "ORCA"
$zip = $true
$filename = "Orca.zip"
$exefilename = "C:\windows\system32\msiexec.exe"
$Argument = "/i " + [char]34 + "Orca-x86_en-us.msi" + [char]34 + " /qb"

# Enable Logging to the EventLog
Try
    {
    $EventlogName = "HigginsonConsultancy"
    $EventlogSource = "VM $app Install Script"
    New-EventLog -LogName $EventlogName -Source $EventlogSource
    Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting $app Install Script"
    }
    
    Catch
    {
    }


# Load Modules and Connect to Azure
Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading NuGet module"
    Install-PackageProvider -Name NuGet -Force 
    }
Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading Az.Storage module"
    Install-Module -Name Az.Storage -Force
    }
Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to connect to Azure"
    
    Connect-AzAccount -identity
    }
Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

# Copy zip file to local drive and install
Try {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Atempting to download $app from Azure storage account to C:\Windows\Temp"

    $StorAcc = get-azstorageaccount -resourcegroupname rg-wl-prod-eucpackaging2 -name stwleucpackaging02
    if ($zip) {
        $Result = Get-AzStorageBlobContent -Container data -Blob "./Media/$filename" -destination "c:\Windows\temp\" -context $StorAcc.context
        If ($Result.Name -eq "Media/$filename") {
            Expand-Archive -Path "C:\Windows\Temp\Media\$filename" -DestinationPath C:\Windows\Temp\Media\$app\ -Force
            cd C:\Windows\Temp\Media\$app\ORCA\
            Start-Process -FilePath "$exefilename" -ArgumentList $Argument -Wait
        }
        Else {
            Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download $app"
        }
    }
    else {
        $Result = Get-AzStorageBlobContent -Container data -Blob "./Media/$filename" -Destination "c:\Windows\temp\" -Context $StorAcc.context
        If ($Result.Name -eq "Media/$filename") {
            cd C:\Windows\Temp\Media\
            Start-Process -FilePath "$exefilename" -ArgumentList $Argument -Wait
        }
        Else {
            Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventId 25101 -EntryType Error -Message "Failed to download $app"
        }
    }

}
Catch {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
}
