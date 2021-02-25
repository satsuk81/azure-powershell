#region Setup
# Subscription ID If Required
$azSubscription = (Get-Content ".\subscriptions.txt")[0]

#$Cred = Get-Credential
#Connect-AzAccount -Subscription $azSubscription                    # MFA Account
#Connect-AzAccount -Credential $Cred -Subscription $azSubscription  # Non-MFA
#Connect-AzureAD -Credential $Cred                                  #Old Module

$RequireCreate = $false
$RequireConfigure = $false
$UseTerraform = $false
$RequireUpdateStorage = $true

# Which Script Components to Install
$RequireUserGroups = $false
$RequireRBAC = $false

$RequireResourceGroups = $true
$RequireStorageAccount = $true
$RequireVNET = $true
$RequireNSG = $true
$RequirePublicIPs = $true

$RequireHyperV = $false
$RequireStandardVMs = $true
$RequireAdminStudioVMs = $false

# General Variables
$location = "eastus"                                                # Azure Region for resources to be built into
$RGNameUAT = "rg-wl-prod-eucpackaging2"                              # UAT Resource group name
$RGNamePROD = "rg-wl-prod-eucpackaging2"                             # PROD Resource group name
$VNetUAT = "PackagingVnetUAT"                                       # Environment Virtual Network name
$VNetPROD = "PackagingVnetPROD"                                     # Environment Virtual Network name
$NsgNameUAT = "PackagingNsgUAT"                                     # Network Security Group name (firewall)
$NsgNamePROD = "PackagingNsgPROD"                                   # Network Security Group name (firewall)

# Environment variables
$rbacOwner = "euc-rbac-owner"
$rbacContributor = "euc-rbac-contributor"
$rbacReadOnly = "euc-rbac-readonly"

# Storage Account and Container Names
$StorAccRequired = $RequireStorageAccount                           # Specifies if a Storage Account and Container should be created
$StorAcc = "stwleucpackaging02"                                     # Storage account name (if used)
$ContainerName = "data"                                             # Storage container name (if used)
$ContainerScripts = "C:\Users\d.ames\OneDrive - Avanade\Documents\GitHub\azure-powershell\PackagingFactoryConfig-main" # All files in this path will be copied up to the Storage Account Container, so available to be run on the remote VMs (includes template script for packaging share mapping
$MapFileTmpl = "MapDrvTmpl.ps1"                                     # Filename of Script template for mapping drive to Packaging file share
#$MapDriveCmd = 'New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "MapPackagingDrive" -Value 'powershell -ExecutionPolicy Unrestricted -Command cmd.exe /C "cmdkey /add:`"xxxx.file.core.windows.net`" /user:`"Azure\xxxx`" /pass:`"yyyy`"" ; New-PSDrive -Name L -PSProvider FileSystem -Root "\\xxxx.file.core.windows.net\packaging" -Persist' -PropertyType "String"'                                  

# VM Admin Account
$password = Get-Content ".\password.txt" | ConvertTo-SecureString -AsPlainText -Force                       # Local Admin Password for VMs 
$VMCred = New-Object System.Management.Automation.PSCredential ("AppPackager", $password)   # Local Admin User for VMs

# VM Count and Name
$NumberofStandardVMs = 1                                            # Specify number of Standard VMs to be provisioned
$NumberofAdminStudioVMs = 1                                         # Specify number of AdminStudio VMs to be provisioned
$VMNamePrefixStandard = "vmwleucvan2"                                # Specifies the first part of the Standard VM name (usually alphabetic)
$VMNamePrefixAdminStudio = "vmwleucvan2"                             # Specifies the first part of the Admin Studio VM name (usually alphabetic)
$VMNumberStartStandard = 101                                        # Specifies the second part of the Standard VM name (usually numeric)
$VMNumberStartAdminStudio = 201                                     # Specifies the second part of the Admin Studio VM name (usually numeric)
$VMSizeStandard = "Standard_B2s"                                    # Specifies Azure Size to use for the Standard VM
$VMSizeAdminStudio = "Standard_D2_v2"                               # Specifies Azure Size to use for the Admin Studio VM
$VMImage = "MicrosoftWindowsDesktop:Windows-10:20h2-ent:latest"     # Specifies the Publisher, Offer, SKU and Version of the image to be used to provision the VM
$VMShutdown = $true                                                 # Specifies if the newly provisioned VM should be shutdown (can save costs)
$AutoShutdown = $true                                               # Configures Windows 10 VMs to shutdown at a specified time                                             
$SubnetName = "default"

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"  # Turns off Breaking Changes warnings for Cmdlets
#endregion Setup

