Param(
    [Parameter(Mandatory = $false)][string]$RVMVMName = "",
    [Parameter(Mandatory = $false)][ValidateSet('Standard', 'AdminStudio')][string]$RVMSpec = "Standard"
)

#region Setup
# Subscription ID If Required
$azSubscription = (Get-Content ".\subscriptions.txt")[0]

#Connect-AzAccount -Subscription $azSubscription # MFA Account
#Connect-AzAccount -Credential $Cred -Subscription $azSubscription # Non-MFA

# VM Admin Account
$password = Get-Content ".\password.txt" | ConvertTo-SecureString -AsPlainText -Force       # Local Admin Password for VMs 
$RVMVMCred = New-Object System.Management.Automation.PSCredential ("AppPackager", $password)   # Local Admin User for VMs

$RequirePublicIPs = $true
$RVMResourceGroupName = "rg-wl-prod-eucpackaging2"
$RVMStorageAccountName = "stwleucpackaging02"
$RVMContainerName = "data"
$RVMVNet = "PackagingVnetPROD"                                     # Environment Virtual Network name
$RVMNsgName = "PackagingNsgPROD"
$VMSizeStandard = "Standard_B2s"                                    # Specifies Azure Size to use for the Standard VM
$VMSizeAdminStudio = "Standard_D2_v2" 
$VMImage = "MicrosoftWindowsDesktop:Windows-10:20h2-ent:latest"     # Specifies the Publisher, Offer, SKU and Version of the image to be used to provision the VM
$VMShutdown = $false                                                 # Specifies if the newly provisioned VM should be shutdown (can save costs)
$AutoShutdown = $true                                               # Configures Windows 10 VMs to shutdown at a specified time                                             
$RVMSubnetName = "default"
$RVMLocation = "eastus"  

# Environment variables
$rbacOwner = "euc-rbac-owner"
$rbacContributor = "euc-rbac-contributor"
$rbacReadOnly = "euc-rbac-readonly"

cd $PSScriptRoot
#endregion Setup

function CreateStandardVM-Script($VMName) {
    $PublicIpAddressName = $VMName + "-ip"

    $Params = @{
        ResourceGroupName   = $RVMResourceGroupName
        Name                = $VMName
        Size                = $VMSizeStandard
        Location            = $RVMLocation
        VirtualNetworkName  = $RVMVNet
        SubnetName          = $RVMSubnetName
        SecurityGroupName   = $RVMNsgName
        PublicIpAddressName = $PublicIpAddressName
        ImageName           = $VMImage
        Credential          = $RVMVMCred
    }

    $VMCreate = New-AzVM @Params -SystemAssignedIdentity
}

function CreateAdminStudioVM-Script($VMName) {
    $PublicIpAddressName = $VMName + "-ip"

    $Params = @{
        ResourceGroupName   = $RVMResourceGroupName
        Name                = $VMName
        Size                = $VMSizeAdminStudio
        Location            = $RVMLocation
        VirtualNetworkName  = $RVMVNet
        SubnetName          = $RVMSubnetName
        SecurityGroupName   = $RVMNsgName
        PublicIpAddressName = $PublicIpAddressName
        ImageName           = $VMImage
        Credential          = $RVMVMCred
    }

    $VMCreate = New-AzVM @Params -SystemAssignedIdentity
}

