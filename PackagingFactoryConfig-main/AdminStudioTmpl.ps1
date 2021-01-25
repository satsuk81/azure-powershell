# Enable Logging to the EventLog
Try
    {
    $EventlogName = "HigginsonConsultancy"
    $EventlogSource = "VM AdminStudio Build Script"
    New-EventLog -LogName $EventlogName -Source $EventlogSource
    Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting VM AdminStudio Build Script"
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

# Copy AdminStudio exe to local drive and install
Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Atempting to download AdminStudio2020R2SP1.exe from Azure storage account to C:\Windows\Temp"

    $StorAcc = get-azstorageaccount -resourcegroupname rrrr -name xxxx
    $Result = Get-AzStorageBlobContent -Container data -Blob "./Media/AdminStudio2020R2SP1.exe" -destination "c:\Windows\temp\" -context $StorAcc.context
    If ($Result.Name -eq "Media/AdminStudio2020R2SP1.exe") 
	{
    $Argument = "/silent"
    Start-Process -FilePath "C:\Windows\Temp\Media\AdminStudio2020R2SP1.exe" -ArgumentList $Argument -Wait
	}
    Else
        {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message "Failed to install AdminStudio"
        }
    }
Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }