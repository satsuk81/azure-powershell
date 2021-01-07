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
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Enable Hyper-V"
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    }
Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }

# Load Modules and Connect to Azure
Try
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Information -Message "Enable Management Tools"
    Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
    }
Catch
    {
    Write-EventLog -LogName $EventlogName -Source $EventlogSource -EventID 25101 -EntryType Error -Message $error[0].Exception
    }
