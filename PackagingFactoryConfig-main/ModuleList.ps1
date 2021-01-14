Get-Module -ListAvailable
$modules = Get-Module -ListAvailable | select Name, Path | Export-Csv -Path "c:\output.csv" -Force -NoTypeInformation

Import-Module UEV
$modules = Get-Module | select Name, Path | Export-Csv -Path "c:\output2.csv" -Force -NoTypeInformation

Import-Module Hyper-V
$modules = Get-Module | select Name, Path | Export-Csv -Path "c:\output3.csv" -Force -NoTypeInformation