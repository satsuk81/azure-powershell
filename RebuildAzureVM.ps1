Param(
    [Parameter(Mandatory = $false)][string]$VMName = "",
    [Parameter(Mandatory = $false)][ValidateSet('Standard', 'AdminStudio')][string]$Spec = "Standard"
)

#region Setup
cd $PSScriptRoot

Import-Module Az.Compute,Az.Accounts,Az.Storage,Az.Network,Az.Resources -ErrorAction SilentlyContinue
if(!((Get-Module Az.Compute) -and (Get-Module Az.Accounts) -and (Get-Module Az.Storage) -and (Get-Module Az.Network) -and (Get-Module Az.Resources))) {
    Install-Module Az.Compute,Az.Accounts,Az.Storage,Az.Network,Az.Resources -Repository PSGallery -Scope CurrentUser -Force
    Import-Module AZ.Compute,Az.Accounts,Az.Storage,Az.Network,Az.Resources
}

Clear-AzContext -Force

# Tenant
$azTenant = (Get-Content ".\tenant.txt")

# Subscription ID If Required
$azSubscription = (Get-Content ".\subscription.txt")

#Connect-AzAccount -Credential $(Get-Credential) -Subscription $azSubscription      # Non-MFA
Connect-AzAccount -Tenant $aztenant -Subscription $azSubscription                   # MFA Account

$SubscriptionId = (Get-AzContext).Subscription.Id
if (!($azSubscription -eq $SubscriptionId)) {
    Write-Error "Subscription ID Mismatch!!!!"
    exit
}
Get-AzContext | Rename-AzContext -TargetName "User" -Force

$SPUser = (Get-Content ".\sp.txt")[0]
$SPPassword = (Get-Content ".\sp.txt")[1]
$SPSecurePassword = $SPPassword | ConvertTo-SecureString -AsPlainText -Force
$StorageSP = New-Object System.Management.Automation.PSCredential ($SPUser, $SPSecurePassword)
#$StorageSP = Import-Clixml .\StorageSP.xml

Connect-AzAccount -Tenant $azTenant -Subscription $azSubscription -Credential $StorageSP -ServicePrincipal | Out-Null
Get-AzContext | Rename-AzContext -TargetName "StorageSP" -Force
#Get-AzContext -Name "StorageSP" | Select-AzContext
Get-AzContext -Name "User" | Select-AzContext | Out-Null

# VM Admin Account
$password = Get-Content ".\password.txt" | ConvertTo-SecureString -AsPlainText -Force       # Local Admin Password for VMs 
$VMCred = New-Object System.Management.Automation.PSCredential ("AppPackager", $password)   # Local Admin User for VMs

$tags = @{
    "Application" = "App Packaging"
    "Compliance"  = "General"
    "CostCentre"  = "5400200015"
    "Criticality"   = "Mission Critical"
    "Data Classification" = "General Business"
    "Disaster Recovery" = "None"
    "Envrionment" = "Prod"
}
$RequirePublicIPs = $false
$ResourceGroupName = "rg-wl-prod-packaging"
$StorageAccountName = "wlprodeusprodpkgstr01"
$ContainerName = "data"                                             # Storage container name (if used)
$FileShareName = "pkgazfiles01"                                     # Storage FileShare name (if used)
$VNet = "vnet-wl-eus-prod"                                          # Environment Virtual Network name
$SubnetName = "snet-wl-eus-prod-packaging"                          # Environment Virtual Subnet name
$NsgName = "nsg-wl-eus-prod-packaging"                              # NSG for Virtual Network
$VMSizeStandard = "Standard_B2s"                                    # Specifies Azure Size to use for the Standard VM
$VMSizeAdminStudio = "Standard_B2s"                                 # Specifies Azure Size to use for the AdminStudio VM
#$VMSizeAdminStudio = "Standard_D2_v2"                              # Specifies Azure Size to use for the AdminStudio VM
$VMImage = "MicrosoftWindowsDesktop:Windows-10:20h2-ent:latest"     # Specifies the Publisher, Offer, SKU and Version of the image to be used to provision the VM
$VMShutdown = $false                                                # Specifies if the newly provisioned VM should be shutdown (can save costs)
$AutoShutdown = $true                                               # Configures Windows 10 VMs to shutdown at a specified time                                             
$Location = "eastus"  
$ContainerScripts = "C:\Users\d.ames\OneDrive - Avanade\Documents\GitHub\azure-powershell\PackagingFactoryConfig-main" # All files in this path will be copied up to the Storage Account Container, so available to be run on the remote VMs (includes template script for packaging share mapping

# Environment variables
$rbacOwner = "euc-rbac-owner"
$rbacContributor = "euc-rbac-contributor"
$rbacReadOnly = "euc-rbac-readonly"

#endregion Setup

