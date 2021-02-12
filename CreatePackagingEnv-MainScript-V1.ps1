$RequireCreate = $false
$RequireConfigure = $true
$UseTerraform = $false

# Which Script Components to Install
$RequireResourceGroups = $true
$RequireUserGroups = $false
$RequireRBAC = $false
$RequireStorageAccount = $true
$RequireUpdateStorage = $true
$RequireVNET = $true
$RequireNSG = $true
$RequirePublicIPs = $true

$RequireHyperV = $true
$RequireStandardVMs = $false
$RequireAdminStudioVMs = $false


# Subscription ID If Required
#$azSubscription = '743e9d63-59c8-42c3-b823-28bb773a88a6'
$azSubscription = '1c3b43a4-90da-4988-9598-cab119913f5d'

# General Variables
$location = "eastus"                                               # Azure Region for resources to be built into
$RGNameUAT = "rg-wl-prod-eucpackaging"                              # UAT Resource group name
$RGNamePROD = "rg-wl-prod-eucpackaging"                             # PROD Resource group name
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
$StorAcc = "stwleucpackaging01"                                     # Storage account name (if used)
$ContainerName = "data"                                             # Storage container name (if used)
$ContainerScripts = "C:\Users\d.ames\OneDrive - Avanade\Documents\GitHub\azure-powershell\PackagingFactoryConfig-main" # All files in this path will be copied up to the Storage Account Container, so available to be run on the remote VMs (includes template script for packaging share mapping
$MapFileTmpl = "MapDrvTmpl.ps1"                                     # Filename of Script template for mapping drive to Packaging file share
#$MapDriveCmd = 'New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "MapPackagingDrive" -Value 'powershell -ExecutionPolicy Unrestricted -Command cmd.exe /C "cmdkey /add:`"xxxx.file.core.windows.net`" /user:`"Azure\xxxx`" /pass:`"yyyy`"" ; New-PSDrive -Name L -PSProvider FileSystem -Root "\\xxxx.file.core.windows.net\packaging" -Persist' -PropertyType "String"'                                  

# VM Admin Account
$password = ConvertTo-SecureString “Password1234” -AsPlainText -Force                       # Local Admin Password for VMs 
$VMCred = New-Object System.Management.Automation.PSCredential (“AppPackager”, $password)   # Local Admin User for VMs

# VM Count and Name
$NumberofStandardVMs = 1                                            # Specify number of Standard VMs to be provisioned
$NumberofAdminStudioVMs = 1                                         # Specify number of AdminStudio VMs to be provisioned
$VMNamePrefixStandard = "vmwleucvan"                                # Specifies the first part of the Standard VM name (usually alphabetic)
$VMNamePrefixAdminStudio = "vmwleucvan"                              # Specifies the first part of the Admin Studio VM name (usually alphabetic)
$VMNumberStartStandard = 101                                        # Specifies the second part of the Standard VM name (usually numeric)
$VMNumberStartAdminStudio = 201                                     # Specifies the second part of the Admin Studio VM name (usually numeric)
$VMSizeStandard = "Standard_B2s"                                    # Specifies Azure Size to use for the Standard VM
$VMSizeAdminStudio = "Standard_D2_v2"                               # Specifies Azure Size to use for the Admin Studio VM
$VMImage = "MicrosoftWindowsDesktop:Windows-10:20h2-ent:latest"     # Specifies the Publisher, Offer, SKU and Version of the image to be used to provision the VM
$VMShutdown = $true                                                 # Specifies if the newly provisioned VM should be shutdown (can save costs)
$AutoShutdown = $true                                               # Configures Windows 10 VMs to shutdown at a specified time                                             
$SubnetName = "default"

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"  # Turns off Breaking Changes warnings for Cmdlets

function UpdateStorage {
    if ($RequireUpdateStorage) {
        Try {
            $Key = Get-AzStorageAccountKey -ResourceGroupName $RGNameUAT -AccountName $StorAcc
            $MapFileContent = (Get-Content -Path "$ContainerScripts\$MapFileTmpl").replace("xxxx", $StorAcc) #| Set-Content -path "$ContainerScripts\MapDrv.ps1"
            $MapFileContent.replace("yyyy", $Key.value[0]) | Set-Content -Path "$ContainerScripts\MapDrv.ps1"      
            $RunOnceContent = (Get-Content -Path "$ContainerScripts\RunOnceTmpl.ps1").replace("xxxx", $StorAcc)
            $RunOnceContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\RunOnce.ps1"
            $AdminStudioContent = (Get-Content -Path "$ContainerScripts\AdminStudioTmpl.ps1").replace("xxxx", $StorAcc)
            $AdminStudioContent.replace("rrrr", $RGNameUAT) | Set-Content -Path "$ContainerScripts\AdminStudio.ps1"
        }
        Catch {
            Write-Error "An error occured trying to create the customised scripts for the packaging share."
            Write-Error $_.Exception.Message
        }
        . .\SyncFiles.ps1 -CallFromCreatePackaging             # Sync Files to Storage Blob
        Write-Host "Storage Account has been Updated with files"
    }
}

#=======================================================================================================================================================

# Main Script

Set-Location $PSScriptRoot

#$Cred = Get-Credential
#Connect-AzAccount -Subscription $azSubscription                    # MFA Account
#Connect-AzAccount -Credential $Cred -Subscription $azSubscription  # Non-MFA
#Connect-AzureAD -Credential $Cred                                  #Old Module

# Create Resource Groups
if($RequireResourceGroups) {
    $RG = New-AzResourceGroup -Name $RGNamePROD -Location $Location
    if ($RG.ResourceGroupName -eq $RGNamePROD) {Write-Host "PROD Resource Group created successfully"}Else{Write-Host "*** Unable to create PROD Resource Group! ***"}
    if (!($RGNameUAT -match $RGNamePROD)) {
        $RG = New-AzResourceGroup -Name $RGNameUAT -Location $Location
        if ($RG.ResourceGroupName -eq $RGNameUAT) { Write-Host "UAT Resource Group created successfully" }Else { Write-Host "*** Unable to create UAT Resource Group! ***" }
    }
}

if($RequireCreate) {
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
    # Configure Packaging VM Script
    .\CreatePackagingEnv-PackagingVms-Configure.ps1

    # Configure Hyper-V Script
    if($RequireHyperV) {
        .\CreatePackagingEnv-HyperVServer-Configure.ps1
    }
}
Write-Host "All Scripts Completed"