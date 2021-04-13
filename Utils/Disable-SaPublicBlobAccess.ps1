<#
    .SYNOPSIS
        Disables Public Blob Access for storage accounts

    .DESCRIPTION
        This script will disable public access for blob storage in the specified
        storage accounts, resource groups, or entire subscription

    .PARAMETER AzureSubscriptionId
        Azure subscription to use    

    .PARAMETER StorageAccountNames
        List of one or more storage accounts to disable public blob access

    .PARAMETER ResourceGroupNames
        List of Resource Groups. Storage accounts in the listed resource groups
        will have public blob access disables

    .NOTES
        Version:        1.0
        Author:         Chris Wallen
        Creation Date:  03/19/2021
#>

Param
(
    [parameter(Mandatory)]
    [string]
    $AzureSubscriptionId,    

    [string[]]
    $StorageAccountNames,

    [string[]]
    $ResourceGroupNames
)

$azContext = Set-AzContext -Subscription $AzureSubscriptionId -ErrorAction Stop

$storageAccounts = @()

#Collect all storage accounts in an RG if ResourceGroupNames parameter is specified
if (-not $StorageAccountNames -and $ResourceGroupNames)
{
    foreach ($rgName in $ResourceGroupNames)
    {
        Write-Output "Collecting all storage accounts in resource group $($rgName)"

        $storageAccounts += Get-AzStorageAccount `
            -ResourceGroupName $rgName | where { $_.AllowBlobPublicAccess -ne $false }
    }
}
#Collect all storage accounts specified in StorageAccountNames parameter
elseif ($StorageAccountNames -and -not $ResourceGroupNames)
{
    foreach ($saName in $StorageAccountNames)
    {
        $saResource = Get-AzResource -ResourceType 'Microsoft.Storage/storageAccounts' -Name $saName

        $storageAccounts += Get-AzStorageAccount `
            -StorageAccountName $saName `
            -ResourceGroupName $saResource.ResourceGroupName
    }
}
# Collect all SAs specified in both StorageAccountNames and ResourceGroupNames parameter
elseif ($StorageAccountNames -and $ResourceGroupNames)
{
    foreach ($saName in $StorageAccountNames)
    {
        # Get storage account resource to get the RG name since that's a required param if Name is specified
        $saResource = Get-AzResource -ResourceType 'Microsoft.Storage/storageAccounts' -Name $saName
        $storageAccounts += Get-AzStorageAccount `
            -StorageAccountName $saName `
            -ResourceGroupName $saResource.ResourceGroupName | Where { $_.AllowBlobPublicAccess -eq $null -or $_.AllowBlobPublicAccess -eq $true }
    }

    foreach ($rgName in $ResourceGroupNames)
    {
        $storageAccounts += Get-AzStorageAccount `
            -ResourceGroupName $rgName | where { $_.AllowBlobPublicAccess -eq $null -or $_.AllowBlobPublicAccess -eq $true }
    }
}
# Collect all storage accounts in subscription if neither StorageAccountNames or ResourceGroupNames
# parameters are specified
elseif (-not $StorageAccountNames -and -not $ResourceGroupNames)
{
    Write-Output "Collecting all storage accounts from subscription: $($azContext.Name)"

    $storageAccounts += Get-AzStorageAccount | where { $_.AllowBlobPublicAccess -eq $null -or $_.AllowBlobPublicAccess -eq $true }
}

# Loop through storage accounts and disable blob public access
foreach ($account in $storageAccounts)
{
    Write-Output "Setting AllowBlobPublicAccess false: $($account.StorageAccountName)"

    $null = Set-AzStorageAccount `
        -Name $account.StorageAccountName `
        -ResourceGroupName $account.ResourceGroupName `
        -AllowBlobPublicAccess $false
}