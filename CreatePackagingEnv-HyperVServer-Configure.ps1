function ConfigureHyperVVM($VMName) {
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

        # Add Data disk to Hyper-V server
        $dataDiskName = $VMName + '_datadisk1'
        $diskConfig = New-AzDiskConfig -SkuName $dataDiskSKU -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSize
        $dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $RGNamePROD
        Add-AzVMDataDisk -VM $VMCreate -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1
        Update-AzVM -VM $VMCreate -ResourceGroupName $RGNamePROD

        #Restart-AzVm -ResourceGroupName $RGNamePROD -Name $VMName
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/ConfigureDataDisk.ps1" "ConfigureDataDisk.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/EnableHyperV.ps1" "EnableHyperV.ps1"
        Restart-AzVM -ResourceGroupName $RGNamePROD -Name $VMName | Out-Null    
        Write-Host "Restarting VM..."
        Start-Sleep -Seconds 120
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/ModuleList.ps1" "ModuleList.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/Build-VM.ps1" "Build-VM.ps1"
        RunVMConfig "$VMName" "https://$StorAcc.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
        
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
        ResourceGroupName = $RGNamePROD
        VMName            = $VMName
        Location          = $Location
        FileUri           = $BlobFilePath
        Run               = $Blob
        Name              = "ConfigureVM"
    }

    $VMConfigure = Set-AzVMCustomScriptExtension @Params
    If ($VMConfigure.IsSuccessStatusCode -eq $True) { Write-Host "Virtual Machine $VMName configured successfully" }Else { Write-Host "*** Unable to configure Virtual Machine $VMName! ***" }
}
function TerraformBuild {
    # Configure Hyper-V VMs
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VmHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-Host "Configuring $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart
            ConfigureHyperVVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild {
    # Configure Hyper-V VMs
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VmHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-Host "Configuring $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart
            ConfigureHyperVVM "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

#region Main
#=======================================================================================================================================================

# Main Script
# Create Hyper-V server
$NumberofHyperVVMs = 1                                                            # Specify number of VMs to be provisioned
$VMHyperVNamePrefix = "vmwleuchyperv"                                             # Specifies the first part of the VM name (usually alphabetic)
$VmHyperVNumberStart = 01                                                         # Specifies the second part of the VM name (usually numeric)
$VmSize = "Standard_D16s_v4"                                                # Specifies Azure Size to use for the VM
$VmImage = "MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest"    # Specifies the Publisher, Offer, SKU and Version of the image to be used to provision the VM
$VmShutdown = $true
$dataDiskTier = "S10"
$dataDiskSKU = "Standard_LRS"
$dataDiskSize = 128

if ($UseTerraform) {
    TerraformBuild
}
else {
    ScriptBuild
}
Write-Host "Hyper-V Configure Script Completed"
#endregion Main