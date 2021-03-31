﻿function ConfigureStandardVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Host "Virtual Machine $VMName created successfully"
        
        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        #$Group = Get-AzADGroup -searchstring $rbacContributor
        #Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose
        
        Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue
        Get-AzContext -Name "User" | Select-AzContext | Out-Null

        Restart-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName | Out-Null
        Write-Host "Restarting VM..."
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/VMConfig.ps1" "VMConfig.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/ORCA.ps1" "ORCA.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/7-Zip.ps1" "7-Zip.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/InstEd.ps1" "InstEd.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/DesktopApps.ps1" "DesktopApps.ps1"
        #RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/GlassWire.ps1" "GlassWire.ps1"
        #RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/IntuneWinUtility.ps1" "IntuneWinUtility.ps1"
        
        if ($AutoShutdown) {
            $VMName = $VMCreate.Name
            $SubscriptionId = (Get-AzContext).Subscription.Id
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800 })
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Host "Auto Shutdown Enabled for 1800"
        }
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force
            if ($Stopvm.Status -eq "Succeeded") { Write-Host "VM $VMName shutdown successfully" }Else { Write-Host "*** Unable to shutdown VM $VMName! ***" }
        }
    }
    Else {
        Write-Host "*** Unable to configure Virtual Machine $VMName! ***"
    }
}

function ConfigureAdminStudioVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Host "Virtual Machine $VMName created successfully"
        
        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        #$Group = Get-AzADGroup -searchstring $rbacContributor
        #Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id

        Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue
        Get-AzContext -Name "User" | Select-AzContext | Out-Null
        
        Restart-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName | Out-Null
        Write-Host "Restarting VM..."
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/VMConfig.ps1" "VMConfig.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/AdminStudio.ps1" "AdminStudio.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/ORCA.ps1" "ORCA.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/GlassWire.ps1" "GlassWire.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/7-Zip.ps1" "7-Zip.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/InstEd.ps1" "InstEd.ps1"
        
        if ($AutoShutdown) {
            $VMName = $VMCreate.Name
            $SubscriptionId = (Get-AzContext).Subscription.Id
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800 })
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Host "Auto Shutdown Enabled for 1800"
        }
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force
            if ($Stopvm.Status -eq "Succeeded") { Write-Host "VM $VMName shutdown successfully" }Else { Write-Host "*** Unable to shutdown VM $VMName! ***" }
        }
    }
    Else {
        Write-Host "*** Unable to configure Virtual Machine $VMName! ***"
    }
}

function ConfigureJumpboxVM($VMName) {
    $VMCreate = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Host "Virtual Machine $VMName created successfully"
        
        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        #$Group = Get-AzADGroup -searchstring $rbacContributor
        #Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id

        Get-AzContext -Name "StorageSP" | Select-AzContext | Out-Null
        New-AzRoleAssignment -ObjectId $NewVm.Id -RoleDefinitionName "Contributor" -Scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Storage/storageAccounts/$StorageAccountName" -Verbose -ErrorAction SilentlyContinue
        Get-AzContext -Name "User" | Select-AzContext | Out-Null
        
        Restart-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName | Out-Null
        Write-Host "Restarting VM..."
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/DomainJoin.ps1" "DomainJoin.ps1"
        
        if ($AutoShutdown) {
            $VMName = $VMCreate.Name
            $SubscriptionId = (Get-AzContext).Subscription.Id
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800 })
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $Location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Host "Auto Shutdown Enabled for 1800"
        }
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force
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
    If ($VMConfigure.IsSuccessStatusCode -eq $True) { Write-Host "Virtual Machine $VMName configured with $Blob successfully" }Else { Write-Host "*** Unable to configure Virtual Machine $VMName with $Blob ***" }
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

        # Configure Jumpbox VMs
    if ($RequireJumpboxVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartJumpbox
        While ($Count -le $NumberofJumpboxVMs) {
            Write-Host "Configuring $Count of $NumberofJumpboxVMs VMs"
            $VM = $VMNamePrefixJumpbox + $VMNumberStart
            ConfigureJumpboxVM "$VM"
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
           $VM = $VMNamePrefixAdminStudio + $VMNumberStart
            ConfigureAdminStudioVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }

        # Configure Jumpbox VMs
    if ($RequireJumpboxVMs) {
        $Count = 1
        $VMNumberStart = $VMNumberStartJumpbox
        While ($Count -le $NumberofJumpboxVMs) {
            Write-Host "Configuring $Count of $NumberofJumboxVMs VMs"
            $VM = $VMNamePrefixJumpbox + $VMNumberStart
            ConfigureJumpboxVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

#region Main
#=======================================================================================================================================================

# Main Script
if ($UseTerraform) {
    TerraformBuild
}
else {
   ScriptBuild
}

Write-Host "Configure Packaging VM Script Completed"
#endregion Main