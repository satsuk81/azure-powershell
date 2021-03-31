function CreateHyperVVM-Terraform($VMName) {
    mkdir -Path ".\Terraform\" -Name "$VMName" -Force
    $TerraformVMVariables = (Get-Content -Path ".\Terraform\template-server2019\variables.tf").Replace("xxxx", $VMName) | Set-Content -Path ".\Terraform\$VMName\variables.tf"
    $TerraformVMMain = (Get-Content -Path ".\Terraform\template-server2019\main.tf") | Set-Content -Path ".\Terraform\$VMName\main.tf"

    $TerraformText = "
module " + [char]34 + $VMName + [char]34 + " {
  source = " + [char]34 + "./" + $VMName + [char]34 + "

  myterraformgroupName = module.environment.myterraformgroup.name
  myterraformsubnetID = module.environment.myterraformsubnet.id
  myterraformnsgID = module.environment.myterraformnsg.id
}"

    $TerraformMain = Get-Content -Path ".\Terraform\main.tf"
    $TerraformText | Add-Content -Path ".\Terraform\main.tf"
}

function CreateHyperVVM-Script($VMName) {
    $Vnet = Get-AzVirtualNetwork -Name $VNetPROD -ResourceGroupName $RGNameVNET 
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet
    $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $RGNamePROD -Location $Location -SubnetId $Subnet.Id
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VmSize -IdentityType SystemAssigned
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $VMCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $RGNamePROD -Location $Location -VM $VirtualMachine -Verbose  
}

function TerraformBuild {
        # Build Hyper-V Server VM
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VMHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-Host "Creating $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart

            CreateHyperVVM-Terraform "$VM"
            $Count++
            $VMNumberStart++
        }
    }
}

function ScriptBuild {
        # Build Hyper-V Server VM
    if ($RequireHyperV) {
        $Count = 1
        $VMNumberStart = $VMHyperVNumberStart
        While ($Count -le $NumberofHyperVVMs) {
            Write-Host "Creating $Count of $NumberofHyperVVMs VMs"
            $VM = $VMHyperVNamePrefix + $VMNumberStart
            $VMCheck = Get-AzVM -Name "$VM" -ResourceGroup $RGNameUAT -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if (!$VMCheck) {
                CreateHyperVVM-Script "$VM"
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

#region Main
#=======================================================================================================================================================
$NumberofHyperVVMs = 1                                                  # Specify number of VMs to be provisioned
$VMHyperVNamePrefix = "wlprodeushypv0"                                  # Specifies the first part of the VM name (usually alphabetic)
$VmHyperVNumberStart = 1                                                # Specifies the second part of the VM name (usually numeric)
$VmSize = "Standard_D16s_v4"                                           # Specifies Azure Size to use for the VM
#$VmSize = "Standard_D2s_v4"                                             # Specifies Azure Size to use for the VM
$dataDiskTier = "P50"
$dataDiskSKU = "Premium_LRS"
$dataDiskSize = 4096
#$dataDiskTier = "S10"
#$dataDiskSKU = "Standard_LRS"
#$dataDiskSize = 128

if ($UseTerraform) {
    TerraformBuild
}
else {
    ScriptBuild
}
Write-Host "Hyper-V Create Script Completed"
#endregion Main