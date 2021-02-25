function ConfigureStandardVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNameUAT -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Host "Virtual Machine $VMName created successfully"
        if (!$requirePublicIPs) { 
            $VMNic = Get-AzNetworkInterface -Name $VMCreate.Name -ResourceGroup $RGNameUAT
            $VMNic.IpConfigurations.publicipaddress.id = $null
            Set-AzNetworkInterface -NetworkInterface $VMNic | Out-Null
            Remove-AzPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $RGNameUAT -Force
        }
        if ($AutoShutdown) {
            $VMName = $VMCreate.Name
            $SubscriptionId = (Get-AzContext).Subscription.Id
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$RGNameUAT/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800 })
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Host "Auto Shutdown Enabled for 1800"
        }
        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        $Group = Get-AzADGroup -searchstring $rbacContributor
        Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose

        Restart-AzVM -ResourceGroupName $RGNameUAT -Name $VMName | Out-Null
        Write-Host "Restarting VM..."
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/ORCA.ps1" "ORCA.ps1"
        #RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/GlassWire.ps1" "GlassWire.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/7-Zip.ps1" "7-Zip.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/InstEd.ps1" "InstEd.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/IntuneWinUtility.ps1" "IntuneWinUtility.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/DesktopApps.ps1" "DesktopApps.ps1"
        
        # Shutdown VM if $VMShutdown is true
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $RGNameUAT -Name $VMName -Force
            if ($Stopvm.Status -eq "Succeeded") { Write-Host "VM $VMName shutdown successfully" }Else { Write-Host "*** Unable to shutdown VM $VMName! ***" }
        }
    }
    Else {
        Write-Host "*** Unable to configure Virtual Machine $VMName! ***"
    }
}

function ConfigureAdminStudioVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $RGNameUAT -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Host "Virtual Machine $VMName created successfully"
        if (!$requirePublicIPs) { 
            $VMNic = Get-AzNetworkInterface -Name $VMCreate.Name -ResourceGroup $RGNameUAT
            $VMNic.IpConfigurations.publicipaddress.id = $null
            Set-AzNetworkInterface -NetworkInterface $VMNic | Out-Null
            Remove-AzPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $RGNameUAT -Force
        }
        if ($AutoShutdown) {
            $VMName = $VMCreate.Name
            $SubscriptionId = (Get-AzContext).Subscription.Id
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$RGNameUAT/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800 })
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Host "Auto Shutdown Enabled for 1800"
        }
        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        $Group = Get-AzADGroup -searchstring $rbacContributor
        Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id

        Restart-AzVM -ResourceGroupName $RGNameUAT -Name $VMName | Out-Null
        Write-Host "Restarting VM..."
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
        #RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/AdminStudio.ps1" "AdminStudio.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/ORCA.ps1" "ORCA.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/GlassWire.ps1" "GlassWire.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/7-Zip.ps1" "7-Zip.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/InstEd.ps1" "InstEd.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/IntuneWinUtility.ps1" "IntuneWinUtility.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/DesktopApps.ps1" "DesktopApps.ps1"
        
        
        # Shutdown VM if $VMShutdown is true
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $RGNameUAT -Name $VMName -Force
            if ($Stopvm.Status -eq "Succeeded") { Write-Host "VM $VMName shutdown successfully" }Else { Write-Host "*** Unable to shutdown VM $VMName! ***" }
        }
    }
    Else {
        Write-Host "*** Unable to configure Virtual Machine $VMName! ***"
    }
}

function RunVMConfig($VMName, $BlobFilePath, $Blob) {

    $Params = @{
        ResourceGroupName = $RGNameUAT
        VMName = $VMName
        Location = $Location
        FileUri = $BlobFilePath
        Run = $Blob
        Name = "ConfigureVM"
    }

    $VMConfigure = Set-AzVMCustomScriptExtension @Params
    If ($VMConfigure.IsSuccessStatusCode -eq $True) {Write-Host "Virtual Machine $VMName configured successfully"}Else{Write-Host "*** Unable to configure Virtual Machine $VMName! ***"}
}

function TerraformBuild {
    # Configure Standard VMs
    if ($RequireStandardVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartStandard
        While ($Count -le $NumberofStandardVMs) {
            Write-Host "Configuring $Count of $NumberofStandardVMs VMs"
            $VM = $VMNamePrefixStandard + $VMNumberStart
            ConfigureStandardVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }

    # Configure AdminStudio VMs
    if ($RequireAdminStudioVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartAdminStudio
        While ($Count -le $NumberofAdminStudioVMs) {
            Write-Host "Configuring $Count of $NumberofAdminStudioVMs VMs"
           $VM = $VMNamePrefixStandard + $VMNumberStart
            ConfigureAdminStudioVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild {
    # Configure Standard VMs
    if ($RequireStandardVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartStandard
        While ($Count -le $NumberofStandardVMs) {
            Write-Host "Configuring $Count of $NumberofStandardVMs VMs"
            $VM = $VMNamePrefixStandard + $VMNumberStart
            ConfigureStandardVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }

    # Configure AdminStudio VMs
    if ($RequireAdminStudioVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartAdminStudio
        While ($Count -le $NumberofAdminStudioVMs) {
            Write-Host "Configuring $Count of $NumberofAdminStudioVMs VMs"
           $VM = $VMNamePrefixStandard + $VMNumberStart
            ConfigureAdminStudioVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

#=======================================================================================================================================================

# Main Script
if ($UseTerraform) {
    TerraformBuild
}
else {
   ScriptBuild
}

Write-Host "Configure Packaging VM Script Completed"