function CreateStandardVM-Script($VMName) {
    $Vnet = Get-AzVirtualNetwork -Name $VNet -ResourceGroupName "rg-wl-prod-vnet"
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet
    $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Subnet.Id
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSizeStandard -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $VMCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-10' -Skus '20h2-ent' -Version 'latest'
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine -Verbose
}

function CreateAdminStudioVM-Script($VMName) {
    $Vnet = Get-AzVirtualNetwork -Name $VNet -ResourceGroupName "rg-wl-prod-vnet"
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet
    $NIC = New-AzNetworkInterface -Name "$VMName-nic" -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $Subnet.Id
    $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSizeAdminStudio -IdentityType SystemAssigned -Tags $tags
    $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $VMCred #-ProvisionVMAgent -EnableAutoUpdate
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsDesktop' -Offer 'Windows-10' -Skus '20h2-ent' -Version 'latest'
    $VirtualMachine = Set-AzVMBootDiagnostic -VM $VirtualMachine -Disable

    New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine -Verbose
}

function ConfigureStandardVM($VMName) {
    $PublicIpAddressName = $VMName + "-ip"
    $VMCreate = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Host "Virtual Machine $VMName created successfully"
        #if (!$requirePublicIPs) { 
        #    $VMNic = Get-AzNetworkInterface -Name $VMCreate.Name* -ResourceGroup $ResourceGroupName
        #    $VMNic.IpConfigurations.publicipaddress.id = $null
        #    Set-AzNetworkInterface -NetworkInterface $VMNic | Out-Null
        #    Remove-AzPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $ResourceGroupName -Force
        #}
        
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

        # Shutdown VM if $VMShutdown is true
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
    $PublicIpAddressName = $VMName + "-ip"
    $VMCreate = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Host "Virtual Machine $VMName created successfully"
        #if (!$requirePublicIPs) { 
        #    $VMNic = Get-AzNetworkInterface -Name $VMCreate.Name -ResourceGroup $ResourceGroupName
        #    $VMNic.IpConfigurations.publicipaddress.id = $null
        #    Set-AzNetworkInterface -NetworkInterface $VMNic | Out-Null
        #    Remove-AzPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $ResourceGroupName -Force
        #}
        
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
        RunVMConfig "$VMName" "https://$StorageAccountName.blob.core.windows.net/data/DesktopApps.ps1" "DesktopApps.ps1"
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

        # Shutdown VM if $VMShutdown is true
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
        ResourceGroupName = $ResourceGroupName
        VMName            = $VMName
        Location          = $Location
        FileUri           = $BlobFilePath
        Run               = $Blob
        Name              = "ConfigureVM"
    }

    $VMConfigure = Set-AzVMCustomScriptExtension @Params
    If ($VMConfigure.IsSuccessStatusCode -eq $True) { Write-Host "Virtual Machine $VMName configured with $Blob successfully" }Else { Write-Host "*** Unable to configure Virtual Machine $VMName with $Blob ***" }
}

function ScriptBuild-Create {
    switch ($Spec) {
        "Standard" {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $ResourceGroupName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $ResourceGroupName -Force -Verbose
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $ResourceGroupName | Remove-AzNetworkInterface -Force -Verbose
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $ResourceGroupName | Remove-AzPublicIpAddress -Force -Verbose
                Get-AzDisk -Name $VMName* -ResourceGroupName $ResourceGroupName | Remove-AzDisk -Force -Verbose
                CreateStandardVM-Script "$VMName"
            }
            else {
                Write-Host "Virtual Machine $VMName doesn't exist!"
                CreateStandardVM-Script "$VMName"
            }
        }
        "AdminStudio" {
            $VMCheck = Get-AzVM -Name "$VMName" -ResourceGroup $ResourceGroupName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($VMCheck) {
                Remove-AzVM -Name $VMName -ResourceGroupName $ResourceGroupName -Force -Verbose
                Get-AzNetworkInterface -Name $VMName* -ResourceGroupName $ResourceGroupName | Remove-AzNetworkInterface -Force -Verbose
                Get-AzPublicIpAddress -Name $VMName* -ResourceGroupName $ResourceGroupName | Remove-AzPublicIpAddress -Force -Verbose
                Get-AzDisk -Name $VMName* -ResourceGroupName $ResourceGroupName | Remove-AzDisk -Force -Verbose
                CreateAdminStudioVM-Script "$VMName"
            }
            else {
                Write-Host "Virtual Machine $VMName doesn't exist!"
                CreateAdminStudioVM-Script "$VMName"
            }
        }
    }
}

function ScriptBuild-Config {
    switch ($Spec) {
        "Standard" {
            ConfigureStandardVM "$VMName"
        }
        "AdminStudio" {
            ConfigureAdminStudioVM "$VMName"

        }
    }

}

