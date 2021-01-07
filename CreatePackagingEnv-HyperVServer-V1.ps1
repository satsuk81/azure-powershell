function CreateVMp($VMName) {
    $PublicIpAddressName = $VMName + "-ip"

    $Params = @{
    ResourceGroupName = $RGName
    Name = $VMName
    Size = $VmSize
    Location = $Location
    VirtualNetworkName = $VNet
    SubnetName = "default"
    SecurityGroupName = $NsgName
    PublicIpAddressName = $PublicIpAddressName
    ImageName = $VmImage
    Credential = $VMCred
    }

    $VMCreate = New-AzVm @Params -SystemAssignedIdentity
    


    If ($VMCreate.ProvisioningState -eq "Succeeded") 
        {
        Write-Host "Virtual Machine $VMName created successfully"
        If ($AutoShutdown)
           {
            $VMName = $VMCreate.Name
            $SubscriptionId = (Get-AzSubscription).Id
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$RGName/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time'= 1900})
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status='Disabled'; timeInMinutes=15})
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $location -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force
            }
        $NewVm = Get-AzADServicePrincipal -displayname $VMName
        $Group = Get-AzADGroup -searchstring "Packaging-Contributor-RBAC"
        Add-AzureADGroupMember -ObjectId $Group.Id -RefObjectId $NewVm.Id
        }
    Else
    {
    Write-Host "*** Unable to create Virtual Machine $VMName! ***"
    }
}

function RunVMConfig($VMName, $BlobFilePath, $Blob) {

    $Params = @{
    ResourceGroupName = $RGName
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

# Create Hyper-V server
$NumberofVMs = 1                                                    # Specify number of VMs to be provisioned
$VmNamePrefix = "HyperV"                                            # Specifies the first part of the VM name (usually alphabetic)
$VmNumberStart = 01                                                # Specifies the second part of the VM name (usually numeric)
$VmSize = "Standard_D2_v3"                                            # Specifies Azure Size to use for the VM
$VmImage = "MicrosoftWindowsServer:WindowsServer:2019-Datacenter:latest"     # Specifies the Publisher, Offer, SKU and Version of the image to be used to provision the VM
$VmShutdown = $False
$VM = $VmNamePrefix + $VmNumberStart  

CreateVMp "$VM"

# Add Data disk to Hyper-V server
$dataDiskName = $VM + '_datadisk1'
$diskConfig = New-AzDiskConfig -SkuName "Standard_LRS" -Location $location -CreateOption Empty -DiskSizeGB 128
$dataDisk1 = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $RGName
$VMName = Get-AzVM -Name $VM -ResourceGroupName $RGName 
$VMName = Add-AzVMDataDisk -VM $VMName -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1

Update-AzVM -VM $VMName -ResourceGroupName $RGName

$VirtualMachine = Get-AzVM -Name $VM
Restart-AzVm -ResourceGroupName $RGName -Name $VM