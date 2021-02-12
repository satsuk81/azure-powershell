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
}

function CreateStandardVM-Terraform($VMName) {
    mkdir -Path ".\Terraform\" -Name "$VMName" -Force
    $TerraformVMVariables = (Get-Content -path ".\Terraform\template-win10\variables.tf").Replace("xxxx",$VMName) | Set-Content -path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path ".\Terraform\template-win10\main.tf") | Set-Content -Path ".\Terraform\$VMName\main.tf"

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
    $TerraformVMVariables = (Get-Content -Path ".\Terraform\template-win10\variables.tf").Replace("xxxx", $VMName) | Set-Content -Path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path ".\Terraform\template-win10\main.tf") | Set-Content -Path ".\Terraform\$VMName\main.tf"

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