function ScriptBuild-Create {
    switch($RVMSpec) {
        "Standard" {
            $VMCheck = Get-AzVM -Name "$RVMVMName" -ResourceGroup $RVMResourceGroupName
            if ($VMCheck) {
                Remove-AzVM -Name $RVMVMName -ResourceGroupName $RVMResourceGroupName -Force -Verbose
                Get-AzNetworkInterface -Name $RVMVMName* -ResourceGroupName $RVMResourceGroupName | Remove-AzNetworkInterface -Force -Verbose
                Get-AzPublicIpAddress -Name $RVMVMName* -ResourceGroupName $RVMResourceGroupName | Remove-AzPublicIpAddress -Force -Verbose
                Get-AzDisk -Name $RVMVMName* -ResourceGroupName $RVMResourceGroupName | Remove-AzDisk -Force -Verbose
                CreateStandardVM-Script "$RVMVMName"
            }
            else {
                Write-Host "Virtual Machine $RVMVMName doesn't exist!"
                CreateStandardVM-Script "$RVMVMName"
            }
        }
        "AdminStudio" {
            $VMCheck = Get-AzVM -Name "$RVMVMName" -ResourceGroup $RVMResourceGroupName
            if ($VMCheck) {
                Remove-AzVM -Name $RVMVMName -ResourceGroupName $RVMResourceGroupName -Force -Verbose
                Get-AzNetworkInterface -Name $RVMVMName* -ResourceGroupName $RVMResourceGroupName | Remove-AzNetworkInterface -Force -Verbose
                Get-AzPublicIpAddress -Name $RVMVMName* -ResourceGroupName $RVMResourceGroupName | Remove-AzPublicIpAddress -Force -Verbose
                Get-AzDisk -Name $RVMVMName* -ResourceGroupName $RVMResourceGroupName | Remove-AzDisk -Force -Verbose
                CreateAdminStudioVM-Script "$RVMVMName"
            }
            else {
                Write-Host "Virtual Machine $RVMVMName doesn't exist!"
                CreateAdminStudioVM-Script "$RVMVMName"
            }
        }
    }
}

function ConfigureStandardVM($VMName) {
    $PublicIpAddressName = $VMName + "-ip"
    $VMCreate = Get-AzVM -ResourceGroupName $RVMResourceGroupName -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Host "Virtual Machine $VMName created successfully"
        if (!$requirePublicIPs) { 
            $VMNic = Get-AzNetworkInterface -Name $VMCreate.Name -ResourceGroup $RVMResourceGroupName
            $VMNic.IpConfigurations.publicipaddress.id = $null
            Set-AzNetworkInterface -NetworkInterface $VMNic | Out-Null
            Remove-AzPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $RVMResourceGroupName -Force
        }
        if ($AutoShutdown) {
            $VMName = $VMCreate.Name
            $SubscriptionId = (Get-AzContext).Subscription.Id
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$RVMResourceGroupName/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800 })
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $RVMLocation -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Host "Auto Shutdown Enabled for 1800"
        }
        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        $Group = Get-AzADGroup -searchstring $rbacContributor
        Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id -Verbose

        Restart-AzVM -ResourceGroupName $RVMResourceGroupName -Name $VMName | Out-Null
        Write-Host "Restarting VM..."
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/ORCA.ps1" "ORCA.ps1"
        #RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/GlassWire.ps1" "GlassWire.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/7-Zip.ps1" "7-Zip.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/InstEd.ps1" "InstEd.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/IntuneWinUtility.ps1" "IntuneWinUtility.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/DesktopApps.ps1" "DesktopApps.ps1"
        
        # Shutdown VM if $VMShutdown is true
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $RVMResourceGroupName -Name $VMName -Force
            if ($Stopvm.Status -eq "Succeeded") { Write-Host "VM $VMName shutdown successfully" }Else { Write-Host "*** Unable to shutdown VM $VMName! ***" }
        }
    }
    Else {
        Write-Host "*** Unable to configure Virtual Machine $VMName! ***"
    }
}

