#region Setup
cd $PSScriptRoot

Import-Module Az.Compute, Az.Accounts, Az.Storage, Az.Network, Az.Resources -ErrorAction SilentlyContinue
if (!((Get-Module Az.Compute) -and (Get-Module Az.Accounts) -and (Get-Module Az.Storage) -and (Get-Module Az.Network) -and (Get-Module Az.Resources))) {
    Install-Module Az.Compute, Az.Accounts, Az.Storage, Az.Network, Az.Resources -Repository PSGallery -Scope CurrentUser -Force
    Import-Module AZ.Compute, Az.Accounts, Az.Storage, Az.Network, Az.Resources
}

Clear-AzContext -Force

    # Tenant ID
$azTenant = (Get-Content ".\tenants.txt")[1]                    # 1 is LIVE

    # Subscription ID If Required
$azSubscription = (Get-Content ".\subscriptions.txt")[2]        # 2 is LIVE

Connect-AzAccount -Tenant $aztenant -Subscription $azSubscription

$SubscriptionId = (Get-AzContext).Subscription.Id
if (!($azSubscription -eq $SubscriptionId)) {
    Write-Error "Subscription ID Mismatch!!!!"
    exit
}
Get-AzContext | Rename-AzContext -TargetName "User" -Force

$StorageSP = Import-Clixml .\StorageSP.xml
Connect-AzAccount -Tenant $azTenant -Subscription $azSubscription -Credential $StorageSP -ServicePrincipal
Get-AzContext | Rename-AzContext -TargetName "StorageSP" -Force
Get-AzContext -Name "User" | Select-AzContext

$RequireCreate = $true
$RequireConfigure = $true
$UseTerraform = $false
$RequireUpdateStorage = $true

    # Which Script Components to Install
$RequireUserGroups = $false
$RequireRBAC = $false

$RequireResourceGroups = $false
$RequireStorageAccount = $false
$RequireVNET = $false
$RequireNSG = $false
$RequirePublicIPs = $false

$RequireHyperV = $true
$RequireStandardVMs = $false
$RequireAdminStudioVMs = $false
$RequireJumpboxVMs = $false

    # General Variables
$location = "eastus"                                            # Azure Region for resources to be built into
$RGNameUAT = "rg-wl-prod-packaging"                             # UAT Resource group name
$RGNamePROD = "rg-wl-prod-packaging"                            # PROD Resource group name
$ResourceGroupName = $RGNamePROD
$RGNameVNET = "rg-wl-prod-vnet"                                 # VNET Resource group name
#$RGNameVNET = "rg-wl-prod-packaging"                            # VNET Resource group name
$VNetUAT = "vnet-wl-eus-prod"                                   # UAT Environment Virtual Network name
$VNetPROD = "vnet-wl-eus-prod"                                  # PROD Environment Virtual Network name
$SubnetName = "snet-wl-eus-prod-packaging"                      # Environment Virtual Subnet name
#$SubnetName = "default"                                         # Environment Virtual Subnet name
$NsgNameUAT = "nsg-wl-eus-prod-packaging"                       # UAT Network Security Group name (firewall)
$NsgNamePROD = "nsg-wl-eus-prod-packaging"                      # PROD Network Security Group name (firewall)

    # Environment variables
$rbacOwner = "euc-rbac-owner"
$rbacContributor = "euc-rbac-contributor"
$rbacReadOnly = "euc-rbac-readonly"

    # Storage Account and Container Names
$StorAccRequired = $RequireStorageAccount                       # Specifies if a Storage Account and Container should be created
$StorAcc = "wlprodeusprodpkgstr01"                              # Storage account name (if used) (24 chars maximum)
#$StorAcc = "wlprodeusprodpkgstr02"                              # Storage account name (if used) (24 chars maximum)
$StorageAccountName = $StorAcc
$ContainerName = "data"                                         # Storage container name (if used)
$FileShareName = "pkgazfiles01"                                 # Storage FileShare name (if used)
$ContainerScripts = "C:\Users\d.ames\OneDrive - Avanade\Documents\GitHub\azure-powershell\PackagingFactoryConfig-main" # All files in this path will be copied up to the Storage Account Container, so available to be run on the remote VMs (includes template script for packaging share mapping

    # VM Admin Account
$password = Get-Content ".\password.txt" | ConvertTo-SecureString -AsPlainText -Force           # Local Admin Password for VMs 
$VMCred = New-Object System.Management.Automation.PSCredential ("AppPackager", $password)       # Local Admin User for VMs

    # VM Count, Name, Spec, and Settings
$NumberofStandardVMs = 1                                        # Specify number of Standard VMs to be provisioned
$NumberofAdminStudioVMs = 0                                     # Specify number of AdminStudio VMs to be provisioned
$NumberofJumpboxVMs = 0                                         # Specify number of Jumpbox VMs to be provisioned
$VMNamePrefixStandard = "vmwleusvan"                            # Specifies the first part of the Standard VM name (usually alphabetic) (15 chars max)
$VMNamePrefixAdminStudio = "vmwleusas"                          # Specifies the first part of the Admin Studio VM name (usually alphabetic) (15 chars max)
$VMNamePrefixJumpbox = "vmwleusjb"                              # Specifies the first part of the Jumpbox VM name (usually alphabetic) (15 chars max)
$VMNumberStartStandard = 101                                    # Specifies the second part of the Standard VM name (usually numeric)
$VMNumberStartAdminStudio = 201                                 # Specifies the second part of the Admin Studio VM name (usually numeric)
$VMNumberStartJumpbox = 301                                     # Specifies the second part of the Jumpbox VM name (usually numeric)
$VMSizeStandard = "Standard_B2s"                                # Specifies Azure Size to use for the Standard VM
$VMSizeAdminStudio = "Standard_B2s"                             # Specifies Azure Size to use for the Admin Studio VM
$VMSizeJumpbox = "Standard_B2s"                                 # Specifies Azure Size to use for the Jumpbox VM
    # Specifies the Publisher, Offer, SKU and Version of the image to be used
