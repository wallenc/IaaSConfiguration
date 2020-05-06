<#
    .SYNOPSIS
        Enables Secure Transfer Required for Storage Accounts

    .DESCRIPTION
        This script will set secure transfer required to true for all storage accounts in
        specified resource groups or for an entire subscription

    .PARAMETER azureSubscriptionID
        ID of Azure subscription to use

    .PARAMETER azureEnvironment
        The Azure Cloud environment to use, i.e. AzureCloud, AzureUSGovernment

    .PARAMETER azureStorageAccounts
        List of one or more storage accounts to set secure transfered required

    .PARAMETER ResourceGroupNames
        List of Resource Groups. Storage accounts in the listed resource groups
        will have secure transfer required enabled

    .PARAMETER VMNames
        List of VMs to install OMS extension to
        Specified in the format ['vmname1','vmname2']

    .NOTES
        Version:        1.0
        Author:         Chris Wallen
        Creation Date:  04/30/2020
#>

Param
(
    #[parameter(mandatory)]
    [string]$azureSubscriptionId = 'd8abb5fd-9d00-48fd-862a-0f778306cce7',

    #[parameter(mandatory)]
    [string]$azureEnvironment = 'AzureUSGovernment',

    [string[]]$storageAccountNames = ("ansiblestor","ansiblergdiag"),

    [string[]]$resourceGroupNames
)


function Set-AzureConnection
{
    Param
    (
        [parameter(mandatory = $true)]
        $SubscriptionID,

        $AutomationConnection,

        $AzureEnvironment
    )

    $context = Get-AzContext

    if ($null -eq $context.Account)
    {
        $envARM = Get-AzEnvironment -Name $AzureEnvironment

        if ($null -ne $AutomationConnection)
        {
            $context = Add-AzAccount `
                -ServicePrincipal `
                -Tenant $Conn.TenantID `
                -ApplicationId $Conn.ApplicationID `
                -CertificateThumbprint $Conn.CertificateThumbprint `
                -Environment $envARM
        }
        else # if no connection info, log in using the web prompts
        {
            $context = Add-AzAccount -Environment $envARM -ErrorAction Stop
        }
    }

    $null = Set-AzContext -Subscription $azureSubscriptionID -ErrorAction Stop
}


if ($PSPrivateMetadata.JobId)
{
    # in Azure Automation
    # connect to Azure using AzureRunAs account
    $conn = Get-AutomationConnection -Name AzureRunAsConnection -ErrorAction Stop

    Set-AzureConnection -SubscriptionId $azureSubscriptionID -AutomationConnection $conn -AzureEnvironment $azureEnvironment -ErrorAction Stop
}
else
{
    # not in Azure Automation
    # connect to Azure using standard method
    Set-AzureConnection -SubscriptionId $azureSubscriptionID -AutomationConnection $conn -ErrorAction Stop
}

$azContext = Select-AzSubscription -subscriptionId $azureSubscriptionID -ErrorAction Stop

$storageAccounts = @()
$resourceGroups = @()

if (-not $resourceGroupNames -and -not $storageAccountNames)
{
    Write-Output "No resource groups or storage accounts specified. Collecting all storage accounts"
    $resourceGroups = (Get-AzResourceGroup).ResourceGroupName
    $storageAccounts = Get-AzStorageAccount | where { $_.EnableHttpsTrafficOnly -eq $false }
    #$resourceGroups = (Get-AzResourceGroup).ResourceGroupName
}
elseif (-not $storageAccountNames -and $resourceGroupNames)
{
    foreach ($rg in $resourceGroupNames)
    {
        Write-Output "Collecting storage accounts from RG: $rg"

        $storageAccounts += Get-AzStorageAccount -ResourceGroupName $rg | where { $_.EnableHttpsTrafficOnly -eq $false }
    }
}
else
{
    $resources = @()

    foreach ($account in $storageAccountNames)
    {
        $resources += (Get-AzResource | where{$_.Name -like "$account"})
    }
    foreach ($resource in $resources)
    {
        $storageAccounts += Get-AzStorageAccount -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
    }
}

foreach ($account in $storageAccounts)
{
    Write-Output "Setting EnableHTTPSTrafficOnly true for: $($account.StorageAccountName)"
    $null = Set-AzStorageAccount -Name $account.StorageAccountName -ResourceGroupName $account.ResourceGroupName -EnableHttpsTrafficOnly $true
}

