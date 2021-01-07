function ConfigureNetwork {
    $virtualNetwork = New-AzVirtualNetwork -ResourceGroupName $RGName -Location $Location -Name $VNet -AddressPrefix 10.0.0.0/16
    $subnetConfig = Add-AzVirtualNetworkSubnetConfig -Name default -AddressPrefix 10.0.0.0/24 -VirtualNetwork $virtualNetwork
        
    $rule1 = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
    $rule2 = New-AzNetworkSecurityRuleConfig -Name smb-rule -Description "Allow SMB" -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 445
    
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $RGName -Location $location -Name $NsgName -SecurityRules $rule1, $rule2     # $Rule1, $Rule2 etc. 
        If ($nsg.ProvisioningState -eq "Succeeded") {Write-Host "Network Security Group created successfully"}Else{Write-Host "*** Unable to create or configure Network Security Group! ***"}
    $Vnsc = Set-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $virtualNetwork -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsg
    $virtualNetwork | Set-AzVirtualNetwork >> null
        If ($virtualNetwork.ProvisioningState -eq "Succeeded") {Write-Host "Virtual Network created and associated with the Network Security Group successfully"}Else{Write-Host "*** Unable to create the Virtual Network, or associate it to the Network Security Group! ***"}
}

function CreateRBACConfig {
    $OwnerGroup = Get-AzAdGroup -DisplayName "Packaging-Owner-RBAC"
    $ContributorGroup = Get-AzAdGroup -DisplayName "Packaging-Contributor-RBAC"
    $ReadOnlyGroup = Get-AzAdGroup -DisplayName "Packaging-ReadOnly-RBAC"

    If ($OwnerGroup -eq $null){$Owner = New-AzureADGroup -DisplayName "Packaging-Owner-RBAC" -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet"}Else{Write-Host "Owner RBAC group already exists"}
    If ($ContributorGroup -eq $null){$Contributor = New-AzureADGroup -DisplayName "Packaging-Contributor-RBAC" -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet"}Else{Write-Host "Contributor RBAC group already exists"}
    If ($ReadOnlyGroup -eq $null){$ReadOnly = New-AzureADGroup -DisplayName "Packaging-ReadOnly-RBAC" -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet"}Else{Write-Host "ReadOnly RBAC group already exists"}   
        
    Start-Sleep -s 20

    Try
    {
        New-AzRoleAssignment -ObjectId $Owner.ObjectId -RoleDefinitionName "Owner" -ResourceGroupName $RGName
        New-AzRoleAssignment -ObjectId $Contributor.ObjectId -RoleDefinitionName "Contributor" -ResourceGroupName $RGName
        New-AzRoleAssignment -ObjectId $ReadOnly.ObjectId -RoleDefinitionName "Reader" -ResourceGroupName $RGName
    }
    Catch
    {
        Write-Error $_.Exception.Message
    }
}

function CreateStorageAccount {
    If ($StorAccRequired -eq $True)
        {
        $storageAccount = New-AzStorageAccount -ResourceGroupName $RGName -AccountName $StorAcc -Location uksouth -SkuName Standard_LRS
        $ctx = $storageAccount.Context
        $Container = New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Container
        If ($storageAccount.StorageAccountName -eq $StorAcc -and $Container.Name -eq $ContainerName) {Write-Host "Storage Account and container created successfully"}Else{Write-Host "*** Unable to create the Storage Account or container! ***"}    
        #$BlobUpload = Set-AzStorageBlobContent -File $BlobFilePath -Container $ContainerName -Blob $Blob -Context $ctx 
        Try
        {
            $Key = Get-AzStorageAccountKey -ResourceGroupName $RGName -AccountName $StorAcc
            $MapFileContent = (Get-Content -path "$ContainerScripts\$MapFileTmpl").replace("xxxx",$StorAcc) #| Set-Content -path "C:\Temp\PackagingVM\Config\MapDrv.ps1"
            $MapFileContent.replace("yyyy",$Key.value[0]) | Set-Content -path "C:\Temp\PackagingVM\Config\MapDrv.ps1"      
            $RunOnceContent = (Get-Content -path "$ContainerScripts\RunOnceTmpl.ps1").replace("xxxx",$StorAcc)
            $RunOnceContent.replace("rrrr",$RGName) | Set-Content -path "C:\Temp\PackagingVM\Config\RunOnce.ps1"
        }
        Catch
        {
            Write-Error "An error occured trying to create the Map script for the packaging share."
            Write-Error $_.Exception.Message
        }
        Get-ChildItem -Path $ContainerScripts -File -Recurse | Set-AzStorageBlobContent -Container "data" -Context $ctx
        }
        Else
        {
            Write-Host "Creation of Storage Account and Storage Container not required"
        } 
        $Share = New-AzStorageShare -Name "packaging" -Context $ctx  
}

#=======================================================================================================================================================

# Main Script

# Create RBAC groups and assignments
CreateRBACConfig

# Create VNet, NSG and rules (Comment out if not required)
ConfigureNetwork

# Create Storage Account and copy media (Comment out if not required)
CreateStorageAccount
