$Cred = Get-Credential

Connect-AzAccount -Credential $Cred
Connect-AzureAD -Credential $Cred

# General variables
$location = "UKSouth"                                               # Azure Region for resources to be built into
$RGName = "HiggCon"                                                 # Resource group name
$VNet = "PackagingVNET"                                             # Environment Virtual Network name
$NsgName = "PackagingNSG"                                           # Network Security Group name (firewall)

# Storage account and container names
$StorAccRequired = $true                                            # Specifies if a Storage Account and Container should be created
$StorAcc = "packagingstoracc"                                       # Storage account name (if used)
$ContainerName = "data"                                             # Storage container name (if used)
$ContainerScripts = "C:\Temp\PackagingVM\Config"                    # All files in this path will be copied up to the Storage Account Container, so available to be run on the remote VMs (includes template script for packaging share mapping
$MapFileTmpl = "MapDrvTmpl.ps1"                                       # Filename of Script template for mapping drive to Packaging file share
#$MapDriveCmd = 'New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "MapPackagingDrive" -Value 'powershell -ExecutionPolicy Unrestricted -Command cmd.exe /C "cmdkey /add:`"xxxx.file.core.windows.net`" /user:`"Azure\xxxx`" /pass:`"yyyy`"" ; New-PSDrive -Name L -PSProvider FileSystem -Root "\\xxxx.file.core.windows.net\packaging" -Persist' -PropertyType "String"'                                  

# VM Admin Account
$password = ConvertTo-SecureString “Password1234” -AsPlainText -Force                       # Local Admin Password for VMs 
$VMCred = New-Object System.Management.Automation.PSCredential (“AppPackager”, $password)   # Local Admin User for VMs

# VM Count and Name
$NumberofVMs = 1                                                    # Specify number of VMs to be provisioned
$VmNamePrefix = "PVMMSI"                                            # Specifies the first part of the VM name (usually alphabetic)
$VmNumberStart = 500                                                # Specifies the second part of the VM name (usually numeric)
$VmSize = "Standard_B2s"                                            # Specifies Azure Size to use for the VM
$VmImage = "MicrosoftWindowsDesktop:Windows-10:20h2-ent:latest"     # Specifies the Publisher, Offer, SKU and Version of the image to be used to provision the VM
$VmShutdown = $true                                                 # Specifies if the newly provisioned VM should be shutdown (can save costs)
$AutoShutdown = $True                                               # Configures Windows 10 VMs to shutdown at a specified time                                             

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"                          # Turns off Breaking Changes warnings for Cmdlets

#=======================================================================================================================================================

# Main Script

# Create Resource Group
$RG = New-AzResourceGroup -Name $RGName -Location $Location
If ($RG.ResourceGroupName -eq $RGName) {Write-Host "Resource Group created successfully"}Else{Write-Host "*** Unable to create Resource Group! ***"}


# Call additional scripts

# Environment Script
.\CreatePackagingEnv-Env-V1.ps1

# Environment Script
.\CreatePackagingEnv-PackagingVms-V1.ps1

# Environment Script
.\CreatePackagingEnv-HyperVServer-V1.ps1
