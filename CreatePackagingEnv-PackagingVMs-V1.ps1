function CreateStandardVMp($VMName) {
    $PublicIpAddressName = $VMName + "-ip"

    if($requirePublicIPs) {
        $Params = @{
            ResourceGroupName   = $RGNameUAT
            Name                = $VMName
            Size                = $VMSizeStandard
            Location            = $Location
            VirtualNetworkName  = $VNetPROD
            SubnetName          = $SubnetName
            SecurityGroupName   = $NsgNamePROD
            PublicIpAddressName = $PublicIpAddressName
            ImageName           = $VMImage
            Credential          = $VMCred
        }
    }
    else {
        $Params = @{
            ResourceGroupName   = $RGNameUAT
            Name                = $VMName
            Size                = $VMSizeStandard
            Location            = $Location
            VirtualNetworkName  = $VNetPROD
            SubnetName          = $SubnetName
            SecurityGroupName   = $NsgNamePROD
            PublicIpAddressName = $PublicIpAddressName
            ImageName           = $VMImage
            Credential          = $VMCred
        }
    }

    $VMCreate = New-AzVm @Params -SystemAssignedIdentity
    if (!$requirePublicIPs) { Remove-AzPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $RGNameUAT }

    If ($VMCreate.ProvisioningState -eq "Succeeded") 
        {
        Write-Host "Virtual Machine $VMName created successfully"
        If ($AutoShutdown)
           {
            $VMName = $VMCreate.Name
            $SubscriptionId = (Get-AzContext).Subscription.Id
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$RGNameUAT/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time'= 1800})
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status='Disabled'; timeInMinutes=15})
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Host "Auto Shutdown Enabled for 1800"
            }
        $NewVm = Get-AzADServicePrincipal -displayname $VMName
        $Group = Get-AzADGroup -searchstring $rbacContributor
        Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id
        }
    Else
    {
    Write-Host "*** Unable to create Virtual Machine $VMName! ***"
    }
}

function CreateAdminStudioVMp($VMName) {
    $PublicIpAddressName = $VMName + "-ip"

    if($requirePublicIPs) {
        $Params = @{
            ResourceGroupName   = $RGNameUAT
            Name                = $VMName
            Size                = $VMSizeAdminStudio
            Location            = $Location
            VirtualNetworkName  = $VNetPROD
            SubnetName          = $SubnetName
            SecurityGroupName   = $NsgNamePROD
            PublicIpAddressName = $PublicIpAddressName
            ImageName           = $VMImage
            Credential          = $VMCred
        }
    }
    else {
        $Params = @{
            ResourceGroupName   = $RGNameUAT
            Name                = $VMName
            Size                = $VMSizeAdminStudio
            Location            = $Location
            VirtualNetworkName  = $VNetPROD
            SubnetName          = $SubnetName
            SecurityGroupName   = $NsgNamePROD
            PublicIpAddressName = $PublicIpAddressName
            ImageName           = $VMImage
            Credential          = $VMCred
        }
    }

    $VMCreate = New-AzVM @Params -SystemAssignedIdentity
    if (!$requirePublicIPs) { Remove-AzPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $RGNameUAT }

    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Host "Virtual Machine $VMName created successfully"
        If ($AutoShutdown) {
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
    }
    Else {
        Write-Host "*** Unable to create Virtual Machine $VMName! ***"
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


#=======================================================================================================================================================

# Main Script

# Build Standard VMs
if($RequireStandardVMs) {
    $Count = 1
    While ($Count -le $NumberofStandardVMs) {
        Write-Host "Creating and configuring $Count of $NumberofStandardVMs VMs"
        $VM = $VMNamePrefixStandard + $VMNumberStartStandard
        CreateStandardVMp "$VM"
        Restart-AzVm -ResourceGroupName $RGNameUAT -Name $VM | Out-Null
        Write-Host "Restarting VM..."
        RunVMConfig "$VM" "https://$StorAcc.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$VM" "https://$StorAcc.blob.core.windows.net/data/VMConfig.ps1" "VMConfig.ps1"
        
        # Shutdown VM if $VMShutdown is true
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $RGNameUAT -Name $VM -Force
            if ($Stopvm.Status -eq "Succeeded") {Write-Host "VM $VM shutdown successfully"}Else{Write-Host "*** Unable to shutdown VM $VM! ***"}
        }
        $Count++
        $VMNumberStartStandard++
    }
}
# Build AdminStudio VMs
if($RequireAdminStudioVMs) {
    $Count = 1
    While ($Count -le $NumberofAdminStudioVMs) {
        Write-Host "Creating and configuring $Count of $NumberofAdminStudioVMs VMs"
        $VM = $VMNamePrefixAdminStudio + $VMNumberStartAdminStudio
        CreateAdminStudioVMp "$VM"
        Restart-AzVM -ResourceGroupName $RGNameUAT -Name $VM | Out-Null
        Write-Host "Restarting VM..."
        RunVMConfig "$VM" "https://$StorAcc.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$VM" "https://$StorAcc.blob.core.windows.net/data/VMConfig.ps1" "VMConfig.ps1"
        RunVMConfig "$VM" "https://$StorAcc.blob.core.windows.net/data/AdminStudio.ps1" "AdminStudio.ps1"
        Restart-AzVM -ResourceGroupName $RGNameUAT -Name $VM | Out-Null
        Write-Host "Restarting VM..."
        
        # Shutdown VM if $VMShutdown is true
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $RGNameUAT -Name $VM -Force
            if ($Stopvm.Status -eq "Succeeded") { Write-Host "VM $VM shutdown successfully" }Else { Write-Host "*** Unable to shutdown VM $VM! ***" }
        }
        $Count++
        $VMNumberStartAdminStudio++
    }
}
Write-Host "Packaging VM Script Completed"