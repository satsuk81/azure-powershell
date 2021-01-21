function ConfigureNetwork {
    $virtualNetworkUAT = New-AzVirtualNetwork -ResourceGroupName $RGNameUAT -Location $Location -Name $VNetUAT -AddressPrefix 10.0.0.0/16
    $subnetConfigUAT = Add-AzVirtualNetworkSubnetConfig -Name default -AddressPrefix 10.0.0.0/24 -VirtualNetwork $virtualNetworkUAT
    $virtualNetworkPROD = New-AzVirtualNetwork -ResourceGroupName $RGNamePROD -Location $Location -Name $VNetPROD -AddressPrefix 10.0.0.0/16
    $subnetConfigPROD = Add-AzVirtualNetworkSubnetConfig -Name default -AddressPrefix 10.0.0.0/24 -VirtualNetwork $virtualNetworkPROD

    $rule1 = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
    $rule2 = New-AzNetworkSecurityRuleConfig -Name smb-rule -Description "Allow SMB" -Access Allow -Protocol Tcp -Direction Outbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 445
    
    $nsgUAT = New-AzNetworkSecurityGroup -ResourceGroupName $RGNameUAT -Location $location -Name $NsgNameUAT -SecurityRules $rule1, $rule2     # $Rule1, $Rule2 etc. 
        If ($nsgUAT.ProvisioningState -eq "Succeeded") {Write-Host "UAT Network Security Group created successfully"}Else{Write-Host "*** Unable to create or configure UAT Network Security Group! ***"}
    $VnscUAT = Set-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $virtualNetworkUAT -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsgUAT
    $virtualNetworkUAT | Set-AzVirtualNetwork >> null
        If ($virtualNetworkUAT.ProvisioningState -eq "Succeeded") {Write-Host "UAT Virtual Network created and associated with the Network Security Group successfully"}Else{Write-Host "*** Unable to create the UAT Virtual Network, or associate it to the Network Security Group! ***"}

    $nsgPROD = New-AzNetworkSecurityGroup -ResourceGroupName $RGNamePROD -Location $location -Name $NsgNamePROD -SecurityRules $rule1, $rule2     # $Rule1, $Rule2 etc. 
        If ($nsgPROD.ProvisioningState -eq "Succeeded") {Write-Host "PROD Network Security Group created successfully"}Else{Write-Host "*** Unable to create or configure PROD Network Security Group! ***"}
    $VnscPROD = Set-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $virtualNetworkPROD -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsgPROD
    $virtualNetworkPROD | Set-AzVirtualNetwork >> null
        If ($virtualNetworkPROD.ProvisioningState -eq "Succeeded") {Write-Host "PROD Virtual Network created and associated with the Network Security Group successfully"}Else{Write-Host "*** Unable to create the PROD Virtual Network, or associate it to the Network Security Group! ***"}
}

function CreateRBACConfig {
    $OwnerGroup = Get-AzAdGroup -DisplayName $rbacOwner
    $ContributorGroup = Get-AzAdGroup -DisplayName $rbacContributor
    $ReadOnlyGroup = Get-AzAdGroup -DisplayName $rbacReadOnly

    If ($OwnerGroup -eq $null){$Owner = New-AzADGroup -DisplayName $rbacOwner -MailNickName "NotSet"}Else{Write-Host "Owner RBAC group already exists";$Owner=$OwnerGroup}
    If ($ContributorGroup -eq $null){$Contributor = New-AzADGroup -DisplayName $rbacContributor -MailNickName "NotSet"}Else{Write-Host "Contributor RBAC group already exists";$Contributor=$ContributorGroup}
    If ($ReadOnlyGroup -eq $null){$ReadOnly = New-AzADGroup -DisplayName $rbacReadOnly -MailNickName "NotSet"}Else{Write-Host "ReadOnly RBAC group already exists";$ReadOnly=$ReadOnlyGroup}   
        
    Start-Sleep -s 20

    Try
    {
        New-AzRoleAssignment -ObjectId $Owner.Id -RoleDefinitionName "Owner" -ResourceGroupName $RGNameUAT | Out-Null
        New-AzRoleAssignment -ObjectId $Contributor.Id -RoleDefinitionName "Contributor" -ResourceGroupName $RGNameUAT | Out-Null
        New-AzRoleAssignment -ObjectId $ReadOnly.Id -RoleDefinitionName "Reader" -ResourceGroupName $RGNameUAT | Out-Null

        New-AzRoleAssignment -ObjectId $Owner.Id -RoleDefinitionName "Owner" -ResourceGroupName $RGNamePROD | Out-Null
        New-AzRoleAssignment -ObjectId $Contributor.Id -RoleDefinitionName "Contributor" -ResourceGroupName $RGNamePROD | Out-Null
        New-AzRoleAssignment -ObjectId $ReadOnly.Id -RoleDefinitionName "Reader" -ResourceGroupName $RGNamePROD | Out-Null

        Write-Host "Role Assignments Set"
    }
    Catch
    {
        Write-Error $_.Exception.Message
    }
}

function CreateStorageAccount {
    If ($StorAccRequired -eq $True)
        {
        $storageAccount = New-AzStorageAccount -ResourceGroupName $RGNameUAT -AccountName $StorAcc -Location uksouth -SkuName Standard_LRS
        $ctx = $storageAccount.Context
        $Container = New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Blob
        If ($storageAccount.StorageAccountName -eq $StorAcc -and $Container.Name -eq $ContainerName) {Write-Host "Storage Account and container created successfully"}Else{Write-Host "*** Unable to create the Storage Account or container! ***"}    
        #$BlobUpload = Set-AzStorageBlobContent -File $BlobFilePath -Container $ContainerName -Blob $Blob -Context $ctx 
        Try
        {
            $Key = Get-AzStorageAccountKey -ResourceGroupName $RGNameUAT -AccountName $StorAcc
            $MapFileContent = (Get-Content -path "$ContainerScripts\$MapFileTmpl").replace("xxxx",$StorAcc) #| Set-Content -path "$ContainerScripts\MapDrv.ps1"
            $MapFileContent.replace("yyyy",$Key.value[0]) | Set-Content -path "$ContainerScripts\MapDrv.ps1"      
            $RunOnceContent = (Get-Content -path "$ContainerScripts\RunOnceTmpl.ps1").replace("xxxx",$StorAcc)
            $RunOnceContent.replace("rrrr",$RGNameUAT) | Set-Content -path "$ContainerScripts\RunOnce.ps1"
        }
        Catch
        {
            Write-Error "An error occured trying to create the Map script for the packaging share."
            Write-Error $_.Exception.Message
        }
        $files = Get-ChildItem -Path $ContainerScripts -File -Recurse | Set-AzStorageBlobContent -Container "data" -Context $ctx
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