function ConfigureAdminStudioVM($VMName) {
    $PublicIpAddressName = $VMName + "-ip"
    $VMCreate = Get-AzVM -ResourceGroupName $RVMResourceGroupName -Name $VMName
    If ($VMCreate.ProvisioningState -eq "Succeeded") {
        Write-Host "Virtual Machine $VMName created successfully"
        if (!$requirePublicIPs) { 
            $VMNic = Get-AzNetworkInterface -Name $VMCreate.Name -ResourceGroup $RVMResourceGroupName
            $VMNic.IpConfigurations.publicipaddress.id = $null
            Set-AzNetworkInterface -NetworkInterface $VMNic | Out-Null
            Remove-AzPublicIpAddress -Name $PublicIpAddressName -ResourceGroupName $RVMResourceGroupName -Force
        }
        if ($AutoShutdown) {
            $VMName = $VMCreate.Name
            $SubscriptionId = (Get-AzContext).Subscription.Id
            $VMResourceId = $VMCreate.Id
            $ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/$RVMResourceGroupName/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

            $Properties = @{}
            $Properties.Add('status', 'Enabled')
            $Properties.Add('taskType', 'ComputeVmShutdownTask')
            $Properties.Add('dailyRecurrence', @{'time' = 1800 })
            $Properties.Add('timeZoneId', "GMT Standard Time")
            $Properties.Add('notificationSettings', @{status = 'Disabled'; timeInMinutes = 15 })
            $Properties.Add('targetResourceId', $VMResourceId)
            New-AzResource -Location $RVMLocation -ResourceId $ScheduledShutdownResourceId -Properties $Properties -Force | Out-Null
            Write-Host "Auto Shutdown Enabled for 1800"
        }
        $NewVm = Get-AzADServicePrincipal -DisplayName $VMName
        $Group = Get-AzADGroup -searchstring $rbacContributor
        Add-AzADGroupMember -TargetGroupObjectId $Group.Id -MemberObjectId $NewVm.Id

        Restart-AzVM -ResourceGroupName $RVMResourceGroupName -Name $VMName | Out-Null
        Write-Host "Restarting VM..."
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/RunOnce.ps1" "RunOnce.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/AdminStudio.ps1" "AdminStudio.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/ORCA.ps1" "ORCA.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/GlassWire.ps1" "GlassWire.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/7-Zip.ps1" "7-Zip.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/InstEd.ps1" "InstEd.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/IntuneWinUtility.ps1" "IntuneWinUtility.ps1"
        RunVMConfig "$VMName" "https://$RVMStorageAccountName.blob.core.windows.net/data/DesktopApps.ps1" "DesktopApps.ps1"
        
        # Shutdown VM if $VMShutdown is true
        if ($VMShutdown) {
            $Stopvm = Stop-AzVM -ResourceGroupName $RVMResourceGroupName -Name $VMName -Force
            if ($Stopvm.Status -eq "Succeeded") { Write-Host "VM $VMName shutdown successfully" }Else { Write-Host "*** Unable to shutdown VM $VMName! ***" }
        }
    }
    Else {
        Write-Host "*** Unable to configure Virtual Machine $VMName! ***"
    }
}

function RunVMConfig($VMName, $BlobFilePath, $Blob) {

    $Params = @{
        ResourceGroupName = $RVMResourceGroupName
        VMName            = $VMName
        Location          = $RVMLocation
        FileUri           = $BlobFilePath
        Run               = $Blob
        Name              = "ConfigureVM"
    }

    $VMConfigure = Set-AzVMCustomScriptExtension @Params
    If ($VMConfigure.IsSuccessStatusCode -eq $True) { Write-Host "Virtual Machine $VMName configured with $Blob successfully" }Else { Write-Host "*** Unable to configure Virtual Machine $VMName with $Blob ***" }
}

function ScriptBuild-Config {
    switch ($RVMSpec) {
        "Standard" {
            ConfigureStandardVM "$RVMVMName"
        }
        "AdminStudio" {
            ConfigureAdminStudioVM "$RVMVMName"

        }
    }

}

#region Main
Write-Host "Running RebuildVM.ps1"

if($RVMVMName -eq "") {
    $VMlist = Get-AzVM -Name * -ResourceGroupName $RVMResourceGroupName
    $RVMVMName = ($VMlist | where { $_.Name -ne "vmwleuchyperv1" } | select Name | ogv -Title "Select Virtual Machine to Rebuild" -PassThru).Name

    $VMSpec = @("Standard","AdminStudio")
    $RVMSpec = $VMSpec | ogv -Title "Select Virtual Machine Spec" -PassThru
}

Write-Host "Rebuilding $RVMVMName"
Try {
    ScriptBuild-Create
    ScriptBuild-Config
} Catch {
    Write-Error $_.Exception.Message
}
Write-Host "Completed RebuildVM.ps1"
#endregion Main