Param(
    [switch]$CallFromCreatePackaging
)

$azSubscription = '743e9d63-59c8-42c3-b823-28bb773a88a6'
#$azSubscription = '1c3b43a4-90da-4988-9598-cab119913f5d'
#Connect-AzAccount -Subscription $azSubscription # MFA Account
#Connect-AzAccount -Credential $Cred -Subscription $azSubscription # Non-MFA

$SFLocalPath = "C:\Users\d.ames\OneDrive - Avanade\Documents\GitHub\azure-powershell\PackagingFactoryConfig-main"
$SFResourceGroupName = "rg-wl-prod-eucpackaging"
$SFStorageAccountName = "eucpackagingstoracc01"
$SFContainerName = "data"

function SyncFiles {
    Param(
        [String]$LocalPath,
        [String]$ResourceGroupName,
        [String]$StorageAccountName,
        [String]$ContainerName
    )

    $StorageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName
    if(!$Context){$Context = $storageAccount.Context}
    #if(!$Container){$Container = Get-AzStorageContainer -Name $ContainerName -Context $Context}
    $files = Get-ChildItem -Path $LocalPath -File -Recurse | Set-AzStorageBlobContent -Container $ContainerName -Context $Context -Force
}

switch ($CallFromCreatePackaging) {
    $True { SyncFiles -LocalPath $ContainerScripts -ResourceGroupName $RGNameUAT -ContainerName $ContainerName -StorageAccountName $StorAcc }
    $False {
        SyncFiles -LocalPath $SFLocalPath -ResourceGroupName $SFResourceGroupName -StorageAccountName $SFStorageAccountName -ContainerName $SFContainerName
    }
}