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
    $password = ConvertTo-SecureString “St4rf1sh” -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential (“graham@higginson.org”, $password)

    Install-PackageProvider -Name NuGet -scope currentuser -Force 
    Install-Module -Name Az.Storage -scope currentuser -Force
    Connect-AzAccount -identity

    }
Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }



# Download the source media
Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Attempting to download media"
    $url="https://github.com/HigginsonConsultancy/Media/raw/master/Orca.zip"
    $output="c:\Windows\Temp\Orca.zip"
    (New-Object System.Net.WebClient).DownloadFile($url, $output)
    }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting to expand media to correct location"
    Expand-Archive -LiteralPath $output -DestinationPath C:\Windows\Temp\
    }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Starting Application Install"
    $Argument3 = "/i " + [char]34 + "C:\Windows\Temp\Orca\Orca-x86_en-us.msi" + [char]34 + " /qb"
    Start-Process -FilePath msiexec.exe -ArgumentList $Argument3 -Wait
        }
    
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Copying MapDrv script"
    $ctx = get-azstorageaccount -ResourceGroupName Higgcon -name packagingstoracc
    $ctx | Get-AzStorageBlobContent -Container "data" -Blob "MapDrv.ps1" -Destination "C:\Users\Public\Desktop"
    }
    Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "VM Build Script Completed"
