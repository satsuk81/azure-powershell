function CreateStandardVM-Script($VMName) {
    $PublicIpAddressName = $VMName + "-ip"

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

    $VMCreate = New-AzVm @Params -SystemAssignedIdentity
    if (!$requirePublicIPs) { 
        $VMNic = Get-AzNetworkInterface -Name $VMCreate.Name -ResourceGroup $RGNameUAT
        $VMNic.IpConfigurations.publicipaddress.id = $null
        Set-AzNetworkInterface -NetworkInterface $VMNic | Out-Null
        Remove-AzPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $RGNameUAT -Force
    }

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

function CreateStandardVM-Terraform($VMName) {
    #$VMCreate = New-AzVM @Params -SystemAssignedIdentity
    #$ARGUinit = "init"
    #$ARGUplan = "plan -var vmname=" + [char]34 + "$VMName" + [char]34 + " -var vmnic=" + [char]34 + "$VMName-nic" + [char]34 + " -var vmip=" + [char]34 + "$VMName-ip" + [char]34 + " -var vmosdisk=" + [char]34 + "$VMName-osdisk" + [char]34 + " -out .\$VMName.tfplan"
    #$ARGUapply = "apply -auto-approve .\$VMName.tfplan"
    #Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUinit -Wait
    #Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUplan -Wait -RedirectStandardOutput .\$VMName-plan.txt
    #Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUapply -Wait -RedirectStandardOutput .\$VMName-apply.txt

    mkdir -Path ".\Terraform\" -Name "$VMName" -Force
    $TerraformVM = (Get-Content -path ".\Terraform\template\variables.tf").Replace("xxx",$VMName) | Set-Content -path ".\Terraform\$VMName\variables.tf"

    $TerraformText = "
module "+[char]34+$VMName+[char]34+" {
  source = "+[char]34+"./"+$VMName+[char]34+"

  myterraformgroupName = module.environment.myterraformgroup.name
  myterraformsubnetID = module.environment.myterraformsubnet.id
  myterraformnsgID = module.environment.myterraformnsg.id
}"

    $TerraformMain = Get-Content -Path ".\Terraform\main.tf"
    #$TerraformMain = $TerraformMain[0..($TerraformMain.Length - 2)]
    #$TerraformMain | Set-Content -Path ".\Terraform\main.tf"
    $TerraformText | Add-Content -Path ".\Terraform\main.tf"
}

function CreateAdminStudioVM-Script($VMName) {
    $PublicIpAddressName = $VMName + "-ip"

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

    $VMCreate = New-AzVM @Params -SystemAssignedIdentity
    if (!$requirePublicIPs) { 
        $VMNic = Get-AzNetworkInterface -Name $VMCreate.Name -ResourceGroup $RGNameUAT
        $VMNic.IpConfigurations.publicipaddress.id = $null
        Set-AzNetworkInterface -NetworkInterface $VMNic | Out-Null
        Remove-AzPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $RGNameUAT -Force
    }

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

        $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameUAT
        if(!$VMCheck) {
            if($UseTerraform) {
                CreateStandardVM-Terraform "$VM"
            }
            else {
                CreateStandardVM-Script "$VM"
            }
            Restart-AzVM -ResourceGroupName $RGNameUAT -Name $VM | Out-Null
            Write-Host "Restarting VM..."
            RunVMConfig "$VM" "https://$StorAcc.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
            RunVMConfig "$VM" "https://$StorAcc.blob.core.windows.net/data/VMConfig.ps1" "VMConfig.ps1"
        
            # Shutdown VM if $VMShutdown is true
            if ($VMShutdown) {
                $Stopvm = Stop-AzVM -ResourceGroupName $RGNameUAT -Name $VM -Force
                if ($Stopvm.Status -eq "Succeeded") { Write-Host "VM $VM shutdown successfully" }Else { Write-Host "*** Unable to shutdown VM $VM! ***" }
            }
            $Count++
            $VMNumberStartStandard++
        }
        else {
            Write-Host "Virtual Machine $VM already exists!"
            break
        }
    }
}
# Build AdminStudio VMs
if($RequireAdminStudioVMs) {
    $Count = 1
    While ($Count -le $NumberofAdminStudioVMs) {
        Write-Host "Creating and configuring $Count of $NumberofAdminStudioVMs VMs"
        $VM = $VMNamePrefixAdminStudio + $VMNumberStartAdminStudio

        $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameUAT
        if(!$VMCheck) {
            if($UseTerraform) {
                CreateAdminStudioVM-Terraform "$VM"
            }
            else {
                CreateAdminStudioVM-Script "$VM"    
            }
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
        else {
            Write-Host "Virtual Machine $VM already exists!"
            break
        }
        
    }
}
Write-Host "Packaging VM Script Completed"