#set-executionpolicy Unrestricted -scope currentuser -Force

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
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Loading modules and attempting to connect to Azure"

    Install-PackageProvider -Name NuGet -scope currentuser -Force 
    Install-Module -Name Az.Storage -scope currentuser -Force
    Connect-AzAccount -identity

    }
Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Copying MapDrv script"
    $ctx = get-azstorageaccount -ResourceGroupName rg-wl-prod-eucpackaging -name stwleucpackaging01
    $ctx | Get-AzStorageBlobContent -Container "data" -Blob "MapDrv.ps1" -Destination "C:\Users\Public\Desktop"
    }
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "VM Build Script Completed"