$VMSpecPublisherName = "MicrosoftWindowsDesktop"
$VMSpecOffer = "Windows-10"
$VMSpecSKUS = "20h2-ent"
$VMSpecVersion = "latest"
$VMShutdown = $true                                             # Specifies if the newly provisioned VM should be shutdown (can save costs)
$AutoShutdown = $true                                           # Configures Windows 10 VMs to shutdown at a specified time                                             

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"  # Turns off Breaking Changes warnings for Cmdlets
#endregion Setup

function UpdateStorage {
    if ($RequireUpdateStorage) {
        Try {
            $Key = Get-AzStorageAccountKey -ResourceGroupName $RGNameUAT -AccountName $StorAcc
            $HyperVContent = (Get-Content -Path "$ContainerScripts\EnableHyperVTmpl.ps1").replace("xxxx", $StorAcc)
            $HyperVContent = $HyperVContent.replace("ssss", $azSubscription)
            $HyperVContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\EnableHyperV.ps1"      
            $VMConfigContent = (Get-Content -Path "$ContainerScripts\VMConfigTmpl.ps1").replace("xxxx", $StorAcc)
            $VMConfigContent = $VMConfigContent.replace("ssss", $azSubscription)
            $VMConfigContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\VMConfig.ps1"
            $DomainJoinContent = (Get-Content -Path "$ContainerScripts\DomainJoinTmpl.ps1").replace("xxxx", $StorAcc)
            $DomainJoinContent = $DomainJoinContent.replace("ssss", $azSubscription)
            $DomainJoinContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\DomainJoin.ps1"
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
function UpdateRBAC {
    Try {
        $OwnerGroup = Get-AzADGroup -DisplayName $rbacOwner
        $ContributorGroup = Get-AzADGroup -DisplayName $rbacContributor
        $ReadOnlyGroup = Get-AzADGroup -DisplayName $rbacReadOnly

        New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName "Owner" -ResourceGroupName $RGNamePROD | Out-Null
        New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName "Contributor" -ResourceGroupName $RGNamePROD | Out-Null
        New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName "Reader" -ResourceGroupName $RGNamePROD | Out-Null
        if (!($RGNameUAT -match $RGNamePROD)) {
            New-AzRoleAssignment -ObjectId $OwnerGroup.Id -RoleDefinitionName "Owner" -ResourceGroupName $RGNameUAT | Out-Null
            New-AzRoleAssignment -ObjectId $ContributorGroup.Id -RoleDefinitionName "Contributor" -ResourceGroupName $RGNameUAT | Out-Null
            New-AzRoleAssignment -ObjectId $ReadOnlyGroup.Id -RoleDefinitionName "Reader" -ResourceGroupName $RGNameUAT | Out-Null
        }
        Write-Host "Role Assignments Set"
    } Catch {
        Write-Error $_.Exception.Message
    }
}

#region Main
#=======================================================================================================================================================
Set-Location $PSScriptRoot

if($RequireCreate) {
        # Create Resource Groups
    if($RequireResourceGroups -and !$UseTerraform) {
        $RG = New-AzResourceGroup -Name $RGNamePROD -Location $Location
        if ($RG.ResourceGroupName -eq $RGNamePROD) {Write-Host "PROD Resource Group created successfully"}Else{Write-Host "*** Unable to create PROD Resource Group! ***"}
        if (!($RGNameUAT -match $RGNamePROD)) {
            $RG = New-AzResourceGroup -Name $RGNameUAT -Location $Location
            if ($RG.ResourceGroupName -eq $RGNameUAT) { Write-Host "UAT Resource Group created successfully" }Else { Write-Host "*** Unable to create UAT Resource Group! ***" }
        }
    }
    if ($UseTerraform) {
        $TerraformMainTemplate = Get-Content -Path ".\Terraform\Root Template\main.tf" | Set-Content -Path ".\Terraform\main.tf"    
    }

        # Environment Script
    .\CreatePackagingEnv-Env-V2.ps1

        # Create Packaging VM Script
    .\CreatePackagingEnv-PackagingVms-V2.ps1

        # Create Hyper-V Script
    if ($RequireHyperV) {
        .\CreatePackagingEnv-HyperVServer-V1.ps1
    }

    if($UseTerraform) {
        cd .\terraform
        $ARGUinit = "init"
        $ARGUplan = "plan -out .\terraform.tfplan"
        $ARGUapply = "apply -auto-approve .\terraform.tfplan"
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUinit -Wait -RedirectStandardOutput .\terraform-init.txt -RedirectStandardError .\terraform-error-init.txt
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUplan -Wait -RedirectStandardOutput .\terraform-plan.txt -RedirectStandardError .\terraform-error-plan.txt
        Start-Process -FilePath .\terraform.exe -ArgumentList $ARGUapply -Wait -RedirectStandardOutput .\terraform-apply.txt -RedirectStandardError .\terraform-error-apply.txt
        cd ..
    }
}

    # Update Storage
if($RequireUpdateStorage) {
    UpdateStorage
}

if ($RequireConfigure) {
        # Update RBAC
    #UpdateRBAC

        # Configure Packaging VM Script
    .\CreatePackagingEnv-PackagingVms-Configure.ps1

        # Configure Hyper-V Script
    if($RequireHyperV) {
        .\CreatePackagingEnv-HyperVServer-Configure.ps1
    }
}
Write-Host "All Scripts Completed"
#endregion Main