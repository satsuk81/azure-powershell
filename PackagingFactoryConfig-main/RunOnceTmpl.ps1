Try
    {
    $EventlogName = "HigginsonConsultancy"
    $EventlogSource = "VM Build Script"
    New-EventLog -LogName $EventlogName -Source $EventlogSource
    Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName $EventlogName
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting VM Build Script"
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

# Copy MapDrv.ps1 to local drive
Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Atempting to download MapDrv.ps1 from Azure storage account to C:\Windows\Temp"

    $StorAcc = get-azstorageaccount -resourcegroupname rrrr -name xxxx
    $Result = Get-AzStorageBlobContent -Container data -Blob "MapDrv.ps1" -destination "c:\Windows\temp\" -context $StorAcc.context
    If ($Result.Name -eq "MapDrv.ps1") 
	{
	new-itemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "MapPackagingDrive" -Value "Powershell.exe -ExecutionPolicy Unrestricted -file `"C:\Windows\Temp\MapDrv.ps1`"" -PropertyType "String"
	}
    Else
        {
        Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message "Failed to download MapDrv.ps1 from Azure storage account to C:\Windows\Temp"
        }
    }
Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }
