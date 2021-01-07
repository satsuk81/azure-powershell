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

# Build VM/s
$Count = 1
While ($Count -le $NumberOfVMs)
    {
    Write-Host "Creating and configuring $Count of $NumberofVMs VMs"
    $VM = $VmNamePrefix + $VmNumberStart
    CreateVMp "$VM"
    Restart-AzVm -ResourceGroupName $RGName -Name $VM
    RunVMConfig "$VM" "https://packagingstoracc.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
    RunVMConfig "$VM" "https://packagingstoracc.blob.core.windows.net/data/VMConfig.ps1" "VMConfig.ps1"
    
    # Shutdown VM if $VmShutdown is true
    If ($VmShutdown)
        {
        $Stopvm = Stop-AzVM -ResourceGroupName $RGName -Name $VM -Force
        If ($RG.ResourceGroupName -eq $RGName) {Write-Host "VM $VM shutdown successfully"}Else{Write-Host "*** Unable to shutdown VM $VM! ***"}
        }
    $Count++
    $VmNumberStart++
    }