function UpdateStorage {
    if ($true) {
        Try {
            $RGNameUAT = $ResourceGroupName
            $StorAcc = $StorageAccountName
            $Key = Get-AzStorageAccountKey -ResourceGroupName $RGNameUAT -AccountName $StorAcc
            $HyperVContent = (Get-Content -Path "$ContainerScripts\EnableHyperVTmpl.ps1").replace("xxxx", $StorAcc)
            $HyperVContent = $HyperVContent.replace("ssss", $azSubscription)
            $HyperVContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\EnableHyperV.ps1"      
            $VMConfigContent = (Get-Content -Path "$ContainerScripts\VMConfigTmpl.ps1").replace("xxxx", $StorAcc)
            $VMConfigContent = $VMConfigContent.replace("ssss", $azSubscription)
            $VMConfigContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\VMConfig.ps1"
            $RunOnceContent = (Get-Content -Path "$ContainerScripts\RunOnceTmpl.ps1").replace("xxxx", $StorAcc)
            $RunOnceContent = $RunOnceContent.replace("ssss", $azSubscription)
            $RunOnceContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\RunOnce.ps1"
            $AdminStudioContent = (Get-Content -Path "$ContainerScripts\AdminStudioTmpl.ps1").replace("xxxx", $StorAcc)
            $AdminStudioContent = $AdminStudioContent.replace("ssss", $azSubscription)
            $AdminStudioContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\AdminStudio.ps1"
            $ORCAContent = (Get-Content -Path "$ContainerScripts\ORCATmpl.ps1").replace("xxxx", $StorAcc)
            $ORCAContent = $ORCAContent.replace("ssss", $azSubscription)
            $ORCAContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\ORCA.ps1"
            $GlassWireContent = (Get-Content -Path "$ContainerScripts\GlassWireTmpl.ps1").replace("xxxx", $StorAcc)
            $GlassWireContent = $GlassWireContent.replace("ssss", $azSubscription)
            $GlassWireContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\GlassWire.ps1"
            $7zipContent = (Get-Content -Path "$ContainerScripts\7-ZipTmpl.ps1").replace("xxxx", $StorAcc)
            $7zipContent = $7zipContent.replace("ssss", $azSubscription)
            $7zipContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\7-Zip.ps1"
            $DesktopAppsContent = (Get-Content -Path "$ContainerScripts\DesktopAppsTmpl.ps1").replace("xxxx", $StorAcc)
            $DesktopAppsContent = $DesktopAppsContent.replace("ssss", $azSubscription)
            $DesktopAppsContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\DesktopApps.ps1"
            $InstEdContent = (Get-Content -Path "$ContainerScripts\InstEdTmpl.ps1").replace("xxxx", $StorAcc)
            $InstEdContent = $InstEdContent.replace("ssss", $azSubscription)
            $InstEdContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\InstEd.ps1"
            $IntuneWinUtilityContent = (Get-Content -Path "$ContainerScripts\IntuneWinUtilityTmpl.ps1").replace("xxxx", $StorAcc)
            $IntuneWinUtilityContent = $IntuneWinUtilityContent.replace("ssss", $azSubscription)
            $IntuneWinUtilityContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\IntuneWinUtility.ps1"

            $MapFileContent = (Get-Content -Path "$ContainerScripts\MapDrvTmpl.ps1").replace("xxxx", $StorAcc)
            $MapFileContent.replace("yyyy", $Key.value[0]) | Set-Content -Path "$ContainerScripts\MapDrv.ps1"      
            
        }
        Catch {
            Write-Error "An error occured trying to create the customised scripts for the packaging share."
            Write-Error $_.Exception.Message
        }
        #. .\SyncFiles.ps1 -CallFromCreatePackaging -Recurse        # Sync Files to Storage Blob
        . .\SyncFiles.ps1 -CallFromCreatePackaging                  # Sync Files to Storage Blob
        Write-Host "Storage Account has been Updated with files"
    }
}

#region Main
Write-Host "Running RebuildVM.ps1"

if($VMName -eq "") {
    $VMlist = Get-AzVM -Name * -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    $VMName = ($VMlist | where { $_.Name -ne "wleushyperv01" } | select Name | ogv -Title "Select Virtual Machine to Rebuild" -PassThru).Name
    if (!$VMName) {exit}
    $VMSpec = @("Standard","AdminStudio")
    $Spec = $VMSpec | ogv -Title "Select Virtual Machine Spec" -PassThru
}

#Write-Host "Syncing Files"
#UpdateStorage

Write-Host "Rebuilding $VMName"
Try {
    ScriptBuild-Create
    ScriptBuild-Config
} Catch {
    Write-Error $_.Exception.Message
}
Write-Host "Completed RebuildVM.ps1"
#endregion Main