function UpdateStorage {
    if ($RequireUpdateStorage) {
        Try {
            $Key = Get-AzStorageAccountKey -ResourceGroupName $RGNameUAT -AccountName $StorAcc
            $HyperVContent = (Get-Content -Path "$ContainerScripts\EnableHyperVTmpl.ps1").replace("xxxx", $StorAcc)
            $HyperVContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\EnableHyperV.ps1"      
            $MapFileContent = (Get-Content -Path "$ContainerScripts\$MapFileTmpl").replace("xxxx", $StorAcc) #| Set-Content -path "$ContainerScripts\MapDrv.ps1"
            $MapFileContent.replace("yyyy", $Key.value[0]) | Set-Content -Path "$ContainerScripts\MapDrv.ps1"      
            $VMConfigContent = (Get-Content -Path "$ContainerScripts\VMConfigTmpl.ps1").replace("xxxx", $StorAcc)
            $VMConfigContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\VMConfig.ps1"
            $RunOnceContent = (Get-Content -Path "$ContainerScripts\RunOnceTmpl.ps1").replace("xxxx", $StorAcc)
            $RunOnceContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\RunOnce.ps1"
            $AdminStudioContent = (Get-Content -Path "$ContainerScripts\AdminStudioTmpl.ps1").replace("xxxx", $StorAcc)
            $AdminStudioContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\AdminStudio.ps1"
            $ORCAContent = (Get-Content -Path "$ContainerScripts\ORCATmpl.ps1").replace("xxxx", $StorAcc)
            $ORCAContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\ORCA.ps1"
            $GlassWireContent = (Get-Content -Path "$ContainerScripts\GlassWireTmpl.ps1").replace("xxxx", $StorAcc)
            $GlassWireContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\GlassWire.ps1"
            $7zipContent = (Get-Content -Path "$ContainerScripts\7-ZipTmpl.ps1").replace("xxxx", $StorAcc)
            $7zipContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\7-Zip.ps1"
            $DesktopAppsContent = (Get-Content -Path "$ContainerScripts\DesktopAppsTmpl.ps1").replace("xxxx", $StorAcc)
            $DesktopAppsContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\DesktopApps.ps1"
            $InstEdContent = (Get-Content -Path "$ContainerScripts\InstEdTmpl.ps1").replace("xxxx", $StorAcc)
            $InstEdContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\InstEd.ps1"
            $IntuneWinUtilityContent = (Get-Content -Path "$ContainerScripts\IntuneWinUtilityTmpl.ps1").replace("xxxx", $StorAcc)
            $IntuneWinUtilityContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\IntuneWinUtility.ps1"
        }
        Catch {
            Write-Error "An error occured trying to create the customised scripts for the packaging share."
            Write-Error $_.Exception.Message
        }
        . .\SyncFiles.ps1 -CallFromCreatePackaging -Recurse            # Sync Files to Storage Blob
        #. .\SyncFiles.ps1 -CallFromCreatePackaging            # Sync Files to Storage Blob
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

# Main Script

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
    UpdateRBAC

    # Configure Packaging VM Script
    .\CreatePackagingEnv-PackagingVms-Configure.ps1

    # Configure Hyper-V Script
    if($RequireHyperV) {
        .\CreatePackagingEnv-HyperVServer-Configure.ps1
    }
}
Write-Host "All Scripts Completed"
#endregion Main