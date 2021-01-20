function CreateVMp($VMName) {
    $PublicIpAddressName = $VMName + "-ip"

    $Params = @{
    ResourceGroupName = $RGNameUAT
    Name = $VMName
    Size = $VmSize
    Location = $Location
    VirtualNetworkName = $VNetUAT
    SubnetName = "default"
    SecurityGroupName = $NsgNameUAT
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
        $Group = Get-AzADGroup -searchstring "Packaging-Contributor-RBAC"
        Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id
        }
    Else
    {
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

# Build VM/s
$Count = 1
While ($Count -le $NumberOfVMs)
    {
    Write-Host "Creating and configuring $Count of $NumberofVMs VMs"
    $VM = $VmNamePrefix + $VmNumberStart
    CreateVMp "$VM"
    Restart-AzVm -ResourceGroupName $RGNameUAT -Name $VM | Out-Null
    Write-Host "Restarting VM..."
    RunVMConfig "$VM" "https://$StorAcc.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
    RunVMConfig "$VM" "https://$StorAcc.blob.core.windows.net/data/VMConfig.ps1" "VMConfig.ps1"
    
    # Shutdown VM if $VmShutdown is true
    If ($VmShutdown)
        {
        $Stopvm = Stop-AzVM -ResourceGroupName $RGNameUAT -Name $VM -Force
        If ($Stopvm.Status -eq "Succeeded") {Write-Host "VM $VM shutdown successfully"}Else{Write-Host "*** Unable to shutdown VM $VM! ***"}
        }
    $Count++
    $VmNumberStart++
    }
