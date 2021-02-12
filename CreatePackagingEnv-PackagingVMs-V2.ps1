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
    $TerraformVMVariables = (Get-Content -path ".\Terraform\template\variables.tf").Replace("xxxx",$VMName) | Set-Content -path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path ".\Terraform\template\main.tf") | Set-Content -Path ".\Terraform\$VMName\main.tf"

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

function CreateAdminStudioVM-Terraform($VMName) {
    #$VMCreate = New-AzVM @Params -SystemAssignedIdentity
    #$ARGUinit = "init"
    #$ARGUplan = "plan -var vmname=" + [char]34 + "$VMName" + [char]34 + " -var vmnic=" + [char]34 + "$VMName-nic" + [char]34 + " -var vmip=" + [char]34 + "$VMName-ip" + [char]34 + " -var vmosdisk=" + [char]34 + "$VMName-osdisk" + [char]34 + " -out .\$VMName.tfplan"
    #$ARGUapply = "apply -auto-approve .\$VMName.tfplan"
    #Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUinit -Wait
    #Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUplan -Wait -RedirectStandardOutput .\$VMName-plan.txt
    #Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUapply -Wait -RedirectStandardOutput .\$VMName-apply.txt

    mkdir -Path ".\Terraform\" -Name "$VMName" -Force
    $TerraformVMVariables = (Get-Content -Path ".\Terraform\template\variables.tf").Replace("xxxx", $VMName) | Set-Content -Path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path ".\Terraform\template\main.tf") | Set-Content -Path ".\Terraform\$VMName\main.tf"

    $TerraformText = "
module " + [char]34 + $VMName + [char]34 + " {
  source = " + [char]34 + "./" + $VMName + [char]34 + "

  myterraformgroupName = module.environment.myterraformgroup.name
  myterraformsubnetID = module.environment.myterraformsubnet.id
  myterraformnsgID = module.environment.myterraformnsg.id
}"

    $TerraformMain = Get-Content -Path ".\Terraform\main.tf"
    #$TerraformMain = $TerraformMain[0..($TerraformMain.Length - 2)]
    #$TerraformMain | Set-Content -Path ".\Terraform\main.tf"
    $TerraformText | Add-Content -Path ".\Terraform\main.tf"
}

function TerraformBuild {
    $TerraformMainTemplate = Get-Content -Path ".\Terraform\Root Template\main.tf" | Set-Content -Path ".\Terraform\main.tf"
    # Build Standard VMs
    if ($RequireStandardVMs) {
        # Create VMs
        $Count = 1
        $VMNumberStart = $VMNumberStartStandard
        While ($Count -le $NumberofStandardVMs) {
            Write-Host "Creating $Count of $NumberofStandardVMs VMs"
            $VM = $VMNamePrefixStandard + $VMNumberStart

            CreateStandardVM-Terraform "$VM"
            $Count++
            $VMNumberStart++
        }
    }
    # Build AdminStudio VMs
    if ($RequireAdminStudioVMs) {
        # Create VMs
        $Count = 1
        $VMNumberStart = $VMNumberStartAdminStudio
        While ($Count -le $NumberofAdminStudioVMs) {
            Write-Host "Creating $Count of $NumberofAdminStudioVMs VMs"
            $VM = $VMNamePrefixStandard + $VMNumberStart

            CreateAdminStudioVM-Terraform "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild {
    # Build Standard VMs
    if ($RequireStandardVMs) {
        # Create VMs
        $Count = 1
        $VMNumberStart = $VMNumberStartStandard
        While ($Count -le $NumberofStandardVMs) {
            Write-Host "Creating $Count of $NumberofStandardVMs VMs"
            $VM = $VMNamePrefixStandard + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameUAT
            if (!$VMCheck) {
                CreateStandardVM-Script "$VM"
            }
            else {
                Write-Host "Virtual Machine $VM already exists!"
                break
            }
            $Count++
            $VMNumberStart++
        }
    }

    # Build AdminStudio VMs
    if ($RequireAdminStudioVMs) {
        # Create VMs
        $Count = 1
        $VMNumberStart = $VMNumberStartAdminStudio
        While ($Count -le $NumberofAdminStudioVMs) {
            Write-Host "Creating $Count of $NumberofAdminStudioVMs VMs"
            $VM = $VMNamePrefixStandard + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameUAT
            if (!$VMCheck) {
                CreateAdminStudioVM-Script "$VM"
            }
            else {
                Write-Host "Virtual Machine $VM already exists!"
                break
            }
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

Write-Host "Packaging VM Script Completed"